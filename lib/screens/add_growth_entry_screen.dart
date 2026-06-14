import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'verdoro_chats_list_screen.dart';
import '../theme/app_theme.dart';
import '../utils/toast_utils.dart';

class AddGrowthEntryScreen extends StatefulWidget {
  final String plantName;
  final String plantId;
  final String healthStatus;

  const AddGrowthEntryScreen({
    super.key,
    required this.plantName,
    required this.plantId,
    this.healthStatus = 'Healthy',
  });

  @override
  State<AddGrowthEntryScreen> createState() => _AddGrowthEntryScreenState();
}

class _AddGrowthEntryScreenState extends State<AddGrowthEntryScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _leavesController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  bool _showNotesError = false;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  @override
  void dispose() {
    _heightController.dispose();
    _leavesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveEntry() async {
    setState(() {
      _showNotesError = _notesController.text.trim().isEmpty;
    });

    if (_showNotesError) return;

    setState(() => _isLoading = true);

    try {
      String imageUrl = '';

      if (_imageFile != null) {
        final url = await _storageService.uploadGrowthPhoto(_imageFile!, widget.plantId, context);
        if (url == null) {
          setState(() => _isLoading = false);
          return;
        }
        imageUrl = url;
      }

      final entry = {
        'height': _heightController.text.trim(),
        'newLeaves': _leavesController.text.trim(),
        'notes': _notesController.text.trim(),
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'photoUrl': imageUrl,
        'date': FieldValue.serverTimestamp(),
        'note': _notesController.text.trim(),
      };

      await _firestoreService.addGrowthEntry(widget.plantId, entry);

      if (mounted) {
        showToast(context, AppLocalizations.of(context).journalEntrySaved, isError: false);
      }

      if (imageUrl.isNotEmpty) {
        final assessment = await GeminiService().analyzeGrowthPhoto(
          imageUrl: imageUrl,
          plantName: widget.plantName,
          previousHealthStatus: widget.healthStatus,
        );
        await FirestoreService().saveHealthAssessment(widget.plantId, assessment);

        final issuesDetected = (assessment['issuesDetected'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

        if (issuesDetected.isNotEmpty) {
          if (mounted) {
            final l2 = AppLocalizations.of(context);
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              builder: (sheetContext) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l2.verdoroNoticedSomething, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: issuesDetected.map((issue) => Chip(
                          label: Text(issue),
                          backgroundColor: Colors.orange.shade50,
                          labelStyle: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                          side: BorderSide.none,
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VerdoroChatsListScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l2.askVerdoroAboutThis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.forest900, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l2.viewTreatmentCases, style: const TextStyle(color: AppColors.forest900, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            );
            return;
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, AppLocalizations.of(context).somethingWentWrong, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading)
              LinearProgressIndicator(color: primaryColor, backgroundColor: Colors.white),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(CupertinoIcons.chevron_back, color: AppColors.forest700),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              l.addJournalEntry,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Ask Verdoro Button
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const VerdoroChatsListScreen()));
                      },
                      icon: const Icon(Icons.psychology, color: AppColors.forest900),
                      label: Text(l.notSureAskVerdoro, style: const TextStyle(color: AppColors.forest900, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.forest900, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Image Picker Area
                    GestureDetector(
                      onTap: () async {
                        final picked = await _picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setState(() => _imageFile = File(picked.path));
                        }
                      },
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.forest100,
                          borderRadius: BorderRadius.circular(16),
                          image: _imageFile != null
                              ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _imageFile == null
                            ? const Center(child: Icon(Icons.eco, size: 48, color: Color(0x6614301E)))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Plant Name (readonly)
                    Text(l.plantLabel, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    Text(widget.plantName, style: const TextStyle(color: AppColors.bone500, fontSize: 16)),
                    const SizedBox(height: 24),

                    // Height Field
                    Text(l.heightInCm, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: l.heightHint,
                        hintStyle: const TextStyle(color: AppColors.bone300),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Leaves Field
                    Text(l.newLeaves, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _leavesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: l.newLeavesHint,
                        hintStyle: const TextStyle(color: AppColors.bone300),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Notes Field
                    Text(l.notesLabel, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: l.notesPlantHint,
                        hintStyle: const TextStyle(color: AppColors.bone300),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                      ),
                    ),
                    if (_showNotesError)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(l.pleaseAddANote, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    const SizedBox(height: 48),

                    // Save Button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(l.saveEntry, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
