import 'package:flutter/material.dart';
import 'global_search_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'profile_screen.dart';
import 'wiki_plant_detail_screen.dart';
import 'blog_detail_screen.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class WikiScreen extends StatefulWidget {
  const WikiScreen({super.key});

  @override
  State<WikiScreen> createState() => _WikiScreenState();
}

class _WikiScreenState extends State<WikiScreen> {
  // Internal English key used for Firestore tag matching — must NOT be localized
  String _selectedFilter = 'All Plants';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    FirestoreService().seedSpeciesData();
    FirestoreService().seedBlogData();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // Map from internal English key → localized display label
    final filterLabels = {
      'All Plants': l.wikiFilterAllPlants,
      'Pet Friendly': l.wikiFilterPetFriendly,
      'Low Light': l.lowLight,
      'Air Purifying': l.wikiFilterAirPurifying,
      'Beginner': l.wikiFilterBeginner,
    };

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                      child: const CircleAvatar(
                        backgroundColor: AppColors.bone500,
                        radius: 18,
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ),
                    Text(
                      l.digitalConservatory,
                      style: const TextStyle(
                        color: AppColors.forest900,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => GlobalSearchScreen()));
                      },
                    ),
                  ],
                ),
              ),

              // Title and Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.plantWiki,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.wikiSubtitle,
                      style: const TextStyle(
                        color: AppColors.bone500,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: l.searchByNameSpeciesTrait,
                      hintStyle: const TextStyle(color: AppColors.bone500),
                      prefixIcon: const Icon(Icons.search, color: AppColors.bone500),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: filterLabels.entries.map((entry) {
                    return _buildFilterChip(
                      internalKey: entry.key,
                      displayLabel: entry.value,
                      isSelected: _selectedFilter == entry.key,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Plant Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('species').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text(l.errorLoadingWikiData));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allDocs = snapshot.data?.docs ?? [];
                    if (allDocs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text(
                            l.noPlantsInWikiYet,
                            style: const TextStyle(color: AppColors.bone500),
                          ),
                        ),
                      );
                    }

                    final filteredPlants = allDocs.where((doc) {
                      final p = doc.data() as Map<String, dynamic>;
                      final matchesSearch =
                          (p['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          (p['commonName'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());

                      bool matchesFilter = true;
                      if (_selectedFilter != 'All Plants') {
                        // Tag matching uses internal English key — not localized
                        final tags = List<String>.from(p['tags'] ?? []);
                        matchesFilter = tags.contains(_selectedFilter);
                      }

                      return matchesSearch && matchesFilter;
                    }).toList();

                    if (filteredPlants.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text(
                            l.noPlantsFoundForSearch,
                            style: const TextStyle(color: AppColors.bone500),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (var plantDoc in filteredPlants) ...[
                          _buildPlantCard(
                            context: context,
                            name: (plantDoc.data() as Map<String, dynamic>)['name'] ?? '',
                            commonName: (plantDoc.data() as Map<String, dynamic>)['commonName'] ?? '',
                            category: (plantDoc.data() as Map<String, dynamic>)['category'] ?? '',
                            tags: List<String>.from((plantDoc.data() as Map<String, dynamic>)['tags'] ?? []),
                            imageUrl: (plantDoc.data() as Map<String, dynamic>)['imageUrl'] ?? '',
                            plantData: plantDoc.data() as Map<String, dynamic>,
                          ),
                          const SizedBox(height: 24),
                        ],
                        const SizedBox(height: 40),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Blog Section Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  l.latestFromBlog,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Blog Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('blogs')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text(l.errorLoadingBlogs));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allBlogsRaw = snapshot.data?.docs ?? [];
                    // Only show blogs with a real localImagePath starting with 'assets/'
                    final allBlogs = allBlogsRaw.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final path = (d['localImagePath'] as String? ?? '').trim();
                      return path.isNotEmpty && path.startsWith('assets/');
                    }).toList();

                    if (allBlogs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: AppColors.forest900),
                              const SizedBox(height: 16),
                              Text(
                                l.blogPostsLoading,
                                style: const TextStyle(color: AppColors.bone500),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (var blogDoc in allBlogs) ...[
                          _buildBlogCard(
                            context: context,
                            blogData: blogDoc.data() as Map<String, dynamic>,
                          ),
                          const SizedBox(height: 16),
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
    );
  }

  Widget _buildFilterChip({
    required String internalKey,
    required String displayLabel,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = internalKey;
          });
        },
        child: Chip(
          avatar: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          label: Text(
            displayLabel,
            style: TextStyle(
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          backgroundColor: isSelected ? AppColors.forest900 : Colors.transparent,
          side: isSelected ? BorderSide.none : const BorderSide(color: AppColors.bone300),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildPlantCard({
    required BuildContext context,
    required String name,
    required String commonName,
    required String category,
    required List<String> tags,
    required String imageUrl,
    required Map<String, dynamic> plantData,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => WikiPlantDetailScreen(plantData: plantData)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 200,
              width: double.infinity,
              color: AppColors.forest100,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.eco, color: Color(0x6614301E), size: 48)),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: Icon(Icons.eco, color: Color(0x6614301E), size: 48));
                      },
                    )
                  : const Center(child: Icon(Icons.eco, color: Color(0x6614301E), size: 48)),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          color: AppColors.terracotta900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseAuth.instance.currentUser != null
                            ? FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .collection('bookmarks')
                                .doc(name)
                                .snapshots()
                            : const Stream.empty(),
                        builder: (context, snapshot) {
                          final isBookmarked = snapshot.hasData && snapshot.data!.exists;
                          return GestureDetector(
                            onTap: () async {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) return;
                              final docRef = FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('bookmarks')
                                  .doc(name);
                              if (isBookmarked) {
                                await docRef.delete();
                              } else {
                                await docRef.set({
                                  'plantName': name,
                                  'bookmarkedAt': FieldValue.serverTimestamp(),
                                });
                              }
                            },
                            child: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: isBookmarked ? AppColors.forest900 : AppColors.bone500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    commonName,
                    style: const TextStyle(
                      color: AppColors.bone500,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) => _buildTagChip(tag)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.forest100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: AppColors.forest700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBlogCard({
    required BuildContext context,
    required Map<String, dynamic> blogData,
  }) {
    final l = AppLocalizations.of(context);
    final title = (blogData['title'] as String? ?? 'Untitled');
    final category = (blogData['category'] as String? ?? 'General');
    final readMinutes = (blogData['readMinutes'] as num?)?.toInt() ?? 5;
    final summary = (blogData['summary'] as String? ?? '');
    final localImagePath = (blogData['localImagePath'] as String? ?? '');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BlogDetailScreen(blogData: blogData)),
        );
      },
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (localImagePath.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  localImagePath,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    width: double.infinity,
                    color: AppColors.forest100,
                    child: const Center(
                      child: Icon(Icons.article, color: AppColors.forest900, size: 48),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 160,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.forest100,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(
                  child: Icon(Icons.article, color: AppColors.forest900, size: 48),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.forest100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: AppColors.forest700,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '$readMinutes ${l.minRead}',
                        style: const TextStyle(color: AppColors.bone500, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    style: const TextStyle(
                      color: AppColors.bone500,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
