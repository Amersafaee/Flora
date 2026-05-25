import 'dart:io';
import 'package:flutter/material.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'plant_detail_screen.dart';
import '../theme/app_theme.dart';

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
  String _listingTitle = '';
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
          _listingTitle = doc.data()?['listingTitle'] ?? '';
          _listingPlantId = doc.data()?['listingId'] ?? '';
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
      'status': 'sent',
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
          SnackBar(content: Text('${AppLocalizations.of(context).failedToSendImagePrefix}$e')),
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
            SnackBar(
              content: Text(AppLocalizations.of(context).locationPermissionRequired),
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
          SnackBar(content: Text('${AppLocalizations.of(context).couldNotGetLocationPrefix}$e')),
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
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.tradeChat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (_listingTitle.isNotEmpty)
              Text(
                _listingTitle,
                style: const TextStyle(fontSize: 12, color: AppColors.bone500, fontWeight: FontWeight.normal),
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
              label: Text(l.viewListing),
              style: TextButton.styleFrom(foregroundColor: AppColors.forest900),
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
                if (docs.isEmpty) return Center(child: Text(l.startTradeNegotiation, style: const TextStyle(color: AppColors.bone500)));

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
                          color: isMe ? AppColors.forest900 : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      child: const Center(child: CircularProgressIndicator()),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Icon(Icons.broken_image, color: AppColors.bone500),
                                  ),
                                ),
                              if (text.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(16, 12, 16, type == 'location' ? 4 : 12),
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
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
                                        color: isMe ? Colors.white70 : AppColors.bone500,
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
              child: LinearProgressIndicator(color: AppColors.forest900),
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
                // FIX 2: anchor buttons to bottom as field expands
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.bone500),
                    onPressed: _pickAndSendImage,
                    tooltip: l.sendImageTooltip,
                  ),
                  IconButton(
                    icon: const Icon(Icons.location_on_outlined, color: AppColors.bone500),
                    onPressed: _shareLocation,
                    tooltip: l.shareLocationTooltip,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: l.messageHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      // FIX 2: Telegram-style expanding field (1–6 lines)
                      minLines: 1,
                      maxLines: 6,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.forest900,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_upward, color: Colors.white),
                        onPressed: () => _sendMessage(),
                      ),
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
