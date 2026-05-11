import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

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

      await postRef.update({
        'commentsCount': FieldValue.increment(1),
      });

      final postDoc = await postRef.get();
      final postAuthorUid = postDoc.data()?['authorUid'];
      if (postAuthorUid != null && postAuthorUid != user.uid) {
        String truncatedTitle = widget.postTitle;
        if (truncatedTitle.length > 40) truncatedTitle = '${truncatedTitle.substring(0, 37)}...';
        await FirebaseFirestore.instance.collection('users').doc(postAuthorUid).collection('notifications').add({
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post comment'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
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

  void _showSaveToJournalSheet(BuildContext context, String commentText) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
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
                'Save this tip to a plant journal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
                      return const Center(child: Text('Failed to load plants'));
                    }
                    
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('Add some plants first to save tips', style: TextStyle(color: Colors.grey)),
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
                            backgroundColor: Color(0xFFE8F3EA),
                            child: Icon(Icons.eco, color: Color(0xFF154212)),
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
                                  SnackBar(content: Text('Saved to $plantName journal 🌿'), backgroundColor: const Color(0xFF2D5A27)),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to save to journal'), backgroundColor: Colors.red),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
        shadowColor: Colors.black12,
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).cardColor,
                  child: Text(
                    widget.postTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
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
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        body,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                    if (imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ]
                  ],
                ),
              );
            },
          ),
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
                  return const Center(child: Text('Failed to load comments'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data?.docs ?? [];
                if (comments.isEmpty) {
                  return const Center(
                    child: Text('No comments yet. Be the first to reply!', style: TextStyle(color: Colors.grey)),
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
                              backgroundColor: Color(0xFF154212),
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
                                color: data['isFloraAnswer'] == true ? const Color(0xFFE8F5E9) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (data['isFloraAnswer'] == true) ...[
                                        const Icon(Icons.eco, color: Color(0xFF154212), size: 12),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'FLORA AI EXPERT ANSWER',
                                          style: TextStyle(color: Color(0xFF154212), fontWeight: FontWeight.bold, fontSize: 11),
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
                                        _formatTimestamp(data['timestamp']),
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['text'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: data['isFloraAnswer'] == true ? const Color(0xFF154212) : null,
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
                                            await commentRef.update({
                                              'likedBy': FieldValue.arrayRemove([currentUserId])
                                            });
                                          } else {
                                            await commentRef.update({
                                              'likedBy': FieldValue.arrayUnion([currentUserId])
                                            });
                                          }
                                        },
                                        child: Icon(
                                          (List<String>.from(data['likedBy'] ?? []).contains(FirebaseAuth.instance.currentUser?.uid)) 
                                            ? Icons.favorite 
                                            : Icons.favorite_border,
                                          size: 16,
                                          color: (List<String>.from(data['likedBy'] ?? []).contains(FirebaseAuth.instance.currentUser?.uid)) 
                                            ? const Color(0xFF8D3220) 
                                            : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(data['likedBy'] as List?)?.length ?? 0}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF2C2C2C) 
                          : Colors.grey.shade100,
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
                        icon: Icon(Icons.send, color: _hasText ? primaryColor : Colors.grey),
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

