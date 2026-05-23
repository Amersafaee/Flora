import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import 'identify_result_screen.dart';
import '../services/onboarding_service.dart';
import 'onboarding_overlay_screen.dart';
import '../theme/app_theme.dart';

class IdentifyScreen extends StatefulWidget {
  const IdentifyScreen({super.key});

  @override
  State<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen> {
  static const Color _darkGreen = AppColors.forest900;

  File? _selectedImage;
  bool _isAnalyzing = false;
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await OnboardingService.shouldShow('identify_screen')) {
        await OnboardingService.markShown('identify_screen');
        if (mounted) _showFeatureOnboarding();
      }
    });
  }

  void _showFeatureOnboarding() {
    final l = AppLocalizations.of(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => OnboardingOverlayScreen(
          title: l.welcomeToPlantScanner,
          description: l.plantScannerDescription,
          tips: [
            l.plantScannerTip1,
            l.plantScannerTip2,
            l.plantScannerTip3,
          ],
          featureKey: 'identify_screen',
        ),
      ),
    );
  }

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
            content: Text('${AppLocalizations.of(context).couldNotAccessImagePrefix}$e'),
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
      final languageCode = Localizations.localeOf(context).languageCode;
      final result = await _geminiService.analyzeePlantImage(
        _selectedImage!,
        _analysisPrompt,
        languageCode,
      );
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
            content: Text(AppLocalizations.of(context).analysisFailed),
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
      body: Stack(
        children: [
          Column(
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
          
          // × Close button – top left (FIX 3)
          if (_selectedImage == null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
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
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Empty state (no image selected)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyImageArea() {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 64,
                  color: _darkGreen,
                ),
                const SizedBox(height: 16),
                Text(
                  l.analyzeYourPlant,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _darkGreen,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Primary CTA (Take a photo)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Take a photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Secondary CTA (Choose from your photos)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.forest700, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text(
                      'Choose from your photos',
                      style: TextStyle(
                        color: AppColors.forest700,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        boxShadow: const [
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
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
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
    final l = AppLocalizations.of(context);
    if (!hasImage) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            l.selectPhotoToAnalyze,
            style: const TextStyle(
              color: AppColors.bone500,
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
        backgroundColor: AppColors.forest900,
        disabledBackgroundColor: AppColors.forest900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: _isAnalyzing
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l.analyzingLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  l.analyzeWithFlora,
                  style: const TextStyle(
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
