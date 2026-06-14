import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:verdoro/models/task_model.dart';

void main() {
  group('Task Model Tests', () {
    // ── Existing tests (unchanged) ─────────────────────────────────────────

    test('Normal valid data parses correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'task1',
        'plantId': 'plant1',
        'plantName': 'Monstera',
        'taskType': 'Watering',
        'dueDate': Timestamp.fromDate(now),
        'isCompleted': false,
        'notes': 'Water well',
        'repeatType': 'weekly',
        'repeatDays': 7,
      };

      final task = Task.fromMap(map);
      expect(task.id, 'task1');
      expect(task.plantId, 'plant1');
      expect(task.plantName, 'Monstera');
      expect(task.taskType, 'Watering');
      expect(task.dueDate.difference(now).inSeconds, 0);
      expect(task.isCompleted, false);
      expect(task.notes, 'Water well');
      expect(task.repeatType, 'weekly');
      expect(task.repeatDays, 7);
    });

    test('Missing repeatDays defaults to 0', () {
      final map = {
        'id': 'task1',
        'plantName': 'Monstera',
        'taskType': 'Watering',
        'dueDate': Timestamp.fromDate(DateTime.now()),
        'isCompleted': false,
        'notes': 'Water well',
      };
      final task = Task.fromMap(map);
      expect(task.repeatDays, 0);
    });

    test('repeatDays stored as int parses without throwing', () {
      final map = {
        'id': 'task1',
        'plantName': 'Monstera',
        'taskType': 'Watering',
        'dueDate': Timestamp.fromDate(DateTime.now()),
        'isCompleted': false,
        'notes': 'Water well',
        'repeatDays': 5,
      };
      final task = Task.fromMap(map);
      expect(task.repeatDays, 5);
    });

    test('repeatDays stored as double parses correctly', () {
      final map = {
        'id': 'task1',
        'plantName': 'Monstera',
        'taskType': 'Watering',
        'dueDate': Timestamp.fromDate(DateTime.now()),
        'isCompleted': false,
        'notes': 'Water well',
        'repeatDays': 7.0,
      };
      final task = Task.fromMap(map);
      expect(task.repeatDays, 7);
    });

    test('Missing repeatType defaults to "none"', () {
      final map = {
        'id': 'task1',
        'plantName': 'Monstera',
        'taskType': 'Watering',
        'dueDate': Timestamp.fromDate(DateTime.now()),
        'isCompleted': false,
        'notes': 'Water well',
      };
      final task = Task.fromMap(map);
      expect(task.repeatType, 'none');
    });

    test('Missing plantId defaults to empty string', () {
      final map = {
        'id': 'task1',
        'plantName': 'Monstera',
        'taskType': 'Watering',
        'dueDate': Timestamp.fromDate(DateTime.now()),
        'isCompleted': false,
        'notes': 'Water well',
      };
      final task = Task.fromMap(map);
      expect(task.plantId, '');
    });

    test('isCompleted stored as bool true works', () {
      final map = {
        'id': 'task1',
        'plantName': 'Monstera',
        'taskType': 'Watering',
        'dueDate': Timestamp.fromDate(DateTime.now()),
        'isCompleted': true,
        'notes': 'Water well',
      };
      final task = Task.fromMap(map);
      expect(task.isCompleted, true);
    });

    test('isCompleted stored as null defaults to false', () {
      final map = {
        'id': 'task1',
        'plantName': 'Monstera',
        'taskType': 'Watering',
        'dueDate': Timestamp.fromDate(DateTime.now()),
        'isCompleted': null,
        'notes': 'Water well',
      };
      final task = Task.fromMap(map);
      expect(task.isCompleted, false);
    });

    test('dueDate stored as Timestamp parses to DateTime', () {
      final now = DateTime.now();
      final map = {
        'id': 'task1',
        'plantName': 'Monstera',
        'taskType': 'Watering',
        'dueDate': Timestamp.fromDate(now),
        'isCompleted': false,
        'notes': 'Water well',
      };
      final task = Task.fromMap(map);
      expect(task.dueDate.difference(now).inSeconds, 0);
    });

    test('dueDate stored as null defaults to DateTime.now() approximately', () {
      final before = DateTime.now();
      final map = {
        'id': 'task1',
        'plantName': 'Monstera',
        'taskType': 'Watering',
        'dueDate': null,
        'isCompleted': false,
        'notes': 'Water well',
      };
      final task = Task.fromMap(map);
      final after = DateTime.now();
      expect(task.dueDate.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(task.dueDate.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('toMap then fromMap round trip produces identical values', () {
      final now = DateTime.now();
      final originalTask = Task(
        id: 't1',
        plantId: 'p1',
        plantName: 'Snake Plant',
        taskType: 'Fertilize',
        dueDate: now,
        isCompleted: true,
        notes: 'Used liquid fertilizer',
        repeatType: 'monthly',
        repeatDays: 30,
      );

      final map = originalTask.toMap();
      final reconstructedTask = Task.fromMap(map);

      expect(reconstructedTask.id, originalTask.id);
      expect(reconstructedTask.plantId, originalTask.plantId);
      expect(reconstructedTask.plantName, originalTask.plantName);
      expect(reconstructedTask.taskType, originalTask.taskType);
      expect(reconstructedTask.dueDate, originalTask.dueDate);
      expect(reconstructedTask.isCompleted, originalTask.isCompleted);
      expect(reconstructedTask.notes, originalTask.notes);
      expect(reconstructedTask.repeatType, originalTask.repeatType);
      expect(reconstructedTask.repeatDays, originalTask.repeatDays);
    });

    test('Task with all fields populated serializes and deserializes correctly', () {
      final date = DateTime(2025, 1, 1);
      final map = {
        'id': 't2',
        'plantId': 'p2',
        'plantName': 'Pothos',
        'taskType': 'Water',
        'dueDate': Timestamp.fromDate(date),
        'isCompleted': true,
        'notes': 'done',
        'repeatType': 'weekly',
        'repeatDays': 7,
      };

      final task = Task.fromMap(map);
      final outMap = task.toMap();

      expect(outMap['id'], 't2');
      expect(outMap['plantId'], 'p2');
      expect(outMap['plantName'], 'Pothos');
      expect(outMap['taskType'], 'Water');
      expect(outMap['dueDate'], date);
      expect(outMap['isCompleted'], true);
      expect(outMap['notes'], 'done');
      expect(outMap['repeatType'], 'weekly');
      expect(outMap['repeatDays'], 7);
    });

    // ── New tests ──────────────────────────────────────────────────────────

    test('repeatDays stored as List<dynamic> (malformed data) throws TypeError', () {
      // In sound Dart, (map['repeatDays'] as num?) throws TypeError when the
      // value is a List — this documents the known behavior so future refactors
      // can choose to add a try/catch guard if resilience is needed.
      final map = {
        'id': 'task1',
        'plantName': 'Monstera',
        'taskType': 'Watering',
        'dueDate': Timestamp.fromDate(DateTime.now()),
        'isCompleted': false,
        'notes': '',
        'repeatDays': [7, 'weekly'], // malformed list value
      };
      // Sound Dart cannot cast List to num? — documents the throw behavior
      expect(() => Task.fromMap(map), throwsA(isA<TypeError>()));
    });


    test('dueDate stored as DateTime object (not Timestamp) parses correctly', () {
      final target = DateTime(2025, 8, 20, 10, 30);
      final map = {
        'id': 'task1',
        'plantName': 'Cactus',
        'taskType': 'Misting',
        'dueDate': target, // already a DateTime, not Timestamp
        'isCompleted': false,
        'notes': '',
      };
      final task = Task.fromMap(map);
      expect(task.dueDate, target);
    });

    test('toMap() includes all required Firestore fields', () {
      final due = DateTime(2025, 5, 1);
      final task = Task(
        id: 'task-abc',
        plantId: 'plant-xyz',
        plantName: 'Peace Lily',
        taskType: 'Inspection',
        dueDate: due,
        isCompleted: false,
        notes: 'Check for pests',
        repeatType: 'weekly',
        repeatDays: 7,
        climateAdjusted: true,
        climateNote: 'High humidity today',
      );

      final map = task.toMap();

      expect(map['id'], 'task-abc');
      expect(map['plantId'], 'plant-xyz');
      expect(map['plantName'], 'Peace Lily');
      expect(map['taskType'], 'Inspection');
      expect(map['dueDate'], due);
      expect(map['isCompleted'], false);
      expect(map['notes'], 'Check for pests');
      expect(map['repeatType'], 'weekly');
      expect(map['repeatDays'], 7);
      expect(map['climateAdjusted'], true);
      expect(map['climateNote'], 'High humidity today');
    });

    test('climateAdjusted and climateNote default correctly when missing', () {
      final map = {
        'id': 't3',
        'plantName': 'Orchid',
        'taskType': 'Watering',
        'dueDate': Timestamp.fromDate(DateTime.now()),
        'isCompleted': false,
        'notes': '',
      };
      final task = Task.fromMap(map);
      expect(task.climateAdjusted, false);
      expect(task.climateNote, '');
    });

    test('Missing dueDate does not throw and returns a valid DateTime', () {
      final map = {
        'id': 't4',
        'plantName': 'Basil',
        'taskType': 'Watering',
        'isCompleted': false,
        'notes': '',
        // dueDate deliberately omitted
      };
      expect(() => Task.fromMap(map), returnsNormally);
      final task = Task.fromMap(map);
      expect(task.dueDate, isA<DateTime>());
    });
  });
}
