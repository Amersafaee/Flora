import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/swap_providers.dart';
import '../../data/message_providers.dart';
import '../../theme/app_theme.dart';

class SwapDetailScreen extends ConsumerWidget {
  final String listingId;
  const SwapDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(swapDetailProvider(listingId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return detailAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (item) {
        if (item == null) {
          return Scaffold(body: Center(child: Text(l10n.listingNotFound)));
        }

        final isOwner = item.ownerUid == uid;
        String typeLabel = l10n.wholePlantLabel;
        if (item.type == 'cutting') typeLabel = l10n.cuttingLabel;
        if (item.type == 'seeds') typeLabel = l10n.seedsLabel;

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
                              item.isFree ? l10n.freeLabel : typeLabel.toUpperCase(),
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
                              child: Text(
                                l10n.completedBadge,
                                style: const TextStyle(
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
                      Text(l10n.descriptionHeader, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(item.description, style: const TextStyle(fontSize: 16, height: 1.5)),
                      const SizedBox(height: 32),

                      // Owner Block
                      Text(l10n.listedByHeader, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                                child: Text(l10n.messageAction),
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
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).listingMarkedCompleted, style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.forest700, behavior: SnackBarBehavior.floating));
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.forestGreen,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
                              ),
                              child: Text(l10n.markAsCompleted),
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              await deleteListing(item.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).listingDeleted, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
                                context.pop();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.terracotta,
                              side: const BorderSide(color: AppColors.terracotta),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
                            ),
                            child: Text(l10n.deleteListingAction),
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
