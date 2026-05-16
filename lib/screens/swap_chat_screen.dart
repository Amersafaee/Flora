import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'plant_detail_screen.dart';

class SwapChatScreen extends StatefulWidget {
  final String conversationId;

  const SwapChatScreen({super.key, required this.conversationId});

  @override
  State<SwapChatScreen> createState() => _SwapChatScreenState();
}

class _SwapChatScreenState extends State<SwapChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;
  final ImagePicker _picker = ImagePicker();
  
  bool _isUploading = false;
  String _listingTitle = 'Loading...';
  String _listingPlantId = '';

  @override
  void initState() {
    super.initState();
    _loadConversationDetails();
  }

  Future<void> _loadConversationDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('swap_conversations')
          .doc(widget.conversationId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _listingTitle = doc.data()?['listingTitle'] ?? 'Chat';
          _listingPlantId = doc.data()?['listingId'] ?? ''; // Assuming listingId maps to plantId
        });
      }
    } catch (e) {
      debugPrint('Error loading conversation: $e');
    }
  }

  Future<void> _sendMessage({String? text, String? imageUrl, String? messageType}) async {
    final msgText = text ?? _msgController.text.trim();
    if (msgText.isEmpty && imageUrl == null) return;

    if (text == null) _msgController.clear();

    final messagesRef = FirebaseFirestore.instance
        .collection('swap_conversations')
        .doc(widget.conversationId)
        .collection('messages');

    await messagesRef.add({
      'senderId': _currentUid,
      'text': msgText,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (messageType != null) 'type': messageType,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent', // For single-check delivery indicator
    });

    await FirebaseFirestore.instance
        .collection('swap_conversations')
        .doc(widget.conversationId)
        .update({
      'lastMessage': messageType == 'image' ? '📷 Image' : (messageType == 'location' ? '📍 Location shared' : msgText),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _pickAndSendImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked == null || _currentUid == null) return;

      setState(() => _isUploading = true);

      final file = File(picked.path);
      final ext = picked.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = FirebaseStorage.instance
          .ref()
          .child('swap_conversations/${widget.conversationId}/images/$fileName');
      
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await _sendMessage(text: '', imageUrl: url, messageType: 'image');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _shareLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission required to share your location'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _sendMessage(
        text: '📍 My location: https://maps.google.com/?q=${position.latitude},${position.longitude}',
        messageType: 'location',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trade Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              _listingTitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (_listingPlantId.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlantDetailScreen(plantId: _listingPlantId, plantName: _listingTitle),
                  ),
                );
              },
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View Listing'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF154212)),
            ),
        ],
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
                if (docs.isEmpty) return const Center(child: Text('Start the trade negotiation!', style: TextStyle(color: Colors.grey)));

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _currentUid;
                    final text = data['text'] ?? '';
                    final imageUrl = data['imageUrl'] as String?;
                    final type = data['type'] as String?;
                    final timestamp = data['timestamp'];
                    final status = data['status'] ?? 'sent';

                    String timeStr = '';
                    if (timestamp is Timestamp) {
                      timeStr = DateFormat('HH:mm').format(timestamp.toDate());
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF154212) : Colors.grey.shade200,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 20),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (imageUrl != null && imageUrl.isNotEmpty)
                                Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      width: double.infinity,
                                      color: Colors.grey.shade300,
                                      child: const Center(child: CircularProgressIndicator()),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              if (text.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(16, 12, 16, type == 'location' ? 4 : 12),
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                      fontWeight: type == 'location' ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(right: 12, bottom: 8, left: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        color: isMe ? Colors.white70 : Colors.grey.shade600,
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.check,
                                        size: 12,
                                        color: status == 'read' ? Colors.blue : Colors.white70,
                                      ),
                                    ],
                                  ],
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
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: Color(0xFF154212)),
            ),
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2))
                ],
              ),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.grey),
                    onPressed: _pickAndSendImage,
                    tooltip: 'Send Image',
                  ),
                  IconButton(
                    icon: const Icon(Icons.location_on_outlined, color: Colors.grey),
                    onPressed: _shareLocation,
                    tooltip: 'Share Location',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF154212),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.white),
                      onPressed: () => _sendMessage(),
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
