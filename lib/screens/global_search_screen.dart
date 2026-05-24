import 'dart:async';
import 'package:flutter/material.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'plant_detail_screen.dart';
import 'post_comments_screen.dart';
import 'wiki_plant_detail_screen.dart';
import '../theme/app_theme.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;
  
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
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    if (value.length < 2) {
      setState(() {
        _wikiResults = [];
        _myPlantsResults = [];
        _communityResults = [];
      });
      return;
    }
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    setState(() => _isLoading = true);
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
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
        
        if (!mounted) return;

        setState(() {
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
          
          _isLoading = false;
        });
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
            hintText: l.searchHint,
            hintStyle: const TextStyle(color: AppColors.bone300),
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
                  label: Text(l.myPlants),
                  selected: _showPlants,
                  onSelected: (val) => setState(() => _showPlants = val),
                  selectedColor: primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: primaryColor,
                  labelStyle: TextStyle(color: textColor),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l.community),
                  selected: _showCommunity,
                  onSelected: (val) => setState(() => _showCommunity = val),
                  selectedColor: primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: primaryColor,
                  labelStyle: TextStyle(color: textColor),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l.wiki),
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
                      l.searchPrompt,
                      style: const TextStyle(color: AppColors.bone500),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _isLoading
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 5,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Container(width: 40, height: 40, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, shape: BoxShape.circle)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(width: double.infinity, height: 16, color: Theme.of(context).colorScheme.surfaceContainerHighest),
                                    const SizedBox(height: 8),
                                    Container(width: 100, height: 14, color: Theme.of(context).colorScheme.surfaceContainerHighest),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search, size: 64, color: AppColors.bone300),
                                const SizedBox(height: 16),
                                Text(
                                  '${l.noResultsForPrefix} "$_query"',
                                  style: const TextStyle(color: AppColors.bone500, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (hasWiki) ...[
                                _buildSectionHeader(l.wikiPlants, primaryColor),
                                ..._wikiResults.map((doc) => _buildWikiTile(doc)),
                                const SizedBox(height: 16),
                              ],
                              if (hasPlants) ...[
                                _buildSectionHeader(l.myPlants, primaryColor),
                                ..._myPlantsResults.map((doc) => _buildMyPlantTile(doc)),
                                const SizedBox(height: 16),
                              ],
                              if (hasCommunity) ...[
                                _buildSectionHeader(l.communityPosts, primaryColor),
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
      leading: const Icon(Icons.eco_outlined, color: AppColors.forest900),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(commonName),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WikiPlantDetailScreen(plantData: data)),
        );
      },
    );
  }

  Widget _buildMyPlantTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = data['name'] ?? '';
    final species = data['species'] ?? '';
    return ListTile(
      leading: const Icon(Icons.local_florist_outlined, color: AppColors.forest900),
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
      leading: const Icon(Icons.forum_outlined, color: AppColors.forest900),
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
