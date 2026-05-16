import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_model.dart';
import '../models/task_model.dart';


class WeeklyReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> generateWeeklyReport(String userUid) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Tasks
    final tasksQuery = await _db.collection('users').doc(userUid).collection('tasks')
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .get();

    int completedTasks = 0;
    int skippedTasks = 0;
    
    for (var doc in tasksQuery.docs) {
      final task = Task.fromMap(doc.data()..['id'] = doc.id);
      // Ensure dueDate is strictly before 'now' or within the 7 day period
      if (task.dueDate.isBefore(now) || task.dueDate.isAtSameMomentAs(now)) {
        if (task.isCompleted) {
          completedTasks++;
        } else {
          skippedTasks++;
        }
      }
    }

    final totalTasks = completedTasks + skippedTasks;
    double completionRate = 0;
    if (totalTasks > 0) {
      completionRate = (completedTasks / totalTasks) * 100;
    }

    // Plants & Growth Entries
    final plantsQuery = await _db.collection('users').doc(userUid).collection('plants').get();
    int newGrowthEntries = 0;
    String? mostImprovedPlant;
    int maxImprovement = 0;
    int totalHealthScore = 0;
    int activePlantCount = 0;
    
    String topConcern = '';
    int minHealthScore = 100;

    for (var doc in plantsQuery.docs) {
      final plantData = doc.data();
      plantData['id'] = doc.id;
      final plant = Plant.fromMap(plantData);

      if (!plant.isDeceased) {
        activePlantCount++;
        totalHealthScore += plant.healthScore;

        final prevScore = plantData['previousHealthScore'] as int? ?? plant.healthScore;
        final improvement = plant.healthScore - prevScore;
        if (improvement > maxImprovement) {
          maxImprovement = improvement;
          mostImprovedPlant = plant.name;
        }

        // Count growth entries in last 7 days
        final growthQuery = await doc.reference.collection('growth')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
            .get();
        newGrowthEntries += growthQuery.docs.length;
        
        if (plant.healthScore < 80 && plant.healthScore < minHealthScore) {
          minHealthScore = plant.healthScore;
          topConcern = plant.name;
        }
      }
    }

    int collectionHealthAvg = 100;
    if (activePlantCount > 0) {
      collectionHealthAvg = (totalHealthScore / activePlantCount).round();
    }

    // Climate Readings
    // Get default zone
    double avgTemperature = 0;
    double avgHumidity = 0;
    final zonesQuery = await _db.collection('users').doc(userUid).collection('zones').limit(1).get();
    if (zonesQuery.docs.isNotEmpty) {
      final zoneId = zonesQuery.docs.first.id;
      final tempQuery = await _db.collection('users').doc(userUid).collection('zones').doc(zoneId).collection('readings')
          .where('type', isEqualTo: 'temperature')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get();
      if (tempQuery.docs.isNotEmpty) {
        double sumTemp = 0;
        for (var doc in tempQuery.docs) {
          sumTemp += (doc.data()['value'] as num).toDouble();
        }
        avgTemperature = sumTemp / tempQuery.docs.length;
      }

      final humQuery = await _db.collection('users').doc(userUid).collection('zones').doc(zoneId).collection('readings')
          .where('type', isEqualTo: 'humidity')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get();
      if (humQuery.docs.isNotEmpty) {
        double sumHum = 0;
        for (var doc in humQuery.docs) {
          sumHum += (doc.data()['value'] as num).toDouble();
        }
        avgHumidity = sumHum / humQuery.docs.length;
      }
    }

    // Headline
    String headline;
    if (completionRate >= 80) {
      headline = "Outstanding week. Your plants are thriving.";
    } else if (completionRate >= 60) {
      headline = "Good progress. Keep up the consistent care.";
    } else if (completionRate >= 40) {
      headline = "Steady week. A few plants could use more attention.";
    } else {
      headline = "Your plants need you. Let us get back on track together.";
    }

    final userDoc = await _db.collection('users').doc(userUid).get();
    int streakAtEndOfWeek = 0;
    if (userDoc.exists && userDoc.data()!.containsKey('careStreak')) {
      streakAtEndOfWeek = userDoc.data()!['careStreak'] as int;
    }

    try {
      await _db.collection('users').doc(userUid).set({
        'lastWeeklyReportSummary': {
          'weekEndDate': now.toIso8601String(),
          'tasksCompleted': completedTasks,
          'tasksSkipped': skippedTasks,
          'avgHealthScore': collectionHealthAvg.toDouble(),
          'topConcern': topConcern,
          'streakAtEndOfWeek': streakAtEndOfWeek,
        }
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore
    }

    return {
      'completedTasks': completedTasks,
      'skippedTasks': skippedTasks,
      'completionRate': completionRate,
      'newGrowthEntries': newGrowthEntries,
      'mostImprovedPlant': mostImprovedPlant,
      'collectionHealthAvg': collectionHealthAvg,
      'avgTemperature': avgTemperature,
      'avgHumidity': avgHumidity,
      'weekStartDate': sevenDaysAgo,
      'weekEndDate': now,
      'headline': headline,
    };
  }

  Future<bool> shouldShowWeeklyReport() async {
    final now = DateTime.now();
    // Only show on Sundays (weekday == 7)
    if (now.weekday != DateTime.sunday) return false;

    final prefs = await SharedPreferences.getInstance();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final lastDateStr = prefs.getString('last_weekly_report_date');

    // Guard: already shown today
    if (lastDateStr == todayStr) return false;
    return true;
  }

  Future<void> markWeeklyReportShown() async {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_weekly_report_date', todayStr);
  }
}
