import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/plant_providers.dart';
import '../../data/task_providers.dart';
import '../../theme/tokens.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.split(' ').first ?? '';
    final h = DateTime.now().hour;
    final greeting = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
    return name.isNotEmpty ? '$greeting, $name.' : '$greeting.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(userPlantsProvider);
    final todayTasks  = ref.watch(todayTasksProvider).valueOrNull ?? [];
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return plantsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (plants) {
        final pendingCount = todayTasks.length;
        final subtitle = pendingCount == 0
            ? 'Your conservatory is thriving.'
            : '$pendingCount plant${pendingCount == 1 ? '' : 's'} need${pendingCount == 1 ? 's' : ''} attention.';

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/flora-chat'),
            backgroundColor: AppColors.forestGreen,
            child: const Icon(Icons.eco, color: Colors.white),
          ),
          body: CustomScrollView(
            slivers: [
              // ── Greeting Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(), style: TextStyle(
                      fontFamily: 'NotoSerif',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.forestGreen,
                    )),
                    const SizedBox(height: 4),
                    Text(subtitle, style: tt.bodyMedium?.copyWith(color: AppColors.moss)),
                  ],
                ),
              ),
            ),

            // ── Identify Card ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () {
                  context.go('/identify');
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen,
                    borderRadius: AppRadius.borderLg,
                    boxShadow: [BoxShadow(
                      color: AppColors.forestGreen.withAlpha(60),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Identify a Plant', style: TextStyle(
                              fontFamily: 'NotoSerif',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                            const SizedBox(height: 6),
                            Text('Point your camera at any plant',
                              style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Stats Chip ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.dew,
                    borderRadius: AppRadius.borderPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco, color: AppColors.leafGreen, size: 16),
                      const SizedBox(width: 6),
                      Text('${plants.length} Plant${plants.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.forestGreen, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),

            // ── Section Header "My Plants" ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Text('My Plants', style: TextStyle(
                      fontFamily: 'NotoSerif',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.forestGreen,
                    )),
                    const Spacer(),
                    if (plants.isNotEmpty)
                      GestureDetector(
                        onTap: () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Coming soon', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF2D5A27), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4, duration: const Duration(seconds: 3), )); },
                        child: const Text('VIEW ALL', style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.leafGreen,
                          letterSpacing: 0.5,
                        )),
                      ),
                  ],
                ),
              ),
            ),

            // ── Plant List (horizontal or empty) ─────────────────────────
            if (plants.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: AppRadius.borderLg,
                    boxShadow: AppShadows.cardShadow,
                  ),
                  child: Column(
                    children: [
                      const Text('🌿', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      Text('Add your first plant', style: TextStyle(
                        fontFamily: 'NotoSerif',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.forestGreen,
                      )),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: () => context.go('/identify'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.forestGreen,
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
                          ),
                          child: const Text('Identify a plant'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: plants.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => _PlantCard(plant: plants[i]),
                  ),
                ),
              ),

            // ── Full plant list below the horizontal scroll ──────────────
            if (plants.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text('All Plants', style: TextStyle(
                    fontFamily: 'NotoSerif',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.forestGreen,
                  )),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList.separated(
                  itemCount: plants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PlantListTile(plant: plants[i]),
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

// ── Horizontal plant card ─────────────────────────────────────────────────────
class _PlantCard extends StatelessWidget {
  final PlantDoc plant;
  const _PlantCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    final isHealthy = plant.healthStatus == 'healthy';

    return GestureDetector(
      onTap: () => context.push('/plant/${plant.id}'),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            ClipRRect(
              borderRadius: AppRadius.borderMd,
              child: Container(
                width: 160,
                height: 140,
                color: AppColors.dew,
                child: plant.photoBase64.isNotEmpty
                    ? Image.memory(
                        base64Decode(plant.photoBase64),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      )
                    : const Center(child: Text('🪴', style: TextStyle(fontSize: 48))),
              ),
            ),
            const SizedBox(height: 8),
            // Nickname
            Text(
              plant.nickname.isNotEmpty ? plant.nickname : plant.commonName,
              style: const TextStyle(
                fontFamily: 'NotoSerif',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Health pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isHealthy ? AppColors.leafGreen.withAlpha(25) : AppColors.terracotta.withAlpha(25),
                borderRadius: AppRadius.borderPill,
              ),
              child: Text(
                isHealthy ? 'Healthy' : 'Needs care',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isHealthy ? AppColors.leafGreen : AppColors.terracotta,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Vertical plant list tile ──────────────────────────────────────────────────
class _PlantListTile extends StatelessWidget {
  final PlantDoc plant;
  const _PlantListTile({required this.plant});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => context.push('/plant/${plant.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadius.borderMd,
          boxShadow: AppShadows.cardShadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppRadius.borderSm,
              child: Container(
                width: 50, height: 50,
                color: AppColors.dew,
                child: plant.photoBase64.isNotEmpty
                    ? Image.memory(base64Decode(plant.photoBase64), fit: BoxFit.cover, gaplessPlayback: true)
                    : const Center(child: Text('🪴', style: TextStyle(fontSize: 24))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.nickname.isNotEmpty ? plant.nickname : plant.commonName,
                    style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  if (plant.zone.isNotEmpty)
                    Text(plant.zone, style: tt.bodySmall?.copyWith(color: cs.outline)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}


