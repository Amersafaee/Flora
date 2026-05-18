import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';

class AddGrowthEntrySheet extends StatefulWidget {
  final String plantId;
  const AddGrowthEntrySheet({super.key, required this.plantId});

  @override
  State<AddGrowthEntrySheet> createState() => _AddGrowthEntrySheetState();
}

class _AddGrowthEntrySheetState extends State<AddGrowthEntrySheet> {
  final _noteCtrl   = TextEditingController();
  final _heightCtrl = TextEditingController();
  String? _photoBase64;
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file == null) return;

    // Compress
    final compressed = await FlutterImageCompress.compressWithFile(
      file.path,
      minWidth: 800,
      quality: 70,
    );
    if (compressed == null) return;

    setState(() => _photoBase64 = base64Encode(compressed));
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final note = _noteCtrl.text.trim();
    final heightText = _heightCtrl.text.trim();
    final heightCm = double.tryParse(heightText);

    if (note.isEmpty && _photoBase64 == null && heightCm == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Add a photo, note, or height to save.'),
        backgroundColor: AppColors.terracotta,
      ));
      return;
    }

    setState(() => _saving = true);

    try {
      // Write growth entry
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('plants').doc(widget.plantId)
          .collection('growth').doc()
          .set({
        if (_photoBase64 != null) 'photoBase64': _photoBase64,
        'note': note,
        if (heightCm != null) 'heightCm': heightCm,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update plant's lastUpdated
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('plants').doc(widget.plantId)
          .update({'lastUpdated': FieldValue.serverTimestamp()});

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('📝 Growth entry added!'),
          backgroundColor: AppColors.leafGreen,
        ));
      }
    } catch (e) {
      debugPrint('[Flora] Growth entry error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text('Add Growth Entry', style: TextStyle(
              fontFamily: 'NotoSerif', fontSize: 22, fontWeight: FontWeight.w700,
              color: AppColors.forestGreen,
            )),
            const SizedBox(height: 20),

            // Photo buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.forestGreen,
                      side: const BorderSide(color: AppColors.forestGreen),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.forestGreen,
                      side: const BorderSide(color: AppColors.forestGreen),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    ),
                  ),
                ),
              ],
            ),

            // Photo preview
            if (_photoBase64 != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: AppRadius.borderMd,
                child: Image.memory(
                  base64Decode(_photoBase64!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Note field
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Note',
                hintText: 'How is your plant doing?',
                border: OutlineInputBorder(borderRadius: AppRadius.borderMd),
              ),
            ),
            const SizedBox(height: 12),

            // Height field
            TextField(
              controller: _heightCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Height (cm) — optional',
                border: OutlineInputBorder(borderRadius: AppRadius.borderMd),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

