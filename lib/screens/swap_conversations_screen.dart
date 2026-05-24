import 'dart:async';
import 'package:flutter/material.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'swap_chat_screen.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class SwapConversationsScreen extends StatefulWidget {
  const SwapConversationsScreen({super.key});

  @override
  State<SwapConversationsScreen> createState() => _SwapConversationsScreenState();
}

class _SwapConversationsScreenState extends State<SwapConversationsScreen> {
  StreamSubscription? _buyerSub;
  StreamSubscription? _sellerSub;

  Map<String, DocumentSnapshot> _buyerDocs = {};
  Map<String, DocumentSnapshot> _sellerDocs = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final db = FirebaseFirestore.instance;
      _buyerSub = db.collection('swap_conversations').where('buyerUid', isEqualTo: uid).snapshots().listen((snap) {
        if (!mounted) return;
        final newDocs = <String, DocumentSnapshot>{};
        for (var doc in snap.docs) {
          newDocs[doc.id] = doc;
        }
        setState(() {
          _buyerDocs = newDocs;
          _isLoading = false;
        });
      });
      _sellerSub = db.collection('swap_conversations').where('sellerUid', isEqualTo: uid).snapshots().listen((snap) {
        if (!mounted) return;
        final newDocs = <String, DocumentSnapshot>{};
        for (var doc in snap.docs) {
          newDocs[doc.id] = doc;
        }
        setState(() {
          _sellerDocs = newDocs;
          _isLoading = false;
        });
      });
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _buyerSub?.cancel();
    _sellerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.messages)),
        body: Center(child: Text(l.notLoggedIn)),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l.mySwapConversations, style: const TextStyle(fontWeight: FontWeight.bold))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final mergedDocs = <String, DocumentSnapshot>{};
    mergedDocs.addAll(_buyerDocs);
    mergedDocs.addAll(_sellerDocs);

    final sortedDocs = mergedDocs.values.toList()..sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTime = aData['lastMessageAt'] as Timestamp?;
      final bTime = bData['lastMessageAt'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l.mySwapConversations, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: sortedDocs.isEmpty
          ? Center(child: Text(l.noActiveConversations, style: const TextStyle(color: AppColors.bone500)))
          : ListView.separated(
              itemCount: sortedDocs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final data = sortedDocs[index].data() as Map<String, dynamic>;
                final isBuyer = data['buyerUid'] == uid;
                final otherPartyName = isBuyer ? data['sellerName'] : data['buyerName'];
                final listingTitle = data['listingTitle'] ?? l.listingLabel;
                final lastMessage = data['lastMessage'] ?? '';

                String timeStr = '';
                final timestamp = data['lastMessageAt'];
                if (timestamp is Timestamp) {
                  timeStr = DateFormat.yMd().add_jm().format(timestamp.toDate());
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.forest100,
                    child: Icon(Icons.person, color: AppColors.forest900),
                  ),
                  title: Text(
                    '$otherPartyName • $listingTitle',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    lastMessage.isEmpty ? l.noMessagesYet : lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.bone500),
                  ),
                  trailing: Text(timeStr, style: const TextStyle(color: AppColors.bone500, fontSize: 12)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SwapChatScreen(conversationId: sortedDocs[index].id)),
                    );
                  },
                );
              },
            ),
    );
  }
}
