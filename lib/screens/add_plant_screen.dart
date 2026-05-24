import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/badges_service.dart';
import '../models/plant_model.dart';
import '../models/task_model.dart';
import 'flora_screen.dart';
import '../theme/app_theme.dart';

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

  // Internal Firestore values — must stay English
  String _selectedCategory = 'Tropical';

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
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('plants')
          .doc();
      final plantId = docRef.id;

      if (_imageFile != null) {
        final url = await _storageService.uploadPlantPhoto(_imageFile!, plantId, context);
        if (url == null) {
          setState(() => _isLoading = false);
          return;
        }
        imageUrl = url;
      } else if (_initialImageUrl.isNotEmpty) {
        imageUrl = _initialImageUrl;
      }

      final plant = Plant(
        id: plantId,
        name: _nameController.text.trim(),
        commonName: _commonNameController.text.trim(),
        category: _selectedCategory,
        zone: '',
        imageUrl: imageUrl,
        healthStatus: 'Healthy',
        dateAdded: DateTime.now(),
      );

      await _firestoreService.addPlant(plant);

      // Award badges for plant milestones — fire and forget, never blocks the UI
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        BadgesService().checkAndAwardBadges(uid).catchError((_) {});
      }

      if (mounted) {
        _showCareScheduleBottomSheet(plant.name, plantId);
      }
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l.somethingWentWrong} ${l.pleaseTryAgain}'),
            backgroundColor: AppColors.bone500,
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
    final l = AppLocalizations.of(context);
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // Localized display labels for category (Firestore value stays English)
    final List<Map<String, String>> categories = [
      {'value': 'Tropical', 'label': 'Tropical'},
      {'value': 'Succulent', 'label': 'Succulent'},
      {'value': 'Fern', 'label': 'Fern'},
      {'value': 'Herb', 'label': 'Herb'},
      {'value': 'Cactus', 'label': 'Cactus'},
      {'value': 'Other', 'label': 'Other'},
    ];

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
                              l.addPlant,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Image Picker
                    GestureDetector(
                      onTap: () async {
                        final ImageSource? source = await showModalBottomSheet<ImageSource>(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                                  title: Text(AppLocalizations.of(context).takeAPhoto,
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
                        final picked = await _picker.pickImage(source: source);
                        if (picked != null) {
                          setState(() {
                            _imageFile = File(picked.path);
                            _initialImageUrl = '';
                          });
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
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Icon(Icons.eco, size: 48, color: Color(0x6614301E)),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(Icons.eco, size: 48, color: Color(0x6614301E)),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 32),                    // First field: Name
                    const Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "what you call this plant, common name/nickname",
                        hintStyle: const TextStyle(color: AppColors.bone300),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.forest900, width: 2)),
                      ),
                    ),
                    if (_showNameError)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(l.plantNameRequired, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    const SizedBox(height: 20),

                    // Second field: Scientific name (optional)
                    Text(AppLocalizations.of(context).scientificNameOptional, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _commonNameController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).scientificNameOptional,
                        hintStyle: const TextStyle(color: AppColors.bone300),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.forest900, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category
                    Text(l.category, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: categories.map((cat) => DropdownMenuItem<String>(
                            value: cat['value'],
                            child: Text(cat['label']!),
                          )).toList(),
                          onChanged: (newValue) {
                            setState(() { if (newValue != null) _selectedCategory = newValue; });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _savePlant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                "Save plant",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

  /// Maps a watering-days string extracted from AI to the internal schedule label.
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurfaceElevated
          : Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final l = AppLocalizations.of(context);
        String wateringVal = _wateringDaysToLabel(_initialWateringDays);
        String fertilizingVal = 'Monthly';
        String mistingVal = 'Skip';

        // These option labels map 1-to-1 to Firestore repeatType values via _saveSchedules
        // so we keep them as English strings and use them as both display and internal key.
        final List<String> options = [
          'Every day', 'Every 2 days', 'Every 3 days', 'Weekly', 'Every 2 weeks', 'Monthly', 'Skip'
        ];

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 5,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Text(
                      'Set up care for $plantName 🌿',
                      style: const TextStyle(fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.howOftenCareDesc,
                      style: const TextStyle(color: AppColors.bone500, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    _buildCareRow(l.watering, Icons.water_drop, Colors.blue, wateringVal, options, (val) {
                      setSheetState(() => wateringVal = val!);
                    }),
                    const SizedBox(height: 16),
                    _buildCareRow(l.fertilizing, Icons.science, Colors.green, fertilizingVal, options, (val) {
                      setSheetState(() => fertilizingVal = val!);
                    }),
                    const SizedBox(height: 16),
                    _buildCareRow(l.misting, Icons.air, Colors.cyan, mistingVal, options, (val) {
                      setSheetState(() => mistingVal = val!);
                    }),

                    const SizedBox(height: 32),

                    OutlinedButton.icon(
                      onPressed: () async {
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid == null) return;
                        final pName = _nameController.text.trim().isEmpty ? 'your plant' : _nameController.text.trim();
                        final db = FirebaseFirestore.instance;
                        final chatsRef = db.collection('users').doc(uid).collection('flora_chats');
                        final docRef = await chatsRef.add({
                          'title': 'Care advice for $pName',
                          'createdAt': FieldValue.serverTimestamp(),
                          'lastMessageAt': FieldValue.serverTimestamp(),
                          'lastMessage': 'Care advice for $pName',
                        });
                        final conversationId = docRef.id;
                        final messagesRef = chatsRef.doc(conversationId).collection('messages');
                        final userText = (widget.analysisResult != null && widget.analysisResult!.isNotEmpty)
                            ? widget.analysisResult!
                            : 'I just added $pName to my collection. Can you give me specific advice on watering schedule, fertilizing, and repotting for this plant?';
                        await messagesRef.add({
                          'role': 'user',
                          'text': userText,
                          'imageUrl': '',
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => FloraScreen(conversationId: conversationId)));
                      },
                      icon: const Icon(Icons.psychology, color: AppColors.forest900),
                      label: Text(l.askFloraForAdvice, style: const TextStyle(color: AppColors.forest900, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.forest900),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () async {
                        await _saveSchedules(plantName, plantId, wateringVal, fertilizingVal, mistingVal);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3A7A52)
                            : AppColors.forest900,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l.saveCareSchedule, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),

                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Text(l.skipForNow, style: const TextStyle(color: AppColors.bone500)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSchedules(String plantName, String plantId, String watering, String fertilizing, String misting) async {
    final l = AppLocalizations.of(context);
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
        id: '', plantId: plantId, plantName: plantName, taskType: 'Watering',
        dueDate: now.add(const Duration(days: 1)), isCompleted: false, notes: '',
        repeatType: getRepeatType(watering),
      ));
    }

    if (fertilizing != 'Skip') {
      await _firestoreService.addTask(Task(
        id: '', plantId: plantId, plantName: plantName, taskType: 'Fertilizing',
        dueDate: now.add(const Duration(days: 14)), isCompleted: false, notes: '',
        repeatType: getRepeatType(fertilizing),
      ));
    }

    if (misting != 'Skip') {
      await _firestoreService.addTask(Task(
        id: '', plantId: plantId, plantName: plantName, taskType: 'Misting',
        dueDate: now.add(const Duration(days: 3)), isCompleted: false, notes: '',
        repeatType: getRepeatType(misting),
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.careScheduleSaved),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }
}
