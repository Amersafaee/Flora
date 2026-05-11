import 'package:cloud_firestore/cloud_firestore.dart';

class CareIntelligenceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> computeNextCareDate({
    required String plantId,
    required String plantName,
    required String category,
    required int baseIntervalDays,
    required DateTime lastWateredDate,
    required String zoneUid,
    required String userUid,
  }) async {
    // 1. Load last 5 humidity readings
    final readingsQuery = await _db
        .collection('users')
        .doc(userUid)
        .collection('zones')
        .doc(zoneUid)
        .collection('readings')
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

  Future<List<Map<String, dynamic>>> generateWeeklyCarePlan(String userUid) async {
    final plantsQuery = await _db.collection('users').doc(userUid).collection('plants').get();
    
    List<Map<String, dynamic>> plan = [];

    for (var plantDoc in plantsQuery.docs) {
      final plantData = plantDoc.data();
      final plantId = plantDoc.id;
      final plantName = plantData['name'] ?? 'Unknown Plant';
      final category = plantData['category'] ?? '';
      
      // Get last completed watering
      final lastWaterQuery = await _db
          .collection('users')
          .doc(userUid)
          .collection('tasks')
          .where('plantName', isEqualTo: plantName)
          .where('taskType', isEqualTo: 'Watering')
          .where('isCompleted', isEqualTo: true)
          .orderBy('dueDate', descending: true)
          .limit(1)
          .get();

      DateTime lastWatered = DateTime.now().subtract(const Duration(days: 7)); // Default fallback
      if (lastWaterQuery.docs.isNotEmpty) {
        lastWatered = (lastWaterQuery.docs.first.data()['dueDate'] as Timestamp).toDate();
      } else if (plantData['dateAdded'] != null) {
        lastWatered = (plantData['dateAdded'] as Timestamp).toDate();
      }

      final smartWatering = await computeNextCareDate(
        plantId: plantId,
        plantName: plantName,
        category: category,
        baseIntervalDays: 7, // Default base interval for watering
        lastWateredDate: lastWatered,
        zoneUid: 'main_zone', // Assuming main_zone for simplicity, or we can fetch plant's zone if it exists
        userUid: userUid,
      );

      plan.add({
        'plantName': plantName,
        'taskType': 'Watering',
        'recommendedDate': smartWatering['nextDate'],
        'reasoning': smartWatering['reasoning'],
      });

      // Fertilizing (Base 30)
      // For simplicity, let's just use the same lastWatered base or today.
      final smartFertilizing = await computeNextCareDate(
        plantId: plantId,
        plantName: plantName,
        category: category,
        baseIntervalDays: 30,
        lastWateredDate: lastWatered, // Not entirely accurate, but serves the purpose
        zoneUid: 'main_zone',
        userUid: userUid,
      );
      
      plan.add({
        'plantName': plantName,
        'taskType': 'Fertilizing',
        'recommendedDate': smartFertilizing['nextDate'],
        'reasoning': smartFertilizing['reasoning'],
      });

      // Repotting (Base 365)
      final smartRepotting = await computeNextCareDate(
        plantId: plantId,
        plantName: plantName,
        category: category,
        baseIntervalDays: 365,
        lastWateredDate: lastWatered,
        zoneUid: 'main_zone',
        userUid: userUid,
      );

      plan.add({
        'plantName': plantName,
        'taskType': 'Repotting check',
        'recommendedDate': smartRepotting['nextDate'],
        'reasoning': smartRepotting['reasoning'],
      });
    }

    // Sort by recommendedDate ascending
    plan.sort((a, b) {
      final dateA = a['recommendedDate'] as DateTime;
      final dateB = b['recommendedDate'] as DateTime;
      return dateA.compareTo(dateB);
    });

    return plan;
  }
}
