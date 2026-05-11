import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/badges_service.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final BadgesService _badgesService = BadgesService();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  final List<Map<String, String>> allBadges = [
    {
      'badgeId': 'first_leaf',
      'badgeName': 'First Leaf',
      'badgeDescription': 'Added your first plant to the collection.',
    },
    {
      'badgeId': 'green_thumb',
      'badgeName': 'Green Thumb',
      'badgeDescription': 'Growing a collection of 5 plants.',
    },
    {
      'badgeId': 'plant_parent',
      'badgeName': 'Plant Parent',
      'badgeDescription': 'Caring for 10 plants at once.',
    },
    {
      'badgeId': 'caretaker',
      'badgeName': 'Caretaker',
      'badgeDescription': 'Completed your first care task.',
    },
    {
      'badgeId': 'dedicated_gardener',
      'badgeName': 'Dedicated Gardener',
      'badgeDescription': 'Completed 10 care tasks.',
    },
    {
      'badgeId': 'journalist',
      'badgeName': 'Journalist',
      'badgeDescription': 'Logged your first growth entry.',
    },
    {
      'badgeId': 'flora_friend',
      'badgeName': 'Flora Friend',
      'badgeDescription': 'Had your first conversation with Flora.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF154212);
    const Color backgroundColor = Color(0xFFF8FAF8);
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Badges',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _badgesService.getUserBadges(currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load badges.', style: TextStyle(color: Colors.grey)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final earnedDocs = snapshot.data?.docs ?? [];
          final earnedBadgeIds = earnedDocs.map((doc) => doc['badgeId'] as String).toList();
          final earnedCount = earnedBadgeIds.length;
          final currentLevel = _badgesService.getUserLevel(earnedCount);

          final earnedBadgesData = <Map<String, dynamic>>[];
          final lockedBadgesData = <Map<String, dynamic>>[];

          for (var badge in allBadges) {
            if (earnedBadgeIds.contains(badge['badgeId'])) {
              final doc = earnedDocs.firstWhere((d) => d['badgeId'] == badge['badgeId']);
              final timestamp = doc['earnedDate'] as Timestamp?;
              earnedBadgesData.add({
                ...badge,
                'earnedDate': timestamp?.toDate(),
              });
            } else {
              lockedBadgesData.add(badge);
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Centered Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events, size: 64, color: primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        currentLevel,
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep growing to unlock more badges.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Earned Badges
                if (earnedBadgesData.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'EARNED BADGES',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildGrid(earnedBadgesData, true, primaryColor, textColor),
                  const SizedBox(height: 32),
                ],

                // Locked Badges
                if (lockedBadgesData.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'LOCKED BADGES',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildGrid(lockedBadgesData, false, primaryColor, textColor),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> badges, bool isEarned, Color primaryColor, Color textColor) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final earnedDate = badge['earnedDate'] as DateTime?;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: isEarned ? primaryColor : Colors.grey.shade200,
                    child: Icon(
                      Icons.eco,
                      color: isEarned ? Colors.white : Colors.grey.shade400,
                      size: 32,
                    ),
                  ),
                  if (!isEarned)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock,
                          color: Colors.grey.shade500,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                badge['badgeName'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isEarned ? textColor : Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  badge['badgeDescription'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isEarned && earnedDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(earnedDate),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}



