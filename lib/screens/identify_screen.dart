import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import 'identify_result_screen.dart';

class IdentifyScreen extends StatefulWidget {
  const IdentifyScreen({super.key});

  @override
  State<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen> {
  static const Color _darkGreen = Color(0xFF154212);
  static const Color _softGreen = Color(0xFFE8F5E9);

  File? _selectedImage;
  bool _isAnalyzing = false;
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();

  static const String _analysisPrompt =
      'Please analyze this plant photo completely and provide: '
      '1. Plant species identification with common name and scientific name. '
      '2. Overall health score from 0 to 100 and health status. '
      '3. Any diseases, pests, nutrient deficiencies, or problems visible. '
      '4. Watering frequency recommendation specific to this plant. '
      '5. Light requirements. '
      '6. Soil type recommendation. '
      '7. Most urgent action needed if something is wrong, or a positive encouragement if everything looks healthy. '
      'Be specific and practical. Format with clear sections.';

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access image: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null || _isAnalyzing) return;
    setState(() => _isAnalyzing = true);
    try {
      final result =
          await _geminiService.analyzeePlantImage(_selectedImage!, _analysisPrompt);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IdentifyResultScreen(
              imageFile: _selectedImage!,
              analysisResult: result,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Analysis failed. Please try again.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _clearImage() => setState(() => _selectedImage = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Top 60%: image area ───────────────────────────────────────
          Expanded(
            flex: 6,
            child: _selectedImage == null
                ? _buildEmptyImageArea()
                : _buildSelectedImageArea(),
          ),

          // ── Bottom 40%: control panel ─────────────────────────────────
          Expanded(
            flex: 4,
            child: _buildControlPanel(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Empty state (no image selected)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyImageArea() {
    return Container(
      width: double.infinity,
      color: _softGreen,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: _darkGreen,
              ),
              const SizedBox(height: 16),
              const Text(
                'Analyze Your Plant',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _darkGreen,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPickerButton(
                    icon: Icons.camera_alt,
                    label: 'Take Photo',
                    onTap: () => _pickImage(ImageSource.camera),
                    filled: false,
                  ),
                  const SizedBox(width: 16),
                  _buildPickerButton(
                    icon: Icons.photo_library_outlined,
                    label: 'From Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                    filled: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: filled ? _darkGreen : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _darkGreen, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: filled ? Colors.white : _darkGreen, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : _darkGreen,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Image selected state
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSelectedImageArea() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Image.file(
            _selectedImage!,
            fit: BoxFit.cover,
          ),
        ),
        // Clear button – top left
        SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: GestureDetector(
                onTap: _clearImage,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Control panel (bottom 40%)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildControlPanel() {
    final bool hasImage = _selectedImage != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Spacer(),

            // Analyze button
            SizedBox(
              height: 56,
              child: _buildAnalyzeButton(hasImage),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton(bool hasImage) {
    if (!hasImage) {
      // Disabled state
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Select a Photo to Analyze',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Active / loading state
    return ElevatedButton(
      onPressed: _isAnalyzing ? null : _analyzeImage,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF154212),
        disabledBackgroundColor: const Color(0xFF154212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: _isAnalyzing
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Analyzing...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Analyze with Flora 🌿',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }
}
