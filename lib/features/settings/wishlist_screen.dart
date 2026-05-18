import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/species_providers.dart';
import '../../data/wishlist_providers.dart';
import '../../theme/app_theme.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speciesAsync = ref.watch(speciesListProvider);
    final wishlistAsync = ref.watch(wishlistProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist', style: TextStyle(fontFamily: 'NotoSerif', fontWeight: FontWeight.bold)),
      ),
      body: wishlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (wishlistedIds) {
          if (wishlistedIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 64, color: AppColors.mist),
                  const SizedBox(height: 16),
                  Text('Your wishlist is empty.', style: TextStyle(color: AppColors.moss, fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/wiki'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
                    child: const Text('Explore Plant Wiki', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            );
          }

          return speciesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (allSpecies) {
              final wishlistedSpecies = allSpecies.where((s) => wishlistedIds.contains(s.id)).toList();

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: wishlistedSpecies.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final s = wishlistedSpecies[index];

                  return GestureDetector(
                    onTap: () => context.push('/species/${s.id}'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: AppRadius.borderLg,
                        boxShadow: AppShadows.cardShadow,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.network(
                              'https://source.unsplash.com/200x200/?${Uri.encodeComponent(s.imageQuery)}',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: AppColors.dew),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.commonName, style: TextStyle(
                                    fontFamily: 'NotoSerif',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.forestGreen,
                                  )),
                                  Text(s.scientificName, style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                    color: AppColors.moss,
                                  )),
                                  const SizedBox(height: 8),
                                  Text(s.category, style: const TextStyle(
                                    color: AppColors.leafGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  )),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite, color: AppColors.terracotta),
                            onPressed: () => toggleWishlist(s.id, true),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

