import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'plant_detail_screen.dart';
import 'post_comments_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  
  List<DocumentSnapshot> _wikiResults = [];
  List<DocumentSnapshot> _myPlantsResults = [];
  List<DocumentSnapshot> _communityResults = [];
  bool _isLoading = false;
  bool _showPlants = true;
  bool _showCommunity = true;
  bool _showWiki = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) async {
    setState(() => _query = value);
    if (value.length < 2) {
      setState(() {
        _wikiResults = [];
        _myPlantsResults = [];
        _communityResults = [];
      });
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final queryLower = value.toLowerCase();
      final user = FirebaseAuth.instance.currentUser;
      
      final speciesTask = FirebaseFirestore.instance.collection('species').get();
      final postsTask = FirebaseFirestore.instance.collection('posts').get();
      Future<QuerySnapshot>? plantsTask;
      if (user != null) {
        plantsTask = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('plants').get();
      }
      
      final speciesSnapshot = await speciesTask;
      final postsSnapshot = await postsTask;
      final plantsSnapshot = plantsTask != null ? await plantsTask : null;
      
      _wikiResults = speciesSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final name = (data['name'] ?? '').toString().toLowerCase();
        final commonName = (data['commonName'] ?? '').toString().toLowerCase();
        return name.contains(queryLower) || commonName.contains(queryLower);
      }).toList();
      
      _myPlantsResults = plantsSnapshot?.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final name = (data['name'] ?? '').toString().toLowerCase();
        return name.contains(queryLower);
      }).toList() ?? [];
      
      _communityResults = postsSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final title = (data['title'] ?? '').toString().toLowerCase();
        final body = (data['body'] ?? '').toString().toLowerCase();
        return title.contains(queryLower) || body.contains(queryLower);
      }).toList();
      
    } catch (e) {
      // ignore
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).primaryColor;
    
    final bool hasWiki = _showWiki && _wikiResults.isNotEmpty;
    final bool hasPlants = _showPlants && _myPlantsResults.isNotEmpty;
    final bool hasCommunity = _showCommunity && _communityResults.isNotEmpty;
    final bool isEmpty = !hasWiki && !hasPlants && !hasCommunity;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: InputBorder.none,
          ),
          style: TextStyle(color: textColor, fontSize: 18),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Plants'),
                  selected: _showPlants,
                  onSelected: (val) => setState(() => _showPlants = val),
                  selectedColor: primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: primaryColor,
                  labelStyle: TextStyle(color: textColor),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Community'),
                  selected: _showCommunity,
                  onSelected: (val) => setState(() => _showCommunity = val),
                  selectedColor: primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: primaryColor,
                  labelStyle: TextStyle(color: textColor),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Wiki'),
                  selected: _showWiki,
                  onSelected: (val) => setState(() => _showWiki = val),
                  selectedColor: primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: primaryColor,
                  labelStyle: TextStyle(color: textColor),
                ),
              ],
            ),
          ),
          Expanded(
            child: _query.length < 2
                ? Center(
                    child: Text(
                      'Start typing to search across your plants and the wiki.',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : isEmpty
                        ? Center(
                            child: Text(
                              'No results found',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (hasWiki) ...[
                                _buildSectionHeader('Wiki Plants', primaryColor),
                                ..._wikiResults.map((doc) => _buildWikiTile(doc)),
                                const SizedBox(height: 16),
                              ],
                              if (hasPlants) ...[
                                _buildSectionHeader('My Plants', primaryColor),
                                ..._myPlantsResults.map((doc) => _buildMyPlantTile(doc)),
                                const SizedBox(height: 16),
                              ],
                              if (hasCommunity) ...[
                                _buildSectionHeader('Community Posts', primaryColor),
                                ..._communityResults.map((doc) => _buildPostTile(doc)),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildWikiTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = data['name'] ?? '';
    final commonName = data['commonName'] ?? '';
    return ListTile(
      leading: const Icon(Icons.eco_outlined, color: Color(0xFF154212)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(commonName),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coming soon', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF2D5A27), behavior: SnackBarBehavior.floating),
        );
      },
    );
  }

  Widget _buildMyPlantTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = data['name'] ?? '';
    final species = data['species'] ?? '';
    return ListTile(
      leading: const Icon(Icons.local_florist_outlined, color: Color(0xFF154212)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(species),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: doc.id)),
        );
      },
    );
  }

  Widget _buildPostTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final title = data['title'] ?? '';
    final category = data['category'] ?? '';
    return ListTile(
      leading: const Icon(Icons.forum_outlined, color: Color(0xFF154212)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(category),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostCommentsScreen(postId: doc.id, postTitle: title)),
        );
      },
    );
  }
}

