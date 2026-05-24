import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_conservatory/models/plant_model.dart';

void main() {
  group('Plant Model Tests', () {
    // ── Existing tests (unchanged) ─────────────────────────────────────────

    test('Normal valid data parses correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'p1',
        'name': 'Bob',
        'commonName': 'Monstera',
        'category': 'Tropical',
        'zone': 'Living Room',
        'imageUrl': 'http://example.com/img.png',
        'healthStatus': 'Healthy',
        'dateAdded': Timestamp.fromDate(now),
        'healthScore': 95,
        'isDeceased': false,
      };

      final plant = Plant.fromMap(map);
      expect(plant.id, 'p1');
      expect(plant.name, 'Bob');
      expect(plant.commonName, 'Monstera');
      expect(plant.category, 'Tropical');
      expect(plant.zone, 'Living Room');
      expect(plant.imageUrl, 'http://example.com/img.png');
      expect(plant.healthStatus, 'Healthy');
      expect(plant.dateAdded.difference(now).inSeconds, 0);
      expect(plant.healthScore, 95);
      expect(plant.isDeceased, false);
    });

    test('Missing healthScore defaults to 100', () {
      final map = {
        'id': 'p1',
      };
      final plant = Plant.fromMap(map);
      expect(plant.healthScore, 100);
    });

    test('Missing isDeceased defaults to false', () {
      final map = {
        'id': 'p1',
      };
      final plant = Plant.fromMap(map);
      expect(plant.isDeceased, false);
    });

    test('dateAdded as Timestamp parses correctly', () {
      final date = DateTime(2023, 5, 5);
      final map = {
        'dateAdded': Timestamp.fromDate(date),
      };
      final plant = Plant.fromMap(map);
      expect(plant.dateAdded, date);
    });

    test('dateAdded as null does not throw', () {
      final map = {
        'dateAdded': null,
      };
      final plant = Plant.fromMap(map);
      expect(plant.dateAdded, isNotNull);
    });

    test('Round trip fromMap toMap produces identical values', () {
      final date = DateTime(2024, 1, 1);
      final deceasedDate = DateTime(2025, 1, 1);
      final original = Plant(
        id: 'p1',
        name: 'Bob',
        commonName: 'Ficus',
        category: 'Tree',
        zone: 'Office',
        imageUrl: 'url',
        healthStatus: 'Critical',
        dateAdded: date,
        healthScore: 10,
        isDeceased: true,
        deceasedDate: deceasedDate,
        memorialNote: 'Miss you',
        eulogy: 'A great plant',
      );

      final map = original.toMap();
      final copy = Plant.fromMap(map);

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.commonName, original.commonName);
      expect(copy.category, original.category);
      expect(copy.zone, original.zone);
      expect(copy.imageUrl, original.imageUrl);
      expect(copy.healthStatus, original.healthStatus);
      expect(copy.dateAdded, original.dateAdded);
      expect(copy.healthScore, original.healthScore);
      expect(copy.isDeceased, original.isDeceased);
      expect(copy.deceasedDate, original.deceasedDate);
      expect(copy.memorialNote, original.memorialNote);
      expect(copy.eulogy, original.eulogy);
    });

    // ── New tests ──────────────────────────────────────────────────────────

    test('healthScore stored as double (e.g. 82.0) converts to int', () {
      final map = {
        'id': 'p1',
        'healthScore': 82.0, // Firestore can return double for numeric fields
      };
      final plant = Plant.fromMap(map);
      expect(plant.healthScore, isA<int>());
      expect(plant.healthScore, 82);
    });

    test('isDeceased stored as int 1 is treated as false (not == true)', () {
      // Only the Dart literal `true` should be accepted — int 1 must not pass
      final map = {
        'id': 'p1',
        'isDeceased': 1, // integer, not bool true
      };
      final plant = Plant.fromMap(map);
      expect(plant.isDeceased, false);
    });

    test('isDeceased stored as bool true is treated as true', () {
      final map = {
        'id': 'p1',
        'isDeceased': true,
      };
      final plant = Plant.fromMap(map);
      expect(plant.isDeceased, true);
    });

    test('All string fields null in map default to empty string', () {
      final map = <String, dynamic>{
        'id': null,
        'name': null,
        'commonName': null,
        'category': null,
        'zone': null,
        'imageUrl': null,
        'healthStatus': null,
      };
      final plant = Plant.fromMap(map);
      expect(plant.id, '');
      expect(plant.name, '');
      expect(plant.commonName, '');
      expect(plant.category, '');
      expect(plant.zone, '');
      expect(plant.imageUrl, '');
      expect(plant.healthStatus, '');
    });

    test('toMap() produces all required keys', () {
      final date = DateTime(2024, 6, 15);
      final plant = Plant(
        id: 'p99',
        name: 'Snake Plant',
        commonName: 'Sansevieria',
        category: 'Succulent',
        zone: 'Bedroom',
        imageUrl: 'https://example.com/snake.jpg',
        healthStatus: 'Healthy',
        dateAdded: date,
        healthScore: 90,
        isDeceased: false,
      );

      final map = plant.toMap();

      expect(map.containsKey('id'), isTrue);
      expect(map.containsKey('name'), isTrue);
      expect(map.containsKey('commonName'), isTrue);
      expect(map.containsKey('category'), isTrue);
      expect(map.containsKey('zone'), isTrue);
      expect(map.containsKey('imageUrl'), isTrue);
      expect(map.containsKey('healthStatus'), isTrue);
      expect(map.containsKey('dateAdded'), isTrue);
      expect(map.containsKey('healthScore'), isTrue);
      expect(map.containsKey('isDeceased'), isTrue);

      expect(map['id'], 'p99');
      expect(map['name'], 'Snake Plant');
      expect(map['healthScore'], 90);
      expect(map['isDeceased'], false);
    });

    test('toMap() omits location key when location is null', () {
      final plant = Plant(
        id: 'p1',
        name: 'Cactus',
        commonName: 'Cactaceae',
        category: 'Cactus',
        zone: '',
        imageUrl: '',
        healthStatus: 'Healthy',
        dateAdded: DateTime.now(),
        location: null,
      );
      final map = plant.toMap();
      expect(map.containsKey('location'), isFalse);
    });

    test('toMap() includes location key when location is non-empty', () {
      final plant = Plant(
        id: 'p1',
        name: 'Fern',
        commonName: 'Pteridophyte',
        category: 'Fern',
        zone: '',
        imageUrl: '',
        healthStatus: 'Healthy',
        dateAdded: DateTime.now(),
        location: 'Living Room',
      );
      final map = plant.toMap();
      expect(map.containsKey('location'), isTrue);
      expect(map['location'], 'Living Room');
    });

    test('deceasedDate stored as Timestamp parses correctly', () {
      final date = DateTime(2025, 3, 10);
      final map = {
        'id': 'p1',
        'isDeceased': true,
        'deceasedDate': Timestamp.fromDate(date),
      };
      final plant = Plant.fromMap(map);
      expect(plant.deceasedDate, date);
    });

    test('deceasedDate stored as null remains null', () {
      final map = {
        'id': 'p1',
        'deceasedDate': null,
      };
      final plant = Plant.fromMap(map);
      expect(plant.deceasedDate, isNull);
    });
  });
}
