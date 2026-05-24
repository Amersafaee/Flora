import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';

class BadgesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> checkAndAwardBadges(String userId) async {
    final int plantsCount = await _firestoreService.getTotalPlantsCount();
    final int tasksCount = await _firestoreService.getCompletedTasksCount();
    final int journalsCount = await _firestoreService.getTotalJournalEntriesCount();

    // Check if user has used Flora Chat (we check a flag on the user document if it exists)
    bool usedFloraChat = false;
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        usedFloraChat = userDoc.data()?['usedFloraChat'] == true;
      }
    } catch (_) {}

    final List<Map<String, dynamic>> potentialBadges = [];

    if (plantsCount >= 1) {
      potentialBadges.add({
        'badgeId': 'first_leaf',
        'badgeName': 'First Leaf',
        'badgeDescription': 'Added your first plant to the collection.',
      });
    }
    if (plantsCount >= 5) {
      potentialBadges.add({
        'badgeId': 'green_thumb',
        'badgeName': 'Green Thumb',
        'badgeDescription': 'Growing a collection of 5 plants.',
      });
    }
    if (plantsCount >= 10) {
      potentialBadges.add({
        'badgeId': 'plant_parent',
        'badgeName': 'Plant Parent',
        'badgeDescription': 'Caring for 10 plants at once.',
      });
    }
    if (tasksCount >= 1) {
      potentialBadges.add({
        'badgeId': 'caretaker',
        'badgeName': 'Caretaker',
        'badgeDescription': 'Completed your first care task.',
      });
    }
    if (tasksCount >= 10) {
      potentialBadges.add({
        'badgeId': 'dedicated_gardener',
        'badgeName': 'Dedicated Gardener',
        'badgeDescription': 'Completed 10 care tasks.',
      });
    }
    if (journalsCount >= 1) {
      potentialBadges.add({
        'badgeId': 'journalist',
        'badgeName': 'Journalist',
        'badgeDescription': 'Logged your first growth entry.',
      });
    }
    if (usedFloraChat) {
      potentialBadges.add({
        'badgeId': 'flora_friend',
        'badgeName': 'Flora Friend',
        'badgeDescription': 'Had your first conversation with Flora.',
      });
    }

    final badgesRef = _db.collection('users').doc(userId).collection('badges');

    for (var badge in potentialBadges) {
      final badgeId = badge['badgeId'];
      final docSnap = await badgesRef.doc(badgeId).get();
        if (!docSnap.exists) {
        await badgesRef.doc(badgeId).set({
          'badgeId': badge['badgeId'],
          'badgeName': badge['badgeName'],
          'badgeDescription': badge['badgeDescription'],
          'earnedDate': FieldValue.serverTimestamp(),
        });

        // Store badge name for home screen celebration dialog
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_badge_celebration', badge['badgeName']);
        } catch (_) {}
        
        await _db.collection('users').doc(userId).collection('notifications').add({
          'badgeCelebration': true,
          'badgeId': badge['badgeId'],
          'badgeName': badge['badgeName'],
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    }
  }

  Stream<QuerySnapshot> getUserBadges(String userId) {
    return _db.collection('users').doc(userId).collection('badges').snapshots();
  }

  String getUserLevel(int badgeCount) {
    if (badgeCount == 0) return 'Seedling';
    if (badgeCount == 1 || badgeCount == 2) return 'Sprout';
    if (badgeCount == 3 || badgeCount == 4) return 'Grower';
    if (badgeCount == 5 || badgeCount == 6) return 'Gardener';
    return 'Master Gardener'; // For 7
  }
}

