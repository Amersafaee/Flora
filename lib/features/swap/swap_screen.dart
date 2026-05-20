import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    Future.microtask(() => determineUserLocation(ref));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeFilter = ref.watch(swapFilterProvider);
    final listingsAsync = ref.watch(swapListingsProvider);
    final userLoc = ref.watch(userLocationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Build filter list with localized labels; store->display mapping
    final filters = <String, String>{
      'All': l10n.all,
      'Cuttings': l10n.cuttingChip,
      'Seeds': l10n.seedsChip,
      'Whole Plants': l10n.wholePlantChip,
      'Free': l10n.freeFilter,
    };

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
                    Text(l10n.swapMarket, style: TextStyle(
                      fontFamily: 'NotoSerif',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.forestGreen,
                      letterSpacing: -0.5,
                    )),
                    const SizedBox(height: 4),
                    Text(l10n.tradePlantsNearby, style: const TextStyle(
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
                        child: Text(l10n.listYourPlant, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (userLoc == null)
                      Row(
                        children: [
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Text(l10n.findingNearbyPlants, style: TextStyle(color: AppColors.moss, fontSize: 13)),
                        ],
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppColors.leafGreen),
                          const SizedBox(width: 4),
                          Text(l10n.showingListingsNear(userLoc.city), style: const TextStyle(color: AppColors.leafGreen, fontSize: 13, fontWeight: FontWeight.w600)),
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
                  children: filters.entries.map((entry) {
                    final key = entry.key;
                    final label = entry.value;
                    final isActive = activeFilter == key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label, style: TextStyle(
                          color: isActive ? Colors.white : AppColors.bark,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        )),
                        selected: isActive,
                        onSelected: (_) => ref.read(swapFilterProvider.notifier).state = key,
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
                            Text(
                              l10n.nothingNearbyYet,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontFamily: 'NotoSerif', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.beFirstToShareInArea,
                              style: const TextStyle(fontSize: 14, color: AppColors.moss),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () => context.push('/add-swap'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.forestGreen,
                                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
                              ),
                              child: Text(l10n.listAPlant),
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

                      String typeLabel = l10n.wholePlantLabel;
                      if (item.type == 'cutting') typeLabel = l10n.cuttingLabel;
                      if (item.type == 'seeds') typeLabel = l10n.seedsLabel;

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
                                  Positioned(
                                    top: 12, left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: item.isFree ? AppColors.terracotta : AppColors.leafGreen,
                                        borderRadius: AppRadius.borderPill,
                                      ),
                                      child: Text(
                                        item.isFree ? l10n.freeLabel : typeLabel.toUpperCase(),
                                        style: const TextStyle(
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
                                            style: const TextStyle(color: AppColors.moss, fontSize: 13),
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
                                              Text(userLoc != null ? l10n.nearbyLabel : item.city, style: const TextStyle(fontSize: 12, color: AppColors.moss)),
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
                                        child: Text(l10n.messageAction, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(color: AppColors.dew, borderRadius: AppRadius.borderPill),
                                        child: Text(l10n.yourListingBadge, style: const TextStyle(fontSize: 12, color: AppColors.forestGreen, fontWeight: FontWeight.bold)),
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
