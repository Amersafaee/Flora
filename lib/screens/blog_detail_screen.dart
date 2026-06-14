import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'verdoro_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/shared/primary_button.dart';

class BlogDetailScreen extends StatelessWidget {
  final Map<String, dynamic> blogData;

  const BlogDetailScreen({super.key, required this.blogData});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = (blogData['title'] as String? ?? 'Untitled');
    final category = (blogData['category'] as String? ?? 'General');
    final readMinutes = (blogData['readMinutes'] as num?)?.toInt() ?? 5;
    final content = (blogData['content'] as String? ?? '');
    final imageUrl = (blogData['imageUrl'] as String? ?? '').trim();
    final tags = (blogData['tags'] as List<dynamic>? ?? []).cast<String>();
    final summary = (blogData['summary'] as String? ?? '');

    // Split content into paragraphs (double-newline first, then sentence groups)
    List<String> paragraphs = _buildParagraphs(content);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paragraphStyle = GoogleFonts.plusJakartaSans(
      fontSize: 16,
      height: 1.6,
      color: isDark ? AppColors.darkTextPrimary : AppColors.bone900,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.bone50,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero image with overlaid back button
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        CupertinoIcons.chevron_back,
                        size: 20,
                        color: AppColors.forest700,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                automaticallyImplyLeading: false, // Hide default back button
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.bone50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                CupertinoIcons.leaf_arrow_circlepath,
                                size: 32,
                                color: AppColors.forest700.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.bone50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.leaf_arrow_circlepath,
                                  size: 32,
                                  color: AppColors.forest700.withValues(alpha: 0.2),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.bone50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              CupertinoIcons.leaf_arrow_circlepath,
                              size: 32,
                              color: AppColors.forest700.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  color: isDark ? AppColors.darkBackground : AppColors.bone50,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category chip + read-time badge row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(color: AppColors.bone100, borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                category,
                                style: const TextStyle(color: AppColors.forest700, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time, size: 14, color: AppColors.bone500),
                            const SizedBox(width: 4),
                            Text(
                              '$readMinutes ${l.minRead}',
                              style: const TextStyle(color: AppColors.bone500, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title � Noto Serif bold 26px
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Content paragraphs
                        ...paragraphs.asMap().entries.map((entry) {
                          final i = entry.key;
                          final para = entry.value;
                          final isFirst = i == 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: isFirst
                                ? Container(
                                    padding: const EdgeInsets.only(left: 14),
                                    decoration: const BoxDecoration(
                                      border: Border(left: BorderSide(color: AppColors.forest600, width: 3)),
                                    ),
                                    child: Text(
                                      para,
                                      style: paragraphStyle,
                                    ),
                                  )
                                : Text(
                                    para,
                                    style: paragraphStyle,
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

                        // Ask Verdoro CTA button
                        PrimaryButton(
                          label: l.askVerdoroAboutTopic,
                          onPressed: () => _openVerdoroWithTopic(context, title, summary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Splits content into readable paragraphs.
  /// Tries double-newline first; falls back to grouping every 3 sentences.
  List<String> _buildParagraphs(String content) {
    if (content.isEmpty) return [];

    final byNewline = content.split('\n\n').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (byNewline.length > 1) return byNewline;

    final rawSentences = content.split('. ');
    const sentencesPerParagraph = 3;
    final paragraphs = <String>[];
    for (int i = 0; i < rawSentences.length; i += sentencesPerParagraph) {
      final chunk = rawSentences.sublist(
        i,
        (i + sentencesPerParagraph) > rawSentences.length ? rawSentences.length : i + sentencesPerParagraph,
      );
      final para = chunk.where((s) => s.trim().isNotEmpty).join('. ').trim();
      if (para.isNotEmpty) {
        paragraphs.add(
          para.endsWith('.') || para.endsWith('!') || para.endsWith('?') ? para : '$para.',
        );
      }
    }
    return paragraphs;
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: AppColors.bone100, borderRadius: BorderRadius.circular(20)),
      child: Text(tag, style: const TextStyle(color: AppColors.forest700, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _openVerdoroWithTopic(BuildContext context, String blogTitle, String blogSummary) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final db = FirebaseFirestore.instance;
    final chatsRef = db.collection('users').doc(uid).collection('verdoro_chats');

    final initialText = blogSummary.isNotEmpty
        ? 'I was just reading about "$blogTitle". $blogSummary Can you tell me more about this?'
        : 'I was just reading about "$blogTitle". Can you tell me more about this?';

    final docRef = await chatsRef.add({
      'title': 'About: $blogTitle',
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessage': initialText,
    });

    final conversationId = docRef.id;
    await chatsRef.doc(conversationId).collection('messages').add({
      'role': 'user',
      'text': initialText,
      'imageUrl': '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VerdoroScreen(conversationId: conversationId)),
    );
  }
}
