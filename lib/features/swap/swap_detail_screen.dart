import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/swap_providers.dart';
import '../../data/message_providers.dart';
import '../../theme/tokens.dart';

class SwapDetailScreen extends ConsumerWidget {
  final String listingId;
  const SwapDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(swapDetailProvider(listingId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return detailAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (item) {
        if (item == null) {
          return const Scaffold(body: Center(child: Text('Listing not found.')));
        }

        final isOwner = item.ownerUid == uid;
        String typeLabel = "Whole Plant";
        if (item.type == 'cutting') typeLabel = 'Cutting';
        if (item.type == 'seeds') typeLabel = 'Seeds';

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Header
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.dew,
                      child: const Icon(Icons.eco, size: 64, color: AppColors.mist),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.isFree ? AppColors.terracotta : AppColors.leafGreen,
                              borderRadius: AppRadius.borderPill,
                            ),
                            child: Text(
                              item.isFree ? 'FREE' : typeLabel.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (item.status == 'completed')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.mist,
                                borderRadius: AppRadius.borderPill,
                              ),
                              child: const Text(
                                'COMPLETED',
                                style: TextStyle(
                                  color: AppColors.bark,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title & City
                      Text(item.title, style: TextStyle(
                        fontFamily: 'NotoSerif',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.forestGreen,
                      )),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppColors.moss),
                          const SizedBox(width: 4),
                          Text(item.city, style: const TextStyle(fontSize: 14, color: AppColors.moss)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(item.description, style: const TextStyle(fontSize: 16, height: 1.5)),
                      const SizedBox(height: 32),

                      // Owner Block
                      const Text('Listed By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: AppRadius.borderLg,
                          boxShadow: AppShadows.cardShadow,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.dew,
                              child: Text(
                                item.ownerInitials,
                                style: const TextStyle(fontSize: 18, color: AppColors.forestGreen, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(item.ownerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                            if (!isOwner)
                              ElevatedButton(
                                onPressed: () {
                                  if (uid == null) return;
                                  final tId = getThreadId(uid, item.ownerUid);
                                  context.push('/messages/$tId', extra: item.ownerName);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.forestGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
                                ),
                                child: const Text('Message'),
                              ),
                          ],
                        ),
                      ),

                      // Owner Actions
                      if (isOwner) ...[
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        if (item.status != 'completed')
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                await completeListing(item.id);
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Coming soon', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF2D5A27), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4, duration: const Duration(seconds: 3), ));
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.forestGreen,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
                              ),
                              child: const Text('Mark as Completed'),
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              await deleteListing(item.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Coming soon', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF2D5A27), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4, duration: const Duration(seconds: 3), ));
                                context.pop();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.terracotta,
                              side: const BorderSide(color: AppColors.terracotta),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
                            ),
                            child: const Text('Delete Listing'),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


