import 'package:flutter/material.dart';
import 'listing_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'create_listing_screen.dart';
import 'swap_conversations_screen.dart';

class SwapMarketScreen extends StatefulWidget {
  const SwapMarketScreen({super.key});

  @override
  State<SwapMarketScreen> createState() => _SwapMarketScreenState();
}

class _SwapMarketScreenState extends State<SwapMarketScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    const Color softGreen = Color(0xFFE8F3EA);

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
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Swap Market',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.map_outlined, color: primaryColor),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              height: 400,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Listings by Location',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
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
                                          return const Center(child: Text('No listings available', style: TextStyle(color: Colors.grey)));
                                        }
                                        final docs = snapshot.data!.docs.where((d) => (d.data() as Map<String, dynamic>)['isAvailable'] == true).toList();
                                        if (docs.isEmpty) {
                                          return const Center(child: Text('No listings available', style: TextStyle(color: Colors.grey)));
                                        }
                                        return ListView.builder(
                                          itemCount: docs.length,
                                          itemBuilder: (context, index) {
                                            final data = docs[index].data() as Map<String, dynamic>;
                                            final title = data['title'] ?? 'Unknown Plant';
                                            final location = data['location'] ?? 'Unknown Location';
                                            return ListTile(
                                              leading: const Icon(Icons.location_on, color: Color(0xFF154212)),
                                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              subtitle: Text(location),
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(doc: docs[index])));
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
                      icon: Icon(Icons.chat_bubble_outline, color: primaryColor),
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
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search plants or cuttings...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildFilterChip('All', isSelected: _selectedFilter == 'All'),
                    _buildFilterChip('Cuttings', isSelected: _selectedFilter == 'Cuttings'),
                    _buildFilterChip('Seeds', isSelected: _selectedFilter == 'Seeds'),
                    _buildFilterChip('Whole Plants', isSelected: _selectedFilter == 'Whole Plants'),
                  ],
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
                      return const Center(child: Text('Error loading listings', style: TextStyle(color: Colors.grey)));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()));
                    }

                    final allDocs = snapshot.data?.docs.where((d) => (d.data() as Map<String, dynamic>)['isAvailable'] == true).toList() ?? [];
                    if (allDocs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text('No listings available right now.', style: TextStyle(color: Colors.grey)),
                        ),
                      );
                    }

                    final filteredDocs = allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title = (data['title'] ?? '').toString().toLowerCase();
                      final desc = (data['description'] ?? '').toString().toLowerCase();
                      final type = (data['type'] ?? '');
                      final query = _searchQuery.toLowerCase();
                      
                      bool matchesSearch = title.contains(query) || desc.contains(query);
                      bool matchesFilter = true;
                      
                      if (_selectedFilter == 'Cuttings') matchesFilter = type == 'Cutting';
                      if (_selectedFilter == 'Seeds') matchesFilter = type == 'Free Seeds';
                      if (_selectedFilter == 'Whole Plants') matchesFilter = type == 'Whole Plant';
                      
                      return matchesSearch && matchesFilter;
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text('No listings found for your search.', style: TextStyle(color: Colors.grey)),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (var doc in filteredDocs) ...[
                          _buildListingCard(
                            context: context,
                            doc: doc,
                            primaryColor: primaryColor,
                            softGreen: softGreen,
                          ),
                          const SizedBox(height: 20),
                        ],
                        const SizedBox(height: 40),
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateListingScreen()),
          );
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('List Your Plant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: Chip(
          label: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          backgroundColor: isSelected ? const Color(0xFF154212) : Colors.transparent,
          side: isSelected ? BorderSide.none : const BorderSide(color: Color(0xFFCCCCCC)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
    
    String timeAgo = 'Recently';
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListingDetailScreen(doc: doc),
            ),
          );
        },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder
            Container(
              height: 180,
              width: double.infinity,
              color: const Color(0xFFE8F5E9),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.eco, color: const Color(0xFF154212).withValues(alpha: 0.4), size: 48),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.eco, color: const Color(0xFF154212).withValues(alpha: 0.4), size: 48),
                    ),
            ),
            
            // Content
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
                        decoration: BoxDecoration(
                          color: softGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.grey.shade500, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$location · ${distanceKm}km',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.swap_horiz, color: const Color(0xFF8D3220), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Looking for: $lookingFor',
                          style: TextStyle(
                            color: const Color(0xFF8D3220),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ownerName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}







