import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpeciesDoc {
  final String id;
  final String commonName;
  final String scientificName;
  final String category;
  final List<String> traits;
  final String imageQuery;
  final Map<String, String> careDefaults;
  final Map<String, String> careGuide;

  SpeciesDoc({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.category,
    required this.traits,
    required this.imageQuery,
    required this.careDefaults,
    required this.careGuide,
  });

  factory SpeciesDoc.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SpeciesDoc(
      id: doc.id,
      commonName: data['commonName'] as String? ?? 'Unknown',
      scientificName: data['scientificName'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      traits: List<String>.from(data['traits'] ?? []),
      imageQuery: data['imageQuery'] as String? ?? 'plant',
      careDefaults: Map<String, String>.from(data['careDefaults'] ?? {}),
      careGuide: Map<String, String>.from(data['careGuide'] ?? {}),
    );
  }
}

// ── Search & Filter State ───────────────────────────────────────────────────

final wikiSearchQueryProvider = StateProvider<String>((ref) => '');
final wikiActiveFilterProvider = StateProvider<String>((ref) => 'All');

// ── Species List Provider ───────────────────────────────────────────────────
// For the Wiki Screen (loads 15 at a time, plus filtering)
// Note: This is a simple StreamProvider without complex pagination for now, 
// to ensure a working MVP. We apply the filter on traits directly.

final speciesListProvider = StreamProvider<List<SpeciesDoc>>((ref) {
  final activeFilter = ref.watch(wikiActiveFilterProvider);
  
  Query query = FirebaseFirestore.instance.collection('species').limit(50);
  
  if (activeFilter != 'All') {
    query = query.where('traits', arrayContains: activeFilter);
  }

  return query.snapshots().map((snap) => 
    snap.docs.map((doc) => SpeciesDoc.fromDoc(doc)).toList()
  );
});

// ── Single Species Provider ─────────────────────────────────────────────────
final speciesDetailProvider = StreamProvider.family<SpeciesDoc?, String>((ref, id) {
  return FirebaseFirestore.instance.collection('species').doc(id).snapshots().map((doc) {
    if (!doc.exists) return null;
    return SpeciesDoc.fromDoc(doc);
  });
});

