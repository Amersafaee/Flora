import 'package:cloud_firestore/cloud_firestore.dart';
import 'plant.dart';

/// CRUD operations for the "plants" Firestore collection.
///
/// For now the collection is global (no auth). When you add Firebase Auth,
/// scope this to `users/{uid}/plants`.
class PlantRepository {
  PlantRepository._();
  static final PlantRepository instance = PlantRepository._();

  final _col = FirebaseFirestore.instance.collection('plants');

  // ─── READ ──────────────────────────────────────────────────────────────────

  /// Live stream of all plants, ordered by name.
  Stream<List<Plant>> watchAll() => _col
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map(Plant.fromDoc).toList());

  /// One-time fetch of a single plant.
  Future<Plant?> fetchById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? Plant.fromDoc(doc) : null;
  }

  // ─── WRITE ─────────────────────────────────────────────────────────────────

  /// Add a new plant and return its generated document ID.
  Future<String> add(Plant plant) async {
    final ref = await _col.add({
      ...plant.toMap(),
      'addedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Overwrite an existing plant document.
  Future<void> update(Plant plant) =>
      _col.doc(plant.id).set(plant.toMap(), SetOptions(merge: true));

  /// Mark a plant as watered right now and schedule next watering.
  Future<void> markWatered(String id, {int daysUntilNext = 3}) {
    final now  = DateTime.now();
    final next = now.add(Duration(days: daysUntilNext));
    return _col.doc(id).update({
      'lastWatered':  Timestamp.fromDate(now),
      'nextWatering': Timestamp.fromDate(next),
    });
  }

  /// Permanently delete a plant.
  Future<void> delete(String id) => _col.doc(id).delete();
}

