import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/plant_model.dart';
import '../models/task_model.dart';
import 'flora_screen.dart';

class AddPlantScreen extends StatefulWidget {
  final String? initialPlantName;
  final String? initialCommonName;
  final String? initialCategory;
  final String? initialHealthStatus;
  final File? initialImageFile;
  final String? initialImageUrl;
  final String? initialWateringDays;
  final String? analysisResult;

  const AddPlantScreen({
    super.key,
    this.initialPlantName,
    this.initialCommonName,
    this.initialCategory,
    this.initialHealthStatus,
    this.initialImageFile,
    this.initialImageUrl,
    this.initialWateringDays,
    this.analysisResult,
  });

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _commonNameController;
  
  String _selectedCategory = 'Tropical';
  String _selectedHealth = 'Healthy';

  bool _isLoading = false;
  bool _showNameError = false;

  File? _imageFile;
  String _initialImageUrl = '';
  String _initialWateringDays = '7';
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

    if (widget.initialHealthStatus != null &&
        ['Healthy', 'Needs Attention', 'Critical'].contains(widget.initialHealthStatus)) {
      _selectedHealth = widget.initialHealthStatus!;
    }

    if (widget.initialImageFile != null) {
      _imageFile = widget.initialImageFile;
    } else if (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty) {
      _initialImageUrl = widget.initialImageUrl!;
    }

    if (widget.initialWateringDays != null && widget.initialWateringDays!.isNotEmpty) {
      _initialWateringDays = widget.initialWateringDays!;
    }

    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commonNameController.dispose();
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
      final docRef = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).collection('plants').doc();
      final plantId = docRef.id;

      if (_imageFile != null) {
        final url = await _storageService.uploadPlantPhoto(_imageFile!, plantId, context);
        if (url == null) {
          setState(() => _isLoading = false);
          return;
        }
        imageUrl = url;
      } else if (_initialImageUrl.isNotEmpty) {
        // Pre-filled from identify — use the network URL directly
        imageUrl = _initialImageUrl;
      }
      
      final plant = Plant(
        id: plantId,
        name: _nameController.text.trim(),
        commonName: _commonNameController.text.trim(),
        category: _selectedCategory,
        zone: '',
        imageUrl: imageUrl,
        healthStatus: _selectedHealth,
        dateAdded: DateTime.now(),
      );
      
      await _firestoreService.addPlant(plant);
      
      if (mounted) {
        _showCareScheduleBottomSheet(plant.name, plantId);
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
                    setState(() {
                      _imageFile = File(picked.path);
                      _initialImageUrl = ''; // clear URL if user picks new file
                    });
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
                  child: _imageFile != null
                      ? null
                      : _initialImageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _initialImageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(
                                    Icons.eco,
                                    size: 48,
                                    color: const Color(0xFF154212).withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.eco,
                                size: 48,
                                color: const Color(0xFF154212).withValues(alpha: 0.4),
                              ),
                            ),
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
  /// Maps a watering-days string extracted from AI to the dropdown label.
  String _wateringDaysToLabel(String daysStr) {
    final days = int.tryParse(daysStr.trim()) ?? 7;
    if (days <= 1) return 'Every day';
    if (days <= 2) return 'Every 2 days';
    if (days <= 4) return 'Every 3 days';
    if (days <= 8) return 'Weekly';
    if (days <= 16) return 'Every 2 weeks';
    return 'Monthly';
  }

  void _showCareScheduleBottomSheet(String plantName, String plantId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String wateringVal = _wateringDaysToLabel(_initialWateringDays);
        String fertilizingVal = 'Monthly';
        String mistingVal = 'Skip';

        final List<String> options = [
          'Every day', 'Every 2 days', 'Every 3 days', 'Weekly', 'Every 2 weeks', 'Monthly', 'Skip'
        ];

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Text(
                      'Set up care for $plantName 🌿',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'How often does this plant need care? We will add it to your calendar automatically.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    _buildCareRow('Watering', Icons.water_drop, Colors.blue, wateringVal, options, (val) {
                      setState(() => wateringVal = val!);
                    }),
                    const SizedBox(height: 16),
                    _buildCareRow('Fertilizing', Icons.science, Colors.green, fertilizingVal, options, (val) {
                      setState(() => fertilizingVal = val!);
                    }),
                    const SizedBox(height: 16),
                    _buildCareRow('Misting', Icons.air, Colors.cyan, mistingVal, options, (val) {
                      setState(() => mistingVal = val!);
                    }),
                    
                    const SizedBox(height: 32),
                    
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid == null) return;
                        final plantName = _nameController.text.trim().isEmpty ? 'your plant' : _nameController.text.trim();
                        final db = FirebaseFirestore.instance;
                        final chatsRef = db.collection('users').doc(uid).collection('flora_chats');
                        // Create conversation
                        final docRef = await chatsRef.add({
                          'title': 'Care advice for $plantName',
                          'createdAt': FieldValue.serverTimestamp(),
                          'lastMessageAt': FieldValue.serverTimestamp(),
                          'lastMessage': 'Care advice for $plantName',
                        });
                        final conversationId = docRef.id;
                        final messagesRef = chatsRef.doc(conversationId).collection('messages');
                        // Seed the first message
                        final userText = (widget.analysisResult != null && widget.analysisResult!.isNotEmpty)
                            ? widget.analysisResult!
                            : 'I just added $plantName to my collection. Can you give me specific advice on watering schedule, fertilizing, and repotting for this plant?';
                        await messagesRef.add({
                          'role': 'user',
                          'text': userText,
                          'imageUrl': '',
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        if (!context.mounted) return;
                        Navigator.pop(context); // close bottom sheet
                        Navigator.push(context, MaterialPageRoute(builder: (_) => FloraScreen(conversationId: conversationId)));
                      },
                      icon: const Icon(Icons.psychology, color: Color(0xFF154212)),
                      label: const Text(
                        'Ask Flora for advice 🌿',
                        style: TextStyle(color: Color(0xFF154212), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF154212)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ElevatedButton(
                      onPressed: () async {
                        await _saveSchedules(plantName, plantId, wateringVal, fertilizingVal, mistingVal);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154212),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Save Care Schedule',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // close bottom sheet
                        Navigator.pop(context); // close add plant screen
                      },
                      child: Text(
                        'Skip for now',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCareRow(String title, IconData icon, Color color, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: options.map((String opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSchedules(String plantName, String plantId, String watering, String fertilizing, String misting) async {
    final now = DateTime.now();

    String getRepeatType(String val) {
      switch (val) {
        case 'Every day': return 'daily';
        case 'Every 2 days': return 'every2days';
        case 'Every 3 days': return 'every3days';
        case 'Weekly': return 'weekly';
        case 'Every 2 weeks': return 'biweekly';
        case 'Monthly': return 'monthly';
        default: return 'none';
      }
    }

    if (watering != 'Skip') {
      await _firestoreService.addTask(Task(
        id: '',
        plantId: plantId,
        plantName: plantName,
        taskType: 'Watering',
        dueDate: now.add(const Duration(days: 1)),
        isCompleted: false,
        notes: '',
        repeatType: getRepeatType(watering),
      ));
    }
    
    if (fertilizing != 'Skip') {
      await _firestoreService.addTask(Task(
        id: '',
        plantId: plantId,
        plantName: plantName,
        taskType: 'Fertilizing',
        dueDate: now.add(const Duration(days: 14)),
        isCompleted: false,
        notes: '',
        repeatType: getRepeatType(fertilizing),
      ));
    }

    if (misting != 'Skip') {
      await _firestoreService.addTask(Task(
        id: '',
        plantId: plantId,
        plantName: plantName,
        taskType: 'Misting',
        dueDate: now.add(const Duration(days: 3)),
        isCompleted: false,
        notes: '',
        repeatType: getRepeatType(misting),
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Care schedule saved — tasks added to your calendar 🌿'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context); // close sheet
      Navigator.pop(context); // close screen
    }
  }
}




