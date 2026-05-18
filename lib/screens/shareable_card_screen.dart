import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/plant_model.dart';
import '../services/milestone_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class ShareableCardScreen extends StatefulWidget {
  final Plant plant;
  const ShareableCardScreen({super.key, required this.plant});

  @override
  State<ShareableCardScreen> createState() => _ShareableCardScreenState();
}

class _ShareableCardScreenState extends State<ShareableCardScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  Map<String, dynamic>? _cardData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirestoreService().currentUserId;
    if (uid != null) {
      final data = await MilestoneService().generateShareableCard(uid, widget.plant);
      setState(() {
        _cardData = data;
      });
    }
  }

  Future<void> _shareCard() async {
    final image = await _screenshotController.capture();
    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/share.png').create();
      await imagePath.writeAsBytes(image);
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(imagePath.path)], text: 'Check out my plant on Digital Conservatory!');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cardData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = _cardData!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Screenshot(
                controller: _screenshotController,
                child: Container(
                  width: 375,
                  height: 500,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A3A1A), AppColors.forest900],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20)), // For visually rounded corners, though Instagram post is often square, instructions say "centered on screen with a dark green gradient background".
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.eco, color: AppColors.forest900, size: 24),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.forest100,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          image: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(data['imageUrl']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: data['imageUrl'] == null || data['imageUrl'].toString().isEmpty
                            ? Icon(Icons.eco, size: 64, color: AppColors.forest900)
                            : null,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        data['plantName'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['commonName']?.toString().isNotEmpty == true ? data['commonName'] : data['category'],
                        style: const TextStyle(
                          color: AppColors.forest100,
                          fontStyle: FontStyle.italic,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatBox(data['healthScore'].toString(), 'Health'),
                          const SizedBox(width: 16),
                          _buildStatBox(data['daysSinceAdded'].toString(), 'Days Together'),
                          const SizedBox(width: 16),
                          _buildStatBox(data['totalGrowthEntries'].toString(), 'Check-ins'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        data['tagline'],
                        style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontStyle: FontStyle.italic,
                          fontSize: 18,
                          shadows: [
                            Shadow(
                              color: Colors.white.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Grown with Digital Conservatory',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.forest900,
                      side: const BorderSide(color: AppColors.forest900),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _shareCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Share Card'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
