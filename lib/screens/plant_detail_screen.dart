import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'add_growth_entry_screen.dart';
import 'family_tree_screen.dart';
import 'treatment_case_screen.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import 'edit_plant_screen.dart';
import 'shareable_card_screen.dart';
import 'plant_passport_screen.dart';
import '../models/plant_model.dart';
import '../models/treatment_case_model.dart';

// ignore_for_file: avoid_dynamic_calls

class PlantDetailScreen extends StatelessWidget {
  final String plantId;
  final String plantName;

  const PlantDetailScreen({
    super.key,
    this.plantId = 'mock_id',
    this.plantName = 'Monstera Deliciosa',
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: uid != null
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('plants')
              .doc(plantId)
              .snapshots()
          : const Stream.empty(),
      builder: (context, plantSnap) {
        final plantData = plantSnap.data?.data() ?? {};
        final currentHealthStatus =
            (plantData['healthStatus'] as String?)?.trim().isNotEmpty == true
                ? plantData['healthStatus'] as String
                : 'Healthy';
        final lastAssessment =
            plantData['lastAssessment'] as Map<String, dynamic>?;
        final lastAssessmentTs =
            plantData['lastAssessmentDate'] as Timestamp?;

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddGrowthEntryScreen(
                plantName: plantData['name'] as String? ?? plantName,
                plantId: plantId,
                healthStatus: currentHealthStatus,
              ),
            ),
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      plantData['name'] as String? ?? plantName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.share, color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () {
                        final plantMap = Map<String, dynamic>.from(plantData);
                        plantMap['id'] = plantId;
                        final plantObj = Plant.fromMap(plantMap);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ShareableCardScreen(plant: plantObj)));
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                      leading: const Icon(Icons.edit),
                                      title: const Text('Edit Plant'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditPlantScreen(plantId: plantId),
                                          ),
                                        );
                                      },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.badge_outlined, color: Color(0xFF154212)),
                                    title: const Text('View Plant Passport', style: TextStyle(color: Color(0xFF154212))),
                                    onTap: () {
                                      Navigator.pop(context);
                                      final plantMap = Map<String, dynamic>.from(plantData);
                                      plantMap['id'] = plantId;
                                      final plantObj = Plant.fromMap(plantMap);
                                      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PlantPassportScreen(plant: plantObj, userUid: uid),
                                        ),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.local_hospital),
                                    title: const Text('Mark as Unhealthy'),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      final uid = FirebaseAuth.instance.currentUser?.uid;
                                      if (uid != null) {
                                        await FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').doc(plantId).update({
                                          'healthStatus': 'Unhealthy',
                                          'healthScore': 50,
                                        });
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plant marked as unhealthy', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF8D3220)));
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.sentiment_dissatisfied, color: Colors.grey),
                                    title: const Text('Mark as Deceased', style: TextStyle(color: Colors.grey)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showMemorialDialog(context, plantId, plantData['name'] as String? ?? plantName, plantData);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete, color: Color(0xFF8D3220)),
                                    title: const Text('Delete Plant', style: TextStyle(color: Color(0xFF8D3220))),
                                    onTap: () {
                                      Navigator.pop(context);
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Plant?'),
                                          content: const Text('This action cannot be undone.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                final uid = FirebaseAuth.instance.currentUser?.uid;
                                                if (uid != null) {
                                                  await FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').doc(plantId).delete();
                                                }
                                                if (!context.mounted) return;
                                                Navigator.pop(context); // close dialog
                                                Navigator.pop(context); // go back
                                              },
                                              child: const Text('Delete', style: TextStyle(color: Color(0xFF8D3220))),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Stats Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('tasks')
                      .where('plantName', isEqualTo: plantData['name'] as String? ?? plantName)
                      .snapshots(),
                  builder: (context, taskSnap) {
                    DateTime? lastWateredDate;
                    if (taskSnap.hasData) {
                      final tasks = taskSnap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
                      tasks.sort((a, b) {
                         final aTs = a['dueDate'] as Timestamp?;
                         final bTs = b['dueDate'] as Timestamp?;
                         if (aTs == null && bTs == null) return 0;
                         if (aTs == null) return 1;
                         if (bTs == null) return -1;
                         return bTs.compareTo(aTs);
                      });
                      
                      for (var data in tasks) {
                        final type = (data['taskType'] as String?)?.toLowerCase() ?? '';
                        if (data['isCompleted'] == true && type.contains('water')) {
                          lastWateredDate = (data['dueDate'] as Timestamp?)?.toDate();
                          break;
                        }
                      }
                    }
                    
                    final healthScore = plantData['healthScore'] ?? 100;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // Left Box (Health Score)
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.favorite, color: primaryColor), // heart
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Health Score',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '$healthScore/100',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Vitals',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Divider
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 16),
                          
                          // Right Box (Last Watered)
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.water_drop, color: primaryColor),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Last Watered',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      lastWateredDate != null 
                                          ? DateFormat('MMM d').format(lastWateredDate) 
                                          : 'Never',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      lastWateredDate != null ? 'Completed' : 'No history',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ),
              const SizedBox(height: 16),

              // ── Last Health Assessment Card ──────────────────────────────
              if (lastAssessment != null)
                _buildAssessmentSection(
                  context: context,
                  primaryColor: primaryColor,
                  assessment: lastAssessment,
                  assessmentDate: lastAssessmentTs,
                ),

              // ── Health Cases Row ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: StreamBuilder<List<TreatmentCase>>(
                  stream: FirestoreService().getTreatmentCases(plantId),
                  builder: (context, caseSnap) {
                    final cases = caseSnap.data ?? [];
                    final hasActive = cases.any((c) =>
                        c.status == 'Active' || c.status == 'Monitoring');

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TreatmentCaseScreen(
                              plantId: plantId,
                              plantName: plantData['name'] as String? ?? plantName,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.grey.shade200, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8D3220).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.local_hospital,
                                  color: Color(0xFF8D3220), size: 20),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Health Cases',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hasActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Family Tree Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FamilyTreeScreen(
                            plantId: plantId,
                            plantName: plantData['name'] as String? ?? plantName,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_tree_outlined, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'View Family Tree',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Time-lapse Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showTimeLapse(context, plantId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.movie_creation_outlined, color: Colors.white), // film icon
                        SizedBox(width: 12),
                        Text(
                          'Create Time-lapse',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Generate text
              const Center(
                child: Text(
                  'Watch your plant grow over time',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Growth History Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Growth History',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Growth Entries
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService().getGrowthEntries(plantId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Something went wrong',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      );
                    }
                    
                    final entries = snapshot.data ?? [];
                    if (entries.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No growth history yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    
                    return Column(
                      children: entries.map((entry) {
                        final timestamp = entry['timestamp'] as Timestamp?;
                        final dateStr = timestamp != null
                            ? DateFormat('MMMM d, yyyy').format(timestamp.toDate())
                            : 'Just now';
                            
                        final height = entry['height'] as String? ?? '';
                        final hasHeight = height.isNotEmpty;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildGrowthEntryCard(
                            context: context,
                            label: 'JOURNAL ENTRY',
                            date: dateStr,
                            chipText: hasHeight ? '$height cm' : 'Entry',
                            isChipGreen: hasHeight,
                            body: entry['notes'] as String? ?? '',
                            imageUrl: entry['imageUrl'] as String?,
                            primaryColor: primaryColor,
                          ),
                        );
                      }).toList(),
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
    },
    );
  }

  Widget _buildGrowthEntryCard({
    required BuildContext context,
    required String label,
    required String date,
    required String chipText,
    required bool isChipGreen,
    required String body,
    String? imageUrl,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isChipGreen ? primaryColor : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  chipText,
                  style: TextStyle(
                    color: isChipGreen ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Image
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Icon(Icons.error_outline, color: Colors.grey)),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.eco,
                        size: 48,
                        color: const Color(0xFF154212).withValues(alpha: 0.4),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.eco,
                  size: 48,
                  color: const Color(0xFF154212).withValues(alpha: 0.4),
                ),
              ),
            ),
          const SizedBox(height: 16),
          
          // Body Text
          Text(
            body,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Health Assessment Card ─────────────────────────────────────────────────

  Widget _buildAssessmentSection({
    required BuildContext context,
    required Color primaryColor,
    required Map<String, dynamic> assessment,
    required Timestamp? assessmentDate,
  }) {
    final int score = (assessment['overallScore'] as num?)?.toInt() ?? 70;
    final String condition = assessment['condition']?.toString() ?? 'Healthy';
    final String observations = assessment['observations']?.toString() ?? '';
    final bool newGrowth = assessment['newGrowthDetected'] == true;
    final List<String> issues = (assessment['issuesDetected'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final String recommendations =
        assessment['recommendations']?.toString() ?? '';

    final dateStr = assessmentDate != null
        ? DateFormat('MMM d, yyyy').format(assessmentDate.toDate())
        : '';

    // Score colour
    final Color scoreColor = score > 70
        ? const Color(0xFF154212)
        : score >= 40
            ? Colors.orange.shade700
            : Colors.red.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // New growth celebration banner
          if (newGrowth)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDFF5E3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Color(0xFF154212), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'New growth detected! 🌱',
                    style: TextStyle(
                      color: const Color(0xFF154212),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Main assessment card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LAST HEALTH ASSESSMENT',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Score + condition row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          condition,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          'out of 100',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Observations
                if (observations.isNotEmpty)
                  Text(
                    observations,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),

                // Issues chips
                if (issues.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: issues
                        .map(
                          (issue) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(
                                  color: Colors.red.shade200, width: 1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              issue,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],

                // Recommendation
                if (recommendations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: primaryColor, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          recommendations,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}














Future<void> _showMemorialDialog(BuildContext context, String plantId, String plantName, Map<String, dynamic> plantData) async {
  final noteController = TextEditingController();
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Mark $plantName as Deceased'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Would you like to leave a note about $plantName?'),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Memorial note...'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final note = noteController.text;
    await FirestoreService().markPlantAsDeceased(plantId, note);
    final category = plantData['category']?.toString() ?? 'plant';
    final dateAdded = plantData['dateAdded'] != null ? (plantData['dateAdded'] as Timestamp).toDate() : DateTime.now();
    final daysCaredFor = DateTime.now().difference(dateAdded).inDays;
    final uid = FirestoreService().currentUserId;
    int waterings = 0;
    int growthEntries = 0;
    if (uid != null) {
      final tasks = await FirebaseFirestore.instance.collection('users').doc(uid).collection('tasks').where('plantName', isEqualTo: plantName).where('taskType', isEqualTo: 'Watering').where('isCompleted', isEqualTo: true).count().get();
      waterings = tasks.count ?? 0;
      final growths = await FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').doc(plantId).collection('growth').count().get();
      growthEntries = growths.count ?? 0;
    }
    final eulogy = await GeminiService().generatePlantEulogy(
      plantName: plantName,
      category: category,
      daysCaredFor: daysCaredFor,
      totalWaterings: waterings,
      totalGrowthEntries: growthEntries,
      memorialNote: note,
    );
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').doc(plantId).update({'eulogy': eulogy});
    }
    if (context.mounted) {
      Navigator.pop(context); // pop loading
      await showDialog(
        context: context,
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF1E211E),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_florist, color: Colors.white, size: 64),
                    const SizedBox(height: 24),
                    Text(
                      plantName,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontFamily: 'serif', fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      eulogy,
                      style: const TextStyle(color: Colors.white70, fontSize: 18, fontStyle: FontStyle.italic, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 64),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context); // pop back to home
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E211E),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}

Future<void> _showTimeLapse(BuildContext context, String plantId) async {
    final entriesSnap = await FirestoreService().getGrowthEntries(plantId).first;
    final photos = entriesSnap
        .map((e) => e['imageUrl'] as String?)
        .where((url) => url != null && url.isNotEmpty)
        .cast<String>()
        .toList();

    if (!context.mounted) return;

    if (photos.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add more growth photos to create a time lapse — you need at least 2', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF154212),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text('Growth Time-lapse', style: TextStyle(color: Colors.white)),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Tap photos to view your plant\'s journey (${photos.length} photos)',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        photos[index],
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }