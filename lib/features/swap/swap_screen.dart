import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/swap_providers.dart';
import '../../data/message_providers.dart';
import '../../theme/app_theme.dart';

class SwapScreen extends ConsumerStatefulWidget {
  const SwapScreen({super.key});

  @override
  ConsumerState<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends ConsumerState<SwapScreen> {
  @override
  void initState() {
    super.initState();
    // Start locating the user in the background if needed
    Future.microtask(() => determineUserLocation(ref));
  }

  @override
  Widget build(BuildContext context) {
    final activeFilter = ref.watch(swapFilterProvider);
    final listingsAsync = ref.watch(swapListingsProvider);
    final userLoc = ref.watch(userLocationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Swap Market', style: TextStyle(
                      fontFamily: 'NotoSerif',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.forestGreen,
                      letterSpacing: -0.5,
                    )),
                    const SizedBox(height: 4),
                    const Text('Trade plants with people nearby.', style: TextStyle(
                      fontSize: 16, color: AppColors.moss,
                    )),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/add-swap'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
                          elevation: 0,
                        ),
                        child: const Text('List Your Plant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (userLoc == null)
                      Row(
                        children: [
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Text('Finding nearby plants...', style: TextStyle(color: AppColors.moss, fontSize: 13)),
                        ],
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppColors.leafGreen),
                          const SizedBox(width: 4),
                          Text('Showing listings near ${userLoc.city}', style: const TextStyle(color: AppColors.leafGreen, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    const SizedBox(height: 16),
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
                    'All', 'Cuttings', 'Seeds', 'Whole Plants', 'Free'
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
                        onSelected: (_) => ref.read(swapFilterProvider.notifier).state = filter,
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

            // ── Swap Listings ────────────────────────────────────────────────
            listingsAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
              data: (listings) {
                if (listings.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🪴', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            const Text(
                              'Nothing nearby yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'NotoSerif', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Be the first to share in your area!',
                              style: TextStyle(fontSize: 14, color: AppColors.moss),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () => context.push('/add-swap'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.forestGreen,
                                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
                              ),
                              child: const Text('List a plant'),
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
                    itemCount: listings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = listings[index];
                      final isOwner = item.ownerUid == uid;

                      // Display label logic
                      String typeLabel = "Whole Plant";
                      if (item.type == 'cutting') typeLabel = 'Cutting';
                      if (item.type == 'seeds') typeLabel = 'Seeds';

                      return GestureDetector(
                        onTap: () => context.push('/swap/${item.id}'),
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
                                    height: 180,
                                    width: double.infinity,
                                    child: Image.network(
                                      item.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.dew,
                                        child: const Icon(Icons.eco, size: 48, color: AppColors.mist),
                                      ),
                                    ),
                                  ),
                                  // Type Pill
                                  Positioned(
                                    top: 12, left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: item.isFree ? AppColors.terracotta : AppColors.leafGreen,
                                        borderRadius: AppRadius.borderPill,
                                      ),
                                      child: Text(
                                        item.isFree ? 'FREE' : typeLabel.toUpperCase(),
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
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.title, style: TextStyle(
                                            fontFamily: 'NotoSerif',
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : AppColors.forestGreen,
                                          )),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.description,
                                            style: TextStyle(color: AppColors.moss, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor: AppColors.dew,
                                                child: Text(
                                                  item.ownerInitials,
                                                  style: const TextStyle(fontSize: 10, color: AppColors.forestGreen, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(item.ownerName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.bark)),
                                              const SizedBox(width: 12),
                                              const Icon(Icons.location_on, size: 12, color: AppColors.mist),
                                              const SizedBox(width: 4),
                                              // Approximate distance text
                                              Text(userLoc != null ? 'Nearby' : item.city, style: const TextStyle(fontSize: 12, color: AppColors.moss)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (!isOwner)
                                      OutlinedButton(
                                        onPressed: () {
                                          if (uid == null) return;
                                          final tId = getThreadId(uid, item.ownerUid);
                                          context.push('/messages/$tId', extra: item.ownerName);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.forestGreen,
                                          side: const BorderSide(color: AppColors.forestGreen),
                                          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
                                        ),
                                        child: const Text('Message', style: TextStyle(fontWeight: FontWeight.w600)),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(color: AppColors.dew, borderRadius: AppRadius.borderPill),
                                        child: const Text('Your Listing', style: TextStyle(fontSize: 12, color: AppColors.forestGreen, fontWeight: FontWeight.bold)),
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

