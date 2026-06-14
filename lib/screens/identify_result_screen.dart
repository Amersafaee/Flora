import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'add_plant_screen.dart';
import 'verdoro_screen.dart';
import 'wiki_plant_detail_screen.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/toast_utils.dart';
import '../widgets/shared/analysis_card_view.dart';

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
  bool _isOpeningVerdoro = false;

  // -- Section parsers -------------------------------------------------------

  Map<String, String> _parseSections() {
    final raw = widget.analysisResult;
    final labels = [
      'Plant identified:',
      'Health score:',
      'Status:',
      'What I can see:',
      'Most urgent action:',
      'Care tip:',
    ];

    final result = <String, String>{};

    for (int i = 0; i < labels.length; i++) {
      final label = labels[i];
      final labelIdx = raw.toLowerCase().indexOf(label.toLowerCase());
      if (labelIdx == -1) continue;

      final contentStart = labelIdx + label.length;
      int contentEnd = raw.length;
      for (int j = i + 1; j < labels.length; j++) {
        final nextIdx = raw.toLowerCase().indexOf(labels[j].toLowerCase(), contentStart);
        if (nextIdx != -1 && nextIdx < contentEnd) {
          contentEnd = nextIdx;
        }
      }

      final key = label.replaceAll(':', '').trim();
      result[key] = raw.substring(contentStart, contentEnd).trim();
    }

    return result;
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
    final sections = _parseSections();
    if (sections.containsKey('Plant identified')) {
      final val = sections['Plant identified']!.split('\n').first.trim();
      if (val.isNotEmpty && val.length < 60) return val;
    }
    final pattern = RegExp(r'(?:common\s+name)[:\s*]+([A-Z][^\n,\.]{2,40})', caseSensitive: false);
    final m = pattern.firstMatch(widget.analysisResult);
    if (m != null) {
      final candidate = m.group(1)?.trim() ?? '';
      if (candidate.isNotEmpty && candidate.length < 40) return candidate;
    }
    return null;
  }

  String? _extractScientificName() {
    final pattern = RegExp(
      r'(?:scientific\s+name|species)[:\s*]+([A-Z][a-z]+(?:\s+[a-z]+)+)',
      caseSensitive: false,
    );
    final m = pattern.firstMatch(widget.analysisResult);
    if (m != null) {
      final candidate = m.group(1)?.trim() ?? '';
      if (candidate.isNotEmpty && candidate.length < 60) return candidate;
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
    return 'Other';
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

  Future<void> _openVerdoroWithPlantContext() async {
    if (_isOpeningVerdoro) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        showToast(context, l.pleaseSignInToContinue, isError: true);
      }
      return;
    }

    setState(() => _isOpeningVerdoro = true);

    try {
      final plantName = _extractPlantName();
      final db = FirebaseFirestore.instance;
      final chatsRef = db.collection('users').doc(uid).collection('verdoro_chats');

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
          ? '${widget.analysisResult.substring(0, 597)}�'
          : widget.analysisResult;

      final verdoroIntro =
          'Great news � I have already analyzed your photo! ??\n\n'
          'Here is what I found:\n\n'
          '$snippet\n\n'
          'Feel free to ask me anything else about $plantName � '
          'care tips, watering schedules, common issues, or anything you are curious about!';

      await messagesRef.add({
        'role': 'model',
        'text': verdoroIntro,
        'imageUrl': '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await docRef.update({
        'lastMessage': 'Verdoro has analyzed your plant',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VerdoroScreen(conversationId: conversationId)),
      );
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        showToast(context, '${l.couldNotOpenVerdoroPrefix}$e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isOpeningVerdoro = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final commonName = _extractCommonName();
    final scientificName = _extractScientificName();
    final healthStatus = _extractHealthStatus();

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
          l.plantAnalysis,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Plant image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.forest100,
                        child: Image.file(widget.imageFile, fit: BoxFit.cover, width: double.infinity),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Main analysis card
                    AnalysisCardView(rawText: widget.analysisResult),
                    const SizedBox(height: 16),

                    // Wiki care guide link
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
                                color: isDark ? AppColors.darkSurface : AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A224A1E),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
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
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? AppColors.darkTextPrimary : AppColors.forest900),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.bone400),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),

                    // Continue with Verdoro button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isOpeningVerdoro ? null : _openVerdoroWithPlantContext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isOpeningVerdoro
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Continue with Verdoro',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Add to my garden button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          final plantName = _extractPlantName();
                          final category = _extractCategory();
                          final wateringDays = _extractWateringFrequency();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddPlantScreen(
                                initialPlantName: plantName == 'this plant' ? null : plantName,
                                initialCommonName: commonName,
                                initialScientificName: scientificName,
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
                          side: const BorderSide(color: AppColors.forest700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Add to my garden',
                          style: GoogleFonts.outfit(color: AppColors.forest700, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Analyze another plant button
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Analyze another plant',
                          style: GoogleFonts.outfit(
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
