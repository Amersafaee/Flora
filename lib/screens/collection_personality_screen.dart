import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/firestore_service.dart';

class CollectionPersonalityScreen extends StatefulWidget {
  const CollectionPersonalityScreen({super.key});

  @override
  State<CollectionPersonalityScreen> createState() => _CollectionPersonalityScreenState();
}

class _CollectionPersonalityScreenState extends State<CollectionPersonalityScreen> {
  final Map<String, int> _categoryCounts = {};
  int _totalPlants = 0;
  String _personalityTitle = '';
  String _personalityDescription = '';
  IconData _personalityIcon = Icons.eco;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _analyzeCollection();
  }

  Future<void> _analyzeCollection() async {
    final uid = FirestoreService().currentUserId;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    final stream = FirestoreService().getPlants();
    final plants = await stream.first;
    
    // Only count active plants for personality
    final activePlants = plants.where((p) => !p.isDeceased).toList();
    _totalPlants = activePlants.length;

    for (var p in activePlants) {
      final cat = p.category.trim();
      if (cat.isNotEmpty) {
        _categoryCounts[cat] = (_categoryCounts[cat] ?? 0) + 1;
      }
    }

    if (_totalPlants < 3) {
      _personalityTitle = "Budding Plant Parent";
      _personalityDescription = "Every great conservatory starts somewhere. You are at the beginning of a beautiful journey.";
      _personalityIcon = Icons.eco;
    } else {
      String dominantCategory = '';
      int maxCount = 0;
      _categoryCounts.forEach((key, value) {
        if (value > maxCount) {
          maxCount = value;
          dominantCategory = key;
        }
      });

      if (_totalPlants > 10 && (maxCount.toDouble() / _totalPlants) < 0.5) {
        // More than 10 plants and no category makes up more than 50%
        _personalityTitle = "Master Conservatory Keeper";
        _personalityDescription = "Your diverse collection shows true botanical expertise. You understand that every plant has its own needs and you meet them all.";
        _personalityIcon = Icons.emoji_events;
      } else if (dominantCategory.toLowerCase().contains('tropical') && _totalPlants > 5) {
        _personalityTitle = "Tropical Rainforest Curator";
        _personalityDescription = "You have a passion for lush dramatic plants that bring the jungle indoors. Your collection is bold and statement-making.";
        _personalityIcon = Icons.park;
      } else if (dominantCategory.toLowerCase().contains('succulent') || dominantCategory.toLowerCase().contains('cactus')) {
        _personalityTitle = "Desert Garden Architect";
        _personalityDescription = "You appreciate resilience and minimalist beauty. Your collection is low-maintenance and timelessly elegant.";
        _personalityIcon = Icons.wb_sunny;
      } else if (dominantCategory.toLowerCase().contains('fern')) {
        _personalityTitle = "Shade Garden Specialist";
        _personalityDescription = "You have mastered the art of thriving in low light. Your collection is soft textured and wonderfully calming.";
        _personalityIcon = Icons.nightlight_round;
      } else if (dominantCategory.toLowerCase().contains('herb')) {
        _personalityTitle = "Urban Kitchen Gardener";
        _personalityDescription = "Your plants are both beautiful and practical. You grow with purpose and your kitchen thanks you for it.";
        _personalityIcon = Icons.spa;
      } else {
        _personalityTitle = "Budding Plant Parent";
        _personalityDescription = "Every great conservatory starts somewhere. You are at the beginning of a beautiful journey.";
        _personalityIcon = Icons.eco;
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _sharePersonality() async {
    final text = "I'm a $_personalityTitle on Digital Conservatory! $_personalityDescription";
    // ignore: deprecated_member_use
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF154212),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // Sort categories for chart
    final sortedCategories = _categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2D5A27), Color(0xFF154212)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Icon(_personalityIcon, size: 100, color: Colors.white),
                      const SizedBox(height: 32),
                      Text(
                        _personalityTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          _personalityDescription,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 48),
                      if (sortedCategories.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Collection Breakdown',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ...sortedCategories.map((entry) {
                                final ratio = entry.value / _totalPlants;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(color: Colors.white),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              width: (MediaQuery.of(context).size.width - 200) * ratio,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 24,
                                        child: Text(
                                          entry.value.toString(),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      ElevatedButton(
                        onPressed: _sharePersonality,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF154212),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.share, size: 20),
                            SizedBox(width: 8),
                            Text('Share My Personality', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
