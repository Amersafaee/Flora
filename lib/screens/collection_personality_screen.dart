import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class CollectionPersonalityScreen extends StatefulWidget {
  const CollectionPersonalityScreen({super.key});

  @override
  State<CollectionPersonalityScreen> createState() => _CollectionPersonalityScreenState();
}

class _CollectionPersonalityScreenState extends State<CollectionPersonalityScreen> {
  final Map<String, int> _categoryCounts = {};
  int _totalPlants = 0;
  String _personalityKey = 'buddingPlantParent';
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
      _personalityKey = 'buddingPlantParent';
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
        _personalityKey = 'masterConservatoryKeeper';
        _personalityIcon = Icons.emoji_events;
      } else if (dominantCategory.toLowerCase().contains('tropical') && _totalPlants > 5) {
        _personalityKey = 'tropicalRainforestCurator';
        _personalityIcon = Icons.park;
      } else if (dominantCategory.toLowerCase().contains('succulent') || dominantCategory.toLowerCase().contains('cactus')) {
        _personalityKey = 'desertGardenArchitect';
        _personalityIcon = Icons.wb_sunny;
      } else if (dominantCategory.toLowerCase().contains('fern')) {
        _personalityKey = 'shadeGardenSpecialist';
        _personalityIcon = Icons.nightlight_round;
      } else if (dominantCategory.toLowerCase().contains('herb')) {
        _personalityKey = 'urbanKitchenGardener';
        _personalityIcon = Icons.spa;
      } else {
        _personalityKey = 'buddingPlantParent';
        _personalityIcon = Icons.eco;
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _getTitle(AppLocalizations l) {
    switch (_personalityKey) {
      case 'masterConservatoryKeeper': return l.masterConservatoryKeeper;
      case 'tropicalRainforestCurator': return l.tropicalRainforestCurator;
      case 'desertGardenArchitect': return l.desertGardenArchitect;
      case 'shadeGardenSpecialist': return l.shadeGardenSpecialist;
      case 'urbanKitchenGardener': return l.urbanKitchenGardener;
      default: return l.buddingPlantParent;
    }
  }

  String _getDesc(AppLocalizations l) {
    switch (_personalityKey) {
      case 'masterConservatoryKeeper': return l.masterConservatoryKeeperDesc;
      case 'tropicalRainforestCurator': return l.tropicalRainforestCuratorDesc;
      case 'desertGardenArchitect': return l.desertGardenArchitectDesc;
      case 'shadeGardenSpecialist': return l.shadeGardenSpecialistDesc;
      case 'urbanKitchenGardener': return l.urbanKitchenGardenerDesc;
      default: return l.buddingPlantParentDesc;
    }
  }

  Future<void> _sharePersonality(AppLocalizations l) async {
    final title = _getTitle(l);
    final desc = _getDesc(l);
    final text = "I'm a $title on Digital Conservatory! $desc";
    // ignore: deprecated_member_use
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.forest900,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final personalityTitle = _getTitle(l);
    final personalityDescription = _getDesc(l);

    // Sort categories for chart
    final sortedCategories = _categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.forest700, AppColors.forest900],
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
                        personalityTitle,
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
                          personalityDescription,
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
                              Text(
                                l.topCategories,
                                style: TextStyle(
                                  color: Theme.of(context).cardColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ...sortedCategories.take(3).map((entry) {
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
                                                color: Theme.of(context).cardColor,
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
                        onPressed: () => _sharePersonality(l),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.forest900,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.share, size: 20),
                            const SizedBox(width: 8),
                            Text(l.shareMyPersonality, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
