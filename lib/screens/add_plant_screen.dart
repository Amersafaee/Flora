import 'dart:io';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/plant_model.dart';
import '../models/task_model.dart';

class AddPlantScreen extends StatefulWidget {
  final String? initialPlantName;
  final String? initialCommonName;
  final String? initialCategory;
  
  const AddPlantScreen({
    super.key,
    this.initialPlantName,
    this.initialCommonName,
    this.initialCategory,
  });

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _commonNameController;
  final TextEditingController _zoneController = TextEditingController();
  
  String _selectedCategory = 'Tropical';
  String _selectedHealth = 'Healthy';
  
  bool _isLoading = false;
  bool _showNameError = false;
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialPlantName ?? '');
    _commonNameController = TextEditingController(text: widget.initialCommonName ?? '');
    
    if (widget.initialCategory != null &&
        ['Tropical', 'Succulent', 'Fern', 'Herb', 'Cactus', 'Other'].contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
    }
    
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commonNameController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  void _savePlant() async {
    setState(() {
      _showNameError = _nameController.text.trim().isEmpty;
    });
    
    if (_showNameError) return;
    
    setState(() => _isLoading = true);
    
    try {
      String imageUrl = '';
      final docRef = FirebaseFirestore.instance.collection('dummy').doc();
      final plantId = docRef.id;

      if (_imageFile != null) {
        final url = await _storageService.uploadPlantPhoto(_imageFile!, plantId, context);
        if (url == null) {
          setState(() => _isLoading = false);
          return;
        }
        imageUrl = url;
      }
      
      final plant = Plant(
        id: plantId,
        name: _nameController.text.trim(),
        commonName: _commonNameController.text.trim(),
        category: _selectedCategory,
        zone: _zoneController.text.trim(),
        imageUrl: imageUrl,
        healthStatus: _selectedHealth,
        dateAdded: DateTime.now(),
      );
      
      await _firestoreService.addPlant(plant);
      
      final now = DateTime.now();
      await _firestoreService.addTask(Task(
        id: '',
        plantName: plant.name,
        taskType: 'Watering',
        dueDate: now.add(const Duration(days: 1)),
        isCompleted: false,
        notes: '',
        repeatType: 'weekly',
      ));
      
      await _firestoreService.addTask(Task(
        id: '',
        plantName: plant.name,
        taskType: 'Fertilizing',
        dueDate: now.add(const Duration(days: 14)),
        isCompleted: false,
        notes: '',
        repeatType: 'monthly',
      ));
      
      await _firestoreService.addTask(Task(
        id: '',
        plantName: plant.name,
        taskType: 'Inspection',
        dueDate: now.add(const Duration(days: 7)),
        isCompleted: false,
        notes: '',
        repeatType: 'weekly',
      ));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Plant added with care tasks created automatically'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Go back after success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.grey,
            behavior: SnackBarBehavior.floating,
          ),
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
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Add Plant',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance header
                ],
              ),
              const SizedBox(height: 32),
              
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
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? Center(
                          child: Icon(
                            Icons.eco,
                            size: 48,
                            color: const Color(0xFF154212).withValues(alpha: 0.4),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 32),
              
              // Form Fields
              Text(
                'Plant Name',
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Monstera Deliciosa',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E211E) : const Color(0xFFFFFFFF),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF154212), width: 2),
                  ),
                ),
              ),
              if (_showNameError)
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'Plant name is required.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              
              Text(
                'Common Name',
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commonNameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Swiss Cheese Plant',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E211E) : const Color(0xFFFFFFFF),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF154212), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: ['Tropical', 'Succulent', 'Fern', 'Herb', 'Cactus', 'Other']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        if (newValue != null) _selectedCategory = newValue;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Room or Zone',
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _zoneController,
                decoration: InputDecoration(
                  hintText: 'e.g. Living Room',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E211E) : const Color(0xFFFFFFFF),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF154212), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Health Status',
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedHealth,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: ['Healthy', 'Needs Attention', 'Critical']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        if (newValue != null) _selectedHealth = newValue;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              // Save Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePlant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Plant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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




