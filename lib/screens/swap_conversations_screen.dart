import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'swap_chat_screen.dart';
import 'package:intl/intl.dart';

class SwapConversationsScreen extends StatelessWidget {
  const SwapConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Swap Conversations', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('swap_conversations')
            .where(Filter.or(
              Filter('buyerUid', isEqualTo: uid),
              Filter('sellerUid', isEqualTo: uid),
            ))
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No active conversations', style: TextStyle(color: Colors.grey)));
          }

          final sortedDocs = docs.toList()..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['lastMessageAt'] as Timestamp?;
            final bTime = bData['lastMessageAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          return ListView.separated(
            itemCount: sortedDocs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = sortedDocs[index].data() as Map<String, dynamic>;
              final isBuyer = data['buyerUid'] == uid;
              final otherPartyName = isBuyer ? data['sellerName'] : data['buyerName'];
              final listingTitle = data['listingTitle'] ?? 'Listing';
              final lastMessage = data['lastMessage'] ?? '';
              
              String timeStr = '';
              final timestamp = data['lastMessageAt'];
              if (timestamp is Timestamp) {
                timeStr = DateFormat.yMd().add_jm().format(timestamp.toDate());
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.person, color: Color(0xFF154212)),
                ),
                title: Text(
                  '$otherPartyName • $listingTitle',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  lastMessage.isEmpty ? 'No messages yet' : lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: Text(
                  timeStr,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SwapChatScreen(conversationId: sortedDocs[index].id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
