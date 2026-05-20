import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'swap_chat_screen.dart';
import '../theme/app_theme.dart';

class ListingDetailScreen extends StatefulWidget {
  final DocumentSnapshot doc;
  const ListingDetailScreen({super.key, required this.doc});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  Map<String, dynamic> get data => widget.doc.data() as Map<String, dynamic>;

  Future<void> _startConversation() async {
    if (_currentUid == null) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final sellerUid = data['ownerUid'] ?? '';
    final sellerName = data['ownerName'] ?? '';
    final listingId = widget.doc.id;
    final listingTitle = data['title'] ?? '';

    final convId = '${listingId}_$_currentUid';

    final convRef = FirebaseFirestore.instance.collection('swap_conversations').doc(convId);
    final convDoc = await convRef.get();

    if (!convDoc.exists) {
      await convRef.set({
        'listingId': listingId,
        'listingTitle': listingTitle,
        'buyerUid': _currentUid,
        'buyerName': currentUser.displayName ?? 'A fellow plant lover',
        'sellerUid': sellerUid,
        'sellerName': sellerName,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SwapChatScreen(conversationId: convId)));
    }
  }

  Future<void> _deleteListing() async {
    final l = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteListing),
        content: Text(l.deleteListingConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete, style: const TextStyle(color: AppColors.terracotta900)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('swap_listings').doc(widget.doc.id).delete();
      if (mounted) Navigator.pop(context);
    }
  }

  void _editListing(Map<String, dynamic> currentData) {
    final l = AppLocalizations.of(context);
    final titleCtrl = TextEditingController(text: currentData['title']);
    final descCtrl = TextEditingController(text: currentData['description']);
    final lookCtrl = TextEditingController(text: currentData['lookingFor']);
    String type = currentData['type'] ?? 'Cutting';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.editListing, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: InputDecoration(labelText: l.titleLabel)),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: InputDecoration(labelText: l.descriptionLabel)),
              const SizedBox(height: 8),
              TextField(controller: lookCtrl, decoration: InputDecoration(labelText: l.lookingFor)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: type,
                items: ['Cutting', 'Free Seeds', 'Whole Plant', 'Adoption']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setSheetState(() => type = v!),
                decoration: InputDecoration(labelText: l.typeLabel),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('swap_listings').doc(widget.doc.id).update({
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'lookingFor': lookCtrl.text.trim(),
                    'type': type,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(l.save),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('swap_listings').doc(widget.doc.id).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final currentData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          if (currentData.isEmpty) return const SizedBox.shrink();

          final Color primaryColor = Theme.of(context).primaryColor;
          final imageUrl = currentData['imageUrl'] ?? '';
          final title = currentData['title'] ?? '';
          final description = currentData['description'] ?? '';
          final location = currentData['location'] ?? '';
          final type = currentData['type'] ?? '';
          final lookingFor = currentData['lookingFor'] ?? '';
          final ownerName = currentData['ownerName'] ?? '';
          final ownerUid = currentData['ownerUid'] ?? '';
          final careStreak = currentData['careStreak'] as int? ?? 0;
          final isOwner = _currentUid == ownerUid;

          String timeAgo = l.recently;
          final timestamp = currentData['timestamp'];
          if (timestamp is Timestamp) {
            final date = timestamp.toDate();
            final diff = DateTime.now().difference(date);
            if (diff.inMinutes < 60) {
              timeAgo = '${diff.inMinutes}m ago';
            } else if (diff.inHours < 24) {
              timeAgo = '${diff.inHours}h ago';
            } else {
              timeAgo = DateFormat.yMMMd().format(date);
            }
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (isOwner) ...[
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                      onPressed: () => _editListing(currentData),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                      ),
                      onPressed: _deleteListing,
                    ),
                  ],
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.forest100,
                            child: const Center(child: Icon(Icons.eco, size: 64, color: AppColors.forest900)),
                          ))
                      : Container(
                          color: AppColors.forest100,
                          child: const Center(child: Icon(Icons.eco, size: 64, color: AppColors.forest900)),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.forest100, borderRadius: BorderRadius.circular(20)),
                            child: Text(type, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const Spacer(),
                          const Icon(Icons.access_time, size: 14, color: AppColors.bone500),
                          const SizedBox(width: 4),
                          Text(timeAgo, style: const TextStyle(color: AppColors.bone500, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppColors.bone500),
                          const SizedBox(width: 4),
                          Text(location, style: const TextStyle(color: AppColors.bone500, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(l.aboutThisPlant, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 8),
                      Text(description, style: const TextStyle(color: AppColors.bone700, fontSize: 15, height: 1.5)),
                      const SizedBox(height: 24),

                      // Looking to swap for
                      Builder(
                        builder: (context) {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkTerracottaSubtle : AppColors.terracotta100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? AppColors.darkBorderDefault : AppColors.terracotta500),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.swap_horiz, color: isDark ? AppColors.darkTerracotta : AppColors.terracotta900),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l.lookingToSwapFor,
                                        style: TextStyle(color: isDark ? AppColors.darkTerracotta : AppColors.terracotta900, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(lookingFor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Owner card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.bone500,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.listedBy, style: const TextStyle(color: AppColors.bone500, fontSize: 12)),
                                Row(
                                  children: [
                                    Text(ownerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    if (careStreak > 0) ...[
                                      const SizedBox(width: 8),
                                      Builder(
                                        builder: (context) {
                                          final isDark = Theme.of(context).brightness == Brightness.dark;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppColors.darkSurfaceElevated : AppColors.terracotta100,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: isDark ? AppColors.darkBorderDefault : AppColors.terracotta500),
                                            ),
                                            child: Text(
                                              '🔥 $careStreak ${l.careStreak}',
                                              style: TextStyle(color: isDark ? AppColors.darkTerracotta : AppColors.terracotta700, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _currentUid == data['ownerUid']
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => _showPassportSheet(data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest900,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    l.messageSeller,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
    );
  }

  void _showPassportSheet(Map<String, dynamic> currentData) {
    final l = AppLocalizations.of(context);
    final title = currentData['title'] ?? '';
    final type = currentData['type'] ?? '';
    final description = currentData['description'] ?? '';
    final ownerName = currentData['ownerName'] ?? '';
    final healthScore = currentData['healthScore'];

    Widget healthBadge;
    if (healthScore is num) {
      final score = healthScore.toInt();
      final isDark = Theme.of(context).brightness == Brightness.dark;
      Color badgeColor;
      if (score >= 70) {
        badgeColor = isDark ? AppColors.successDark : AppColors.successLight;
      } else if (score >= 40) {
        badgeColor = isDark ? AppColors.warningDark : AppColors.warningLight;
      } else {
        badgeColor = isDark ? AppColors.errorDark : AppColors.errorLight;
      }
      healthBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
        child: Text('${l.healthColonPrefix}$score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      );
    } else {
      healthBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(l.healthNotAssessed, style: const TextStyle(color: AppColors.bone900, fontWeight: FontWeight.bold, fontSize: 12)),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                healthBadge,
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.forest100, borderRadius: BorderRadius.circular(12)),
                  child: Text(type, style: const TextStyle(color: AppColors.forest900, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l.passportDetails, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: AppColors.bone700, fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.person, color: AppColors.bone500, size: 20),
                const SizedBox(width: 8),
                Text('${l.listedBy} $ownerName', style: const TextStyle(color: AppColors.bone500, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(l.viewFullListing, style: const TextStyle(color: AppColors.forest900)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _startConversation();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest900,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(l.messageSellerEmoji, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
