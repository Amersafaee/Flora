import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a plant in the user's collection.
class Plant {
  final String id;
  final String name;
  final String species;
  final String emoji;
  final String location;       // e.g. "Living room", "Balcony"
  final String wateringFreq;   // e.g. "Every 3 days"
  final String notes;
  final DateTime addedAt;
  final DateTime? lastWatered;
  final DateTime? nextWatering;

  const Plant({
    required this.id,
    required this.name,
    required this.species,
    this.emoji = '🪴',
    this.location = '',
    this.wateringFreq = '',
    this.notes = '',
    required this.addedAt,
    this.lastWatered,
    this.nextWatering,
  });

  /// Build from a Firestore document snapshot.
  factory Plant.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Plant(
      id:            doc.id,
      name:          d['name']          as String? ?? '',
      species:       d['species']       as String? ?? '',
      emoji:         d['emoji']         as String? ?? '🪴',
      location:      d['location']      as String? ?? '',
      wateringFreq:  d['wateringFreq']  as String? ?? '',
      notes:         d['notes']         as String? ?? '',
      addedAt:       (d['addedAt']      as Timestamp?)?.toDate() ?? DateTime.now(),
      lastWatered:   (d['lastWatered']  as Timestamp?)?.toDate(),
      nextWatering:  (d['nextWatering'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to a Firestore-compatible map.
  Map<String, dynamic> toMap() => {
    'name':         name,
    'species':      species,
    'emoji':        emoji,
    'location':     location,
    'wateringFreq': wateringFreq,
    'notes':        notes,
    'addedAt':      Timestamp.fromDate(addedAt),
    if (lastWatered  != null) 'lastWatered':  Timestamp.fromDate(lastWatered!),
    if (nextWatering != null) 'nextWatering': Timestamp.fromDate(nextWatering!),
  };

  Plant copyWith({
    String? name,
    String? species,
    String? emoji,
    String? location,
    String? wateringFreq,
    String? notes,
    DateTime? lastWatered,
    DateTime? nextWatering,
  }) => Plant(
    id:            id,
    name:          name          ?? this.name,
    species:       species       ?? this.species,
    emoji:         emoji         ?? this.emoji,
    location:      location      ?? this.location,
    wateringFreq:  wateringFreq  ?? this.wateringFreq,
    notes:         notes         ?? this.notes,
    addedAt:       addedAt,
    lastWatered:   lastWatered   ?? this.lastWatered,
    nextWatering:  nextWatering  ?? this.nextWatering,
  );
}

