import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  final String id;
  final String senderUid;
  final String senderName;
  final String body;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessage(
      id: doc.id,
      senderUid: d['senderUid'] as String? ?? '',
      senderName: d['senderName'] as String? ?? 'User',
      body: d['body'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// Generate deterministic thread ID from two UIDs
String getThreadId(String uid1, String uid2) {
  final list = [uid1, uid2]..sort();
  return '${list[0]}_${list[1]}';
}

final messagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, threadId) {
  return FirebaseFirestore.instance
      .collection('threads')
      .doc(threadId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => ChatMessage.fromDoc(doc)).toList());
});

Future<void> sendSwapMessage(String threadId, String body, String senderName) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || body.trim().isEmpty) return;

  final docRef = FirebaseFirestore.instance
      .collection('threads')
      .doc(threadId)
      .collection('messages')
      .doc();

  final now = FieldValue.serverTimestamp();

  await docRef.set({
    'senderUid': user.uid,
    'senderName': senderName,
    'body': body.trim(),
    'createdAt': now,
  });

  // Update thread metadata to show in inbox
  await FirebaseFirestore.instance.collection('threads').doc(threadId).set({
    'lastMessage': body.trim(),
    'lastMessageAt': now,
    'participants': FieldValue.arrayUnion([user.uid]),
  }, SetOptions(merge: true));
  
  // Update last seen for sender
  await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('threadState').doc(threadId).set({
    'lastSeen': now,
  }, SetOptions(merge: true));
}

Future<void> updateLastSeen(String threadId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('threadState').doc(threadId).set({
    'lastSeen': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

// Stream to check if there are unread messages across threads.
// Simplification for MVP: We just check if there are any threads with lastMessageAt > lastSeen.
final unreadMessagesProvider = StreamProvider<bool>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(false);

  // This is a complex query to do strictly in Firestore without a Cloud Function keeping track.
  // For MVP, we'll just subscribe to user's threads and check locally against threadStates.
  return FirebaseFirestore.instance
      .collection('threads')
      .where('participants', arrayContains: user.uid)
      .snapshots()
      .asyncMap((threadsSnap) async {
        
        if (threadsSnap.docs.isEmpty) return false;

        final threadStatesSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('threadState')
            .get();

        final Map<String, Timestamp> lastSeenMap = {
          for (var doc in threadStatesSnap.docs)
            doc.id: doc.data()['lastSeen'] as Timestamp? ?? Timestamp.fromMillisecondsSinceEpoch(0)
        };

        for (final doc in threadsSnap.docs) {
          final data = doc.data();
          final lastMsgAt = data['lastMessageAt'] as Timestamp?;
          if (lastMsgAt == null) continue;

          final lastSeen = lastSeenMap[doc.id] ?? Timestamp.fromMillisecondsSinceEpoch(0);
          if (lastMsgAt.compareTo(lastSeen) > 0) {
            return true; // Found an unread thread
          }
        }
        return false;
      });
});

