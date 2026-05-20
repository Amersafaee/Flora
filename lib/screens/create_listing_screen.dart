import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class CreateListingScreen extends StatefulWidget {
  final String? initialPlantName;
  final String? initialDescription;
  final String? initialType;
  final int? initialHealthScore;
  final String? initialPlantId;
  final String? initialImageUrl;

  const CreateListingScreen({
    super.key,
    this.initialPlantName,
    this.initialDescription,
    this.initialType,
    this.initialHealthScore,
    this.initialPlantId,
    this.initialImageUrl,
  });

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final TextEditingController _lookingForController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _selectedType = 'Cutting';
  bool _isLoading = false;
  File? _imageFile;
  String _existingImageUrl = '';

  final List<String> _types = ['Cutting', 'Free Seeds', 'Whole Plant', 'Adoption'];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialPlantName ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    if (widget.initialType != null && _types.contains(widget.initialType)) {
      _selectedType = widget.initialType!;
    }
    _existingImageUrl = widget.initialImageUrl ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _lookingForController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 75);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _existingImageUrl = '';
      });
    }
  }

  void _showImagePickerSheet() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.chooseFromGallery),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l.takeAPhoto),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            if (_imageFile != null || _existingImageUrl.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(l.removePhoto, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() { _imageFile = null; _existingImageUrl = ''; });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<String> _uploadImageIfNeeded(String userId) async {
    if (_imageFile == null) return _existingImageUrl;
    final ext = _imageFile!.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = FirebaseStorage.instance.ref().child('swap_listings/$userId/$fileName');
    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  void _saveListing() async {
    final l = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty || description.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.titleDescLocationRequired), backgroundColor: Colors.red),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);

    try {
      int? healthScore = widget.initialHealthScore;
      String? healthStatus;
      String? plantId = widget.initialPlantId;

      if (plantId == null) {
        final plantsSnap = await FirebaseFirestore.instance
            .collection('users').doc(user.uid).collection('plants')
            .where('name', isEqualTo: title).limit(1).get();
        if (plantsSnap.docs.isNotEmpty) {
          final plantDoc = plantsSnap.docs.first;
          final plantData = plantDoc.data();
          healthScore ??= plantData['healthScore'] as int?;
          healthStatus = plantData['healthStatus'] as String?;
          plantId = plantDoc.id;
        }
      } else {
        final plantDoc = await FirebaseFirestore.instance
            .collection('users').doc(user.uid).collection('plants').doc(plantId).get();
        if (plantDoc.exists) {
          final plantData = plantDoc.data()!;
          healthScore ??= plantData['healthScore'] as int?;
          healthStatus = plantData['healthStatus'] as String?;
        }
      }

      int? careStreak;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) careStreak = userDoc.data()?['careStreak'] as int?;

      final imageUrl = await _uploadImageIfNeeded(user.uid);

      final listingData = {
        'ownerUid': user.uid,
        'ownerName': user.displayName ?? 'Local Swapper',
        'title': title,
        'description': description,
        'type': _selectedType,
        'imageUrl': imageUrl,
        'lookingFor': _lookingForController.text.trim(),
        'location': location,
        'distanceKm': 0,
        'timestamp': FieldValue.serverTimestamp(),
        'isAvailable': true,
      };

      if (healthScore != null) listingData['healthScore'] = healthScore;
      if (healthStatus != null) listingData['healthStatus'] = healthStatus;
      if (plantId != null) listingData['plantId'] = plantId;
      if (careStreak != null) listingData['careStreak'] = careStreak;

      await FirebaseFirestore.instance.collection('swap_listings').add(listingData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.listingCreatedSuccessfully), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.failedToSaveListingPrefix}$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasImage = _imageFile != null || _existingImageUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.listYourPlant, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          _isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
              : TextButton(
                  onPressed: _saveListing,
                  child: Text(l.save, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _showImagePickerSheet,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.forest100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasImage ? Colors.transparent : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _imageFile != null
                      ? Stack(fit: StackFit.expand, children: [
                          Image.file(_imageFile!, fit: BoxFit.cover),
                          Positioned(
                            bottom: 8, right: 8,
                            child: _editChip(l.changeLabel),
                          ),
                        ])
                      : _existingImageUrl.isNotEmpty
                          ? Stack(fit: StackFit.expand, children: [
                              Image.network(_existingImageUrl, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 40, color: AppColors.bone500))),
                              Positioned(bottom: 8, right: 8, child: _editChip(l.changeLabel)),
                            ])
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.forest900),
                                const SizedBox(height: 8),
                                Text(l.addAPhoto, style: const TextStyle(color: AppColors.forest900, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(l.tapToChoosePhoto, style: const TextStyle(color: AppColors.bone500, fontSize: 12)),
                              ],
                            ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _label(l.titleLabel, context),
            const SizedBox(height: 8),
            _field(_titleController, l.listingTitleHint, context),
            const SizedBox(height: 24),
            _label(l.typeLabel, context),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _types.map((type) => ChoiceChip(
                label: Text(type),
                selected: _selectedType == type,
                onSelected: (selected) { if (selected) setState(() => _selectedType = type); },
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(color: _selectedType == type ? Colors.white : Theme.of(context).colorScheme.onSurface),
              )).toList(),
            ),
            const SizedBox(height: 24),
            _label(l.descriptionLabel, context),
            const SizedBox(height: 8),
            _field(_descriptionController, l.descriptionHint, context, maxLines: 4),
            const SizedBox(height: 24),
            _label(l.lookingFor, context),
            const SizedBox(height: 8),
            _field(_lookingForController, l.lookingForHint, context),
            const SizedBox(height: 24),
            _label(l.locationLabel, context),
            const SizedBox(height: 8),
            _field(_locationController, l.locationHint, context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, BuildContext context) =>
      Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface));

  Widget _field(TextEditingController controller, String hint, BuildContext context, {int maxLines = 1}) =>
      TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone500)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
        ),
      );

  Widget _editChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.edit, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );
}
