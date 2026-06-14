import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'verdoro_screen.dart';
import 'care_plan_screen.dart';
import 'identify_screen.dart';
import '../theme/app_theme.dart';

class VerdoroChatsListScreen extends StatelessWidget {
  const VerdoroChatsListScreen({super.key});

  String _uid() => FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> _chatsRef() =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid())
          .collection('verdoro_chats');

  Future<void> _createNewConversation(BuildContext context) async {
    final uid = _uid();
    if (uid.isEmpty) return;

    final existingChats = await _chatsRef().limit(1).get();
    final isFirstConversation = existingChats.docs.isEmpty;

    String initialLastMessage = '';
    if (isFirstConversation) {
      initialLastMessage = "Hi there! ?? I'm Verdoro � your personal plant care companion...";
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
        'text': "Hi there! ?? I'm Verdoro � your personal plant care companion inside Verdoro. I've been waiting to meet you! I can help you identify plants, diagnose health issues, build care schedules, and answer any plant question you can think of. I know your entire collection and I pay close attention to every plant's journey. So � do you have any plants already, or are we starting fresh today? ??",
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerdoroScreen(conversationId: docRef.id),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = _uid();

    final chatsStream = uid.isEmpty
        ? const Stream<QuerySnapshot<Map<String, dynamic>>>.empty()
        : _chatsRef().orderBy('lastMessageAt', descending: true).snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: chatsStream,
      builder: (context, snapshot) {
        final chats = snapshot.data?.docs ?? [];

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.bone50,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.forest700,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Verdoro',
                      style: GoogleFonts.outfit(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      'Plant care companion',
                      style: GoogleFonts.outfit(
                        color: AppColors.bone500,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(CupertinoIcons.camera, size: 22, color: AppColors.forest700),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IdentifyScreen()),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Pinned Smart Care Plan Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CarePlanScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A2535) : const Color(0xFFEDF3FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Smart Care Plan',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'AI weekly schedule for all your plants',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.bone400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            CupertinoIcons.calendar_badge_plus,
                            color: AppColors.slateBlue500,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: uid.isEmpty
                      ? Center(
                          child: Text(
                            l.pleaseLogInToUseVerdoro,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.bone500,
                            ),
                          ),
                        )
                      : snapshot.connectionState == ConnectionState.waiting
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.forest700,
                                strokeWidth: 2,
                              ),
                            )
                          : chats.isEmpty
                              ? _buildEmptyState(context)
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  itemCount: chats.length,
                                  itemBuilder: (context, index) {
                                    final doc = chats[index];
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
                                              builder: (_) => VerdoroScreen(
                                                  conversationId: doc.id),
                                            ),
                                          );
                                        },
                                        onLongPress: () =>
                                            _deleteConversation(context, doc.id),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.darkCardSurface : AppColors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: isDark
                                                ? Border.all(color: AppColors.darkCardBorder, width: 1)
                                                : null,
                                            boxShadow: isDark
                                                ? null
                                                : const [
                                                    BoxShadow(
                                                      color: Color(0x0A224A1E),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.bone100,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.eco,
                                                  color: AppColors.forest700,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      title,
                                                      style: GoogleFonts.outfit(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 15,
                                                        color: isDark
                                                            ? AppColors.darkTextPrimary
                                                            : AppColors.forest900,
                                                      ),
                                                    ),
                                                    if (lastMessage.isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        lastMessage,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w400,
                                                          color: AppColors.bone400,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatTimeAgo(lastMessageAt),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppColors.bone400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
          floatingActionButton: chats.isEmpty
              ? null
              : FloatingActionButton(
                  onPressed: () => _createNewConversation(context),
                  backgroundColor: AppColors.forest700,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.bubble_left_bubble_right,
              size: 56,
              color: AppColors.forest200,
            ),
            const SizedBox(height: 16),
            Text(
              "Chat with Verdoro",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.forest800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Ask anything about your plants",
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.bone400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => _createNewConversation(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text(
                  "Start a conversation",
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
