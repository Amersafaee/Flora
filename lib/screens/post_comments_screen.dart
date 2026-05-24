import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class PostCommentsScreen extends StatefulWidget {
  final String postId;
  final String postTitle;

  const PostCommentsScreen({
    super.key,
    required this.postId,
    required this.postTitle,
  });

  @override
  State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isSending = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      setState(() {
        _hasText = _commentController.text.trim().isNotEmpty;
      });
    });
  }

  void _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

      await postRef.collection('comments').add({
        'authorUid': user.uid,
        'authorName': user.displayName ?? 'Anonymous',
        'authorPhotoUrl': user.photoURL ?? '',
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'likedBy': [],
      });

      await postRef.update({'commentsCount': FieldValue.increment(1)});

      final postDoc = await postRef.get();
      final postAuthorUid = postDoc.data()?['authorUid'];
      if (postAuthorUid != null && postAuthorUid != user.uid) {
        String truncatedTitle = widget.postTitle;
        if (truncatedTitle.length > 40) truncatedTitle = '${truncatedTitle.substring(0, 37)}...';
        await FirebaseFirestore.instance
            .collection('users')
            .doc(postAuthorUid)
            .collection('notifications')
            .add({
          'type': 'comment',
          'message': '${user.displayName ?? 'Anonymous'} commented on your post: $truncatedTitle',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'postId': widget.postId,
          'fromUid': user.uid,
        });
      }

      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.failedToPostComment), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _formatTimestamp(dynamic timestamp, AppLocalizations l) {
    if (timestamp == null) return l.justNow;
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final difference = DateTime.now().difference(date);
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 2) {
        return l.yesterday;
      } else {
        return DateFormat.yMMMd().format(date);
      }
    }
    return '';
  }

  void _showSaveToJournalSheet(BuildContext context, String commentText) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final lSheet = AppLocalizations.of(context);
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lSheet.saveTipToJournal, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('plants')
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(child: Text(lSheet.failedToLoadPlants));
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return Center(
                        child: Text(lSheet.addSomePlantsToSaveTips, style: const TextStyle(color: AppColors.bone500)),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final plantData = docs[index].data() as Map<String, dynamic>;
                        final plantId = docs[index].id;
                        final plantName = plantData['name'] ?? 'Unknown Plant';
                        final category = plantData['category'] ?? '';

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.forest100,
                            child: Icon(Icons.eco, color: AppColors.forest900),
                          ),
                          title: Text(plantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(category),
                          onTap: () async {
                            Navigator.pop(context);
                            String truncatedText = commentText;
                            if (truncatedText.length > 200) {
                              truncatedText = '${truncatedText.substring(0, 197)}...';
                            }
                            try {
                              await FirestoreService().addGrowthEntry(
                                plantId,
                                {
                                  'notes': 'Community tip: $truncatedText',
                                  'timestamp': FieldValue.serverTimestamp(),
                                  'source': 'community',
                                  'type': 'note',
                                },
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Saved to $plantName journal 🌿'),
                                    backgroundColor: AppColors.forest700,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(lSheet.failedToSaveToJournal),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
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
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.comments, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
        shadowColor: Colors.black12,
      ),
      body: Column(
        children: [
          // Post preview
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).cardColor,
                  child: Text(widget.postTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                );
              }
              final postData = snapshot.data!.data() as Map<String, dynamic>;
              final title = postData['title'] ?? widget.postTitle;
              final body = postData['body'] ?? '';
              final imageUrl = postData['imageUrl'] ?? '';
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(body, style: const TextStyle(color: AppColors.bone500, fontSize: 14)),
                    ],
                    if (imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(imageUrl, width: double.infinity, height: 200, fit: BoxFit.cover),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          // Comments list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(l.failedToLoadComments));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data?.docs ?? [];
                if (comments.isEmpty) {
                  return Center(
                    child: Text(l.noCommentsYet, style: const TextStyle(color: AppColors.bone500)),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final data = comments[index].data() as Map<String, dynamic>;
                    return GestureDetector(
                      onLongPress: () => _showSaveToJournalSheet(context, data['text'] ?? ''),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data['isFloraAnswer'] == true)
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.forest900,
                                child: Icon(Icons.eco, color: Colors.white, size: 16),
                              )
                            else
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: primaryColor.withValues(alpha: 0.2),
                                backgroundImage: data['authorPhotoUrl'] != null && data['authorPhotoUrl'].toString().isNotEmpty
                                    ? NetworkImage(data['authorPhotoUrl'])
                                    : null,
                                child: data['authorPhotoUrl'] == null || data['authorPhotoUrl'].toString().isEmpty
                                    ? Text(
                                        (data['authorName'] ?? '?')[0].toUpperCase(),
                                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                                      )
                                    : null,
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(data['isFloraAnswer'] == true ? 12.0 : 0),
                                decoration: BoxDecoration(
                                  color: data['isFloraAnswer'] == true ? AppColors.forest100 : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (data['isFloraAnswer'] == true) ...[
                                          const Icon(Icons.eco, color: AppColors.forest900, size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            l.floraAiExpertAnswer,
                                            style: const TextStyle(color: AppColors.forest900, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                          const Spacer(),
                                        ] else ...[
                                          Text(
                                            data['authorName'] ?? 'Anonymous',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatTimestamp(data['timestamp'], l),
                                          style: const TextStyle(color: AppColors.bone500, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data['text'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: data['isFloraAnswer'] == true ? AppColors.forest900 : null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                                            if (currentUserId == null) return;

                                            final likedBy = List<String>.from(data['likedBy'] ?? []);
                                            final isLiked = likedBy.contains(currentUserId);

                                            final commentRef = FirebaseFirestore.instance
                                                .collection('posts')
                                                .doc(widget.postId)
                                                .collection('comments')
                                                .doc(comments[index].id);

                                            if (isLiked) {
                                              await commentRef.update({'likedBy': FieldValue.arrayRemove([currentUserId])});
                                            } else {
                                              await commentRef.update({'likedBy': FieldValue.arrayUnion([currentUserId])});
                                            }
                                          },
                                          child: Icon(
                                            (List<String>.from(data['likedBy'] ?? []).contains(FirebaseAuth.instance.currentUser?.uid))
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            size: 16,
                                            color: (List<String>.from(data['likedBy'] ?? []).contains(FirebaseAuth.instance.currentUser?.uid))
                                                ? AppColors.terracotta900
                                                : AppColors.bone500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(data['likedBy'] as List?)?.length ?? 0}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.bone500),
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () {
                                            final authorName = data['authorName'] ?? 'Anonymous';
                                            _commentController.text = '@$authorName ';
                                            _commentController.selection = TextSelection.fromPosition(
                                              TextPosition(offset: _commentController.text.length),
                                            );
                                            _commentFocusNode.requestFocus();
                                          },
                                          child: Text(
                                            l.reply,
                                            style: const TextStyle(fontSize: 12, color: AppColors.bone500, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Comment input bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    decoration: InputDecoration(
                      hintText: l.addAComment,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: Icon(Icons.send, color: _hasText ? primaryColor : AppColors.bone500),
                        onPressed: _hasText ? _sendComment : null,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
