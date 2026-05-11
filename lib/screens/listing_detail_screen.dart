import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ListingDetailScreen extends StatefulWidget {
  final DocumentSnapshot doc;
  const ListingDetailScreen({super.key, required this.doc});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;
  bool _messageSent = false;

  Map<String, dynamic> get data => widget.doc.data() as Map<String, dynamic>;

  Future<void> _sendInterestMessage() async {
    if (_currentUid == null) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    final senderName = currentUser?.displayName ?? 'A fellow plant lover';

    await FirebaseFirestore.instance
        .collection('swap_listings')
        .doc(widget.doc.id)
        .collection('interests')
        .add({
      'fromUid': _currentUid,
      'fromName': senderName,
      'message': 'Hi! I am interested in swapping for your ${data['title']}. Let me know if you are open to trading!',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    if (mounted) {
      setState(() => _messageSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Interest sent! The owner will be notified.'),
          backgroundColor: Color(0xFF154212),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final imageUrl = data['imageUrl'] ?? '';
    final title = data['title'] ?? '';
    final description = data['description'] ?? '';
    final location = data['location'] ?? '';
    final type = data['type'] ?? '';
    final lookingFor = data['lookingFor'] ?? '';
    final ownerName = data['ownerName'] ?? '';
    final ownerUid = data['ownerUid'] ?? '';
    final isOwner = _currentUid == ownerUid;

    String timeAgo = 'Recently';
    final timestamp = data['timestamp'];
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
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
              if (isOwner)
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
      ),
      bottomNavigationBar: isOwner
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _messageSent ? null : _sendInterestMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _messageSent ? Colors.grey : const Color(0xFF154212),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    _messageSent ? '✓ Interest Sent' : '🌿 I\'m Interested in Swapping',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
    );
  }
}
