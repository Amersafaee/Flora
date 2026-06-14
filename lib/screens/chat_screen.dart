import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get currentUserId => _auth.currentUser?.uid ?? 'unknown_user';

  String get conversationId {
    List<String> ids = [currentUserId, widget.otherUserId];
    ids.sort();
    return ids.join('_');
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    final message = {
      'senderId': currentUserId,
      'receiverId': widget.otherUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message);

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back, color: AppColors.forest700),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.bone500,
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              widget.otherUserName,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('conversations')
                    .doc(conversationId)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(l.couldNotLoadMessages, style: const TextStyle(color: AppColors.bone500)),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(l.sayHelloStartConversation, style: const TextStyle(color: AppColors.bone500)),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == currentUserId;
                      final text = data['text'] as String? ?? '';
                      final timestamp = data['timestamp'] as Timestamp?;
                      final timeString = timestamp != null
                          ? DateFormat('h:mm a').format(timestamp.toDate())
                          : l.sending;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isMe ? primaryColor : Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20).copyWith(
                                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                                  bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(20),
                                ),
                              ),
                              child: Text(text, style: TextStyle(color: isMe ? Colors.white : textColor, fontSize: 15, height: 1.3)),
                            ),
                            const SizedBox(height: 4),
                            Text(timeString, style: const TextStyle(color: AppColors.bone500, fontSize: 10)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Input Area
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 12),
              color: backgroundColor,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                      ),
                      child: TextField(
                        controller: _textController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: l.typeMessageHint,
                          hintStyle: const TextStyle(color: AppColors.bone300, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
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
