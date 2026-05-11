import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_plant_screen.dart';
import 'flora_screen.dart';

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
    if (score > 70) return const Color(0xFF2E7D32);
    if (score >= 40) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  String _scoreLabel(int score) {
    if (score > 70) return 'Healthy';
    if (score >= 40) return 'Needs Attention';
    return 'Critical';
  }

  /// Tries to pull the first meaningful noun from the analysis result to use
  /// as the plant name in the conversation title. Falls back to "this plant".
  String _extractPlantName() {
    // Look for "Plant Name: X", "Species: X", or "**X**" patterns
    final namePatterns = [
      RegExp(r'(?:plant\s+name|species|identified as)[:\s*]+([A-Z][^\n,\.]{2,40})', caseSensitive: false),
      RegExp(r'\*\*([A-Z][a-zA-Z\s]{2,35})\*\*'),
    ];
    for (final pattern in namePatterns) {
      final m = pattern.firstMatch(widget.analysisResult);
      if (m != null) {
        final candidate = m.group(1)?.trim() ?? '';
        if (candidate.isNotEmpty && candidate.length < 40) return candidate;
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

  /// Creates a new Flora conversation pre-seeded with the identify result,
  /// then navigates directly into the chat.
  Future<void> _openFloraWithPlantContext() async {
    if (_isOpeningFlora) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to continue with Flora.'),
            backgroundColor: Color(0xFF8D3220),
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

      // 1. Create the conversation document
      final docRef = await chatsRef.add({
        'title': 'About $plantName',
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': "Let's talk about your $plantName",
      });

      final conversationId = docRef.id;
      final messagesRef = chatsRef.doc(conversationId).collection('messages');

      // 2. Save the user's photo as the first message (mirrors the identify action)
      await messagesRef.add({
        'role': 'user',
        'text': 'Please analyze this plant',
        'imageUrl': '', // local file — no remote URL available at this point
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 3. Save Flora's warm introduction as the seeded model reply
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

      // 4. Update the conversation's lastMessage preview
      await docRef.update({
        'lastMessage': 'Flora has analyzed your plant',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // 5. Navigate into the pre-seeded conversation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FloraScreen(conversationId: conversationId),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Flora: $e'),
            backgroundColor: const Color(0xFF8D3220),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpeningFlora = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF154212)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Plant Analysis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF154212),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balance
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
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Analysis result card
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Health score badge (if extracted)
                            if (healthScore != null) ...[
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _scoreColor(healthScore)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$healthScore',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: _scoreColor(healthScore),
                                            height: 1,
                                          ),
                                        ),
                                        Text(
                                          '/100',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _scoreColor(healthScore)
                                                .withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _scoreLabel(healthScore),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: _scoreColor(healthScore),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Divider(color: Colors.grey.shade100, height: 1),
                              const SizedBox(height: 16),
                            ],

                            // Full response text
                            Text(
                              widget.analysisResult,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Action buttons ───────────────────────────────────
                    // Add to My Collection
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final plantName = _extractPlantName();
                          final commonName = _extractCommonName();
                          final category = _extractCategory();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddPlantScreen(
                                initialPlantName: plantName == 'this plant' ? null : plantName,
                                initialCommonName: commonName,
                                initialCategory: category,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF154212),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.white, size: 20),
                        label: const Text(
                          'Add to My Collection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Analyze Another
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFF154212), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.refresh,
                            color: Color(0xFF154212), size: 20),
                        label: const Text(
                          'Analyze Another',
                          style: TextStyle(
                            color: Color(0xFF154212),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Continue with Flora — pre-seeds a new conversation
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isOpeningFlora ? null : _openFloraWithPlantContext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          disabledBackgroundColor:
                              const Color(0xFF2E7D32).withValues(alpha: 0.55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        icon: _isOpeningFlora
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.eco,
                                color: Colors.white, size: 20),
                        label: Text(
                          _isOpeningFlora ? 'Opening Flora…' : 'Continue with Flora 🌿',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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
