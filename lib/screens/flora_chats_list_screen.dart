import 'package:flutter/material.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'flora_screen.dart';
import '../theme/app_theme.dart';

class FloraChatsListScreen extends StatelessWidget {
  const FloraChatsListScreen({super.key});

  String _uid() => FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> _chatsRef() =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid())
          .collection('flora_chats');

  Future<void> _createNewConversation(BuildContext context) async {
    final uid = _uid();
    if (uid.isEmpty) return;

    final existingChats = await _chatsRef().limit(1).get();
    final isFirstConversation = existingChats.docs.isEmpty;

    String initialLastMessage = '';
    if (isFirstConversation) {
      initialLastMessage = "Hi there! 🌿 I'm Flora — your personal plant care companion...";
    }

    final docRef = await _chatsRef().add({
      'title': 'New Conversation',
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': initialLastMessage,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    if (isFirstConversation) {
      await docRef.collection('messages').add({
        'role': 'model',
        'text': "Hi there! 🌿 I'm Flora — your personal plant care companion inside Digital Conservatory. I've been waiting to meet you! I can help you identify plants, diagnose health issues, build care schedules, and answer any plant question you can think of. I know your entire collection and I pay close attention to every plant's journey. So — do you have any plants already, or are we starting fresh today? 🪴",
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FloraScreen(conversationId: docRef.id),
        ),
      );
    }
  }

  Future<void> _deleteConversation(
      BuildContext context, String docId) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.deleteConversation),
        content: Text(l.deleteConversationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete,
                style: const TextStyle(color: AppColors.terracotta900)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final messagesSnap =
          await _chatsRef().doc(docId).collection('messages').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final msg in messagesSnap.docs) {
        batch.delete(msg.reference);
      }
      batch.delete(_chatsRef().doc(docId));
      await batch.commit();
    }
  }

  String _formatTimeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final now = DateTime.now();
    final dt = ts.toDate();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final primaryColor = Theme.of(context).primaryColor;
    final uid = _uid();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCanvas
          : AppColors.bone25,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.eco, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.flora,
                        style: TextStyle(
                          fontFamily: 'serif',
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        l.aiPlantConsultant,
                        style: const TextStyle(
                          color: AppColors.bone500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Colors.black12),
            Expanded(
              child: uid.isEmpty
                  ? Center(child: Text(l.pleaseLogInToUseFlora))
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _chatsRef()
                          .orderBy('lastMessageAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return _buildEmptyState(context, primaryColor);
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data();
                            final title =
                                data['title'] as String? ?? 'Conversation';
                            final lastMessage =
                                data['lastMessage'] as String? ?? '';
                            final lastMessageAt =
                                data['lastMessageAt'] as Timestamp?;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FloraScreen(
                                          conversationId: doc.id),
                                    ),
                                  );
                                },
                                onLongPress: () =>
                                    _deleteConversation(context, doc.id),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkSurface
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.eco,
                                            color: Colors.white, size: 20),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                            if (lastMessage.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                lastMessage,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.bone500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatTimeAgo(lastMessageAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.bone300,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewConversation(context),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color primaryColor) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.eco, color: primaryColor, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              l.startFirstConversation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.bone500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.tapPlusToBegin,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.bone500),
            ),
          ],
        ),
      ),
    );
  }
}
