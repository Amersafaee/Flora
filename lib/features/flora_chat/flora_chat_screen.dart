import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../theme/tokens.dart';

class FloraChatScreen extends StatefulWidget {
  final String? initialMessage;
  const FloraChatScreen({super.key, this.initialMessage});

  @override
  State<FloraChatScreen> createState() => _FloraChatScreenState();
}

class _FloraChatScreenState extends State<FloraChatScreen> with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  
  String _currentChatId = 'default';
  bool _isTyping = false;
  String _streamingMessage = '';
  List<String> _suggestions = [];

  // Bouncing dots animation
  late AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();
    _dotsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _ctrl.text = widget.initialMessage!;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0.0, // Because ListView is reversed
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startNewChat() {
    setState(() {
      _currentChatId = DateTime.now().millisecondsSinceEpoch.toString();
      _streamingMessage = '';
      _suggestions = [];
    });
  }

  Future<void> _send([String? textOverride]) async {
    final text = textOverride ?? _ctrl.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    _ctrl.clear();
    setState(() {
      _isTyping = true;
      _streamingMessage = '';
      _suggestions = [];
    });

    // 1. Write user message and update thread metadata
    final chatDoc = FirebaseFirestore.instance.collection('users').doc(uid).collection('chats').doc(_currentChatId);
    
    await chatDoc.set({
      'updatedAt': FieldValue.serverTimestamp(),
      'title': text,
    }, SetOptions(merge: true));

    await chatDoc.collection('messages').add({
      'text': text,
      'isUser': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _scrollToBottom();

    // 2. Fetch prior history for context (excluding the message we just added,
    //    since server timestamps may be null causing ordering issues)
    final snap = await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('chats').doc(_currentChatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(41) // fetch 41, we'll skip the last (just-added) user message if needed
        .get();

    // Build alternating role payload
    final List<Map<String, dynamic>> messagesPayload = [];
    String? currentRole;
    String currentContent = '';

    // Process docs oldest-first, but skip any doc whose text == current user text
    // (it may have been saved with a null timestamp and appear at wrong position)
    final orderedDocs = snap.docs.reversed.toList();
    for (var d in orderedDocs) {
      final data = d.data();
      final msgText = data['text'] ?? '';
      final role = data['isUser'] == true ? 'user' : 'model';

      if (currentRole == null) {
        if (role == 'model') {
          messagesPayload.add({'role': 'user', 'content': 'Hello'});
        }
        currentRole = role;
        currentContent = msgText;
      } else if (currentRole == role) {
        currentContent += '\n$msgText';
      } else {
        messagesPayload.add({'role': currentRole, 'content': currentContent});
        currentRole = role;
        currentContent = msgText;
      }
    }
    if (currentRole != null) {
      messagesPayload.add({'role': currentRole, 'content': currentContent});
    }

    // Ensure the last message is always the current user text
    if (messagesPayload.isEmpty || messagesPayload.last['role'] != 'user') {
      messagesPayload.add({'role': 'user', 'content': text});
    } else if (messagesPayload.last['content'] != text) {
      // The last user message in history isn't the current one — add it explicitly
      messagesPayload.add({'role': 'user', 'content': text});
    }

    debugPrint('Sending ${messagesPayload.length} messages to Gemini');
    
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system('You are Flora, a warm, knowledgeable, and conversational AI plant care expert. You have a long memory of this conversation. Keep your answers brief, practical, and highly personalized based on our chat history.'),
    );

    final List<Content> contents = messagesPayload.map((m) {
      final role = m['role'] as String;
      final msgText = m['content'] as String;
      return role == 'user' ? Content.text(msgText) : Content.model([TextPart(msgText)]);
    }).toList();

    try {
      debugPrint('[Flora] Calling Gemini. Messages: ${contents.length}, last role: ${contents.last.role}');
      
      final responseStream = model.generateContentStream(contents);
      
      await for (final response in responseStream) {
        if (!mounted) return;
        final chunkText = response.text ?? '';
        if (chunkText.isNotEmpty) {
          setState(() {
            _streamingMessage += chunkText;
            _isTyping = false;
          });
          _scrollToBottom();
        }
      }

      debugPrint('[Flora] Stream done. Got: "$_streamingMessage"');
      if (!mounted) return;
      await _saveBotMessage(_streamingMessage);
      
      // Generate suggestions after response completes
      try {
        final suggestionModel = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: apiKey,
          systemInstruction: Content.system("Generate exactly 3 short suggestion phrases for the user to reply with in the context of the conversation. Return ONLY a JSON array of strings, nothing else."),
        );
        final suggResp = await suggestionModel.generateContent(contents);
        final rawText = suggResp.text ?? "[]";
        final cleanJson = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
        final parsed = jsonDecode(cleanJson);
        if (parsed is List && parsed.isNotEmpty && mounted) {
          setState(() {
            _suggestions = List<String>.from(parsed.take(3));
          });
        }
      } catch (e) {
        debugPrint('[Flora] Suggestions error: $e');
      }

    } catch (e) {
      debugPrint('[Flora] Gemini error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Always reset typing state regardless of success or failure
      if (mounted) setState(() => _isTyping = false);
    }
  }

  Future<void> _deleteChat(String chatId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    // Delete all messages in the chat subcollection
    final msgSnap = await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('chats').doc(chatId)
        .collection('messages').get();
    
    for (final doc in msgSnap.docs) {
      await doc.reference.delete();
    }
    
    // Delete the chat document itself
    await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('chats').doc(chatId).delete();
    
    if (_currentChatId == chatId && mounted) {
      setState(() {
        _currentChatId = 'default';
        _streamingMessage = '';
        _suggestions = [];
      });
    }
  }

  Future<void> _saveBotMessage(String text) async {
    if (text.isEmpty) {
      if (mounted) setState(() => _isTyping = false);
      return;
    }
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('chats').doc(_currentChatId)
          .collection('messages').add({
        'text': text,
        'isUser': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      setState(() {
        _isTyping = false;
        _streamingMessage = '';
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            tooltip: 'New Chat',
            onPressed: _startNewChat,
          ),
        ],
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                color: AppColors.forestGreen,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.eco, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Flora',
                  style: TextStyle(fontFamily: 'NotoSerif', fontWeight: FontWeight.w700, fontSize: 18),
                ),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.leafGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('AI Plant Consultant', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.moss)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),

      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Chat History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: uid == null ? const SizedBox() : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('chats').orderBy('updatedAt', descending: true).snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) return const Center(child: Text('No previous chats.'));
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final chatId = docs[index].id;
                        final title = data['title'] as String? ?? 'New Chat';
                        return ListTile(
                          leading: Icon(
                            Icons.chat_bubble_outline,
                            color: _currentChatId == chatId ? AppColors.forestGreen : null,
                          ),
                          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          selected: _currentChatId == chatId,
                          selectedTileColor: AppColors.dew,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Chat?'),
                                  content: const Text('This cannot be undone.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm == true) await _deleteChat(chatId);
                            },
                          ),
                          onTap: () {
                            setState(() {
                              _currentChatId = chatId;
                              _streamingMessage = '';
                              _suggestions = [];
                            });
                            Navigator.pop(context); // Close drawer
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Chat messages ───────────────────────────────────────────────
          Expanded(
            child: uid == null 
              ? const Center(child: Text('Please sign in first.'))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users').doc(uid)
                      .collection('chats').doc(_currentChatId)
                      .collection('messages')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    final docs = snap.data?.docs ?? [];
                    
                    // We render in reverse because ListView is reversed
                    final itemCount = docs.length + (_isTyping || _streamingMessage.isNotEmpty ? 1 : 0);

                    if (itemCount == 0) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🌿', style: TextStyle(fontSize: 64)),
                              SizedBox(height: 16),
                              Text(
                                "Hi! I'm Flora",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'NotoSerif', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Your AI plant consultant. Ask me anything about your plants — or just say hello.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: AppColors.moss),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scroll,
                      reverse: true, // Latest at bottom
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        // The 0th index is the typing/streaming bubble if active
                        if ((_isTyping || _streamingMessage.isNotEmpty) && index == 0) {
                          return _BubbleTile(
                            text: _streamingMessage, 
                            isUser: false, 
                            isTypingIndicator: _isTyping
                          );
                        }
                        
                        // Otherwise, it's a Firestore document
                        final docIndex = (_isTyping || _streamingMessage.isNotEmpty) ? index - 1 : index;
                        final data = docs[docIndex].data() as Map<String, dynamic>;
                        return _BubbleTile(
                          text: data['text'] ?? '',
                          isUser: data['isUser'] == true,
                          isTypingIndicator: false,
                        );
                      },
                    );
                  },
              ),
          ),

          // ── Suggestions ───────────────────────────────────────────────────
          if (_suggestions.isNotEmpty)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final text = _suggestions[index];
                  final isFirst = index == 0;
                  return ActionChip(
                    label: Text(text, style: TextStyle(
                      color: isFirst ? AppColors.forestGreen : AppColors.moss,
                      fontWeight: isFirst ? FontWeight.w600 : FontWeight.w500,
                    )),
                    backgroundColor: isFirst ? AppColors.dew : cs.surface,
                    side: isFirst ? BorderSide.none : BorderSide(color: AppColors.mist),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
                    onPressed: () => _send(text),
                  );
                },
              ),
            ),

          // ── Input bar ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.cream,
              boxShadow: AppShadows.navShadow,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _send(),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Ask Flora anything…',
                        filled: true,
                        fillColor: cs.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.borderPill,
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _send(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.forestGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
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
}

// ── Bubble tile ────────────────────────────────────────────────────────────────
class _BubbleTile extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isTypingIndicator;

  const _BubbleTile({
    required this.text,
    required this.isUser,
    required this.isTypingIndicator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isUser 
        ? AppColors.forestGreen 
        : (isDark ? AppColors.darkSurface : AppColors.mist);
    final textColor = isUser 
        ? Colors.white 
        : (isDark ? AppColors.darkTextPrimary : AppColors.bark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(color: AppColors.forestGreen, shape: BoxShape.circle),
              child: const Center(child: Icon(Icons.eco, color: Colors.white, size: 14)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: AppShadows.cardShadow,
              ),
              child: isTypingIndicator
                  ? const _TypingIndicator()
                  : (isUser 
                      ? Text(text, style: TextStyle(color: textColor, fontSize: 15))
                      : MarkdownBody(
                          data: text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: textColor, fontSize: 15),
                            strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                            em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
                          ),
                        )
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.dew,
              backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                  ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                  : null,
              child: FirebaseAuth.instance.currentUser?.photoURL == null
                  ? const Icon(Icons.person, size: 16, color: AppColors.forestGreen)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bouncing dots ──────────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final offset = (i * 0.2);
            var value = (_ctrl.value - offset) % 1.0;
            if (value < 0) value += 1.0;
            final dy = (value < 0.5) ? -4.0 * (0.5 - (value - 0.25).abs()) * 4 : 0.0;
            
            return Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6, height: 6,
                decoration: const BoxDecoration(color: AppColors.moss, shape: BoxShape.circle),
              ),
            );
          },
        );
      }),
    );
  }
}

