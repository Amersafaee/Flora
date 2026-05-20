import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/gemini_service.dart';
import '../../screens/identify_result_screen.dart';
import '../../theme/app_theme.dart';

class IdentifyScreen extends StatefulWidget {
  const IdentifyScreen({super.key});

  @override
  State<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _isFrontCamera = false;
  bool _flashOn = false;
  
  String _mode = 'species'; // 'species' or 'disease'
  bool _isLoading = false;
  
  late AnimationController _dotsController;
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _setCamera(_cameras!.first);
      }
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _setCamera(CameraDescription desc) async {
    _controller = CameraController(desc, ResolutionPreset.high, enableAudio: false);
    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isCameraReady = true);
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  void _flipCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    _isFrontCamera = !_isFrontCamera;
    final target = _cameras!.firstWhere(
      (c) => c.lensDirection == (_isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => _cameras!.first,
    );
    _isCameraReady = false;
    setState(() {});
    _setCamera(target);
  }

  void _toggleFlash() {
    if (_controller == null || !_isCameraReady) return;
    _flashOn = !_flashOn;
    _controller!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Future<void> _captureOrPick({required bool fromGallery}) async {
    final l10n = AppLocalizations.of(context);
    XFile? file;
    if (fromGallery) {
      file = await _picker.pickImage(source: ImageSource.gallery);
    } else {
      if (_controller == null || !_controller!.value.isInitialized) return;
      try {
        file = await _controller!.takePicture();
      } catch (e) {
        _showError(l10n.failedToCapturePhoto);
        return;
      }
    }

    if (file == null) return;

    setState(() => _isLoading = true);
    
    try {
      final imageFile = File(file.path);
      final question = _mode == 'species'
          ? "Please identify this plant. Tell me its common name, scientific name, a brief description, and key care tips including light, watering, and soil requirements. Keep the response friendly and practical."
          : "Please analyze this plant photo for any signs of disease, pests, or health problems. Tell me what you see, how serious it is, and give me practical treatment steps I can follow at home. If the plant looks healthy just confirm that.";

      final responseText = await _geminiService.analyzeePlantImage(imageFile, question);

      if (!mounted) return;
      setState(() => _isLoading = false);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IdentifyResultScreen(
            imageFile: imageFile,
            analysisResult: responseText,
          ),
        ),
      );
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(AppLocalizations.of(context).failedToIdentifyPrefix(e.toString()));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
    ));
  }

  Widget _buildAnimatedDot(int index) {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        final double val = (_dotsController.value * 3) - index;
        final double active = (val >= 0 && val <= 1) ? 1.0 : 0.0;
        
        return Transform.translate(
          offset: Offset(0, -5 * active),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.leafGreen,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        color: AppColors.darkBackground,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(l10n.cameraAccessRequired, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initCamera,
                child: Text(l10n.grantAccess),
              )
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Camera Preview
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CameraPreview(_controller!),
        ),

        // Corner Brackets
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(60),
            child: CustomPaint(painter: _BracketPainter()),
          ),
        ),

        // Top Buttons
        Positioned(
          top: 40,
          right: 20,
          child: Column(
            children: [
              IconButton(
                icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                onPressed: _toggleFlash,
              ),
              IconButton(
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                onPressed: _flipCamera,
              ),
            ],
          ),
        ),

        // Bottom Controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Toggle Pill
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: AppRadius.borderPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ModeToggle(
                        title: l10n.idSpeciesMode,
                        isActive: _mode == 'species',
                        onTap: () => setState(() => _mode = 'species'),
                      ),
                      _ModeToggle(
                        title: l10n.detectDiseaseMode,
                        isActive: _mode == 'disease',
                        onTap: () => setState(() => _mode = 'disease'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Capture Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () => _captureOrPick(fromGallery: false),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
                    ),
                    child: Text(l10n.captureAndIdentify, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Gallery Link
                GestureDetector(
                  onTap: () => _captureOrPick(fromGallery: true),
                  child: Text(
                    l10n.orPickFromGallery,
                    style: const TextStyle(color: AppColors.moss, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Loading Overlay
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAnimatedDot(0),
                          const SizedBox(width: 8),
                          _buildAnimatedDot(1),
                          const SizedBox(width: 8),
                          _buildAnimatedDot(2),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.analyzingYourPlant,
                        style: const TextStyle(
                          color: AppColors.forestGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeToggle({required this.title, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.forestGreen : Colors.transparent,
          borderRadius: AppRadius.borderPill,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.moss,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
      
    const d = 30.0;
    
    // Top Left
    canvas.drawPath(Path()..moveTo(0, d)..lineTo(0, 0)..lineTo(d, 0), paint);
    // Top Right
    canvas.drawPath(Path()..moveTo(size.width - d, 0)..lineTo(size.width, 0)..lineTo(size.width, d), paint);
    // Bottom Left
    canvas.drawPath(Path()..moveTo(0, size.height - d)..lineTo(0, size.height)..lineTo(d, size.height), paint);
    // Bottom Right
    canvas.drawPath(Path()..moveTo(size.width - d, size.height)..lineTo(size.width, size.height)..lineTo(size.width, size.height - d), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
