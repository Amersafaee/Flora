import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import 'add_plant_screen.dart';
import 'flora_screen.dart';
import 'wiki_plant_detail_screen.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class IdentifyResultScreen extends StatefulWidget {
  final File imageFile;
  final String analysisResult;

  const IdentifyResultScreen({
    super.key,
    required this.imageFile,
    required this.analysisResult,
  });

  @override
  State<IdentifyResultScreen> createState() => _IdentifyResultScreenState();
}

class _IdentifyResultScreenState extends State<IdentifyResultScreen> {
  bool _isOpeningFlora = false;

  // ── Health score extraction ───────────────────────────────────────────────
  static final RegExp _scorePattern = RegExp(
    r'(?:health\s+score[:\s]+|score[:\s]+)?(\d{1,3})\s*(?:\/\s*100|out\s+of\s+100)',
    caseSensitive: false,
  );

  int? _extractHealthScore() {
    final match = _scorePattern.firstMatch(widget.analysisResult);
    if (match != null) {
      final value = int.tryParse(match.group(1) ?? '');
      if (value != null && value >= 0 && value <= 100) return value;
    }
    return null;
  }

  Color _scoreColor(int score) {
    if (score >= 70) return AppColors.forest500;
    if (score >= 40) return const Color(0xFFC8893A);
    return AppColors.errorLight;
  }

  String _scoreLabel(int score, AppLocalizations l) {
    if (score > 70) return l.healthy;
    if (score >= 40) return l.needsAttention;
    return l.critical;
  }

  String _extractPlantName() {
    final patterns = [
      RegExp(r'(?:Plant Name|Species|Common Name|Name):\s*([^\n\r]+)', caseSensitive: false),
      RegExp(r'(?:This is a|This appears to be a|Identified as)\s+([A-Z][a-zA-Z\s]+?)(?:\.|,|\n)', caseSensitive: false),
      RegExp(r'\*\*([A-Z][a-zA-Z\s]+?)\*\*', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(widget.analysisResult);
      if (match != null) {
        final name = match.group(1)?.trim() ?? '';
        final rejectWords = ['identification', 'analysis', 'assessment', 'result', 'note', 'warning', 'however', 'please', 'the plant'];
        final nameLower = name.toLowerCase();
        if (name.isNotEmpty && !rejectWords.any((w) => nameLower.contains(w)) && name.length < 50) {
          return name;
        }
      }
    }
    return 'this plant';
  }

  String? _extractCommonName() {
    final pattern = RegExp(r'(?:common\s+name)[:\s*]+([A-Z][^\n,\.]{2,40})', caseSensitive: false);
    final m = pattern.firstMatch(widget.analysisResult);
    if (m != null) {
      final candidate = m.group(1)?.trim() ?? '';
      if (candidate.isNotEmpty && candidate.length < 40) return candidate;
    }
    return null;
  }

  String? _extractCategory() {
    final categories = ['Tropical', 'Succulent', 'Fern', 'Herb', 'Cactus', 'Other'];
    for (final cat in categories) {
      if (widget.analysisResult.toLowerCase().contains(cat.toLowerCase())) {
        return cat;
      }
    }
    return null;
  }

  String _extractHealthStatus() {
    final lower = widget.analysisResult.toLowerCase();
    if (lower.contains('critical') || lower.contains('severely') || lower.contains('dying')) {
      return 'Critical';
    }
    if (lower.contains('needs attention') || lower.contains('concerning') ||
        lower.contains('yellowing') || lower.contains('disease') ||
        lower.contains('pest')) {
      return 'Needs Attention';
    }
    return 'Healthy';
  }

  String _extractWateringFrequency() {
    final patterns = [
      RegExp(r'water(?:ing)?\s+every\s+(\d+(?:\s*[-\u2013]\s*\d+)?)\s*(day|week)', caseSensitive: false),
      RegExp(r'every\s+(\d+(?:\s*[-\u2013]\s*\d+)?)\s*(day|week)s?\s+water', caseSensitive: false),
      RegExp(r'(\d+(?:\s*[-\u2013]\s*\d+)?)\s*(day|week)s?\s+between\s+water', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(widget.analysisResult);
      if (match != null) {
        final number = match.group(1) ?? '7';
        final unit = match.group(2)?.toLowerCase() ?? 'day';
        if (unit.startsWith('week')) {
          final days = int.tryParse(number.split(RegExp(r'[-\u2013]')).first.trim()) ?? 1;
          return '${days * 7}';
        }
        return number.split(RegExp(r'[-\u2013]')).first.trim();
      }
    }
    return '7';
  }

  Future<void> _openFloraWithPlantContext() async {
    if (_isOpeningFlora) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.pleaseSignInToContinue),
            backgroundColor: AppColors.terracotta900,
          ),
        );
      }
      return;
    }

    setState(() => _isOpeningFlora = true);

    try {
      final plantName = _extractPlantName();
      final db = FirebaseFirestore.instance;
      final chatsRef = db.collection('users').doc(uid).collection('flora_chats');

      final docRef = await chatsRef.add({
        'title': 'About $plantName',
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': "Let's talk about your $plantName",
      });

      final conversationId = docRef.id;
      final messagesRef = chatsRef.doc(conversationId).collection('messages');

      await messagesRef.add({
        'role': 'user',
        'text': 'Please analyze this plant',
        'imageUrl': '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      final snippet = widget.analysisResult.length > 600
          ? '${widget.analysisResult.substring(0, 597)}…'
          : widget.analysisResult;

      final floraIntro =
          'Great news — I have already analyzed your photo! 🌿\n\n'
          'Here is what I found:\n\n'
          '$snippet\n\n'
          'Feel free to ask me anything else about $plantName — '
          'care tips, watering schedules, common issues, or anything you are curious about!';

      await messagesRef.add({
        'role': 'model',
        'text': floraIntro,
        'imageUrl': '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await docRef.update({
        'lastMessage': 'Flora has analyzed your plant',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FloraScreen(conversationId: conversationId)),
      );
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l.couldNotOpenFloraPrefix}$e'),
            backgroundColor: AppColors.terracotta900,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpeningFlora = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final int? healthScore = _extractHealthScore();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.forest900),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l.plantAnalysis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.forest900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Scrollable content ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Plant image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 220,
                        child: Image.file(widget.imageFile, fit: BoxFit.cover, width: double.infinity),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Analysis result card
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (healthScore != null) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                       Text(
                                        '$healthScore',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: _scoreColor(healthScore),
                                        ),
                                      ),
                                      Text(
                                        '/100',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.normal,
                                          color: _scoreColor(healthScore).withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _scoreColor(healthScore),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _scoreLabel(healthScore, l),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Divider(color: Theme.of(context).colorScheme.surfaceContainerHighest, height: 1),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              widget.analysisResult,
                              style: TextStyle(fontSize: 14.5, color: Theme.of(context).colorScheme.onSurface, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Wiki care guide link (if matching species found)
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('species').get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final docs = snapshot.data!.docs;
                        final pName = _extractPlantName().toLowerCase();

                        Map<String, dynamic>? match;
                        for (var d in docs) {
                          final data = d.data() as Map<String, dynamic>;
                          final sName = (data['name'] as String? ?? '').toLowerCase();
                          final cName = (data['commonName'] as String? ?? '').toLowerCase();
                          if (sName.isNotEmpty && (pName.contains(sName) || sName.contains(pName))) {
                            match = data; break;
                          }
                          if (cName.isNotEmpty && (pName.contains(cName) || cName.contains(pName))) {
                            match = data; break;
                          }
                        }

                        if (match == null) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => WikiPlantDetailScreen(plantData: match!)));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: AppColors.forest100, borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.menu_book, color: AppColors.forest600),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      l.readFullCareGuide,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.bone500),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // PRIMARY: Continue with Flora (FIX 4)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isOpeningFlora ? null : _openFloraWithPlantContext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          elevation: 0,
                        ),
                        child: _isOpeningFlora
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Continue with Flora',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // SECONDARY: Add to my garden (FIX 4)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () {
                          final plantName = _extractPlantName();
                          final commonName = _extractCommonName();
                          final category = _extractCategory();
                          final healthStatus = _extractHealthStatus();
                          final wateringDays = _extractWateringFrequency();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddPlantScreen(
                                initialPlantName: plantName == 'this plant' ? null : plantName,
                                initialCommonName: commonName,
                                initialCategory: category,
                                initialHealthStatus: healthStatus,
                                initialImageFile: widget.imageFile,
                                initialWateringDays: wateringDays,
                                analysisResult: widget.analysisResult,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.forest700, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        child: const Text(
                          'Add to my garden',
                          style: TextStyle(color: AppColors.forest700, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // TERTIARY: Analyse another plant (FIX 4)
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Analyse another plant',
                          style: TextStyle(
                            color: AppColors.forest600,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
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
