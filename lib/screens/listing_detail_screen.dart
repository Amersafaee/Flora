import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'swap_chat_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final DocumentSnapshot doc;
  const ListingDetailScreen({super.key, required this.doc});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  Map<String, dynamic> get data => widget.doc.data() as Map<String, dynamic>;

  Future<void> _startConversation() async {
    if (_currentUid == null) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final sellerUid = data['ownerUid'] ?? '';
    final sellerName = data['ownerName'] ?? '';
    final listingId = widget.doc.id;
    final listingTitle = data['title'] ?? '';

    final convId = '${listingId}_$_currentUid';

    final convRef = FirebaseFirestore.instance.collection('swap_conversations').doc(convId);
    final convDoc = await convRef.get();

    if (!convDoc.exists) {
      await convRef.set({
        'listingId': listingId,
        'listingTitle': listingTitle,
        'buyerUid': _currentUid,
        'buyerName': currentUser.displayName ?? 'A fellow plant lover',
        'sellerUid': sellerUid,
        'sellerName': sellerName,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SwapChatScreen(conversationId: convId)));
    }
  }

  Future<void> _deleteListing() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to remove this listing from the swap market?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFF8D3220))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('swap_listings')
          .doc(widget.doc.id)
          .delete();
      if (mounted) Navigator.pop(context);
    }
  }

  void _editListing(Map<String, dynamic> currentData) {
    final titleCtrl = TextEditingController(text: currentData['title']);
    final descCtrl = TextEditingController(text: currentData['description']);
    final lookCtrl = TextEditingController(text: currentData['lookingFor']);
    String type = currentData['type'] ?? 'Cutting';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Edit Listing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 8),
              TextField(controller: lookCtrl, decoration: const InputDecoration(labelText: 'Looking For')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: type,
                items: ['Cutting', 'Free Seeds', 'Whole Plant', 'Adoption']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setSheetState(() => type = v!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('swap_listings').doc(widget.doc.id).update({
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'lookingFor': lookCtrl.text.trim(),
                    'type': type,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('swap_listings').doc(widget.doc.id).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final currentData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          if (currentData.isEmpty) return const SizedBox.shrink();

          final Color primaryColor = Theme.of(context).primaryColor;
          final imageUrl = currentData['imageUrl'] ?? '';
          final title = currentData['title'] ?? '';
          final description = currentData['description'] ?? '';
          final location = currentData['location'] ?? '';
          final type = currentData['type'] ?? '';
          final lookingFor = currentData['lookingFor'] ?? '';
          final ownerName = currentData['ownerName'] ?? '';
          final ownerUid = currentData['ownerUid'] ?? '';
          final isOwner = _currentUid == ownerUid;

          String timeAgo = 'Recently';
          final timestamp = currentData['timestamp'];
          if (timestamp is Timestamp) {
            final date = timestamp.toDate();
            final diff = DateTime.now().difference(date);
            if (diff.inMinutes < 60) {
              timeAgo = '${diff.inMinutes}m ago';
            } else if (diff.inHours < 24) {
              timeAgo = '${diff.inHours}h ago';
            } else {
              timeAgo = DateFormat.yMMMd().format(date);
            }
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (isOwner) ...[
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                      onPressed: () => _editListing(currentData),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                      ),
                      onPressed: _deleteListing,
                    ),
                  ]
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFE8F5E9),
                            child: const Center(child: Icon(Icons.eco, size: 64, color: Color(0xFF154212))),
                          ))
                      : Container(
                          color: const Color(0xFFE8F5E9),
                          child: const Center(child: Icon(Icons.eco, size: 64, color: Color(0xFF154212))),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(type, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const Spacer(),
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(timeAgo, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(location, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('About this plant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 8),
                      Text(description, style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.5)),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3F1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF8D3220).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.swap_horiz, color: Color(0xFF8D3220)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Looking to swap for', style: TextStyle(color: Color(0xFF8D3220), fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(lookingFor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Listed by', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                Text(ownerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      ),
      bottomNavigationBar: _currentUid == data['ownerUid']
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _startConversation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF154212),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Message Seller',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
    );
  }
}
