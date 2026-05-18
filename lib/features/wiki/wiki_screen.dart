import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/species_providers.dart';
import '../../data/wishlist_providers.dart';
import '../../theme/app_theme.dart';

class WikiScreen extends ConsumerWidget {
  const WikiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(wikiActiveFilterProvider);
    final searchQuery = ref.watch(wikiSearchQueryProvider).toLowerCase();
    
    final speciesAsync = ref.watch(speciesListProvider);
    final wishlistAsync = ref.watch(wishlistProvider);
    
    final wishlistedIds = wishlistAsync.valueOrNull ?? {};

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header & Search ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plant Wiki', style: TextStyle(
                      fontFamily: 'NotoSerif',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.forestGreen,
                      letterSpacing: -0.5,
                    )),
                    const SizedBox(height: 4),
                    const Text('Find your next green companion.', style: TextStyle(
                      fontSize: 16, color: AppColors.moss,
                    )),
                    const SizedBox(height: 24),
                    TextField(
                      onChanged: (val) => ref.read(wikiSearchQueryProvider.notifier).state = val,
                      decoration: InputDecoration(
                        hintText: 'Search by name or type…',
                        prefixIcon: const Icon(Icons.search, color: AppColors.moss),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurface : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.borderPill,
                          borderSide: BorderSide(color: AppColors.mist, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.borderPill,
                          borderSide: BorderSide(color: AppColors.mist, width: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Filter Chips ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    'All', 'Pet Friendly', 'Low Light', 'Beginner', 'Tropical', 'Succulent'
                  ].map((filter) {
                    final isActive = activeFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter, style: TextStyle(
                          color: isActive ? Colors.white : AppColors.bark,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        )),
                        selected: isActive,
                        onSelected: (_) => ref.read(wikiActiveFilterProvider.notifier).state = filter,
                        selectedColor: AppColors.forestGreen,
                        backgroundColor: isDark ? AppColors.darkSurface : AppColors.dew,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Species List ────────────────────────────────────────────────
            speciesAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
              data: (speciesList) {
                // Apply client-side search filter
                final filtered = speciesList.where((s) {
                  if (searchQuery.isEmpty) return true;
                  return s.commonName.toLowerCase().contains(searchQuery) ||
                         s.scientificName.toLowerCase().contains(searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🔍', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            const Text(
                              'No plants match',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'NotoSerif', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try a different filter or search term.',
                              style: TextStyle(fontSize: 14, color: AppColors.moss),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final s = filtered[index];
                      final isWishlisted = wishlistedIds.contains(s.id);

                      return GestureDetector(
                        onTap: () => context.push('/species/${s.id}'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: AppRadius.borderLg,
                            boxShadow: AppShadows.cardShadow,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top Image
                              Stack(
                                children: [
                                  SizedBox(
                                    height: 160,
                                    width: double.infinity,
                                    child: Image.network(
                                      'https://source.unsplash.com/400x300/?${Uri.encodeComponent(s.imageQuery)}',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.dew,
                                        child: const Icon(Icons.eco, size: 48, color: AppColors.mist),
                                      ),
                                    ),
                                  ),
                                  // Wishlist Heart
                                  Positioned(
                                    top: 12, right: 12,
                                    child: GestureDetector(
                                      onTap: () => toggleWishlist(s.id, isWishlisted),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.black45 : Colors.white70,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                                          color: isWishlisted ? AppColors.terracotta : AppColors.bark,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Category Pill
                                  Positioned(
                                    top: 12, left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.leafGreen,
                                        borderRadius: AppRadius.borderPill,
                                      ),
                                      child: Text(
                                        s.category,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Info
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.commonName, style: TextStyle(
                                      fontFamily: 'NotoSerif',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.forestGreen,
                                    )),
                                    const SizedBox(height: 2),
                                    if (s.scientificName.isNotEmpty)
                                      Text(s.scientificName, style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 13,
                                        color: AppColors.moss,
                                      )),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: s.traits.take(3).map((t) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkSurface : Color(0x80E8F3EA),
                                          borderRadius: AppRadius.borderSm,
                                        ),
                                        child: Text(t, style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? AppColors.mist : AppColors.bark,
                                        )),
                                      )).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

