import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/plant_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast_utils.dart';

class EditPlantScreen extends StatefulWidget {
  final String plantId;

  const EditPlantScreen({super.key, required this.plantId});

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  late TextEditingController _nameController;
  late TextEditingController _commonNameController;
  late TextEditingController _categoryController;
  late TextEditingController _healthStatusController;
  bool _isLoading = false;
  bool _isFetching = true;
  Plant? _plant;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _commonNameController = TextEditingController();
    _categoryController = TextEditingController();
    _healthStatusController = TextEditingController();
    _fetchPlant();
  }

  void _fetchPlant() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.plantId.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('plants')
          .doc(widget.plantId)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = widget.plantId;
        _plant = Plant.fromMap(data);
        _nameController.text = _plant!.name;
        _commonNameController.text = _plant!.commonName;
        _categoryController.text = _plant!.category;
        _healthStatusController.text = _plant!.healthStatus;
      }
    } catch (e) {
      debugPrint('Error fetching edit plant details: $e');
    }

    if (mounted) {
      setState(() {
        _isFetching = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commonNameController.dispose();
    _categoryController.dispose();
    _healthStatusController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    final l = AppLocalizations.of(context);
    if (_nameController.text.trim().isEmpty || _plant == null) {
      showToast(context, l.plantNameEmpty, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedPlant = Plant(
        id: _plant!.id,
        name: _nameController.text.trim(),
        commonName: _commonNameController.text.trim(),
        category: _categoryController.text.trim(),
        imageUrl: _plant!.imageUrl,
        healthStatus: _healthStatusController.text.trim(),
        dateAdded: _plant!.dateAdded,
        healthScore: _plant!.healthScore,
        isDeceased: _plant!.isDeceased,
        deceasedDate: _plant!.deceasedDate,
        memorialNote: _plant!.memorialNote,
        eulogy: _plant!.eulogy,
      );

      await FirestoreService().updatePlant(updatedPlant);

      if (mounted) {
        Navigator.pop(context);
        showToast(context, l.plantUpdated, isError: false);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, AppLocalizations.of(context).failedToUpdatePlant, isError: true);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.bone50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back, size: 20, color: AppColors.forest700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.editPlant,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
          ),
        ),
        centerTitle: true,
        actions: [
          _isLoading
              ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : TextButton(
                  onPressed: _isFetching ? null : _saveChanges,
                  child: Text(
                    l.saveChanges,
                    style: GoogleFonts.outfit(
                      color: AppColors.forest700,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
        ],
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(l.name, _nameController),
                  const SizedBox(height: 16),
                  _buildTextField(l.commonName, _commonNameController),
                  const SizedBox(height: 16),
                  _buildTextField(l.category, _categoryController),
                  const SizedBox(height: 16),
                  _buildTextField(l.healthStatus, _healthStatusController),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forest700,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                          : Text(
                              l.saveChanges,
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.bone400,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isDark ? AppColors.darkTextPrimary : AppColors.forest800,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.forest900, width: 2)),
          ),
        ),
      ],
    );
  }
}
