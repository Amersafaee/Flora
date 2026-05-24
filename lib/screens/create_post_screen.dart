import 'dart:io';
import 'package:flutter/material.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  final String initialCategory;
  final String? initialTitle;
  final String? initialBody;

  const CreatePostScreen({super.key, this.initialCategory = 'General', this.initialTitle, this.initialBody});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  late String _selectedCategory;
  File? _image;
  bool _isSaving = false;

  final _picker = ImagePicker();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    if (widget.initialTitle != null) _titleController.text = widget.initialTitle!;
    if (widget.initialBody != null) _bodyController.text = widget.initialBody!;
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _savePost() async {
    final l = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.titleBodyRequired), backgroundColor: Colors.red),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // Resolve author name: Firestore fullName → Firestore displayName → Auth displayName → email prefix
      String resolvedAuthorName = '';
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final d = userDoc.data();
          resolvedAuthorName = (d?['fullName'] as String? ?? '').trim();
          if (resolvedAuthorName.isEmpty) {
            resolvedAuthorName = (d?['displayName'] as String? ?? '').trim();
          }
        }
      } catch (_) {}
      if (resolvedAuthorName.isEmpty) resolvedAuthorName = (user.displayName ?? '').trim();
      if (resolvedAuthorName.isEmpty) resolvedAuthorName = user.email?.split('@').first ?? 'Plant Lover';

      final postDoc = await _firestore.collection('posts').add({
        'authorUid': user.uid,
        'authorName': resolvedAuthorName,
        'authorPhotoUrl': user.photoURL ?? '',
        'title': title,
        'body': body,
        'category': _selectedCategory,
        'imageUrl': '',
        'timestamp': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
        'status': 'published',
      });

      String imageUrl = '';
      if (_image != null) {
        if (!mounted) return;
        final url = await _storageService.uploadPostPhoto(_image!, postDoc.id, context);
        if (url != null) {
          imageUrl = url;
          await postDoc.update({'imageUrl': imageUrl});
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).postSharedSuccessfully), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).failedToSharePostPrefix}$e'), backgroundColor: Colors.red),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Category labels — internal values kept stable so Firestore data doesn't change
    final categories = ['General', 'Question', 'Tips', 'Showcase', 'Experience'];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.newPost,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          _isSaving
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
              : TextButton(
                  onPressed: _savePost,
                  child: Text(
                    AppLocalizations.of(context).postAction,
                    style: const TextStyle(color: AppColors.forest700, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: l.postTitleHint,
                border: InputBorder.none,
                hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.bone500),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            TextField(
              controller: _bodyController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: l.postBodyHint,
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              children: categories.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = category);
                  },
                  selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Theme.of(context).primaryColor : AppColors.bone700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (_image != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_image!, height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _image = null),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(l.addPhoto),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
