import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/plant_model.dart';
import '../services/firestore_service.dart';
import 'plant_detail_screen.dart';
import 'add_plant_screen.dart';
import 'care_screen.dart';
import '../theme/app_theme.dart';

class AllPlantsScreen extends StatelessWidget {
  const AllPlantsScreen({super.key});

  // Returns the icon for a given task type (mirrors care_screen logic)
  IconData _taskIcon(String taskType) {
    final t = taskType.toLowerCase();
    if (t.contains('water'))   return Icons.water_drop;
    if (t.contains('fertiliz')) return Icons.science;
    if (t.contains('repot'))   return Icons.yard;
    if (t.contains('prun'))    return Icons.content_cut;
    if (t.contains('mist'))    return Icons.air;
    if (t.contains('inspect')) return Icons.search;
    if (t.contains('treat'))   return Icons.medical_services;
    return Icons.eco;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          l.myGarden,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? Center(child: Text(l.notLoggedIn))
          : CustomScrollView(
              slivers: [
                // ── Today's Care Section ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today's Care",
                              style: GoogleFonts.notoSerif(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.bone900,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CareScreen()),
                              ),
                              child: Text(
                                'View all',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Task cards
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('tasks')
                              .where('isCompleted', isEqualTo: false)
                              .where('dueDate', isLessThanOrEqualTo: DateTime.now().add(const Duration(days: 1)))
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(
                                height: 80,
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              );
                            }

                            final docs = snapshot.data?.docs ?? [];

                            if (docs.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'All caught up 🌿',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.bone500,
                                  ),
                                ),
                              );
                            }

                            return SizedBox(
                              height: 80,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(bottom: 4),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data() as Map<String, dynamic>;
                                  final taskType = data['taskType']?.toString() ?? '';
                                  final plantName = data['plantName']?.toString() ?? '';

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSurface : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _taskIcon(taskType),
                                          size: 20,
                                          color: primaryColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              plantName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              taskType,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.bone500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // ── Plant List ────────────────────────────────────────────
                StreamBuilder<List<Plant>>(
                  stream: FirestoreService().getPlants(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(child: Text(l.noPlantsYetAddOne)),
                      );
                    }

                    final plants = snapshot.data!;
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final plant = plants[index];
                            final name = plant.name;
                            final category = plant.category;
                            final health = plant.healthStatus;

                            Widget badgeWidget;
                            final statusLower = health.toLowerCase();
                            if (statusLower == 'healthy') {
                              badgeWidget = Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.forest400,
                                  shape: BoxShape.circle,
                                ),
                              );
                            } else if (statusLower == 'critical' || statusLower == 'sick') {
                              badgeWidget = Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.terracotta100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  health,
                                  style: const TextStyle(
                                    color: AppColors.terracotta900,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            } else if (statusLower == 'needs attention' || statusLower == 'recovering' || statusLower == 'needs care') {
                              badgeWidget = Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.terracotta100.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  health,
                                  style: const TextStyle(
                                    color: AppColors.terracotta700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            } else {
                              const Color healthColor = Colors.green;
                              badgeWidget = Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: healthColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  health,
                                  style: const TextStyle(
                                    color: healthColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlantDetailScreen(plantId: plant.id, plantName: plant.name),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  children: [
                                    // Left side: Photo thumbnail
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: plant.imageUrl.isNotEmpty
                                            ? Image.network(
                                                plant.imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: AppColors.forest100,
                                                  child: const Center(
                                                    child: Icon(Icons.local_florist, color: AppColors.forest400, size: 24),
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color: AppColors.forest100,
                                                child: const Center(
                                                  child: Icon(Icons.local_florist, color: AppColors.forest400, size: 24),
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Middle: Plant name and metadata
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (statusLower == 'critical' || statusLower == 'sick' || plant.healthScore < 50) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.errorLight,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(category, style: const TextStyle(color: AppColors.bone500, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Right side: Health badge and Chevron
                                    badgeWidget,
                                    const SizedBox(width: 12),
                                    const Icon(Icons.chevron_right, color: AppColors.bone500),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: plants.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPlantScreen()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
