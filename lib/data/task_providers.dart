import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Task model ────────────────────────────────────────────────────────────────
class CareTask {
  final String id;
  final String plantId;
  final String plantNickname;
  final String type; // water | fertilize | repot | mist
  final DateTime dueDate;
  final bool completed;
  final DateTime? completedAt;
  final int intervalDays;

  const CareTask({
    required this.id,
    required this.plantId,
    required this.plantNickname,
    required this.type,
    required this.dueDate,
    required this.completed,
    this.completedAt,
    required this.intervalDays,
  });

  factory CareTask.fromDoc(DocumentSnapshot doc, {String plantNickname = ''}) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return CareTask(
      id:            doc.id,
      plantId:       d['plantId']      as String? ?? '',
      plantNickname: plantNickname,
      type:          d['type']         as String? ?? 'water',
      dueDate:       (d['dueDate']     as Timestamp?)?.toDate() ?? DateTime.now(),
      completed:     d['completed']    as bool? ?? false,
      completedAt:   (d['completedAt'] as Timestamp?)?.toDate(),
      intervalDays:  d['intervalDays'] as int? ?? 7,
    );
  }
}

// ── Interval helpers ──────────────────────────────────────────────────────────
int waterInterval(String level) {
  switch (level.toLowerCase()) {
    case 'high':   return 4;
    case 'medium': return 7;
    default:       return 10; // low
  }
}

int fertilizeInterval(String level) {
  switch (level.toLowerCase()) {
    case 'high':   return 14;
    case 'medium': return 21;
    default:       return 30; // low
  }
}

// ── Create initial tasks for a new plant ──────────────────────────────────────
Future<void> createInitialTasks({
  required String uid,
  required String plantId,
  required String plantNickname,
  required Map<String, String> careDefaults,
}) async {
  if (uid.isEmpty || plantId.isEmpty) return;
  final now       = DateTime.now();
  final waterLvl  = careDefaults['water']      ?? 'medium';
  final fertilize = careDefaults['fertilizer'] ?? 'low';

  final batch = FirebaseFirestore.instance.batch();
  final col   = FirebaseFirestore.instance
      .collection('users').doc(uid)
      .collection('plants').doc(plantId)
      .collection('tasks');

  // Water task
  final wInterval = waterInterval(waterLvl);
  batch.set(col.doc(), {
    'plantId':      plantId,
    'type':         'water',
    'dueDate':      Timestamp.fromDate(now.add(Duration(days: wInterval))),
    'completed':    false,
    'completedAt':  null,
    'intervalDays': wInterval,
  });

  // Fertilize task
  final fInterval = fertilizeInterval(fertilize);
  batch.set(col.doc(), {
    'plantId':      plantId,
    'type':         'fertilize',
    'dueDate':      Timestamp.fromDate(now.add(Duration(days: fInterval))),
    'completed':    false,
    'completedAt':  null,
    'intervalDays': fInterval,
  });

  await batch.commit();
}

// ── Mark task complete + schedule next ────────────────────────────────────────
Future<void> completeTask(CareTask task) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || task.plantId.isEmpty) return;

  final now    = DateTime.now();
  final col    = FirebaseFirestore.instance
      .collection('users').doc(uid)
      .collection('plants').doc(task.plantId)
      .collection('tasks');

  final batch = FirebaseFirestore.instance.batch();

  // Mark done
  batch.update(col.doc(task.id), {
    'completed':   true,
    'completedAt': Timestamp.fromDate(now),
  });

  // Write next task
  batch.set(col.doc(), {
    'plantId':      task.plantId,
    'type':         task.type,
    'dueDate':      Timestamp.fromDate(now.add(Duration(days: task.intervalDays))),
    'completed':    false,
    'completedAt':  null,
    'intervalDays': task.intervalDays,
  });

  await batch.commit();
}

// ── Snooze task ───────────────────────────────────────────────────────────────
Future<void> snoozeTask(CareTask task, int days) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || task.plantId.isEmpty) return;
  final newDue = task.dueDate.add(Duration(days: days));
  await FirebaseFirestore.instance
      .collection('users').doc(uid)
      .collection('plants').doc(task.plantId)
      .collection('tasks').doc(task.id)
      .update({'dueDate': Timestamp.fromDate(newDue)});
}

// ── Stream: all pending tasks for today (across all plants) ───────────────────
// Used by Home Screen subtitle and notifications.
final todayTasksProvider = StreamProvider<List<CareTask>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay   = startOfDay.add(const Duration(days: 1));

  // We need to query across all plants — use a collection group query.
  return FirebaseFirestore.instance
      .collectionGroup('tasks')
      .where('completed', isEqualTo: false)
      .where('dueDate', isLessThan: Timestamp.fromDate(endOfDay))
      .snapshots()
      .map((snap) => snap.docs
          // Filter to only this user's plants (path check)
          .where((d) => d.reference.path.contains('users/$uid'))
          .map((d) => CareTask.fromDoc(d))
          .toList());
});

// ── Stream: tasks for a specific plant ────────────────────────────────────────
final plantTasksProvider =
    StreamProvider.family<List<CareTask>, String>((ref, plantId) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || plantId.isEmpty) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users').doc(uid)
      .collection('plants').doc(plantId)
      .collection('tasks')
      .orderBy('dueDate')
      .snapshots()
      .map((snap) => snap.docs.map((d) => CareTask.fromDoc(d)).toList());
});

