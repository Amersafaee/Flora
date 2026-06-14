import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/section_header.dart';
import 'add_plant_screen.dart';
import 'care_screen.dart';
import 'plant_detail_screen.dart';

class AllPlantsScreen extends StatelessWidget {
  const AllPlantsScreen({super.key});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final plantsStream = user == null
        ? const Stream<List<Plant>>.empty()
        : FirestoreService().getPlants();

    return StreamBuilder<List<Plant>>(
      stream: plantsStream,
      builder: (context, snapshot) {
        final plants = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.bone50,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(CupertinoIcons.chevron_back, size: 20, color: AppColors.forest700),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text(
              l.myGarden,
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
              ),
            ),
            centerTitle: false,
          ),
          body: user == null
              ? Center(
                  child: Text(
                    l.notLoggedIn,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.bone500,
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // Today's Care Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SectionHeader("Today's Care"),
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CareScreen()),
                                  ),
                                  child: Text(
                                    'View all',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.forest700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.forest700,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }

                                final docs = snapshot.data?.docs ?? [];

                                if (docs.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'All caught up 🌿',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.bone400,
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
                                          color: isDark ? AppColors.darkCardSurface : AppColors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: isDark
                                              ? Border.all(color: AppColors.darkCardBorder, width: 1)
                                              : null,
                                          boxShadow: isDark
                                              ? null
                                              : const [
                                                  BoxShadow(
                                                    color: Color(0x0A224A1E),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _taskIcon(taskType),
                                              size: 20,
                                              color: AppColors.forest700,
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  plantName,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  taskType,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    color: AppColors.bone400,
                                                    fontWeight: FontWeight.w400,
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
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.bone200,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    // Plant List
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.forest700,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else if (!snapshot.hasData || plants.isEmpty)
                      SliverFillRemaining(
                        child: EmptyState(
                          icon: Icons.eco,
                          title: l.noPlantsYetAddOne,
                          subtitle: 'Start building your green sanctuary today.',
                          buttonLabel: l.addYourFirstPlant,
                          onButtonTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddPlantScreen()),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final plant = plants[index];
                              final name = plant.name;
                              final category = plant.category;

                              final Color healthColor;
                              if (plant.healthScore >= 80) {
                                healthColor = AppColors.forest500;
                              } else if (plant.healthScore >= 50) {
                                healthColor = const Color(0xFFE8A020);
                              } else {
                                healthColor = AppColors.terracotta500;
                              }

                              final badgeWidget = Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: healthColor,
                                  shape: BoxShape.circle,
                                ),
                              );

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
                                    color: isDark ? AppColors.darkCardSurface : AppColors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isDark
                                        ? Border.all(color: AppColors.darkCardBorder, width: 1)
                                        : null,
                                    boxShadow: isDark
                                        ? null
                                        : const [
                                            BoxShadow(
                                              color: Color(0x0A224A1E),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.forest100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: plant.imageUrl.isNotEmpty
                                              ? Image.network(
                                                  plant.imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: 56,
                                                  height: 56,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.forest100,
                                                    child: Center(
                                                      child: Icon(Icons.local_florist, color: isDark ? AppColors.darkForestPrimary : AppColors.forest400, size: 24),
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.forest100,
                                                  child: Center(
                                                    child: Icon(Icons.local_florist, color: isDark ? AppColors.darkForestPrimary : AppColors.forest400, size: 24),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
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
                                                    style: GoogleFonts.outfit(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16,
                                                      color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              category,
                                              style: GoogleFonts.outfit(
                                                color: AppColors.bone400,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      badgeWidget,
                                      const SizedBox(width: 12),
                                      const Icon(Icons.chevron_right, color: AppColors.bone400),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: plants.length,
                          ),
                        ),
                      ),
                  ],
                ),
          floatingActionButton: plants.isEmpty
              ? null
              : FloatingActionButton(
                  backgroundColor: AppColors.forest700,
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPlantScreen())),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
        );
      },
    );
  }
}
