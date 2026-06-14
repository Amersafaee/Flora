import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant_model.dart';
import 'notification_service.dart';

class MilestoneService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> checkMilestones(String userUid) async {
    if (userUid.isEmpty) return;
    final plantsSnap = await _db.collection('users').doc(userUid).collection('plants').get();
    final now = DateTime.now();

    for (var doc in plantsSnap.docs) {
      final data = doc.data();
      final plantName = data['name'] ?? 'Your plant';
      
      // 1. Birthday Check
      if (data['dateAdded'] != null) {
        final dateAdded = (data['dateAdded'] as Timestamp).toDate();
        if (dateAdded.month == now.month && dateAdded.day == now.day) {
          final years = now.year - dateAdded.year;
          if (years > 0) {
            bool sendNotif = false;
            if (data['lastBirthdayNotification'] == null) {
              sendNotif = true;
            } else {
              final lastNotif = (data['lastBirthdayNotification'] as Timestamp).toDate();
              if (lastNotif.year != now.year || lastNotif.month != now.month || lastNotif.day != now.day) {
                sendNotif = true;
              }
            }

            if (sendNotif) {
              await NotificationService().showInstantNotification(
                id: doc.id.hashCode,
                title: "$plantName's birthday!",
                body: "$plantName is $years years old today. Tap to celebrate.",
              );
              await doc.reference.update({
                'lastBirthdayNotification': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      }

      // 2. Health Score Threshold
      final currentScore = data['healthScore'] as int? ?? 100;
      final prevScore = data['previousHealthScore'] as int? ?? 100;
      if (prevScore < 80 && currentScore >= 80) {
        await NotificationService().showInstantNotification(
          id: doc.id.hashCode + 1,
          title: "$plantName is thriving!",
          body: "Your care is really paying off. $plantName is in excellent health.",
        );
        // Ensure we don't spam this - it's checked based on previousHealthScore which is updated once per session start.
      }

      // 3. First Journal Entry
      final growthSnap = await doc.reference.collection('growth').get();
      if (growthSnap.docs.length == 1) {
        final firstEntry = growthSnap.docs.first.data();
        if (firstEntry['timestamp'] != null) {
          final entryDate = (firstEntry['timestamp'] as Timestamp).toDate();
          if (entryDate.year == now.year && entryDate.month == now.month && entryDate.day == now.day) {
            // It's the first entry and it was today
            // Ensure we only notify once (maybe by adding a flag, or assuming it only happens once ever)
            if (data['firstJournalNotified'] != true) {
              await NotificationService().showInstantNotification(
                id: doc.id.hashCode + 2,
                title: "First journal entry",
                body: "You started tracking $plantName's journey today.",
              );
              await doc.reference.update({
                'firstJournalNotified': true,
              });
            }
          }
        }
      }
    }
  }

  Future<Map<String, dynamic>> generateShareableCard(String userUid, Plant plant) async {
    if (userUid.isEmpty || plant.id.isEmpty) {
      return {
        'plantName': plant.name,
        'commonName': plant.commonName,
        'category': plant.category,
        'healthScore': plant.healthScore,
        'daysSinceAdded': DateTime.now().difference(plant.dateAdded).inDays,
        'totalGrowthEntries': 0,
        'healthStatus': plant.healthStatus,
        'tagline': 'A beautiful plant.',
        'imageUrl': plant.imageUrl,
      };
    }
    final growthSnap = await _db.collection('users').doc(userUid).collection('plants').doc(plant.id).collection('growth').count().get();
    final totalEntries = growthSnap.count ?? 0;
    
    final daysSinceAdded = DateTime.now().difference(plant.dateAdded).inDays;
    
    String tagline;
    final score = plant.healthScore;
    if (score >= 80) {
      tagline = "Thriving beautifully.";
    } else if (score >= 60) {
      tagline = "Growing steadily.";
    } else if (score >= 40) {
      tagline = "Needs some love.";
    } else {
      tagline = "On the recovery journey.";
    }

    return {
      'plantName': plant.name,
      'commonName': plant.commonName,
      'category': plant.category,
      'healthScore': plant.healthScore,
      'daysSinceAdded': daysSinceAdded,
      'totalGrowthEntries': totalEntries,
      'healthStatus': plant.healthStatus,
      'tagline': tagline,
      'imageUrl': plant.imageUrl,
    };
  }
}
