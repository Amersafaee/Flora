import 'package:flutter/material.dart';
import 'global_search_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';
import 'wiki_plant_detail_screen.dart';
import '../services/firestore_service.dart';

class WikiScreen extends StatefulWidget {
  const WikiScreen({super.key});

  @override
  State<WikiScreen> createState() => _WikiScreenState();
}

class _WikiScreenState extends State<WikiScreen> {
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
    
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;

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
                        backgroundColor: Colors.grey,
                        radius: 18,
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ),
                    const Text(
                      'Digital Conservatory',
                      style: TextStyle(
                        color: Color(0xFF154212),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        fontSize: 18,
                      ),
                    ),
                    IconButton(icon: Icon(Icons.search, color: Theme.of(context).primaryColor), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen())); }),
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
                      'Plant Wiki',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore our botanical encyclopedia to find your perfect green companion.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
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
                      hintText: 'Search by name, species, or trait...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
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
                  children: [
                    _buildFilterChip('All Plants', isSelected: _selectedFilter == 'All Plants'),
                    _buildFilterChip('Pet Friendly', isSelected: _selectedFilter == 'Pet Friendly'),
                    _buildFilterChip('Low Light', isSelected: _selectedFilter == 'Low Light'),
                    _buildFilterChip('Air Purifying', isSelected: _selectedFilter == 'Air Purifying'),
                    _buildFilterChip('Beginner', isSelected: _selectedFilter == 'Beginner'),
                  ],
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
                      return const Center(child: Text('Error loading wiki data'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final allDocs = snapshot.data?.docs ?? [];
                    if (allDocs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text(
                            'No plants in the wiki yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    final filteredPlants = allDocs.where((doc) {
                      final p = doc.data() as Map<String, dynamic>;
                      final matchesSearch = (p['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          (p['commonName'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
                      
                      bool matchesFilter = true;
                      if (_selectedFilter != 'All Plants') {
                        final tags = List<String>.from(p['tags'] ?? []);
                        matchesFilter = tags.contains(_selectedFilter);
                      }
                      
                      return matchesSearch && matchesFilter;
                    }).toList();

                    if (filteredPlants.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text(
                            'No plants found for your search.',
                            style: TextStyle(color: Colors.grey),
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
                  'Latest from the Blog',
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
                  stream: FirebaseFirestore.instance.collection('blogs').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading blogs'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final allBlogsRaw = snapshot.data?.docs ?? [];
                    // FIX 8: Only show blogs that have a real localImagePath (filters out seeded species-wiki entries)
                    final allBlogs = allBlogsRaw.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final path = (d['localImagePath'] as String? ?? '').trim();
                      return path.isNotEmpty;
                    }).toList();
                    if (allBlogs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text(
                            'No blogs available.',
                            style: TextStyle(color: Colors.grey),
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
          avatar: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
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
            // Image Placeholder
            Container(
              height: 200,
              width: double.infinity,
              color: const Color(0xFFE8F5E9),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.eco, color: const Color(0xFF154212).withValues(alpha: 0.4), size: 48),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: Icon(Icons.eco, color: const Color(0xFF154212).withValues(alpha: 0.4), size: 48),
                        );
                      },
                    )
                  : Center(
                      child: Icon(Icons.eco, color: const Color(0xFF154212).withValues(alpha: 0.4), size: 48),
                    ),
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
                          color: Color(0xFF8D3220),
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
                              color: isBookmarked ? const Color(0xFF154212) : Colors.grey,
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
                    style: TextStyle(
                      color: Colors.grey.shade600,
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
        color: const Color(0xFFF0F5F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Color(0xFF2D5A27),
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
    final title = (blogData['title'] as String? ?? '');
    final category = (blogData['category'] as String? ?? '');
    final readMinutes = (blogData['readMinutes'] as num?)?.toInt() ?? 5;
    final summary = (blogData['summary'] as String? ?? '');
    final content = (blogData['content'] as String? ?? '');
    final localImagePath = (blogData['localImagePath'] as String? ?? '');

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (localImagePath.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        localImagePath,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          width: double.infinity,
                          color: const Color(0xFFE8F5E9),
                          child: const Center(
                            child: Icon(Icons.article, color: Color(0xFF154212), size: 48),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Color(0xFF2D5A27),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '$readMinutes min read',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Read time indicator
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 6),
                      Text(
                        '$readMinutes min read',
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Paragraph-grouped content
                  Builder(builder: (context) {
                    // Split into sentences and group into paragraphs of ~3 sentences
                    final rawSentences = content.split('. ');
                    final List<String> paragraphs = [];
                    const sentencesPerParagraph = 3;
                    for (int i = 0; i < rawSentences.length; i += sentencesPerParagraph) {
                      final chunk = rawSentences.sublist(
                        i,
                        (i + sentencesPerParagraph) > rawSentences.length
                            ? rawSentences.length
                            : i + sentencesPerParagraph,
                      );
                      final para = chunk.where((s) => s.trim().isNotEmpty).join('. ').trim();
                      if (para.isNotEmpty) {
                        // Re-add period if the last sentence doesn't already end with punctuation
                        paragraphs.add(para.endsWith('.') || para.endsWith('!') || para.endsWith('?') ? para : '$para.');
                      }
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < paragraphs.length; i++) ...[
                          if (i == 0)
                            // First paragraph gets a decorative green left border
                            Container(
                              padding: const EdgeInsets.only(left: 14),
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Color(0xFF2E7D32), width: 3),
                                ),
                              ),
                              child: Text(
                                paragraphs[i],
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.7,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            )
                          else
                            Text(
                              paragraphs[i],
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.7,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          if (i < paragraphs.length - 1) const SizedBox(height: 16),
                        ],
                      ],
                    );
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
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
                    color: const Color(0xFFE8F5E9),
                    child: const Center(
                      child: Icon(Icons.article, color: Color(0xFF154212), size: 48),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 160,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(
                  child: Icon(Icons.article, color: Color(0xFF154212), size: 48),
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
                          color: const Color(0xFFF0F5F1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Color(0xFF2D5A27),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '$readMinutes min read',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                    style: TextStyle(
                      color: Colors.grey.shade600,
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






