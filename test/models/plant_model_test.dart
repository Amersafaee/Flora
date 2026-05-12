import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_conservatory/models/plant_model.dart';

void main() {
  group('Plant Model Tests', () {
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
  });
}
