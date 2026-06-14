import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import 'identify_result_screen.dart';
import '../services/onboarding_service.dart';
import 'onboarding_overlay_screen.dart';
import '../theme/app_theme.dart';
import '../utils/toast_utils.dart';

class IdentifyScreen extends StatefulWidget {
  const IdentifyScreen({super.key});

  @override
  State<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen> {
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
        showToast(context, '${AppLocalizations.of(context).couldNotAccessImagePrefix}$e', isError: true);
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
        showToast(context, AppLocalizations.of(context).analysisFailed, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _clearImage() => setState(() => _selectedImage = null);

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
          l.identifyPlant,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
          ),
        ),
        centerTitle: false,
        actions: _selectedImage != null
            ? [
                IconButton(
                  icon: const Icon(CupertinoIcons.trash, size: 20, color: AppColors.terracotta700),
                  onPressed: _clearImage,
                )
              ]
            : null,
      ),
      body: SafeArea(
        child: _selectedImage == null
            ? _buildEmptyState()
            : Column(
                children: [
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 4,
                    child: _buildControlPanel(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.camera,
              size: 56,
              color: AppColors.forest200,
            ),
            const SizedBox(height: 16),
            Text(
              l.analyzeYourPlant,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.forest800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Take a picture or select an existing photo of your plant.",
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.bone400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _pickImage(ImageSource.camera),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text(
                  l.takePhoto,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.forest700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text(
                  l.chooseFromGallery,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    final bool hasImage = _selectedImage != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A224A1E),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.bone200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 52,
              child: _buildAnalyzeButton(hasImage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton(bool hasImage) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!hasImage) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.bone100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            l.selectPhotoToAnalyze,
            style: GoogleFonts.outfit(
              color: AppColors.bone400,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _isAnalyzing ? null : _analyzeImage,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.forest700,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                    strokeWidth: 2,
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
                  l.analyzeWithVerdoro,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}
