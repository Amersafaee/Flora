import 'package:cloud_firestore/cloud_firestore.dart';

class Plant {
  final String id;
  final String name;
  final String commonName;
  final String category;
  final String zone;
  final String? zoneId;
  final String imageUrl;
  final String healthStatus;
  final DateTime dateAdded;
  final int healthScore;
  final bool isDeceased;
  final DateTime? deceasedDate;
  final String? memorialNote;
  final String? eulogy;
  final String? location;

  Plant({
    required this.id,
    required this.name,
    required this.commonName,
    required this.category,
    this.zone = '',
    this.zoneId,
    required this.imageUrl,
    required this.healthStatus,
    required this.dateAdded,
    this.healthScore = 100,
    this.isDeceased = false,
    this.deceasedDate,
    this.memorialNote,
    this.eulogy,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'commonName': commonName,
      'category': category,
      'imageUrl': imageUrl,
      'healthStatus': healthStatus,
      'dateAdded': dateAdded,
      'healthScore': healthScore,
      'isDeceased': isDeceased,
      'deceasedDate': deceasedDate,
      'memorialNote': memorialNote,
      'eulogy': eulogy,
      if (location != null && location!.isNotEmpty) 'location': location,
    };
  }

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      commonName: (map['commonName'] as String?) ?? '',
      category: (map['category'] as String?) ?? '',
      imageUrl: (map['imageUrl'] as String?) ?? '',
      healthStatus: (map['healthStatus'] as String?) ?? '',
      // Firestore can return numeric fields as double; use num? to handle both
      healthScore: (map['healthScore'] as num?)?.toInt() ?? 100,
      // Use == true pattern so int/null stored as bool doesn't throw TypeError
      isDeceased: map['isDeceased'] == true,
      deceasedDate: map['deceasedDate'] is Timestamp
          ? (map['deceasedDate'] as Timestamp).toDate()
          : (map['deceasedDate'] is DateTime
              ? map['deceasedDate'] as DateTime
              : null),
      memorialNote: (map['memorialNote'] as String?),
      eulogy: (map['eulogy'] as String?),
      location: (map['location'] as String?),
      dateAdded: map['dateAdded'] is Timestamp
          ? (map['dateAdded'] as Timestamp).toDate()
          : (map['dateAdded'] is DateTime
              ? map['dateAdded'] as DateTime
              : DateTime.now()),
    );
  }
}
