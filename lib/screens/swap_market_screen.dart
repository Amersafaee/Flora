import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'listing_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_listing_screen.dart';
import 'swap_conversations_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/shared/app_card.dart';

class SwapMarketScreen extends StatefulWidget {
  const SwapMarketScreen({super.key});

  @override
  State<SwapMarketScreen> createState() => _SwapMarketScreenState();
}

class _SwapMarketScreenState extends State<SwapMarketScreen> {
  // Filter state uses internal English keys that match Firestore type values
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final Color primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? AppColors.darkBackground : AppColors.bone50;
    const Color softGreen = AppColors.forest100;

    // Filter chips: display label → internal Firestore filter key
    final filters = [
      {'label': l.all, 'key': 'All'},
      {'label': l.cuttings, 'key': 'Cuttings'},
      {'label': l.seeds, 'key': 'Seeds'},
      {'label': l.wholePlants, 'key': 'Whole Plants'},
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      IconButton(
                        icon: Icon(CupertinoIcons.chevron_back, color: isDark ? AppColors.forest400 : AppColors.forest700),
                        onPressed: () => Navigator.pop(context),
                      ),
                    Expanded(
                      child: Text(
                        l.swapMarket,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSerif(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.bone900,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.map_outlined, color: isDark ? AppColors.forest400 : primaryColor),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: isDark
                              ? AppColors.darkCardSurface
                              : AppColors.bone50,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                          builder: (context) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              height: 400,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCardSurface
                                    : AppColors.bone50,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.listingsByLocation, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('swap_listings')
                                          .orderBy('timestamp', descending: true)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        if (snapshot.hasError || !snapshot.hasData) {
                                          return Center(child: Text(l.noListingsAvailable, style: const TextStyle(color: AppColors.bone500)));
                                        }
                                        final docs = snapshot.data!.docs
                                            .where((d) => (d.data() as Map<String, dynamic>)['isAvailable'] == true)
                                            .toList();
                                        if (docs.isEmpty) {
                                          return Center(child: Text(l.noListingsAvailable, style: const TextStyle(color: AppColors.bone500)));
                                        }
                                        return ListView.builder(
                                          itemCount: docs.length,
                                          itemBuilder: (context, index) {
                                            final data = docs[index].data() as Map<String, dynamic>;
                                            final title = data['title'] ?? 'Unknown Plant';
                                            final location = data['location'] ?? 'Unknown Location';
                                            return ListTile(
                                              leading: const Icon(Icons.location_on, color: AppColors.forest900),
                                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              subtitle: Text(location),
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.push(context, MaterialPageRoute(
                                                  builder: (_) => ListingDetailScreen(doc: docs[index]),
                                                ));
                                              },
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.chat_bubble_outline, color: isDark ? AppColors.forest400 : primaryColor),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SwapConversationsScreen()));
                      },
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: l.searchPlantsOrCuttings,
                    hintStyle: const TextStyle(color: AppColors.bone500),
                    prefixIcon: const Icon(Icons.search, color: AppColors.bone500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.bone200, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.bone200, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.forest700, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.bone100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: filters.map((f) => _buildFilterChip(f['label']!, f['key']!)).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Listings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('swap_listings')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text(l.errorLoadingListings, style: const TextStyle(color: AppColors.bone500)));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()));
                    }

                    final allDocs = snapshot.data?.docs
                            .where((d) => (d.data() as Map<String, dynamic>)['isAvailable'] == true)
                            .toList() ??
                        [];
                    if (allDocs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text(l.noListingsAvailable, style: const TextStyle(color: AppColors.bone500)),
                        ),
                      );
                    }

                    final filteredDocs = allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title = (data['title'] ?? '').toString().toLowerCase();
                      final desc = (data['description'] ?? '').toString().toLowerCase();
                      final type = (data['type'] ?? '');
                      final query = _searchQuery.toLowerCase();

                      final matchesSearch = title.contains(query) || desc.contains(query);
                      bool matchesFilter = true;

                      if (_selectedFilter == 'Cuttings') matchesFilter = type == 'Cutting';
                      if (_selectedFilter == 'Seeds') matchesFilter = type == 'Free Seeds';
                      if (_selectedFilter == 'Whole Plants') matchesFilter = type == 'Whole Plant';

                      return matchesSearch && matchesFilter;
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text(l.noListingsForSearch, style: const TextStyle(color: AppColors.bone500)),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (var doc in filteredDocs) ...[
                          _buildListingCard(context: context, doc: doc, primaryColor: primaryColor, softGreen: softGreen, l: l),
                          const SizedBox(height: 20),
                        ],
                        const SizedBox(height: 120),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateListingScreen()));
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(l.listYourPlant, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterKey) {
    final isSelected = _selectedFilter == filterKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filterKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.forest700 : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? null
                : Border.all(
                    color: isDark ? AppColors.darkBorderDefault : AppColors.bone200,
                  ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.bone900),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListingCard({
    required BuildContext context,
    required DocumentSnapshot doc,
    required Color primaryColor,
    required Color softGreen,
    required AppLocalizations l,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final imageUrl = data['imageUrl'] ?? '';
    final title = data['title'] ?? '';
    final description = data['description'] ?? '';
    final location = data['location'] ?? '';
    final distanceKm = data['distanceKm'] ?? 0;
    final type = data['type'] ?? '';
    final lookingFor = data['lookingFor'] ?? '';
    final ownerName = data['ownerName'] ?? '';

    String timeAgo = l.recently;
    final timestamp = data['timestamp'];
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final difference = DateTime.now().difference(date);
      if (difference.inMinutes < 60) {
        timeAgo = '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        timeAgo = '${difference.inHours}h ago';
      } else {
        timeAgo = DateFormat.yMMMd().format(date);
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(doc: doc)));
      },
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final placeholderBg = isDark ? AppColors.darkSurfaceElevated : AppColors.forest50;
                return Container(
                  height: 180,
                  width: double.infinity,
                  color: placeholderBg,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 180,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 180,
                            width: double.infinity,
                            color: placeholderBg,
                            child: Center(
                              child: Icon(Icons.local_florist, size: 40, color: isDark ? AppColors.darkForestPrimary.withValues(alpha: 0.4) : AppColors.forest300),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(Icons.local_florist, size: 40, color: isDark ? AppColors.darkForestPrimary.withValues(alpha: 0.4) : AppColors.forest300),
                        ),
                );
              }
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: softGreen, borderRadius: BorderRadius.circular(8)),
                        child: Text(type, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.bone500, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$location · ${distanceKm}km',
                            style: const TextStyle(color: AppColors.bone500, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.bone500, fontSize: 14)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.swap_horiz, color: AppColors.terracotta900, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${l.lookingForPrefix}$lookingFor',
                          style: const TextStyle(color: AppColors.terracotta900, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.bone500,
                            child: Icon(Icons.person, color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 8),
                          Text(ownerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                        ],
                      ),
                      Text(timeAgo, style: const TextStyle(color: AppColors.bone500, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
