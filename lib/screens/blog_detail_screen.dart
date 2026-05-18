import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'flora_screen.dart';
import '../theme/app_theme.dart';

class BlogDetailScreen extends StatelessWidget {
  final Map<String, dynamic> blogData;

  const BlogDetailScreen({super.key, required this.blogData});

  @override
  Widget build(BuildContext context) {
    // FIX 5 — safe typed field access for all fields
    final title = (blogData['title'] as String? ?? 'Untitled');
    final category = (blogData['category'] as String? ?? 'General');
    final readMinutes = (blogData['readMinutes'] as num?)?.toInt() ?? 5;
    final content = (blogData['content'] as String? ?? '');
    final localImagePath = (blogData['localImagePath'] as String? ?? '');
    final tags = (blogData['tags'] as List<dynamic>? ?? []).cast<String>();

    // Split content into paragraphs (double-newline first, then sentence groups)
    List<String> paragraphs = _buildParagraphs(content);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Hero image with overlaid back button
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.forest900,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.45),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: localImagePath.isNotEmpty
                  ? Image.asset(
                      localImagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.forest100,
                        child: const Center(
                          child: Icon(Icons.article, color: AppColors.forest900, size: 64),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.forest100,
                      child: const Center(
                        child: Icon(Icons.article, color: AppColors.forest900, size: 64),
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip + read-time badge row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.forest100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: AppColors.forest700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 14, color: AppColors.bone500),
                      const SizedBox(width: 4),
                      Text(
                        '$readMinutes min read',
                        style: const TextStyle(color: AppColors.bone500, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title — Noto Serif bold 26px
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Content paragraphs
                  ...paragraphs.asMap().entries.map((entry) {
                    final i = entry.key;
                    final para = entry.value;
                    final isFirst = i == 0;
                    return Padding(
                      padding: EdgeInsets.only(bottom: i < paragraphs.length - 1 ? 16 : 0),
                      child: isFirst
                          ? Container(
                              padding: const EdgeInsets.only(left: 14),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: AppColors.forest600, width: 3),
                                ),
                              ),
                              child: Text(
                                para,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.7,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            )
                          : Text(
                              para,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.7,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                    );
                  }),

                  // Tags row
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) => _buildTagChip(tag)).toList(),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Ask Flora CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _openFloraWithTopic(context, title),
                      icon: Icon(Icons.eco, color: Colors.white),
                      label: const Text(
                        'Ask Flora about this topic 🌿',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forest900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Splits content into readable paragraphs.
  /// Tries double-newline first; falls back to grouping every 3 sentences.
  List<String> _buildParagraphs(String content) {
    if (content.isEmpty) return [];

    // Try double-newline split
    final byNewline = content.split('\n\n').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (byNewline.length > 1) return byNewline;

    // Fall back to sentence grouping (3 per paragraph)
    final rawSentences = content.split('. ');
    const sentencesPerParagraph = 3;
    final paragraphs = <String>[];
    for (int i = 0; i < rawSentences.length; i += sentencesPerParagraph) {
      final chunk = rawSentences.sublist(
        i,
        (i + sentencesPerParagraph) > rawSentences.length
            ? rawSentences.length
            : i + sentencesPerParagraph,
      );
      final para = chunk.where((s) => s.trim().isNotEmpty).join('. ').trim();
      if (para.isNotEmpty) {
        paragraphs.add(
          para.endsWith('.') || para.endsWith('!') || para.endsWith('?')
              ? para
              : '$para.',
        );
      }
    }
    return paragraphs;
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  Future<void> _openFloraWithTopic(BuildContext context, String blogTitle) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final db = FirebaseFirestore.instance;
    final chatsRef = db.collection('users').doc(uid).collection('flora_chats');

    final docRef = await chatsRef.add({
      'title': 'About: $blogTitle',
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessage': 'Tell me more about "$blogTitle"',
    });

    final conversationId = docRef.id;
    await chatsRef.doc(conversationId).collection('messages').add({
      'role': 'user',
      'text': 'Tell me more about "$blogTitle". I just read an article about it.',
      'imageUrl': '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FloraScreen(conversationId: conversationId),
      ),
    );
  }
}
