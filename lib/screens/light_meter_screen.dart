import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class LightMeterScreen extends StatefulWidget {
  const LightMeterScreen({super.key});
  @override
  State<LightMeterScreen> createState() => _LightMeterScreenState();
}

class _LightMeterScreenState extends State<LightMeterScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isMeasuring = false;
  bool _isDark = false;
  double _luxValue = 0;
  String _lightLevel = 'Tap Measure to start';
  String _lightDescription = 'Point your camera at the light source';
  Color _levelColor = AppColors.bone500;
  Timer? _measureTimer;
  final List<double> _recentReadings = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _startMeasuring() {
    if (_controller == null || !_isInitialized) return;
    setState(() => _isMeasuring = true);
    _recentReadings.clear();

    _controller!.startImageStream((CameraImage image) {
      _processImage(image);
    });

    _measureTimer = Timer(const Duration(seconds: 5), () {
      _stopMeasuring();
    });
  }

  void _processImage(CameraImage image) {
    try {
      final plane = image.planes.first;
      final bytes = plane.bytes;
      int total = 0;
      final sampleStep = (bytes.length / 500).ceil();
      int count = 0;
      for (int i = 0; i < bytes.length; i += sampleStep) {
        total += bytes[i];
        count++;
      }
      final avgBrightness = count > 0 ? total / count : 0;
      // Map 0-255 brightness to approximate lux range 0-50000
      final estimatedLux = (avgBrightness / 255) * 50000;

      if (mounted) {
        setState(() {
          _luxValue = estimatedLux;
          _recentReadings.add(estimatedLux);
          if (_recentReadings.length > 10) _recentReadings.removeAt(0);
          _updateLightLevel(estimatedLux);
        });
      }
    } catch (e) {
      debugPrint('Image processing error: $e');
    }
  }

  void _updateLightLevel(double lux) {
    if (lux < 500) {
      _lightLevel = 'Low Light';
      _lightDescription = 'Good for shade-tolerant plants like Pothos and Snake Plant';
      // Low light → cool blue-toned neutral
      _levelColor = _isDark ? AppColors.darkTextSecondary : AppColors.bone500;
    } else if (lux < 2500) {
      _lightLevel = 'Medium Light';
      _lightDescription = 'Ideal for Peace Lily, Philodendron and most Ferns';
      // Medium light → warm amber/warning
      _levelColor = _isDark ? AppColors.warningDark : AppColors.warningLight;
    } else if (lux < 10000) {
      _lightLevel = 'Bright Indirect';
      _lightDescription = 'Perfect for Monstera, Pothos and most tropical plants';
      // Bright indirect → healthy forest green
      _levelColor = _isDark ? AppColors.darkForestPrimary : AppColors.forest600;
    } else if (lux < 25000) {
      _lightLevel = 'Bright Direct';
      _lightDescription = 'Great for succulents, cacti and herbs';
      // Bright direct → strong warning
      _levelColor = _isDark ? AppColors.warningDark : AppColors.warning;
    } else {
      _lightLevel = 'Very Intense';
      _lightDescription = 'Too bright for most houseplants — risk of leaf scorch';
      // Very intense → error/danger
      _levelColor = _isDark ? AppColors.errorDark : AppColors.errorLight;
    }
  }

  void _stopMeasuring() {
    _measureTimer?.cancel();
    try {
      _controller?.stopImageStream();
    } catch (_) {}
    if (mounted) setState(() => _isMeasuring = false);
  }

  double get _averageLux {
    if (_recentReadings.isEmpty) return _luxValue;
    return _recentReadings.reduce((a, b) => a + b) / _recentReadings.length;
  }

  double get _gaugeValue {
    return (_averageLux / 50000).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _measureTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Light Meter',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Gauge
              Center(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: CircularProgressIndicator(
                          value: _gaugeValue,
                          strokeWidth: 14,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(_levelColor),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _averageLux > 10000 ? Icons.wb_sunny : _averageLux > 2500 ? Icons.wb_cloudy : Icons.nights_stay,
                            color: _levelColor,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _lightLevel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _levelColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_averageLux.toStringAsFixed(0)} lx',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Description card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _levelColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.eco, color: _levelColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _lightDescription,
                          style: TextStyle(fontSize: 14, height: 1.4, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Measure button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isMeasuring ? _stopMeasuring : _startMeasuring,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isMeasuring
                          ? (_isDark ? AppColors.errorDark : AppColors.errorLight)
                          : primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isMeasuring ? Icons.stop : Icons.camera_alt_outlined, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          _isMeasuring ? 'Stop Measuring' : 'Measure Light',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_isMeasuring)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                      ),
                      const SizedBox(width: 8),
                      Text('Measuring for 5 seconds...', style: TextStyle(color: AppColors.bone500)),
                    ],
                  ),
                ),

              if (!_isMeasuring && _luxValue > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 20, right: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showSaveToPlantSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forest100,
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.eco, color: primaryColor),
                          const SizedBox(width: 12),
                          const Text('Save to a Plant 🌿', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaveToPlantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return const SizedBox();
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3), borderRadius: const BorderRadius.all(Radius.circular(2))),
                  ),
                ),
                const Text('Save Light Reading', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Center(child: Text('No plants found.'));
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final isDeceased = data['isDeceased'] == true;
                          if (isDeceased) return const SizedBox.shrink();
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.forest100,
                              backgroundImage: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                                  ? NetworkImage(data['imageUrl'])
                                  : null,
                              child: data['imageUrl'] == null || data['imageUrl'].toString().isEmpty
                                  ? const Icon(Icons.eco, color: AppColors.forest900)
                                  : null,
                            ),
                            title: Text(data['name'] ?? 'Unknown'),
                            subtitle: Text(data['category'] ?? 'Plant'),
                            trailing: const Icon(Icons.check_circle_outline, color: AppColors.bone500),
                            onTap: () async {
                              Navigator.pop(context);
                              await FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').doc(docs[index].id).update({
                                'lastLightReading': _averageLux,
                                'lastLightReadingLabel': _lightLevel,
                                'lastLightReadingDate': FieldValue.serverTimestamp(),
                              });
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Light reading saved to ${data['name']} 🌿'),
                                    backgroundColor: AppColors.forest900,
                                  ),
                                );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
