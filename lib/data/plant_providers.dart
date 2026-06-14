import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verdoro/services/demo_config_service.dart';

// Inline mock plant data for demo mode (5 items)
final List<PlantDoc> _mockPlants = [
  PlantDoc(
    id: 'p1',
    commonName: 'Snake Plant',
    scientificName: 'Sansevieria trifasciata',
    nickname: 'Greeny',
    zone: '5',
    traits: ['Low Light', 'Hardy'],
    careDefaults: {'water': 'low', 'fertilizer': 'low'},
    healthStatus: 'healthy',
    photoBase64: '',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  ),
  PlantDoc(
    id: 'p2',
    commonName: 'Monstera Deliciosa',
    scientificName: 'Monstera deliciosa',
    nickname: 'Monster',
    zone: '9',
    traits: ['Tropical', 'Medium Light'],
    careDefaults: {'water': 'medium', 'fertilizer': 'medium'},
    healthStatus: 'healthy',
    photoBase64: '',
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
  ),
  PlantDoc(
    id: 'p3',
    commonName: 'Aloe Vera',
    scientificName: 'Aloe barbadensis',
    nickname: 'Aloe',
    zone: '8',
    traits: ['Succulent', 'Bright Light'],
    careDefaults: {'water': 'low', 'fertilizer': 'low'},
    healthStatus: 'healthy',
    photoBase64: '',
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
  ),
  PlantDoc(
    id: 'p4',
    commonName: 'Peace Lily',
    scientificName: 'Spathiphyllum',
    nickname: 'Lily',
    zone: '6',
    traits: ['Low Light', 'Moist'],
    careDefaults: {'water': 'medium', 'fertilizer': 'low'},
    healthStatus: 'healthy',
    photoBase64: '',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  PlantDoc(
    id: 'p5',
    commonName: 'Fiddle Leaf Fig',
    scientificName: 'Ficus lyrata',
    nickname: 'Figgy',
    zone: '10',
    traits: ['Bright Light', 'Large'],
    careDefaults: {'water': 'medium', 'fertilizer': 'high'},
    healthStatus: 'healthy',
    photoBase64: '',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

/// Riverpod StreamProvider: live list of the signed-in user's plants.
/// Path: users/{uid}/plants — ordered by createdAt descending.
final userPlantsProvider = StreamProvider<List<PlantDoc>>((ref) async* {
  if (await DemoConfigService.useMockData()) {
    // Return mock plants for demo
    yield _mockPlants;
    return;
  }
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    yield const [];
    return;
  }
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('plants')
      .orderBy('createdAt', descending: true)
      .get();
  yield snap.docs.map((d) => PlantDoc.fromDoc(d)).toList();
});

/// Riverpod StreamProvider (family): single plant by ID.
final plantByIdProvider =
    StreamProvider.family<PlantDoc?, String>((ref, plantId) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || plantId.isEmpty) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('plants')
      .doc(plantId)
      .snapshots()
      .map((d) => d.exists ? PlantDoc.fromDoc(d) : null);
});

/// Riverpod StreamProvider (family): growth journal for a plant.
final growthJournalProvider =
    StreamProvider.family<List<GrowthEntry>, String>((ref, plantId) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || plantId.isEmpty) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('plants')
      .doc(plantId)
      .collection('growth')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => GrowthEntry.fromDoc(d)).toList());
});

// ─── Plant document model ──────────────────────────────────────────────────
class PlantDoc {
  final String id;
  final String commonName;
  final String scientificName;
  final String nickname;
  final String zone;
  final List<String> traits;
  final Map<String, String> careDefaults; // sun, water, fertilizer
  final String healthStatus;
  final String photoBase64;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  const PlantDoc({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.nickname,
    required this.zone,
    required this.traits,
    required this.careDefaults,
    required this.healthStatus,
    required this.photoBase64,
    required this.createdAt,
    this.lastUpdated,
  });

  factory PlantDoc.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return PlantDoc(
      id: doc.id,
      commonName:     d['commonName']     as String? ?? '',
      scientificName: d['scientificName'] as String? ?? '',
      nickname:       d['nickname']       as String? ?? d['commonName'] as String? ?? '',
      zone:           d['zone']           as String? ?? '',
      traits:         List<String>.from(d['traits'] ?? []),
      careDefaults:   Map<String, String>.from(d['careDefaults'] ?? {}),
      healthStatus:   d['healthStatus']   as String? ?? 'healthy',
      photoBase64:    d['photoBase64']    as String? ?? '',
      createdAt:      (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated:    (d['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }
}

// ─── Growth entry model ────────────────────────────────────────────────────
class GrowthEntry {
  final String id;
  final String photoBase64;
  final String note;
  final double? heightCm;
  final DateTime createdAt;

  const GrowthEntry({
    required this.id,
    required this.photoBase64,
    required this.note,
    this.heightCm,
    required this.createdAt,
  });

  factory GrowthEntry.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return GrowthEntry(
      id:          doc.id,
      photoBase64: d['photoBase64'] as String? ?? '',
      note:        d['note']        as String? ?? '',
      heightCm:    (d['heightCm']   as num?)?.toDouble(),
      createdAt:   (d['createdAt']  as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

