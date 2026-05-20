import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
import '../models/task_model.dart';
import 'wiki_plant_detail_screen.dart';
import 'post_comments_screen.dart';
import 'community_screen.dart';
import 'create_listing_screen.dart' as import_create_listing;
import '../services/onboarding_service.dart';
import 'onboarding_overlay_screen.dart';
import 'home_screen.dart';
import '../theme/app_theme.dart';

// ignore_for_file: avoid_dynamic_calls

class PlantDetailScreen extends StatefulWidget {
  final String plantId;
  final String plantName;

  const PlantDetailScreen({
    super.key,
    this.plantId = '',
    this.plantName = 'Monstera Deliciosa',
  });

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await OnboardingService.shouldShow('plant_detail_screen')) {
        await OnboardingService.markShown('plant_detail_screen');
        if (mounted) _showFeatureOnboarding();
      }
    });
  }

  void _showFeatureOnboarding() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const OnboardingOverlayScreen(
          title: 'Your Plant Dashboard',
          description: 'Everything you need to keep this plant thriving.',
          tips: [
            'Log growth, watering, and care tasks',
            'Generate a scannable plant passport',
            'Create time-lapse videos of growth',
          ],
          featureKey: 'plant_detail_screen',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plantId = widget.plantId;
    final plantName = widget.plantName;
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
        child: Icon(Icons.add, color: Colors.white),
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          plantData['name'] as String? ?? plantName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('lineage').where(Filter.or(Filter('childPlantId', isEqualTo: plantId), Filter('parentPlantId', isEqualTo: plantId))).snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
                            
                            final docs = snapshot.data!.docs;
                            final parentDocs = docs.where((d) => d['childPlantId'] == plantId).toList();
                            final childDocs = docs.where((d) => d['parentPlantId'] == plantId).toList();

                            List<Widget> lineageWidgets = [];

                            if (parentDocs.isNotEmpty) {
                              final parentId = parentDocs.first['parentPlantId'] as String;
                              lineageWidgets.add(
                                FutureBuilder<DocumentSnapshot>(
                                  future: uid != null ? FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').doc(parentId).get() : null,
                                  builder: (context, pSnap) {
                                    if (!pSnap.hasData || pSnap.data == null || !pSnap.data!.exists) return const SizedBox.shrink();
                                    final pName = pSnap.data!.get('name') as String? ?? 'Parent Plant';
                                    return GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: parentId, plantName: pName))),
                                      child: Text('🌱 Propagated from $pName', style: TextStyle(color: primaryColor, fontSize: 12, decoration: TextDecoration.underline)),
                                    );
                                  }
                                )
                              );
                            }
                            if (childDocs.isNotEmpty) {
                              lineageWidgets.add(
                                Text('🪴 ${childDocs.length} propagation(s) from this plant', style: TextStyle(color: AppColors.bone500, fontSize: 12)),
                              );
                            }
                            
                            if (lineageWidgets.isEmpty) return const SizedBox.shrink();
                            
                            return Column(
                              children: [
                                const SizedBox(height: 4),
                                ...lineageWidgets,
                              ],
                            );
                          }
                        ),
                      ],
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
                                      title: Text(AppLocalizations.of(context).editPlant),
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
                                    leading: const Icon(Icons.badge_outlined, color: AppColors.forest900),
                                    title: Text(AppLocalizations.of(context).viewPlantPassport, style: const TextStyle(color: AppColors.forest900)),
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
                                    title: Text(AppLocalizations.of(context).markAsUnhealthy),
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
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).plantMarkedAsUnhealthy, style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.terracotta900));
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.sentiment_dissatisfied, color: AppColors.bone500),
                                    title: Text(AppLocalizations.of(context).markAsDeceased, style: const TextStyle(color: AppColors.bone500)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showMemorialDialog(context, plantId, plantData['name'] as String? ?? plantName, plantData);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete, color: AppColors.terracotta900),
                                    title: Text(AppLocalizations.of(context).deletePlant, style: const TextStyle(color: AppColors.terracotta900)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(AppLocalizations.of(context).deletePlantConfirm),
                                          content: Text(AppLocalizations.of(context).thisActionCannotBeUndone),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text(AppLocalizations.of(context).cancel),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                final uid = FirebaseAuth.instance.currentUser?.uid;
                                                if (uid != null) {
                                                  await FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').doc(plantId).delete();
                                                }
                                                if (!context.mounted) return;
                                                Navigator.of(context).pushAndRemoveUntil(
                                                  MaterialPageRoute(builder: (_) => HomeScreen(onThemeChanged: (_) {})),
                                                  (route) => false,
                                                );
                                              },
                                              child: Text(AppLocalizations.of(context).delete, style: const TextStyle(color: AppColors.terracotta900)),
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
                      .where('plantId', isEqualTo: plantId)
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
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // Left Box (Health Score)
                          Expanded(
                            child: (lastAssessment == null || lastAssessmentTs == null)
                                ? Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.favorite_border, color: AppColors.bone300),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context).healthScore,
                                              style: TextStyle(
                                                color: AppColors.bone500,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    AppLocalizations.of(context).analyzeWithFloraToGetHealthScore,
                                                    style: TextStyle(
                                                      color: AppColors.bone500,
                                                      fontSize: 10,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.camera_alt, size: 16, color: primaryColor),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
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
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
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
                                            AppLocalizations.of(context).healthScore,
                                            style: TextStyle(
                                              color: AppColors.bone500,
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
                                            AppLocalizations.of(context).vitals,
                                            style: TextStyle(
                                              color: AppColors.bone500,
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
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
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
                                      AppLocalizations.of(context).lastWatered,
                                      style: TextStyle(
                                        color: AppColors.bone500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      lastWateredDate != null 
                                          ? DateFormat('MMM d').format(lastWateredDate) 
                                          : AppLocalizations.of(context).never,
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      lastWateredDate != null ? AppLocalizations.of(context).completed : AppLocalizations.of(context).noHistory,
                                      style: TextStyle(
                                        color: AppColors.bone500,
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
              
              if (plantData['lastLightReading'] != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.forest100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.wb_sunny_outlined, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).lastLightReading,
                                style: TextStyle(
                                  color: AppColors.bone500,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${plantData['lastLightReadingLabel'] ?? 'Unknown'} (${(plantData['lastLightReading'] as num).toStringAsFixed(0)} lx)',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (plantData['lastLightReadingDate'] != null)
                                Text(
                                  DateFormat('MMM d, yyyy').format((plantData['lastLightReadingDate'] as Timestamp).toDate()),
                                  style: TextStyle(
                                    color: AppColors.bone500,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
                    if (cases.isEmpty) return const SizedBox.shrink();
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
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.terracotta100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.local_hospital,
                                  color: AppColors.terracotta900, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              AppLocalizations.of(context).healthCases,
                              style: const TextStyle(
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
                                size: 16, color: AppColors.bone300),
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
                      side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5), width: 1.5),
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
                          AppLocalizations.of(context).viewFamilyTree,
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
                      children: [
                        const Icon(Icons.movie_creation_outlined, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context).createTimeLapse,
                          style: const TextStyle(
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
              const SizedBox(height: 16),
              
              // Swap Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => import_create_listing.CreateListingScreen(
                            initialPlantName: plantData['name'] as String? ?? plantName,
                            initialDescription: "Healthy ${plantData['category'] ?? 'plant'} from my personal collection. Health score: ${plantData['healthScore'] ?? 'Unknown'}.",
                            initialType: "Whole Plant",
                            initialHealthScore: plantData['healthScore'] as int?,
                            initialPlantId: plantId,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horiz, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).listForSwapEmoji,
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
              const SizedBox(height: 8),
              
              // Generate text
              Center(
                child: Text(
                  AppLocalizations.of(context).watchPlantGrowOverTime,
                  style: const TextStyle(
                    color: AppColors.bone500,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Upcoming Tasks
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  AppLocalizations.of(context).upcomingTasks,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: StreamBuilder<List<Task>>(
                  stream: FirestoreService().getTasksForPlant(plantId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final tasks = snapshot.data ?? [];
                    final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();
                    if (incompleteTasks.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: Text(AppLocalizations.of(context).noUpcomingTasks, style: const TextStyle(color: AppColors.bone500))),
                      );
                    }
                    return Column(
                      children: incompleteTasks.map((task) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.radio_button_unchecked, color: AppColors.bone300),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(task.taskType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text(DateFormat('MMM d, yyyy').format(task.dueDate), style: const TextStyle(color: AppColors.bone500, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              // ── Care Guide from Wiki ─────────────────────────────────────
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('species').get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final docs = snapshot.data!.docs;
                  final pName = (plantData['name'] as String? ?? plantName).toLowerCase();
                  
                  Map<String, dynamic>? match;
                  for (var d in docs) {
                    final data = d.data() as Map<String, dynamic>;
                    final sName = (data['name'] as String? ?? '').toLowerCase();
                    final cName = (data['commonName'] as String? ?? '').toLowerCase();
                    if (sName.isNotEmpty && (pName.contains(sName) || sName.contains(pName))) {
                      match = data; break;
                    }
                    if (cName.isNotEmpty && (pName.contains(cName) || cName.contains(pName))) {
                      match = data; break;
                    }
                  }
                  
                  if (match == null) return const SizedBox.shrink();
                  
                  final difficulty = match['difficulty'] ?? 'Moderate';
                  Color diffColor = Colors.orange;
                  if (difficulty.toString().toLowerCase().contains('easy')) diffColor = Colors.green;
                  if (difficulty.toString().toLowerCase().contains('hard')) diffColor = Colors.red;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                         AppLocalizations.of(context).careGuideFromWiki,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => WikiPlantDetailScreen(plantData: match!)));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.forest100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.menu_book, color: AppColors.forest600),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(match['commonName'] ?? match['name'] ?? 'Species', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(match['watering'] ?? 'Moderate watering', style: const TextStyle(color: AppColors.bone500, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: diffColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(difficulty.toString(), style: TextStyle(color: diffColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),

              // ── Community Discussions ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).communityDiscussions,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).limit(3).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) return const SizedBox.shrink();
                        
                        return Column(
                          children: [
                            ...docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final title = data['title'] as String? ?? 'Discussion';
                              final author = data['authorName'] as String? ?? 'A';
                              final authorInitial = author.isNotEmpty ? author[0].toUpperCase() : 'A';
                              final truncatedTitle = title.length > 50 ? '${title.substring(0, 47)}...' : title;
                              
                              final ts = data['timestamp'] as Timestamp?;
                              String timeAgo = '';
                              if (ts != null) {
                                final diff = DateTime.now().difference(ts.toDate());
                                if (diff.inHours < 24) {
                                  timeAgo = '${diff.inHours}h ago';
                                } else if (diff.inDays < 7) {
                                  timeAgo = '${diff.inDays}d ago';
                                } else {
                                  timeAgo = DateFormat.yMMMd().format(ts.toDate());
                                }
                              }
                              
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                  child: Text(authorInitial, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(truncatedTitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                trailing: Text(timeAgo, style: TextStyle(color: AppColors.bone500, fontSize: 12)),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => PostCommentsScreen(postId: doc.id, postTitle: title)));
                                },
                              );
                            }),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen()));
                                },
                                child: Text(AppLocalizations.of(context).seeAllDiscussions, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Growth History Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  AppLocalizations.of(context).growthHistory,
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
                      return Center(
                        child: Text(
                          AppLocalizations.of(context).somethingWentWrong,
                          style: const TextStyle(color: AppColors.bone500, fontSize: 12),
                        ),
                      );
                    }
                    
                    final entries = snapshot.data ?? [];
                    if (entries.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            AppLocalizations.of(context).noGrowthHistoryYet,
                            style: const TextStyle(color: AppColors.bone500),
                          ),
                        ),
                      );
                    }
                    
                    return Column(
                      children: entries.map((entry) {
                        final timestamp = entry['timestamp'] as Timestamp?;
                        final dateStr = timestamp != null
                            ? DateFormat('MMMM d, yyyy').format(timestamp.toDate())
                            : AppLocalizations.of(context).justNow;
                            
                        final height = entry['height'] as String? ?? '';
                        final hasHeight = height.isNotEmpty;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildGrowthEntryCard(
                            context: context,
                            label: AppLocalizations.of(context).journalEntry,
                            date: dateStr,
                            chipText: hasHeight ? '$height cm' : AppLocalizations.of(context).addJournalEntry,
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
        color: Theme.of(context).cardColor,
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
                      color: AppColors.bone500,
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
                  color: isChipGreen ? primaryColor : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  chipText,
                  style: TextStyle(
                    color: isChipGreen ? Colors.white : Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Icon(Icons.error_outline, color: AppColors.bone500)),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.forest100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.eco,
                        size: 48,
                        color: Color(0x6614301E),
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
                color: AppColors.forest100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.eco,
                  size: 48,
                  color: Color(0x6614301E),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scoreColor = score > 70
        ? (isDark ? AppColors.successDark : AppColors.successLight)
        : score >= 40
            ? (isDark ? AppColors.warningDark : AppColors.warningLight)
            : (isDark ? AppColors.errorDark : AppColors.errorLight);

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
                color: AppColors.forest100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.forest900, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).newGrowthDetected,
                    style: TextStyle(
                      color: AppColors.forest900,
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
                      AppLocalizations.of(context).lastHealthAssessment,
                      style: TextStyle(
                        color: AppColors.bone500,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: AppColors.bone500,
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
                          AppLocalizations.of(context).outOf100,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.bone500,
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
                      color: AppColors.bone700,
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
                              color: isDark ? AppColors.darkTerracottaSubtle : AppColors.terracotta100,
                              border: Border.all(
                                  color: isDark ? AppColors.darkTerracotta : AppColors.terracotta500, width: 1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              issue,
                              style: TextStyle(
                                color: isDark ? AppColors.errorDark : AppColors.errorLight,
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
      title: Text('${AppLocalizations.of(context).markAsDeceased} $plantName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context).leaveNoteAboutPlant(plantName)),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: InputDecoration(border: const OutlineInputBorder(), hintText: AppLocalizations.of(context).memorialNoteHint),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context).cancel)),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context).confirm)),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final note = noteController.text;

    List<Map<String, dynamic>> photos = [];
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final growthSnap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').doc(plantId).collection('growth').orderBy('timestamp').get();
      for (var doc in growthSnap.docs) {
        final data = doc.data();
        if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
          photos.add({
            'url': data['imageUrl'],
            'date': data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
          });
        }
      }
    }
    
    if (photos.length >= 2) {
      if (!context.mounted) return;
      Navigator.pop(context); // pop loading
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _MemorialSlideshowDialog(
          plantId: plantId,
          plantName: plantName,
          plantData: plantData,
          photos: photos,
          note: note,
        ),
      );
      return;
    }

    await FirestoreService().markPlantAsDeceased(plantId, note);
    final category = plantData['category']?.toString() ?? 'plant';
    final dateAdded = plantData['dateAdded'] != null ? (plantData['dateAdded'] as Timestamp).toDate() : DateTime.now();
    final daysCaredFor = DateTime.now().difference(dateAdded).inDays;
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
          backgroundColor: AppColors.darkSurface,
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
                        foregroundColor: AppColors.darkSurface,
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
        SnackBar(
          content: Text(AppLocalizations.of(context).addGrowthPhotosForTimelapse, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.forest900,
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
                title: Text(AppLocalizations.of(context).growthTimelapse, style: const TextStyle(color: Colors.white)),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '${AppLocalizations.of(context).tapPhotosToViewJourney} (${photos.length} photos)',
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


class _MemorialSlideshowDialog extends StatefulWidget {
  final String plantId;
  final String plantName;
  final Map<String, dynamic> plantData;
  final List<Map<String, dynamic>> photos;
  final String note;

  const _MemorialSlideshowDialog({
    required this.plantId,
    required this.plantName,
    required this.plantData,
    required this.photos,
    required this.note,
  });

  @override
  State<_MemorialSlideshowDialog> createState() => _MemorialSlideshowDialogState();
}

class _MemorialSlideshowDialogState extends State<_MemorialSlideshowDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveAndMove() async {
    setState(() => _isSaving = true);
    
    await FirestoreService().markPlantAsDeceased(widget.plantId, widget.note);
    final category = widget.plantData['category']?.toString() ?? 'plant';
    final dateAdded = widget.plantData['dateAdded'] != null ? (widget.plantData['dateAdded'] as Timestamp).toDate() : DateTime.now();
    final daysCaredFor = DateTime.now().difference(dateAdded).inDays;
    
    final uid = FirestoreService().currentUserId;
    int waterings = 0;
    int growthEntries = 0;
    if (uid != null) {
      final tasks = await FirebaseFirestore.instance.collection('users').doc(uid).collection('tasks').where('plantName', isEqualTo: widget.plantName).where('taskType', isEqualTo: 'Watering').where('isCompleted', isEqualTo: true).count().get();
      waterings = tasks.count ?? 0;
      final growths = await FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').doc(widget.plantId).collection('growth').count().get();
      growthEntries = growths.count ?? 0;
    }
    final eulogy = await GeminiService().generatePlantEulogy(
      plantName: widget.plantName,
      category: category,
      daysCaredFor: daysCaredFor,
      totalWaterings: waterings,
      totalGrowthEntries: growthEntries,
      memorialNote: widget.note,
    );
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').doc(widget.plantId).update({'eulogy': eulogy});
    }
    
    if (mounted) {
      Navigator.pop(context); // pop dialog
      Navigator.pop(context); // pop screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateAdded = widget.plantData['dateAdded'] != null ? (widget.plantData['dateAdded'] as Timestamp).toDate() : DateTime.now();
    final daysCaredFor = DateTime.now().difference(dateAdded).inDays;

    return Dialog.fullscreen(
      backgroundColor: AppColors.darkCanvas,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                AppLocalizations.of(context).farewellToPlant(widget.plantName),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'serif'),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: widget.photos.length,
                    itemBuilder: (context, index) {
                      final photo = widget.photos[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ColorFiltered(
                                  colorFilter: const ColorFilter.matrix([
                                    0.393, 0.769, 0.189, 0, 0,
                                    0.349, 0.686, 0.168, 0, 0,
                                    0.272, 0.534, 0.131, 0, 0,
                                    0, 0, 0, 1, 0,
                                  ]),
                                  child: Image.network(photo['url'], fit: BoxFit.contain, width: double.infinity),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            DateFormat.yMMMMd().format(photo['date']),
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 40),
                        ],
                      );
                    },
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.photos.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index ? Colors.white : Colors.white38,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(AppLocalizations.of(context).thankYouForDaysOfCare(daysCaredFor), style: const TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAndMove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.darkCanvas,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.darkCanvas, strokeWidth: 2))
                        : Text(AppLocalizations.of(context).moveToMemorialGarden, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}