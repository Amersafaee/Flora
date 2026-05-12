import 'package:flutter_test/flutter_test.dart';
import 'package:digital_conservatory/utils/task_utils.dart';

void main() {
  group('Task Recurrence Tests (calculateNextDueDate)', () {
    test('daily repeat adds exactly 1 day', () {
      final currentDue = DateTime(2025, 1, 1);
      final nextDue = calculateNextDueDate(currentDue, 'daily');
      expect(nextDue, DateTime(2025, 1, 2));
    });

    test('every2days adds exactly 2 days', () {
      final currentDue = DateTime(2025, 1, 1);
      final nextDue = calculateNextDueDate(currentDue, 'every2days');
      expect(nextDue, DateTime(2025, 1, 3));
    });

    test('weekly adds exactly 7 days', () {
      final currentDue = DateTime(2025, 1, 1);
      final nextDue = calculateNextDueDate(currentDue, 'weekly');
      expect(nextDue, DateTime(2025, 1, 8));
    });

    test('biweekly adds exactly 14 days', () {
      final currentDue = DateTime(2025, 1, 1);
      final nextDue = calculateNextDueDate(currentDue, 'biweekly');
      expect(nextDue, DateTime(2025, 1, 15));
    });

    test('monthly adds 1 month', () {
      final currentDue = DateTime(2025, 1, 15);
      final nextDue = calculateNextDueDate(currentDue, 'monthly');
      expect(nextDue, DateTime(2025, 2, 15));
    });

    test('none repeat returns null or same date', () {
      final currentDue = DateTime(2025, 1, 1);
      final nextDue = calculateNextDueDate(currentDue, 'none');
      expect(nextDue, isNull);
    });

    test('Calculation from a specific known date produces the exact expected next date', () {
      final currentDue = DateTime(2024, 2, 28); // Leap year
      final nextDue = calculateNextDueDate(currentDue, 'daily');
      expect(nextDue, DateTime(2024, 2, 29));
    });

    test('Default recurrence uses repeatDays', () {
      final currentDue = DateTime(2025, 1, 1);
      final nextDue = calculateNextDueDate(currentDue, 'custom', 5);
      expect(nextDue, DateTime(2025, 1, 6));
    });
  });
}
