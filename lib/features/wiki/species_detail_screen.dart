import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/species_providers.dart';
import '../../data/wishlist_providers.dart';
import '../../data/plant_providers.dart';
import '../../theme/tokens.dart';

class SpeciesDetailScreen extends ConsumerStatefulWidget {
  final String speciesId;
  const SpeciesDetailScreen({super.key, required this.speciesId});

  @override
  ConsumerState<SpeciesDetailScreen> createState() => _SpeciesDetailScreenState();
}

class _SpeciesDetailScreenState extends ConsumerState<SpeciesDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speciesAsync = ref.watch(speciesDetailProvider(widget.speciesId));
    final wishlistAsync = ref.watch(wishlistProvider);
    final userPlantsAsync = ref.watch(userPlantsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return speciesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (species) {
        if (species == null) {
          return const Scaffold(body: Center(child: Text('Species not found.')));
        }

        final isWishlisted = (wishlistAsync.valueOrNull ?? {}).contains(species.id);
        
        // Find if user owns any of these plants (matching commonName)
        final ownedPlants = (userPlantsAsync.valueOrNull ?? [])
            .where((p) => p.commonName.toLowerCase() == species.commonName.toLowerCase() || 
                          p.scientificName.toLowerCase() == species.scientificName.toLowerCase())
            .toList();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Image Header ──────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.forestGreen,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border, color: Colors.white),
                    onPressed: () => toggleWishlist(species.id, isWishlisted),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(
                    'https://source.unsplash.com/600x400/?${Uri.encodeComponent(species.imageQuery)}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.forestGreen),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Names
                      Text(species.commonName, style: TextStyle(
                        fontFamily: 'NotoSerif',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.forestGreen,
                      )),
                      if (species.scientificName.isNotEmpty)
                        Text(species.scientificName, style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 16,
                          color: AppColors.moss,
                        )),
                      const SizedBox(height: 16),

                      // Traits
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: species.traits.map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.dew,
                            borderRadius: AppRadius.borderPill,
                          ),
                          child: Text(t, style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forestGreen,
                          )),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Care Summary Chips
                      Row(
                        children: [
                          Expanded(child: _CareSummaryChip(icon: Icons.wb_sunny, label: 'Sun', value: species.careDefaults['sun'] ?? 'medium')),
                          const SizedBox(width: 12),
                          Expanded(child: _CareSummaryChip(icon: Icons.water_drop, label: 'Water', value: species.careDefaults['water'] ?? 'medium')),
                          const SizedBox(width: 12),
                          Expanded(child: _CareSummaryChip(icon: Icons.eco, label: 'Feed', value: species.careDefaults['fertilizer'] ?? 'low')),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Owned Plants
                      if (ownedPlants.isNotEmpty) ...[
                        Text('My Collection', style: TextStyle(
                          fontFamily: 'NotoSerif',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.forestGreen,
                        )),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 60,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: ownedPlants.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final p = ownedPlants[index];
                              return GestureDetector(
                                onTap: () => context.push('/plant/${p.id}'),
                                child: Container(
                                  width: 160,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurface : Colors.white,
                                    borderRadius: AppRadius.borderMd,
                                    boxShadow: AppShadows.cardShadow,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60, height: 60,
                                        decoration: BoxDecoration(
                                          color: AppColors.dew,
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.md)),
                                          image: p.photoBase64.isNotEmpty
                                              ? DecorationImage(
                                                  image: MemoryImage(Uri.parse(p.photoBase64).data!.contentAsBytes()),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: p.photoBase64.isEmpty ? const Icon(Icons.eco, color: AppColors.mist) : null,
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            p.nickname.isNotEmpty ? p.nickname : p.commonName,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                            maxLines: 2, overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Care Guide Tabs ───────────────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabCtrl,
                    isScrollable: true,
                    labelColor: isDark ? Colors.white : AppColors.forestGreen,
                    unselectedLabelColor: AppColors.moss,
                    indicatorColor: AppColors.forestGreen,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Light'),
                      Tab(text: 'Water'),
                      Tab(text: 'Humidity'),
                      Tab(text: 'Soil'),
                      Tab(text: 'Temp'),
                      Tab(text: 'Propagate'),
                    ],
                  ),
                  isDark ? AppColors.darkSurface : cs.surface,
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 180,
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _GuideTabContent(text: species.careGuide['light'] ?? 'No info'),
                      _GuideTabContent(text: species.careGuide['water'] ?? 'No info'),
                      _GuideTabContent(text: species.careGuide['humidity'] ?? 'No info'),
                      _GuideTabContent(text: species.careGuide['soil'] ?? 'No info'),
                      _GuideTabContent(text: species.careGuide['temperature'] ?? 'No info'),
                      _GuideTabContent(text: species.careGuide['propagation'] ?? 'No info'),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)), // Bottom padding
            ],
          ),
          
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.go('/identify'), // Quick path to add it
            backgroundColor: AppColors.forestGreen,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add to collection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }
}

class _CareSummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CareSummaryChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppRadius.borderMd,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.moss, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.moss, fontWeight: FontWeight.w500)),
          Text(value.toUpperCase(), style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.bark,
          )),
        ],
      ),
    );
  }
}

class _GuideTabContent extends StatelessWidget {
  final String text;
  const _GuideTabContent({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: isDark ? AppColors.mist : AppColors.bark,
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color bgColor;

  _TabBarDelegate(this.tabBar, this.bgColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bgColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

