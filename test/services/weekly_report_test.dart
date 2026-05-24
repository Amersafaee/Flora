// Weekly Report Logic — Pure Unit Tests
//
// shouldShowWeeklyReport() has three layers of logic:
//   1. Weekday gate: only show on Sunday (weekday == 7)
//   2. Account age gate: if createdAt < 7 days ago → false  (Firebase-dependent)
//   3. Date guard: if last_weekly_report_date == today → false  (SharedPrefs-dependent)
//
// We test layers 1 and 3 with SharedPreferences.setMockInitialValues(),
// and layer 2 as isolated pure date-math (no Firebase needed).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Pure helper that mirrors the weekday gate in shouldShowWeeklyReport ───────
bool _isSunday(DateTime dt) => dt.weekday == DateTime.sunday;

// ── Pure helper that mirrors the account-age guard ────────────────────────────
bool _accountOldEnough(DateTime now, DateTime createdAt) {
  return now.difference(createdAt).inDays >= 7;
}

// ── Pure helper that mirrors the date-string guard ───────────────────────────
String _todayString(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

bool _alreadyShownToday(DateTime now, String? lastDateStr) {
  return lastDateStr == _todayString(now);
}

void main() {
  group('Weekly Report — Weekday Gate', () {
    test('Returns false on Monday (weekday 1)', () {
      final monday = DateTime(2025, 5, 19); // confirmed Monday
      expect(_isSunday(monday), isFalse);
    });

    test('Returns false on Tuesday (weekday 2)', () {
      final tuesday = DateTime(2025, 5, 20);
      expect(_isSunday(tuesday), isFalse);
    });

    test('Returns false on Wednesday (weekday 3)', () {
      final wednesday = DateTime(2025, 5, 21);
      expect(_isSunday(wednesday), isFalse);
    });

    test('Returns false on Saturday (weekday 6)', () {
      final saturday = DateTime(2025, 5, 24);
      expect(_isSunday(saturday), isFalse);
    });

    test('Returns true on Sunday (weekday 7)', () {
      final sunday = DateTime(2025, 5, 25); // confirmed Sunday
      expect(_isSunday(sunday), isTrue);
    });
  });

  group('Weekly Report — Account Age Guard (pure date math)', () {
    test('Returns false when account was created today (0 days old)', () {
      final now = DateTime(2025, 5, 25, 12, 0);
      final createdAt = DateTime(2025, 5, 25, 8, 0); // same day, earlier
      expect(_accountOldEnough(now, createdAt), isFalse);
    });

    test('Returns false when account is 3 days old', () {
      final now = DateTime(2025, 5, 25);
      final createdAt = now.subtract(const Duration(days: 3));
      expect(_accountOldEnough(now, createdAt), isFalse);
    });

    test('Returns false when account is 6 days old (boundary)', () {
      final now = DateTime(2025, 5, 25);
      final createdAt = now.subtract(const Duration(days: 6));
      expect(_accountOldEnough(now, createdAt), isFalse);
    });

    test('Returns true when account is exactly 7 days old', () {
      final now = DateTime(2025, 5, 25);
      final createdAt = now.subtract(const Duration(days: 7));
      expect(_accountOldEnough(now, createdAt), isTrue);
    });

    test('Returns true when account is 30 days old', () {
      final now = DateTime(2025, 5, 25);
      final createdAt = now.subtract(const Duration(days: 30));
      expect(_accountOldEnough(now, createdAt), isTrue);
    });
  });

  group('Weekly Report — Date String Guard (SharedPrefs)', () {
    test('todayString formats date correctly', () {
      final date = DateTime(2025, 5, 5);
      expect(_todayString(date), '2025-05-05');
    });

    test('todayString pads single-digit month and day with zeros', () {
      final date = DateTime(2025, 1, 7);
      expect(_todayString(date), '2025-01-07');
    });

    test('alreadyShownToday returns true when lastDateStr == today', () {
      final now = DateTime(2025, 5, 25);
      expect(_alreadyShownToday(now, '2025-05-25'), isTrue);
    });

    test('alreadyShownToday returns false when lastDateStr is yesterday', () {
      final now = DateTime(2025, 5, 25);
      expect(_alreadyShownToday(now, '2025-05-24'), isFalse);
    });

    test('alreadyShownToday returns false when lastDateStr is null (never shown)', () {
      final now = DateTime(2025, 5, 25);
      expect(_alreadyShownToday(now, null), isFalse);
    });

    test('SharedPreferences mock: last_weekly_report_date persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final now = DateTime(2025, 5, 25);
      final todayStr = _todayString(now);

      await prefs.setString('last_weekly_report_date', todayStr);

      final stored = prefs.getString('last_weekly_report_date');
      expect(stored, todayStr);
      expect(_alreadyShownToday(now, stored), isTrue);
    });

    test('SharedPreferences mock: absent key returns null (not shown yet)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final lastDate = prefs.getString('last_weekly_report_date');
      expect(lastDate, isNull);
      expect(_alreadyShownToday(DateTime(2025, 5, 25), lastDate), isFalse);
    });
  });

  group('Weekly Report — Combined logic simulation', () {
    test('Should NOT show: not Sunday', () {
      final wednesday = DateTime(2025, 5, 21);
      // Gate 1 fails → false; further gates irrelevant
      expect(_isSunday(wednesday), isFalse);
    });


    test('Should NOT show: Sunday but account too new', () {
      final sunday = DateTime(2025, 5, 25);
      // 2 days old — account age check fails
      final createdAt = sunday.subtract(const Duration(days: 2));
      // Gate 1 passes, Gate 2 fails
      expect(_isSunday(sunday), isTrue);
      expect(_accountOldEnough(sunday, createdAt), isFalse);
    });

    test('Should NOT show: Sunday, old account, already shown today', () {
      final sunday = DateTime(2025, 5, 25);
      final createdAt = sunday.subtract(const Duration(days: 30));
      const lastDate = '2025-05-25'; // already shown today
      // Gate 1 passes, Gate 2 passes, Gate 3 fails
      expect(_isSunday(sunday), isTrue);
      expect(_accountOldEnough(sunday, createdAt), isTrue);
      expect(_alreadyShownToday(sunday, lastDate), isTrue);
    });

    test('Should show: Sunday, old account, not shown today', () {
      final sunday = DateTime(2025, 5, 25);
      final createdAt = sunday.subtract(const Duration(days: 30));
      final lastDate = '2025-05-18'; // shown last Sunday, not today
      // All gates pass
      expect(_isSunday(sunday), isTrue);
      expect(_accountOldEnough(sunday, createdAt), isTrue);
      expect(_alreadyShownToday(sunday, lastDate), isFalse);
    });
  });
}
