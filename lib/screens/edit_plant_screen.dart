import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import '../models/plant_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

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
  late TextEditingController _zoneController;
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
    _zoneController = TextEditingController();
    _healthStatusController = TextEditingController();
    _fetchPlant();
  }

  void _fetchPlant() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

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
      _zoneController.text = _plant!.zone;
      _healthStatusController.text = _plant!.healthStatus;
    }
    setState(() {
      _isFetching = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commonNameController.dispose();
    _categoryController.dispose();
    _zoneController.dispose();
    _healthStatusController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    final l = AppLocalizations.of(context);
    if (_nameController.text.trim().isEmpty || _plant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.plantNameEmpty), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedPlant = Plant(
        id: _plant!.id,
        name: _nameController.text.trim(),
        commonName: _commonNameController.text.trim(),
        category: _categoryController.text.trim(),
        zone: _zoneController.text.trim(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.plantUpdated), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).failedToUpdatePlant), backgroundColor: Colors.red),
        );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l.editPlant, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _isLoading
              ? const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())
              : TextButton(
                  onPressed: _isFetching ? null : _saveChanges,
                  child: Text(l.saveChanges, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
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
                  _buildTextField(l.zone, _zoneController),
                  const SizedBox(height: 16),
                  _buildTextField(l.healthStatus, _healthStatusController),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone500)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
          ),
        ),
      ],
    );
  }
}
