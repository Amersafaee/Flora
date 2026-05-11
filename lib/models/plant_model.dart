import 'package:cloud_firestore/cloud_firestore.dart';

class Plant {
  final String id;
  final String name;
  final String commonName;
  final String category;
  final String zone;
  final String imageUrl;
  final String healthStatus;
  final DateTime dateAdded;
  final int healthScore;
  final bool isDeceased;
  final DateTime? deceasedDate;
  final String? memorialNote;
  final String? eulogy;

  Plant({
    required this.id,
    required this.name,
    required this.commonName,
    required this.category,
    required this.zone,
    required this.imageUrl,
    required this.healthStatus,
    required this.dateAdded,
    this.healthScore = 100,
    this.isDeceased = false,
    this.deceasedDate,
    this.memorialNote,
    this.eulogy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'commonName': commonName,
      'category': category,
      'zone': zone,
      'imageUrl': imageUrl,
      'healthStatus': healthStatus,
      'dateAdded': dateAdded,
      'healthScore': healthScore,
      'isDeceased': isDeceased,
      'deceasedDate': deceasedDate,
      'memorialNote': memorialNote,
      'eulogy': eulogy,
    };
  }

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      commonName: map['commonName'] ?? '',
      category: map['category'] ?? '',
      zone: map['zone'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      healthStatus: map['healthStatus'] ?? '',
      healthScore: map['healthScore'] ?? 100,
      isDeceased: map['isDeceased'] ?? false,
      deceasedDate: map['deceasedDate'] is Timestamp ? (map['deceasedDate'] as Timestamp).toDate() : null,
      memorialNote: map['memorialNote'],
      eulogy: map['eulogy'],
      dateAdded: map['dateAdded'] is Timestamp 
          ? (map['dateAdded'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }
}
