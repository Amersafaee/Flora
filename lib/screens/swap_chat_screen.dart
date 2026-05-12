import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/gemini_service.dart';

class SwapChatScreen extends StatefulWidget {
  final String conversationId;

  const SwapChatScreen({super.key, required this.conversationId});

  @override
  State<SwapChatScreen> createState() => _SwapChatScreenState();
}

class _SwapChatScreenState extends State<SwapChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _currentUid == null) return;

    _msgController.clear();

    final messagesRef = FirebaseFirestore.instance
        .collection('swap_conversations')
        .doc(widget.conversationId)
        .collection('messages');

    await messagesRef.add({
      'senderId': _currentUid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('swap_conversations')
        .doc(widget.conversationId)
        .update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _askFloraAssistant() async {
    if (_currentUid == null) return;
    
    final plantsSnap = await FirebaseFirestore.instance.collection('users').doc(_currentUid).collection('plants').get();
    final plantNames = plantsSnap.docs.map((doc) => (doc.data()['name'] ?? '').toString()).where((n) => n.isNotEmpty).toList();
    final joinedNames = plantNames.join(', ');

    final convDoc = await FirebaseFirestore.instance.collection('swap_conversations').doc(widget.conversationId).get();
    final listingTitle = convDoc.data()?['listingTitle'] ?? 'plant';

    final prompt = "The user is considering swapping for a $listingTitle. Based on their collection of $joinedNames, is this a good addition? Consider care compatibility and collection diversity. Give a 2 sentence honest recommendation.";
    
    // Show temporary "Flora is typing..." somehow? No, just await it.
    final response = await GeminiService().askFlora(<Map<String, String>>[], prompt);
    
    await FirebaseFirestore.instance
        .collection('swap_conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .add({
      'senderId': 'flora',
      'text': response,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('swap_conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('Say hi!', style: TextStyle(color: Colors.grey)));

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _currentUid;
                    final isFlora = data['senderId'] == 'flora';
                    final text = data['text'] ?? '';
                    final timestamp = data['timestamp'];

                    String timeStr = '';
                    if (timestamp is Timestamp) {
                      timeStr = DateFormat.jm().format(timestamp.toDate());
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF154212) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (isFlora)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.psychology, size: 14, color: Color(0xFF154212)),
                                    SizedBox(width: 4),
                                    Text('Flora Assistant', style: TextStyle(color: Color(0xFF154212), fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            Text(
                              text,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.grey.shade600,
                                fontSize: 10,
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.psychology, color: Color(0xFF154212)),
                    onPressed: _askFloraAssistant,
                    tooltip: 'Ask Flora',
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF154212)),
                    onPressed: _sendMessage,
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
