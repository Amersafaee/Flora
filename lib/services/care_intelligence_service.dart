import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'gemini_service.dart';

class CareIntelligenceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> computeNextCareDate({
    required String plantId,
    required String plantName,
    required String category,
    required int baseIntervalDays,
    required DateTime lastWateredDate,
    required String userUid,
  }) async {
    if (userUid.isEmpty || plantId.isEmpty) {
      return {
        'nextDate': lastWateredDate.add(Duration(days: baseIntervalDays)),
        'reasoning': 'Based on your plant\'s standard needs.',
        'urgency': 'Scheduled',
        'adjustedInterval': baseIntervalDays,
      };
    }
    // 1. Load last 5 humidity readings
    final readingsQuery = await _db
        .collection('users')
        .doc(userUid)
        .collection('climate_readings')
        .where('type', isEqualTo: 'humidity')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();

    double avgHumidity = 50.0; // default
    if (readingsQuery.docs.isNotEmpty) {
      double sum = 0;
      for (var doc in readingsQuery.docs) {
        sum += (doc.data()['value'] as num?)?.toDouble() ?? 50.0;
      }
      avgHumidity = sum / readingsQuery.docs.length;
    }

    // 2. Load last 3 completed watering tasks
    final tasksQuery = await _db
        .collection('users')
        .doc(userUid)
        .collection('tasks')
        .where('plantName', isEqualTo: plantName)
        .where('taskType', isEqualTo: 'Watering')
        .where('isCompleted', isEqualTo: true)
        .orderBy('dueDate', descending: true)
        .limit(3)
        .get();

    double? actualAvgInterval;
    if (tasksQuery.docs.length >= 2) {
      final dates = tasksQuery.docs.map((doc) {
        final data = doc.data();
        return (data['dueDate'] as Timestamp).toDate();
      }).toList();
      
      int totalDays = 0;
      for (int i = 0; i < dates.length - 1; i++) {
        totalDays += dates[i].difference(dates[i+1]).inDays.abs();
      }
      actualAvgInterval = totalDays / (dates.length - 1);
    }

    // 3. Apply adjustment rules
    double multiplier = 1.0;
    String reasoning = 'Based on your plant\'s standard needs.';

    if (avgHumidity > 70) {
      multiplier *= 1.2;
      reasoning = 'I pushed it back slightly because your home humidity has been high at ${avgHumidity.round()}% this week.';
    } else if (avgHumidity < 40) {
      multiplier *= 0.8;
      reasoning = 'The dry air in your home at ${avgHumidity.round()}% humidity means it is drinking faster than usual.';
    }

    final currentMonth = DateTime.now().month;
    final isWinter = [12, 1, 2].contains(currentMonth);
    final isSummer = [6, 7, 8].contains(currentMonth);

    if (isWinter && (category.contains('Tropical') || category.contains('Fern'))) {
      multiplier *= 1.3;
      reasoning = 'I extended the schedule slightly for winter dormancy.';
    } else if (isSummer) {
      multiplier *= 0.9;
      reasoning = 'Your plant needs more frequent watering during the summer growth phase.';
    }

    if (actualAvgInterval != null && actualAvgInterval < baseIntervalDays) {
      multiplier *= 0.95;
      if (reasoning == 'Based on your plant\'s standard needs.') {
        reasoning = 'I adjusted the schedule to match your natural watering rhythm.';
      }
    }

    int adjustedInterval = (baseIntervalDays * multiplier).round();
    if (adjustedInterval < 1) adjustedInterval = 1;

    DateTime nextDate = lastWateredDate.add(Duration(days: adjustedInterval));
    
    // Calculate urgency
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextDateMidnight = DateTime(nextDate.year, nextDate.month, nextDate.day);
    
    String urgency = 'Scheduled';
    if (nextDateMidnight.isBefore(today)) {
      urgency = 'Overdue';
    } else if (nextDateMidnight.difference(today).inDays <= 2) {
      urgency = 'Soon';
    }

    return {
      'nextDate': nextDate,
      'reasoning': reasoning,
      'urgency': urgency,
      'adjustedInterval': adjustedInterval,
    };
  }

  /// Generates a Gemini-powered 7-day care schedule for ALL of the user's
  /// non-deceased plants, informed by their actual task history.
  /// Returns a formatted string with DAY 1 … DAY 7 sections.
  Future<String> generateWeeklyCarePlan(String userUid) async {
    if (userUid.isEmpty) return '';
    // 1. Load all non-deceased plants
    final plantsSnap = await _db
        .collection('users')
        .doc(userUid)
        .collection('plants')
        .where('isDeceased', isEqualTo: false)
        .get();

    if (plantsSnap.docs.isEmpty) {
      return '';
    }

    // 2. Build per-plant context strings with task history
    final contextLines = <String>[];

    for (final plantDoc in plantsSnap.docs) {
      final d = plantDoc.data();
      final name = (d['commonName'] as String?)?.trim().isNotEmpty == true
          ? (d['commonName'] as String).trim()
          : (d['name'] as String?)?.trim() ?? 'Unknown Plant';
      final health = (d['healthStatus'] as String?)?.trim() ?? 'Unknown';
      final waterEvery = (d['wateringFrequencyDays'] as num?)?.toInt();
      final fertilizeEvery = (d['fertilizingFrequencyDays'] as num?)?.toInt();

      // Last watering
      String lastWatered = 'unknown';
      try {
        final wQ = await _db
            .collection('users')
            .doc(userUid)
            .collection('tasks')
            .where('plantId', isEqualTo: plantDoc.id)
            .where('taskType', isEqualTo: 'Watering')
            .where('isCompleted', isEqualTo: true)
            .orderBy('dueDate', descending: true)
            .limit(1)
            .get();
        if (wQ.docs.isNotEmpty) {
          final ts = wQ.docs.first.data()['dueDate'];
          if (ts is Timestamp) {
            lastWatered = DateFormat('d MMM yyyy').format(ts.toDate());
          }
        }
      } catch (e) {
        debugPrint('CareIntelligenceService: watering query error: $e');
      }

      // Last fertilizing
      String lastFertilized = 'unknown';
      try {
        final fQ = await _db
            .collection('users')
            .doc(userUid)
            .collection('tasks')
            .where('plantId', isEqualTo: plantDoc.id)
            .where('taskType', isEqualTo: 'Fertilizing')
            .where('isCompleted', isEqualTo: true)
            .orderBy('dueDate', descending: true)
            .limit(1)
            .get();
        if (fQ.docs.isNotEmpty) {
          final ts = fQ.docs.first.data()['dueDate'];
          if (ts is Timestamp) {
            lastFertilized = DateFormat('d MMM yyyy').format(ts.toDate());
          }
        }
      } catch (e) {
        debugPrint('CareIntelligenceService: fertilizing query error: $e');
      }

      final schedule = [
        if (waterEvery != null) 'water every $waterEvery days',
        if (fertilizeEvery != null) 'fertilize every $fertilizeEvery days',
      ].join(', ');

      contextLines.add(
        'Plant: $name | Health: $health | Last watered: $lastWatered'
        '${lastFertilized != 'unknown' ? ' | Last fertilized: $lastFertilized' : ''}'
        '${schedule.isNotEmpty ? ' | Care schedule: $schedule' : ''}',
      );
    }

    // 3. Build the prompt with today's date and the DAY N format
    final today = DateTime.now();
    final formatter = DateFormat('EEEE d MMMM');
    final dayLines = List.generate(7, (i) {
      final d = today.add(Duration(days: i));
      return 'DAY ${i + 1} - ${formatter.format(d)}';
    }).join('\n');

    final plantContext = contextLines.join('\n');

    final prompt = '''
You are a plant care expert. Based on these plants and their care history, create a practical 7-day care schedule for this week starting from today (${DateFormat('EEEE d MMMM yyyy').format(today)}).

Plants:
$plantContext

Format your response as 7 sections, one per day, using EXACTLY this format (no markdown, no asterisks, no bold):

DAY 1 - ${formatter.format(today)}:
• [PlantName]: [specific care task and why]
• [PlantName]: [specific care task and why]

DAY 2 - ${formatter.format(today.add(const Duration(days: 1)))}:
[Continue for all 7 days]

The 7 day headers must be exactly:
$dayLines

Only include plants that need something on that day. If a day has nothing, write exactly:
DAY N - [day name and date]: Rest day — no tasks needed.

Keep each task to one line. Be specific and practical. Do not use markdown formatting.
''';

    // 4. Call Gemini
    final gemini = GeminiService();
    final response = await gemini.generateWeeklySchedule(prompt);
    return response;
  }
}
