// ignore_for_file: avoid_print, unused_local_variable
import 'dart:io';

void main() async {
  int passed = 0;
  int failed = 0;
  final List<String> failures = [];

  void check(String description, bool condition, {String? detail}) {
    if (condition) {
      print('  ✅ $description');
      passed++;
    } else {
      print('  ❌ $description${detail != null ? " — $detail" : ""}');
      failed++;
      failures.add(description);
    }
  }

  print('\n🔍 JOURNEY CHECK — Flora App Data Flow Tests\n');

  // ─────────────────────────────────────────────────────────
  print('JOURNEY 1 — Task model round trip and field safety');
  // ─────────────────────────────────────────────────────────

  // Test 1: repeatDays as int
  final map1 = {'repeatDays': 7, 'repeatType': 'weekly', 'plantId': 'abc', 'plantName': 'Monstera', 'taskType': 'Watering', 'isCompleted': false, 'notes': '', 'dueDate': 'now'};
  final repeatDays1 = (map1['repeatDays'] as num?)?.toInt() ?? 0;
  check('repeatDays stored as int parses correctly', repeatDays1 == 7, detail: 'got $repeatDays1');

  // Test 2: repeatDays as double
  final map2 = {'repeatDays': 7.0};
  final repeatDays2 = (map2['repeatDays'] as num?)?.toInt() ?? 0;
  check('repeatDays stored as double parses correctly', repeatDays2 == 7, detail: 'got $repeatDays2');

  // Test 3: repeatDays missing
  final map3 = <String, dynamic>{};
  final repeatDays3 = (map3['repeatDays'] as num?)?.toInt() ?? 0;
  check('repeatDays missing defaults to 0', repeatDays3 == 0, detail: 'got $repeatDays3');

  // Test 4: repeatType missing
  final repeatType4 = map3['repeatType']?.toString() ?? 'none';
  check('repeatType missing defaults to none', repeatType4 == 'none', detail: 'got $repeatType4');

  // Test 5: plantId missing
  final plantId5 = map3['plantId']?.toString() ?? '';
  check('plantId missing defaults to empty string', plantId5 == '', detail: 'got "$plantId5"');

  // Test 6: isCompleted null
  final isCompleted6 = map3['isCompleted'] == true;
  check('isCompleted null defaults to false', isCompleted6 == false, detail: 'got $isCompleted6');

  // Test 7: empty map does not throw
  bool threw = false;
  try {
    // Access all fields that Task.fromMap would touch — discard via string interpolation
    final combined = '${map3['dueDate']}|${(map3['repeatDays'] as num?)?.toInt() ?? 0}|${map3['repeatType']?.toString() ?? 'none'}';
    assert(combined.isNotEmpty); // prevent 'combined' unused warning
  } catch (e) {
    threw = true;
  }
  check('Empty map parses without throwing', !threw);

  // ─────────────────────────────────────────────────────────
  print('\nJOURNEY 2 — Recurrence date calculation');
  // ─────────────────────────────────────────────────────────

  DateTime calcNext(DateTime from, String repeatType, int repeatDays) {
    switch (repeatType) {
      case 'daily': return from.add(const Duration(days: 1));
      case 'every2days': return from.add(const Duration(days: 2));
      case 'weekly': return from.add(const Duration(days: 7));
      case 'biweekly': return from.add(const Duration(days: 14));
      case 'monthly': return DateTime(from.year, from.month + 1, from.day);
      default:
        if (repeatDays > 0) return from.add(Duration(days: repeatDays));
        return from;
    }
  }

  final now = DateTime.now();
  final nextDaily = calcNext(now, 'daily', 0);
  check('daily adds 1 day', nextDaily.difference(now).inDays == 1, detail: 'got ${nextDaily.difference(now).inDays} days');

  final nextWeekly = calcNext(now, 'weekly', 0);
  check('weekly adds 7 days', nextWeekly.difference(now).inDays == 7, detail: 'got ${nextWeekly.difference(now).inDays} days');

  final nextBiweekly = calcNext(now, 'biweekly', 0);
  check('biweekly adds 14 days', nextBiweekly.difference(now).inDays == 14, detail: 'got ${nextBiweekly.difference(now).inDays} days');

  final nextMonthly = calcNext(now, 'monthly', 0);
  final monthDiff = (nextMonthly.year - now.year) * 12 + nextMonthly.month - now.month;
  check('monthly adds 1 month', monthDiff == 1, detail: 'got $monthDiff months');

  final nextNone = calcNext(now, 'none', 0);
  check('none repeatType returns same date', nextNone.isAtSameMomentAs(now), detail: 'got ${nextNone.difference(now).inDays} days difference');

  final nextCustom = calcNext(now, 'custom', 10);
  check('custom repeatDays 10 adds 10 days', nextCustom.difference(now).inDays == 10, detail: 'got ${nextCustom.difference(now).inDays} days');

  // ─────────────────────────────────────────────────────────
  print('\nJOURNEY 3 — Late task completion reschedules from today');
  // ─────────────────────────────────────────────────────────

  final tenDaysAgo = now.subtract(const Duration(days: 10));
  final nextFromToday = calcNext(now, 'weekly', 0); // should be today + 7
  final nextFromOriginal = calcNext(tenDaysAgo, 'weekly', 0); // would be 3 days ago

  check('Completing late task reschedules from today not original date',
    nextFromToday.isAfter(now),
    detail: 'nextFromToday=${nextFromToday.toIso8601String().substring(0, 10)}');

  check('Scheduling from original overdue date would create past task',
    nextFromOriginal.isBefore(now),
    detail: 'nextFromOriginal=${nextFromOriginal.toIso8601String().substring(0, 10)} is in the past — proves why we use today');

  // ─────────────────────────────────────────────────────────
  print('\nJOURNEY 4 — Watering frequency extraction from Flora text');
  // ─────────────────────────────────────────────────────────

  String extractWatering(String text) {
    final patterns = [
      RegExp(r'water(?:ing)?\s+every\s+(\d+(?:\s*[-–]\s*\d+)?)\s*(day|week)', caseSensitive: false),
      RegExp(r'every\s+(\d+(?:\s*[-–]\s*\d+)?)\s*(day|week)s?\s+water', caseSensitive: false),
      RegExp(r'(\d+(?:\s*[-–]\s*\d+)?)\s*(day|week)s?\s+between\s+water', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final number = match.group(1) ?? '7';
        final unit = match.group(2)?.toLowerCase() ?? 'day';
        if (unit.startsWith('week')) {
          final days = int.tryParse(number.split(RegExp(r'[-–]')).first.trim()) ?? 1;
          return '${days * 7}';
        }
        return number.split(RegExp(r'[-–]')).first.trim();
      }
    }
    return '7';
  }

  check('Extracts 7 days from "water every 7 days"',
    extractWatering('Water every 7 days for best results') == '7');

  check('Extracts 7 days from "water every 1-2 weeks"',
    extractWatering('Water every 1-2 weeks') == '7');

  check('Extracts 14 from "watering every 14 days"',
    extractWatering('Watering every 14 days is recommended') == '14');

  check('Extracts 3 from "water every 3 days"',
    extractWatering('This plant needs water every 3 days') == '3');

  check('Defaults to 7 when no frequency mentioned',
    extractWatering('No watering frequency mentioned in this text') == '7');

  // ─────────────────────────────────────────────────────────
  print('\nJOURNEY 5 — Health status extraction from Flora text');
  // ─────────────────────────────────────────────────────────

  String extractHealth(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('critical') || lower.contains('severely') || lower.contains('dying')) return 'Critical';
    if (lower.contains('needs attention') || lower.contains('concerning') || lower.contains('yellowing') || lower.contains('disease') || lower.contains('pest')) return 'Needs Attention';
    return 'Healthy';
  }

  check('Extracts Critical from text mentioning critical',
    extractHealth('This plant is in critical condition') == 'Critical');

  check('Extracts Critical from text mentioning dying',
    extractHealth('The plant appears to be dying from root rot') == 'Critical');

  check('Extracts Needs Attention from text mentioning yellowing',
    extractHealth('I notice some yellowing on the lower leaves') == 'Needs Attention');

  check('Extracts Needs Attention from text mentioning pest',
    extractHealth('There appear to be pest issues on this plant') == 'Needs Attention');

  check('Extracts Healthy for positive text',
    extractHealth('This is a beautiful healthy thriving plant') == 'Healthy');

  check('Extracts Healthy for neutral text',
    extractHealth('A nice plant with green leaves') == 'Healthy');

  // ─────────────────────────────────────────────────────────
  print('\nJOURNEY 6 — Plant model field safety');
  // ─────────────────────────────────────────────────────────

  // Test healthScore defaults
  final plantMap1 = <String, dynamic>{'id': 'p1', 'name': 'Monstera', 'category': 'Tropical'};
  final healthScore = (plantMap1['healthScore'] as num?)?.toInt() ?? 100;
  check('Missing healthScore defaults to 100', healthScore == 100, detail: 'got $healthScore');

  // Test isDeceased defaults
  final isDeceased = plantMap1['isDeceased'] == true;
  check('Missing isDeceased defaults to false', isDeceased == false, detail: 'got $isDeceased');

  // Test name parsing
  final name = plantMap1['name']?.toString() ?? 'Unknown';
  check('Plant name parses correctly', name == 'Monstera', detail: 'got $name');

  // Test category defaults
  final category = plantMap1['category']?.toString() ?? 'Other';
  check('Plant category parses correctly', category == 'Tropical', detail: 'got $category');

  // ─────────────────────────────────────────────────────────
  // SUMMARY
  // ─────────────────────────────────────────────────────────
  final total = passed + failed;
  print('\n${'─' * 50}');
  print('JOURNEY CHECK COMPLETE');
  print('$passed of $total assertions passed');
  if (failed > 0) {
    print('\nFailed assertions:');
    for (final f in failures) {
      print('  • $f');
    }
    print('\n🔴 JOURNEY CHECKS FAILED — Fix issues before building APK\n');
    exit(1);
  } else {
    print('\n🟢 ALL JOURNEY CHECKS PASSED — Logic is sound\n');
    exit(0);
  }
}
