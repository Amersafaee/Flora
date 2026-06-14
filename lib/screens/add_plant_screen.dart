import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/badges_service.dart';
import '../models/plant_model.dart';
import '../models/task_model.dart';
import 'verdoro_screen.dart';
import '../theme/app_theme.dart';
import '../utils/care_type_style.dart';
import '../utils/toast_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AddPlantScreen extends StatefulWidget {
  final String? initialPlantName;
  final String? initialCommonName;
  /// Scientific name � pre-fills the same field as [initialCommonName].
  /// When both are supplied, [initialScientificName] takes precedence.
  final String? initialScientificName;
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
    this.initialScientificName,
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

  // Internal Firestore values � must stay English
  String _selectedCategory = 'Tropical';
  String _selectedHealthStatus = 'Healthy';

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
    // initialScientificName takes precedence over initialCommonName
    _commonNameController = TextEditingController(
      text: widget.initialScientificName ?? widget.initialCommonName ?? '',
    );

    if (widget.initialCategory != null &&
        ['Tropical', 'Succulent', 'Fern', 'Herb', 'Cactus', 'Other'].contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
    }

    if (widget.initialHealthStatus != null &&
        ['Healthy', 'Needs Attention', 'Critical', 'Recovering'].contains(widget.initialHealthStatus)) {
      _selectedHealthStatus = widget.initialHealthStatus!;
    }

    if (widget.initialImageFile != null) {
      _imageFile = widget.initialImageFile;
    } else if (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty) {
      _initialImageUrl = widget.initialImageUrl!;
    }

    if (widget.initialWateringDays != null && widget.initialWateringDays!.isNotEmpty) {
      _initialWateringDays = widget.initialWateringDays!;
    }
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
        zoneId: null,
        imageUrl: imageUrl,
        healthStatus: _selectedHealthStatus,
        dateAdded: DateTime.now(),
      );

      await _firestoreService.addPlant(plant);

      // Award badges for plant milestones � fire and forget, never blocks the UI
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
        showToast(context, '${l.somethingWentWrong} ${l.pleaseTryAgain}', isError: true);
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

    // Localized display labels for category (Firestore value stays English)
    final List<Map<String, String>> categories = [
      {'value': 'Tropical', 'label': 'Tropical'},
      {'value': 'Succulent', 'label': 'Succulent'},
      {'value': 'Fern', 'label': 'Fern'},
      {'value': 'Herb', 'label': 'Herb'},
      {'value': 'Cactus', 'label': 'Cactus'},
      {'value': 'Other', 'label': 'Other'},
    ];

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
          l.addPlant,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
          ),
        ),
        centerTitle: true,
      ),
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
                    // Image Picker
                    GestureDetector(
                      onTap: () async {
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
                        if (!mounted) return;
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
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.forest100,
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
                    Text(l.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: GoogleFonts.outfit(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
                      ),
                      onChanged: (value) {
                        if (_showNameError && value.trim().isNotEmpty) {
                          setState(() {
                            _showNameError = false;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: l.plantNameFieldHint,
                        hintStyle: const TextStyle(color: AppColors.bone300),
                        filled: true,
                        fillColor: AppColors.bone100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.forest700, width: 1.5)),
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
                      style: GoogleFonts.outfit(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).scientificNameOptional,
                        hintStyle: const TextStyle(color: AppColors.bone300),
                        filled: true,
                        fillColor: AppColors.bone100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.forest700, width: 1.5)),
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
                    const SizedBox(height: 20),

                    // Health Status
                    Text(
                      l.healthStatus,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                          value: _selectedHealthStatus,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: [
                            DropdownMenuItem(value: 'Healthy',         child: Text(l.healthy)),
                            DropdownMenuItem(value: 'Needs Attention', child: Text(l.needsAttention)),
                            DropdownMenuItem(value: 'Critical',        child: Text(l.critical)),
                            DropdownMenuItem(value: 'Recovering',      child: Text(l.recoveringStatus)),
                          ],
                          onChanged: (newValue) {
                            setState(() { if (newValue != null) _selectedHealthStatus = newValue; });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _savePlant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                l.savePlant,
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                      'Set up care for $plantName ??',
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

                    _buildCareRow(l.watering, careTypeStyle('watering'), wateringVal, options, (val) {
                      setSheetState(() => wateringVal = val!);
                    }),
                    const SizedBox(height: 16),
                    _buildCareRow(l.fertilizing, careTypeStyle('fertilizing'), fertilizingVal, options, (val) {
                      setSheetState(() => fertilizingVal = val!);
                    }),
                    const SizedBox(height: 16),
                    _buildCareRow(l.misting, careTypeStyle('misting'), mistingVal, options, (val) {
                      setSheetState(() => mistingVal = val!);
                    }),

                    const SizedBox(height: 32),

                    OutlinedButton.icon(
                      onPressed: () async {
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid == null) return;
                        final pName = _nameController.text.trim().isEmpty ? 'your plant' : _nameController.text.trim();
                        final db = FirebaseFirestore.instance;
                        final chatsRef = db.collection('users').doc(uid).collection('verdoro_chats');
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
                        Navigator.push(context, MaterialPageRoute(builder: (_) => VerdoroScreen(conversationId: conversationId)));
                      },
                      icon: const Icon(Icons.psychology, color: AppColors.forest900),
                      label: Text(l.askVerdoroForAdvice, style: const TextStyle(color: AppColors.forest900, fontWeight: FontWeight.bold)),
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

  /// Returns the localised display label for a frequency option key.
  String _freqLabel(BuildContext ctx, String opt) {
    final l = AppLocalizations.of(ctx);
    switch (opt) {
      case 'Every day':    return l.everyDay;
      case 'Every 2 days': return l.every2Days;
      case 'Every 3 days': return l.every3Days;
      case 'Weekly':       return l.weekly;
      case 'Every 2 weeks': return l.everyTwoWeeks;
      case 'Monthly':      return l.monthly;
      case 'Skip':         return l.skip;
      default:             return opt;
    }
  }

  /// Shows a custom bottom-sheet picker for frequency options.
  /// [currentValue] is the currently-selected option key.
  /// [options] is the full list of option keys.
  /// [onPicked] is called with the newly-selected key; the sheet pops itself.
  void _showFrequencyPicker(
    BuildContext sheetContext,
    String currentValue,
    List<String> options,
    ValueChanged<String> onPicked,
  ) {
    showModalBottomSheet<void>(
      context: sheetContext,
      backgroundColor: AppColors.bone50,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (pickerCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.bone300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ...options.map((opt) {
                final isSelected = opt == currentValue;
                return ListTile(
                  title: Text(
                    _freqLabel(pickerCtx, opt),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.forest700 : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(CupertinoIcons.checkmark, color: AppColors.forest700, size: 18)
                      : null,
                  onTap: () {
                    Navigator.pop(pickerCtx);
                    onPicked(opt);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCareRow(
    String title,
    CareTypeStyle style,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return InkWell(
      onTap: () => _showFrequencyPicker(
        context,
        value,
        options,
        (picked) => onChanged(picked),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: style.tileColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(style.icon, color: style.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Text(
              _freqLabel(context, value),
              style: const TextStyle(
                color: AppColors.forest700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.chevron_forward,
              color: AppColors.forest700,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  int _parseCareOffset(String? careFrequency, int defaultDays) {
    if (careFrequency == null || careFrequency.isEmpty) return defaultDays;
    final normalized = careFrequency.toLowerCase();
    if (normalized.contains('daily') || normalized.contains('every day')) {
      return 1;
    }
    if (normalized.contains('every 2')) {
      return 2;
    }
    if (normalized.contains('every 3')) {
      return 3;
    }
    if (normalized.contains('weekly') || normalized.contains('every week') || normalized.contains('every 7')) {
      return 7;
    }
    if (normalized.contains('every 10')) {
      return 10;
    }
    if (normalized.contains('every 14') || normalized.contains('biweekly') || normalized.contains('fortnightly')) {
      return 14;
    }
    if (normalized.contains('monthly') || normalized.contains('every month') || normalized.contains('every 30')) {
      return 30;
    }
    return defaultDays;
  }

  Future<void> _saveSchedules(String plantName, String plantId, String watering, String fertilizing, String misting) async {
    // Capture context-dependent values BEFORE any await so they remain valid
    // even if the widget is disposed while Firestore writes are in flight.
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
        dueDate: now.add(Duration(days: _parseCareOffset(watering, 1))), isCompleted: false, notes: '',
        repeatType: getRepeatType(watering),
      ));
    }
    if (!mounted) return;

    if (fertilizing != 'Skip') {
      await _firestoreService.addTask(Task(
        id: '', plantId: plantId, plantName: plantName, taskType: 'Fertilizing',
        dueDate: now.add(Duration(days: _parseCareOffset(fertilizing, 14))), isCompleted: false, notes: '',
        repeatType: getRepeatType(fertilizing),
      ));
    }
    if (!mounted) return;

    if (misting != 'Skip') {
      await _firestoreService.addTask(Task(
        id: '', plantId: plantId, plantName: plantName, taskType: 'Misting',
        dueDate: now.add(Duration(days: _parseCareOffset(misting, 3))), isCompleted: false, notes: '',
        repeatType: getRepeatType(misting),
      ));
    }

    if (mounted) {
      showToast(context, l.careScheduleSaved, isError: false);
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }
}
