import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_screen.dart';
import 'create_post_screen.dart';
import 'post_comments_screen.dart';
import 'swap_market_screen.dart';
import 'all_plants_screen.dart';
import '../services/firestore_service.dart';
import '../utils/user_utils.dart';
import '../services/onboarding_service.dart';
import 'onboarding_overlay_screen.dart';
import '../theme/app_theme.dart';


class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';
  String _feedMode = 'mine';
  List<String> _userPlantNames = [];
  StreamSubscription? _plantsSub;
  List<String> _reportedPostIds = [];

  @override
  void initState() {
    super.initState();
    _checkUnansweredQuestions();
    _checkAndSeedChallenge();
    _loadUserPlants();
    _loadReportedPosts();
    FirestoreService().checkAndFlagReportedPosts();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await OnboardingService.shouldShow('community_screen')) {
        await OnboardingService.markShown('community_screen');
        if (mounted) _showFeatureOnboarding();
      }
    });
  }

  void _showFeatureOnboarding() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const OnboardingOverlayScreen(
          title: 'Welcome to Community',
          description: 'Connect with other plant lovers and experts.',
          tips: [
            'Share your plant progress and tips',
            'Ask for help with sick plants',
            'Join weekly growing challenges',
          ],
          featureKey: 'community_screen',
        ),
      ),
    );
  }


  void _loadUserPlants() {
    _plantsSub = FirestoreService().getPlants().listen((plants) {
      if (!mounted) return;
      setState(() {
        _userPlantNames = plants.map((p) => p.name.toLowerCase()).toList();
      });
    });
  }

  @override
  void dispose() {
    _plantsSub?.cancel();
    super.dispose();
  }

  Future<void> _checkAndSeedChallenge() async {
    try {
      final qs = await FirebaseFirestore.instance.collection('challenges').limit(1).get();
      if (qs.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('challenges').add({
          'title': 'This Week: Show Your Best Growth 🌱',
          'description': 'Share a before and after photo of your most dramatic plant transformation this week',
          'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
          'participantCount': 0,
          'isActive': true,
          'authorName': 'Digital Conservatory Team',
          'authorUid': 'system',
        });
      } else {
        // Backfill authorName if missing on existing challenge
        final doc = qs.docs.first;
        final data = doc.data();
        if (!data.containsKey('authorName')) {
          await doc.reference.update({
            'authorName': 'Digital Conservatory Team',
            'authorUid': 'system',
          });
        }
      }
    } catch (e) {
      debugPrint('Error seeding challenge: $e');
    }
  }

  Future<void> _loadReportedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('reported_posts') ?? '[]';
    try {
      final list = List<String>.from(json.decode(jsonStr) as List);
      if (mounted) setState(() => _reportedPostIds = list);
    } catch (_) {}
  }

  Future<void> _saveReportedPost(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('reported_posts') ?? '[]';
    List<String> list;
    try {
      list = List<String>.from(json.decode(jsonStr) as List);
    } catch (_) {
      list = [];
    }
    if (!list.contains(postId)) {
      list.add(postId);
      await prefs.setString('reported_posts', json.encode(list));
      if (mounted) setState(() => _reportedPostIds = list);
    }
  }

  Future<void> _checkUnansweredQuestions() async {
    try {
      await FirestoreService().checkAndAnswerUnansweredQuestions();
    } catch (e) {
      debugPrint('Error checking unanswered questions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    const Color softGreen = AppColors.forest100;

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen(initialCategory: 'General')));
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Area
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Community',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                      child: buildUserAvatar(radius: 20),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _isSearching = value.isNotEmpty;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search discussions...',
                    hintStyle: TextStyle(color: AppColors.bone300),
                    prefixIcon: Icon(Icons.search, color: AppColors.bone300),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Feed Mode Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('For My Garden'),
                      selected: _feedMode == 'mine',
                      onSelected: (selected) {
                        if (selected) setState(() => _feedMode = 'mine');
                      },
                      selectedColor: primaryColor,
                      labelStyle: TextStyle(
                        color: _feedMode == 'mine' ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        fontWeight: _feedMode == 'mine' ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('All Posts'),
                      selected: _feedMode == 'all',
                      onSelected: (selected) {
                        if (selected) setState(() => _feedMode = 'all');
                      },
                      selectedColor: primaryColor,
                      labelStyle: TextStyle(
                        color: _feedMode == 'all' ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        fontWeight: _feedMode == 'all' ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ],
                ),
              ),

              // Category Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: ['All', 'Questions', 'Tips', 'Showcase', 'General'].map((category) {
                    final isSelected = _selectedCategoryFilter == category;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedCategoryFilter = category);
                        },
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: Theme.of(context).cardColor,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              // Challenge Banner
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('challenges').where('isActive', isEqualTo: true).limit(1).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
                  final challengeData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  final title = challengeData['title'] ?? '';
                  final description = challengeData['description'] ?? '';
                  final endDate = (challengeData['endDate'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final daysLeft = endDate.difference(DateTime.now()).inDays;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.forest900, AppColors.forest700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              Text(
                                '$daysLeft days left',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => CreatePostScreen(initialCategory: 'Showcase', initialTitle: title)));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.forest900,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Join Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Swap Market Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SwapMarketScreen()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: softGreen, width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: softGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.swap_horiz, color: primaryColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plant Swap Market',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Trade cuttings and seeds locally',
                                style: TextStyle(
                                  color: AppColors.bone500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: AppColors.bone300, size: 16),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              
              // Feed
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Failed to load posts', style: TextStyle(color: AppColors.bone500)));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()));
                    }

                    final allDocs = snapshot.data?.docs ?? [];
                    // Filter reported posts (hidden locally)
                    final filteredDocs = allDocs.where((doc) {
                      if (_reportedPostIds.contains(doc.id)) return false;
                      final data = doc.data() as Map<String, dynamic>;
                      final title = (data['title'] ?? '').toString().toLowerCase();
                      final body = (data['body'] ?? '').toString().toLowerCase();
                      final query = _searchQuery.toLowerCase();
                      final matchesSearch = title.contains(query) || body.contains(query);
                      final matchesCategory = _selectedCategoryFilter == 'All' ||
                          data['category'] == _selectedCategoryFilter ||
                          // Normalise Question/Questions mismatch
                          (_selectedCategoryFilter == 'Questions' && data['category'] == 'Question') ||
                          (_selectedCategoryFilter == 'Question' && data['category'] == 'Questions');
                      
                      bool matchesFeedMode = true;
                      if (_feedMode == 'mine') {
                        if (data['category'] == 'Question' || data['category'] == 'Questions') {
                          matchesFeedMode = true;
                        } else {
                          matchesFeedMode = _userPlantNames.any((pName) => pName.isNotEmpty && (title.contains(pName) || body.contains(pName)));
                        }
                      }

                      return matchesSearch && matchesCategory && matchesFeedMode;
                    }).toList();

                    if (allDocs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people, size: 60, color: AppColors.forest900),
                            const SizedBox(height: 20),
                            Text(
                              'Be the first to share',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'The community is waiting for your plant story. Share a tip, ask a question, or show off your collection.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.bone500, fontSize: 14),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen(initialCategory: 'General')));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.forest900,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Start a Discussion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    }

                    if (filteredDocs.isEmpty) {
                      if (_feedMode == 'mine' && !_isSearching) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.eco_outlined, size: 60, color: AppColors.forest900),
                              const SizedBox(height: 20),
                              const Text('No community posts about your plants yet. Be the first to share! 🌿', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.bone500)),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen(initialCategory: 'General')));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.forest900,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Create Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      }
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text('No posts found for your search.', style: TextStyle(color: AppColors.bone500)),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (var doc in filteredDocs) ...[
                          _buildPostCard(
                            context: context,
                            postDoc: doc,
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
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final difference = DateTime.now().difference(date);
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 2) {
        return 'Yesterday';
      } else {
        return DateFormat.yMMMd().format(date);
      }
    }
    return '';
  }

  Widget _buildPostCard({
    required BuildContext context,
    required DocumentSnapshot postDoc,
    required Color primaryColor,
    required Color softGreen,
  }) {
    final data = postDoc.data() as Map<String, dynamic>;
    final authorName = data['authorName'] ?? 'Anonymous';
    final timeAgo = _formatTimestamp(data['timestamp']);
    final title = data['title'] ?? '';
    final body = data['body'] ?? '';
    final imageUrl = data['imageUrl'] ?? '';
    final category = data['category'] ?? '';
    final likesCount = data['likesCount'] ?? 0;
    final commentsCount = data['commentsCount'] ?? 0;
    final authorUid = data['authorUid'] ?? '';
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    bool hasMatch = false;
    final textToCheck = '${title.toLowerCase()} ${body.toLowerCase()}';
    for (final plantName in _userPlantNames) {
      if (textToCheck.contains(plantName)) {
        hasMatch = true;
        break;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostCommentsScreen(
              postId: postDoc.id,
              postTitle: title,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // User info row
          Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor.withValues(alpha: 0.2),
                radius: 18,
                backgroundImage: data['authorPhotoUrl'] != null && data['authorPhotoUrl'].toString().isNotEmpty
                    ? NetworkImage(data['authorPhotoUrl'])
                    : null,
                child: data['authorPhotoUrl'] == null || data['authorPhotoUrl'].toString().isEmpty
                    ? Text(
                        authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: AppColors.bone500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_horiz, color: AppColors.bone500),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.flag_outlined),
                            title: const Text('Report Post'),
                            onTap: () {
                              Navigator.pop(context);
                              // FIX 9: Prevent self-reporting
                              if (currentUserId != null && currentUserId == authorUid) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('You cannot report your own post'),
                                    backgroundColor: AppColors.bone500,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                builder: (context) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('Report this post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      ),
                                      ...['Spam', 'Misinformation', 'Inappropriate content', 'Off topic', 'Other'].map((reason) => ListTile(
                                        title: Text(reason),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          await FirebaseFirestore.instance.collection('reports').add({
                                            'postId': postDoc.id,
                                            'reportedByUid': currentUserId,
                                            'reason': reason,
                                            'timestamp': FieldValue.serverTimestamp(),
                                            'status': 'pending',
                                          });
                                          // Hide post locally from this reporter
                                          await _saveReportedPost(postDoc.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Post hidden. Thank you for keeping the community safe.'),
                                                backgroundColor: Colors.green,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                      )),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          if (currentUserId == authorUid)
                            ListTile(
                              leading: const Icon(Icons.delete_outline, color: AppColors.terracotta900),
                              title: const Text('Delete Post', style: TextStyle(color: AppColors.terracotta900)),
                              onTap: () {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Post'),
                                    content: const Text('Are you sure you want to delete this post?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await FirebaseFirestore.instance.collection('posts').doc(postDoc.id).delete();
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted'), backgroundColor: Colors.green));
                                          }
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Post Text Content
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (hasMatch) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AllPlantsScreen()));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'You grow this',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: AppColors.bone500,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          
          if (imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: AppColors.forest100,
                    child: Center(
                      child: Icon(Icons.eco, color: Color(0x6614301E), size: 48),
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: AppColors.forest100,
                      child: Center(
                        child: Icon(Icons.eco, color: Color(0x6614301E), size: 48),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          if (category.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: softGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#$category',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            
          const SizedBox(height: 16),
          Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          
          // Interaction Row
          Row(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: currentUserId != null 
                    ? FirebaseFirestore.instance.collection('posts').doc(postDoc.id).collection('likes').doc(currentUserId).snapshots()
                    : const Stream.empty(),
                builder: (context, snapshot) {
                  final isLiked = snapshot.hasData && snapshot.data!.exists;
                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? AppColors.terracotta900 : AppColors.bone500,
                          size: 20,
                        ),
                        onPressed: () async {
                          if (currentUserId == null) return;
                          final postRef = FirebaseFirestore.instance.collection('posts').doc(postDoc.id);
                          final likeRef = postRef.collection('likes').doc(currentUserId);
                          if (isLiked) {
                            await likeRef.delete();
                            await postRef.update({'likesCount': FieldValue.increment(-1)});
                          } else {
                            await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
                            await postRef.update({'likesCount': FieldValue.increment(1)});
                          }
                        },
                      ),
                      Text('$likesCount', style: TextStyle(color: AppColors.bone500, fontWeight: FontWeight.bold))
                    ],
                  );
                },
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chat_bubble_outline, color: AppColors.bone500, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostCommentsScreen(
                            postId: postDoc.id,
                            postTitle: title,
                          ),
                        ),
                      );
                    },
                  ),
                  Text('$commentsCount', style: TextStyle(color: AppColors.bone500, fontWeight: FontWeight.bold))
                ],
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.share_outlined, color: AppColors.bone500, size: 20),
                onPressed: () {
                  // ignore: deprecated_member_use
                  Share.share("Check out this plant discussion on Digital Conservatory: $title");
                },
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}









