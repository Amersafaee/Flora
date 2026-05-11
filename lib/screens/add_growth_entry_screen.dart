import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
import '../services/notification_service.dart';
import '../models/treatment_case_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      };
      
      await _firestoreService.addGrowthEntry(widget.plantId, entry);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal entry saved'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }

      // Fire-and-forget background health assessment when an image is present
      if (imageUrl.isNotEmpty) {
        final capturedPlantId = widget.plantId;
        final capturedPlantName = widget.plantName;
        final capturedHealthStatus = widget.healthStatus;
        final capturedImageUrl = imageUrl;
        Future(() async {
          try {
            final assessment = await GeminiService().analyzeGrowthPhoto(
              imageUrl: capturedImageUrl,
              plantName: capturedPlantName,
              previousHealthStatus: capturedHealthStatus,
            );
            await FirestoreService()
                .saveHealthAssessment(capturedPlantId, assessment);

            // Create treatment case if needed
            final condition = assessment['condition']?.toString() ?? 'Healthy';
            if (condition == 'Needs Attention' || condition == 'Critical') {
              final existingCases = await FirestoreService()
                  .getTreatmentCases(capturedPlantId)
                  .first;

              final hasActive =
                  existingCases.any((c) => c.status == 'Active' || c.status == 'Monitoring');

              if (!hasActive) {
                final diagnosis = assessment['observations']?.toString() ??
                    'Health issue detected';
                final recs = assessment['recommendations']?.toString() ?? '';
                final steps = recs.isNotEmpty
                    ? recs.split(RegExp(r'\. |\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
                    : ['Follow general care guidelines'];

                final severity =
                    condition == 'Critical' ? 'Severe' : 'Moderate';

                final dates = [
                  DateTime.now().add(const Duration(days: 3)),
                  DateTime.now().add(const Duration(days: 7)),
                  DateTime.now().add(const Duration(days: 14)),
                ];

                final tCase = TreatmentCase(
                  id: '',
                  plantId: capturedPlantId,
                  plantName: capturedPlantName,
                  diagnosis: diagnosis,
                  severity: severity,
                  detectedDate: DateTime.now(),
                  status: 'Active',
                  treatmentSteps: steps,
                  followUpDates: dates,
                  progressNotes: [],
                  initialPhotoUrl: capturedImageUrl,
                  latestPhotoUrl: capturedImageUrl,
                );

                final newId = await FirestoreService().createTreatmentCase(tCase);

                // Schedule notifications
                for (var i = 0; i < dates.length; i++) {
                  await NotificationService().scheduleHealthCheckNotification(
                    '${newId}_$i',
                    capturedPlantName,
                    dates[i],
                  );
                }
              }
            }
          } catch (e) {
            debugPrint('Background health assessment error: $e');
          }
        });
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
                        'Add Journal Entry',
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
              
              // Plant Name Field (Readonly)
              Text(
                'Plant',
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                widget.plantName,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              
              // Height Field
              Text(
                'Height in cm',
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 64',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Leaves Field
              Text(
                'New Leaves',
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _leavesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 2',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Notes Field
              Text(
                'Notes',
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe how your plant looks today...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
              if (_showNotesError)
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'Please add a note about your plant.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 48),
              
              // Save Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveEntry,
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
                          'Save Entry',
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



