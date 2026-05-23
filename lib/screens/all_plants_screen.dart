import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/plant_model.dart';
import '../services/firestore_service.dart';
import 'plant_detail_screen.dart';
import 'add_plant_screen.dart';
import '../theme/app_theme.dart';

class AllPlantsScreen extends StatelessWidget {
  const AllPlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryColor = Theme.of(context).primaryColor;

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
          : StreamBuilder<List<Plant>>(
              stream: FirestoreService().getPlants(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(l.noPlantsYetAddOne));
                }

                final plants = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: plants.length,
                  itemBuilder: (context, index) {
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
                      Color healthColor = Colors.green;
                      badgeWidget = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: healthColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          health,
                          style: TextStyle(
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
                            // Left side: Photo thumbnail (FIX 3)
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
                            // Middle: Plant name and metadata (FIX 3)
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
                                      // Care due indicator (FIX 4)
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
                            // Right side: Health badge and Chevron (FIX 5)
                            badgeWidget,
                            const SizedBox(width: 12),
                            const Icon(Icons.chevron_right, color: AppColors.bone500),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
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
