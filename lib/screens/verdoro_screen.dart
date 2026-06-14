import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/gemini_service.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared/analysis_card_view.dart';
import 'onboarding_overlay_screen.dart';

class ChatMessage {
  final String role;
  final String text;
  final String imageUrl;
  final File? imageFile;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.text,
    this.imageUrl = '',
    this.imageFile,
    required this.timestamp,
  });
}

class VerdoroScreen extends StatefulWidget {
  final String conversationId;
  final GeminiService? geminiService;
  final FirebaseFirestore? firestore;
  const VerdoroScreen({super.key, required this.conversationId, this.geminiService, this.firestore});

  @override
  State<VerdoroScreen> createState() => _VerdoroScreenState();
}

class _VerdoroScreenState extends State<VerdoroScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late final GeminiService _geminiService = widget.geminiService ?? GeminiService();
  late final FirebaseFirestore _firestore = widget.firestore ?? FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _hasText = false;
  bool _isContextLoading = true;
  bool _isFirstMessage = true;
  Timer? _contextLoadingTimer;
  late AnimationController _dotsController;
  String? _userPhotoUrl;

  String? get _uid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return 'test_uid';
    }
  }

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.trim().isNotEmpty;
      });
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    });

    _loadChatHistory();
    _loadUserPhoto();

    // Auto-dismiss the context-loading banner after 3 seconds
    _contextLoadingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isContextLoading = false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await OnboardingService.shouldShow('verdoro_screen')) {
        await OnboardingService.markShown('verdoro_screen');
        if (mounted) _showFeatureOnboarding();
      }
    });
  }

  Future<void> _loadUserPhoto() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final url = doc.data()?['profilePhotoUrl'] as String?;
      if (mounted && url != null && url.isNotEmpty) {
        setState(() => _userPhotoUrl = url);
      }
    } catch (e) {
      debugPrint('VerdoroScreen: could not load user photo: $e');
    }
  }

  void _showFeatureOnboarding() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => OnboardingOverlayScreen(
          title: AppLocalizations.of(ctx).aiPlantConsultant,
          description: AppLocalizations.of(ctx).yourPersonalPlantCareAssistant,
          tips: [
            AppLocalizations.of(ctx).askVerdoroAnything,
            AppLocalizations.of(ctx).basedOnYourGarden,
            AppLocalizations.of(ctx).analyzeWithVerdoro,
          ],
          featureKey: 'verdoro_screen',
        ),
      ),
    );
  }

  void _loadChatHistory() {
    if (_uid == null || widget.conversationId.isEmpty) return;

    _firestore
        .collection('users')
        .doc(_uid)
        .collection('verdoro_chats')
        .doc(widget.conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _isFirstMessage = snapshot.docs.isEmpty;
        _messages = snapshot.docs.map((doc) {
          final data = doc.data();
          return ChatMessage(
            role: data['role'] ?? 'user',
            text: data['text'] ?? '',
            imageUrl: data['imageUrl'] ?? '',
            timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList();
      });
      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    });
  }

  Future<void> _saveMessageToFirestore(ChatMessage msg) async {
    if (_uid == null || widget.conversationId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('verdoro_chats')
        .doc(widget.conversationId)
        .collection('messages')
        .add({
      'role': msg.role,
      'text': msg.text,
      'imageUrl': msg.imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateConversationMeta({
    required String lastMessage,
    String? newTitle,
  }) async {
    if (_uid == null || widget.conversationId.isEmpty) return;
    final Map<String, dynamic> data = {
      'lastMessage': lastMessage,
      'lastMessageAt': FieldValue.serverTimestamp(),
    };
    if (newTitle != null) data['title'] = newTitle;
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('verdoro_chats')
        .doc(widget.conversationId)
        .update(data);
  }

  @override
  void dispose() {
    _contextLoadingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? text]) async {
    final messageText = text ?? _textController.text.trim();
    if (messageText.isEmpty) return;

    _textController.clear();
    _focusNode.unfocus();

    final bool wasFirst = _isFirstMessage;

    final userMsg = ChatMessage(
      role: 'user',
      text: messageText,
      timestamp: DateTime.now(),
    );

    setState(() {
      _isTyping = true;
      _isFirstMessage = false;
    });

    await _saveMessageToFirestore(userMsg);

    // Mark that the user has used Verdoro Chat � enables the verdoro_friend badge
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _firestore
            .collection('users')
            .doc(uid)
            .update({'usedVerdoroChat': true});
      }
    } catch (_) {}

    await _updateConversationMeta(
      lastMessage: messageText,
      newTitle: wasFirst
          ? messageText.substring(0, messageText.length > 30 ? 30 : messageText.length)
          : null,
    );
    _scrollToBottom();

    final previousMessages = _messages
        .where((m) => m.imageUrl.isEmpty && m.imageFile == null)
        .map((m) => {'role': m.role, 'text': m.text})
        .toList();

    if (previousMessages.isNotEmpty &&
        previousMessages.last['role'] == 'user' &&
        previousMessages.last['text'] == messageText) {
      previousMessages.removeLast();
    }

    final response = await _geminiService.askVerdoroWithContext(
      previousMessages,
      messageText,
      _uid ?? '',
      conversationId: widget.conversationId,
    );

    if (mounted) {
      setState(() {
        _isTyping = false;
        _isContextLoading = false;
      });
      final modelMsg = ChatMessage(
        role: 'model',
        text: response,
        timestamp: DateTime.now(),
      );
      await _saveMessageToFirestore(modelMsg);
      await _updateConversationMeta(lastMessage: 'Verdoro: $response'.substring(
          0, ('Verdoro: $response').length > 60 ? 60 : ('Verdoro: $response').length));
      _scrollToBottom();
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    if (_uid == null) return '';
    final ext = '.${imageFile.path.split('.').last}';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final ref = FirebaseStorage.instance.ref().child('users/$_uid/chat_images/$fileName');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.forest900),
              title: Text(AppLocalizations.of(context).takePhoto,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.forest900),
              title: Text(AppLocalizations.of(context).chooseFromGallery,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    final File imageFile = File(pickedFile.path);

    // Show caption bottom sheet before sending
    if (!mounted) return;
    final String? caption = await _showImageCaptionSheet(imageFile);
    // null means user cancelled
    if (caption == null) return;

    // Validate the image file before proceeding
    final bool fileExists = await imageFile.exists();
    final bool fileNonEmpty = fileExists && imageFile.lengthSync() > 0;
    if (!fileExists || !fileNonEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read image. Please try again.')),
        );
      }
      return;
    }

    if (mounted) setState(() => _isTyping = true);

    String imageUrl = '';
    try {
      imageUrl = await _uploadImage(imageFile);
    } catch (e) {
      debugPrint('Error uploading image: $e');
    }

    final bool wasFirst = _isFirstMessage;
    setState(() => _isFirstMessage = false);

    final userMsg = ChatMessage(
      role: 'user',
      text: caption,
      imageUrl: imageUrl,
      imageFile: imageFile,
      timestamp: DateTime.now(),
    );
    await _saveMessageToFirestore(userMsg);
    final previewText = caption.isNotEmpty ? caption : '?? Image';
    await _updateConversationMeta(
      lastMessage: previewText,
      newTitle: wasFirst ? previewText.substring(0, previewText.length > 30 ? 30 : previewText.length) : null,
    );
    _scrollToBottom();

    try {
      final response = await _geminiService.analyzeePlantImage(
          imageFile, caption.isNotEmpty ? caption : null);

      if (mounted) {
        setState(() => _isTyping = false);
        final modelMsg = ChatMessage(
          role: 'model',
          text: response,
          timestamp: DateTime.now(),
        );
        await _saveMessageToFirestore(modelMsg);
        final verdoroPreview = 'Verdoro: $response';
        await _updateConversationMeta(
            lastMessage: verdoroPreview.substring(
                0, verdoroPreview.length > 60 ? 60 : verdoroPreview.length));
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('VerdoroScreen: error analyzing image: $e');
      if (mounted) {
        setState(() => _isTyping = false);
        const errorText = 'I had trouble analyzing that image. Please try again.';
        final errorMsg = ChatMessage(
          role: 'model',
          text: errorText,
          timestamp: DateTime.now(),
        );
        await _saveMessageToFirestore(errorMsg);
        await _updateConversationMeta(
            lastMessage: 'Verdoro: $errorText'
                .substring(0, 'Verdoro: $errorText'.length > 60 ? 60 : 'Verdoro: $errorText'.length));
        _scrollToBottom();
      }
    }
  }

  Future<String?> _showImageCaptionSheet(File imageFile) async {
    final captionController = TextEditingController();
    String? result;

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Image preview � explicit height+width to satisfy layout constraints
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: Image.file(
                            imageFile,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Caption text field
                      TextField(
                        controller: captionController,
                        autofocus: false,
                        maxLines: 3,
                        minLines: 1,
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.forest900,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).addCaptionOrQuestion,
                          hintStyle: GoogleFonts.outfit(color: AppColors.bone400, fontSize: 14),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.bone200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.bone200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.forest900, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Send button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            result = captionController.text.trim();
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.send, color: Colors.white, size: 18),
                          label: Text(
                            AppLocalizations.of(context).send,
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forest700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Cancel button
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          AppLocalizations.of(context).cancel,
                          style: const TextStyle(color: AppColors.bone500, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Caption sheet error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open image preview'),
            backgroundColor: AppColors.terracotta900,
          ),
        );
      }
    }

    captionController.dispose();
    return result;
  }

  Future<void> _clearChatHistory() async {
    if (_uid == null || widget.conversationId.isEmpty) return;

    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('verdoro_chats')
        .doc(widget.conversationId)
        .collection('messages')
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    if (mounted) {
      setState(() {
        _isFirstMessage = true;
      });
    }
  }

  void _showChatOptionsMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.terracotta900),
                title: Text(
                  AppLocalizations.of(context).clearChatHistory,
                  style: GoogleFonts.outfit(color: AppColors.terracotta900, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _clearChatHistory();
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: isDark ? AppColors.darkTextPrimary : AppColors.forest700),
                title: Text(
                  AppLocalizations.of(context).aboutVerdoro,
                  style: GoogleFonts.outfit(color: isDark ? AppColors.darkTextPrimary : AppColors.forest900, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAboutVerdoroSheet(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAboutVerdoroSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco, color: AppColors.forest200, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Verdoro',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.forest900),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).yourPersonalPlantCareAssistant,
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.bone500),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context).verdoroKnowsPlantsDesc,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 14, height: 1.5, color: isDark ? AppColors.darkTextSecondary : AppColors.forest900),
                ),
                const SizedBox(height: 32),
                Text(
                  AppLocalizations.of(context).version100,
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.bone500),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      AppLocalizations.of(context).close,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.bone50,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back, size: 20, color: AppColors.forest700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkForestPrimary : AppColors.forest700,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Verdoro',
                  style: GoogleFonts.outfit(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Plant care companion',
                  style: GoogleFonts.outfit(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.bone500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: isDark ? AppColors.darkTextPrimary : AppColors.forest700),
            onPressed: () => _showChatOptionsMenu(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [

            // Context-loading banner - shown briefly when Verdoro first opens
            if (_isContextLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : AppColors.forest100,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.forest900),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).verdoroIsReviewingYourPlants,
                      style: const TextStyle(
                        color: AppColors.bone500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _messages.isEmpty && !_isTyping
                  ? _buildSuggestedQuestionsSection()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: _messages.length + (_isTyping ? 2 : 1),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  AppLocalizations.of(context).todayTimestamp(DateFormat('h:mm a').format(DateTime.now())),
                                  style: const TextStyle(
                                    color: AppColors.bone500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final msgIndex = index - 1;

                        if (msgIndex == _messages.length) {
                          final bool isFirstTyping = _messages.isEmpty || _messages.last.role != 'model';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: _buildVerdoroTyping(primaryColor, isFirstTyping),
                          );
                        }

                        final message = _messages[msgIndex];
                        final bool isFirstInGroup = msgIndex == 0 || _messages[msgIndex - 1].role != message.role;
                        bool isLastInGroup = false;
                        if (msgIndex == _messages.length - 1) {
                          if (message.role == 'model' && _isTyping) {
                            isLastInGroup = false;
                          } else {
                            isLastInGroup = true;
                          }
                        } else {
                          isLastInGroup = _messages[msgIndex + 1].role != message.role;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: message.role == 'model'
                              ? _buildVerdoroMessage(
                                  text: message.text,
                                  imageUrl: message.imageUrl,
                                  primaryColor: primaryColor,
                                  isFirstInGroup: isFirstInGroup,
                                  isLastInGroup: isLastInGroup,
                                  timestamp: message.timestamp,
                                )
                              : _buildUserMessage(
                                  text: message.text,
                                  primaryColor: primaryColor,
                                  imageUrl: message.imageUrl,
                                  imageFile: message.imageFile,
                                  isLastInGroup: isLastInGroup,
                                  timestamp: message.timestamp,
                                ),
                        );
                      },
                    ),
            ),
            
            // Bottom Input Area
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 16),
              child: Row(
                // FIX 1: anchor buttons to bottom as field expands
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.bone100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.image_outlined, color: AppColors.forest700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      // FIX 1: Telegram-style expanding field
                      minLines: 1,
                      maxLines: 6,
                      onSubmitted: (_) {
                        if (_hasText) _sendMessage();
                      },
                      style: GoogleFonts.outfit(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).askVerdoroShort,
                        hintStyle: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppColors.bone400,
                        ),
                        filled: true,
                        fillColor: isDark 
                          ? AppColors.darkSurfaceElevated 
                          : AppColors.bone100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppColors.forest700,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: GestureDetector(
                      onTap: _hasText ? () => _sendMessage() : null,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _hasText ? AppColors.forest700 : AppColors.bone300,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send, color: Colors.white, size: 20),
                      ),
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

  Widget _buildSuggestedQuestionsSection() {
    final Color primaryColor = Theme.of(context).primaryColor;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.eco, color: primaryColor, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).hiIAmVerdoro,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).yourPersonalPlantCareAssistant,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.bone500,
                ),
              ),
              const SizedBox(height: 40),
              FutureBuilder<QuerySnapshot>(
                future: _uid != null
                    ? _firestore
                        .collection('users')
                        .doc(_uid)
                        .collection('plants')
                        .where('isDeceased', isEqualTo: false)
                        .limit(3)
                        .get()
                    : null,
                builder: (context, snapshot) {
                  List<String> chips;
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    chips = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['commonName'] as String?)?.trim().isNotEmpty == true
                          ? (data['commonName'] as String).trim()
                          : (data['name'] as String?)?.trim() ?? 'my plant';
                      return "How's my $name doing?";
                    }).toList();
                    chips.add(AppLocalizations.of(context).whatShouldICareForToday);
                  } else {
                    chips = [
                      AppLocalizations.of(context).howOftenWaterMonstera,
                      AppLocalizations.of(context).whyLeavesYellow,
                      AppLocalizations.of(context).plantsGoodForLowLight,
                      AppLocalizations.of(context).howToRepotPlant,
                    ];
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: chips.map((c) => _buildSuggestionChip(c)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        _textController.text = text;
        _hasText = true;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          border: Border.all(
            color: isDark ? AppColors.darkBorderDefault : AppColors.bone200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.bone900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildVerdoroMessage({
    required String text,
    String imageUrl = '',
    required Color primaryColor,
    required bool isFirstInGroup,
    required bool isLastInGroup,
    required DateTime timestamp,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFirstInGroup)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.eco, color: Colors.white, size: 16),
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceElevated : const Color(0xFFFFFFFF),
                  boxShadow: Theme.of(context).brightness == Brightness.dark
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          width: 200,
                          height: 150,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) =>
                              progress == null
                                  ? child
                                  : const SizedBox(
                                      width: 200,
                                      height: 150,
                                      child: Center(child: CircularProgressIndicator(color: AppColors.forest900, strokeWidth: 2)),
                                    ),
                          errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 40),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (text.isNotEmpty)
                      if (AnalysisCardView.isStructuredAnalysis(text))
                        _buildAnalysisContent(text)
                      else
                        MarkdownBody(
                          data: text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.bone900,
                              fontSize: 15,
                              height: 1.4,
                            ),
                            listBullet: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.bone900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
        if (isLastInGroup)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4),
            child: Text(
              DateFormat('h:mm a').format(timestamp),
              style: const TextStyle(color: AppColors.bone500, fontSize: 11),
            ),
          ),
      ],
    );
  }

  /// Renders a structured analysis message. If there is conversational text
  /// *before* the first known analysis label (e.g. "Great news, here's what
  /// I found:"), it is displayed as a MarkdownBody lead-in above the cards.
  /// If splitting is ambiguous or the lead-in is empty the cards are shown
  /// directly — safety takes priority over the extra framing text.
  Widget _buildAnalysisContent(String text) {
    const firstLabels = [
      'plant identified:',
      'health score:',
      'status:',
      'what i can see:',
      'most urgent action:',
      'care tip:',
    ];

    final lower = text.toLowerCase();
    int firstLabelIdx = text.length;
    for (final label in firstLabels) {
      final idx = lower.indexOf(label);
      if (idx != -1 && idx < firstLabelIdx) {
        firstLabelIdx = idx;
      }
    }

    final leadIn = firstLabelIdx > 0 ? text.substring(0, firstLabelIdx).trim() : '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mdStyle = MarkdownStyleSheet(
      p: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : AppColors.bone900,
        fontSize: 15,
        height: 1.4,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (leadIn.isNotEmpty) ...[
          MarkdownBody(data: leadIn, styleSheet: mdStyle),
          const SizedBox(height: 12),
        ],
        AnalysisCardView(rawText: text),
      ],
    );
  }

  Widget _buildVerdoroTyping(Color primaryColor, bool isFirstInGroup) {

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isFirstInGroup)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.eco, color: Colors.white, size: 16),
          )
        else
          const SizedBox(width: 28),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A2535) : const Color(0xFFEDF3FA),
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: AnimatedBuilder(
            animation: _dotsController,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAnimatedDot(0),
                  const SizedBox(width: 4),
                  _buildAnimatedDot(1),
                  const SizedBox(width: 4),
                  _buildAnimatedDot(2),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedDot(int index) {
    final double val = (_dotsController.value * 3) - index;
    final double active = (val >= 0 && val <= 1) ? 1.0 : 0.0;
    
    return Transform.translate(
      offset: Offset(0, -3 * active),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: active > 0 ? AppColors.bone700 : AppColors.bone300,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildUserMessage({
    required String text,
    required Color primaryColor,
    String imageUrl = '',
    File? imageFile,
    required bool isLastInGroup,
    required DateTime timestamp,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark ? const Color(0xFF1A3B2E) : const Color(0xFFD1E2D9);
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.bone900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 40),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [

                  if (imageFile != null || imageUrl.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 200,
                          height: 150,
                          child: imageFile != null
                              ? Image.file(imageFile, fit: BoxFit.cover)
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (ctx, child, progress) =>
                                      progress == null
                                          ? child
                                          : const Center(
                                              child: CircularProgressIndicator(
                                                  color: Colors.white)),
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      color: Colors.white,
                                      size: 40),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isLastInGroup)
              CircleAvatar(
                backgroundColor: AppColors.forest700.withValues(alpha: 0.12),
                radius: 16,
                backgroundImage: _userPhotoUrl != null
                    ? NetworkImage(_userPhotoUrl!)
                    : null,
                child: _userPhotoUrl == null
                    ? const Icon(Icons.person, color: AppColors.forest700, size: 18)
                    : null,
              )
            else
              const SizedBox(width: 32),
          ],
        ),
        if (isLastInGroup)
          Padding(
            padding: const EdgeInsets.only(right: 44, top: 4),
            child: Text(
              DateFormat('h:mm a').format(timestamp),
              style: const TextStyle(color: AppColors.bone500, fontSize: 11),
            ),
          ),
      ],
    );
  }
}












