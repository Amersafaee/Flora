import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/plant_model.dart';
import '../services/gemini_service.dart';
import 'create_listing_screen.dart';

class PlantPassportScreen extends StatefulWidget {
  final Plant plant;
  final String userUid;

  const PlantPassportScreen({super.key, required this.plant, required this.userUid});

  @override
  State<PlantPassportScreen> createState() => _PlantPassportScreenState();
}

class _PlantPassportScreenState extends State<PlantPassportScreen> {
  int _totalWaterings = 0;
  int _totalGrowthEntries = 0;
  int _totalCompletedTasks = 0;
  int _totalTasks = 0;
  bool _hasDisease = false;
  bool _diseaseResolved = false;
  String _diseaseStatusText = 'Clean Record';

  String _summaryText = '';
  bool _isGeneratingSummary = true;
  List<Map<String, dynamic>> _timeline = [];

  @override
  void initState() {
    super.initState();
    _loadPassportData();
  }

  Future<void> _loadPassportData() async {
    final db = FirebaseFirestore.instance;
    final uid = widget.userUid;
    final plantId = widget.plant.id;

    try {
      // 1. Waterings and Tasks
      final tasksQuery = await db.collection('users').doc(uid).collection('tasks')
          .where('plantId', isEqualTo: plantId)
          .get();
          
      int completedWaterings = 0;
      int completed = 0;
      for (var doc in tasksQuery.docs) {
        final data = doc.data();
        if (data['isCompleted'] == true) {
          completed++;
          if (data['type'] == 'Watering') {
            completedWaterings++;
          }
        }
      }
      _totalTasks = tasksQuery.docs.length;
      _totalCompletedTasks = completed;
      _totalWaterings = completedWaterings;

      // 2. Growth entries and timeline
      final growthQuery = await db.collection('users').doc(uid).collection('plants').doc(plantId).collection('growth')
          .orderBy('timestamp', descending: true)
          .get();
          
      _totalGrowthEntries = growthQuery.docs.length;
      
      _timeline = growthQuery.docs.take(5).map((doc) {
        final data = doc.data();
        final ts = data['timestamp'] as Timestamp?;
        final dt = ts?.toDate() ?? DateTime.now();
        return {
          'date': DateFormat.yMMMd().format(dt),
          'notes': data['notes'] as String? ?? '',
        };
      }).toList();

      // 3. Treatment Cases
      final casesQuery = await db.collection('users').doc(uid).collection('treatment_cases')
          .where('plantId', isEqualTo: plantId)
          .get();
          
      if (casesQuery.docs.isNotEmpty) {
        _hasDisease = true;
        bool allResolved = true;
        for (var doc in casesQuery.docs) {
          final status = doc.data()['status'] as String?;
          if (status != 'Resolved') {
            allResolved = false;
            break;
          }
        }
        _diseaseResolved = allResolved;
        _diseaseStatusText = allResolved ? 'Recovered' : 'Active Issue';
      }

      // Generate Summary
      final gemini = GeminiService();
      final summary = await gemini.generatePlantPassportSummary(
        widget.plant.name,
        widget.plant.category,
        _calculateDaysTogether(),
        _totalWaterings,
        _totalGrowthEntries,
        widget.plant.healthScore,
        _hasDisease,
        _diseaseResolved,
      );

      if (mounted) {
        setState(() {
          _summaryText = summary;
          _isGeneratingSummary = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading passport data: $e');
      if (mounted) {
        setState(() => _isGeneratingSummary = false);
      }
    }
  }

  int _calculateDaysTogether() {
    return DateTime.now().difference(widget.plant.dateAdded).inDays;
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return const Color(0xFF8D3220); // Terracotta
    return Colors.red;
  }

  Future<void> _sharePassport() async {
    final consistency = _totalTasks > 0 ? (_totalCompletedTasks / _totalTasks * 100).round() : 100;
    final text = '''
Digital Conservatory Plant Passport

Plant: ${widget.plant.name}
Health Score: ${widget.plant.healthScore}
Care Consistency: $consistency%

$_summaryText
''';
    // ignore: deprecated_member_use
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final consistency = _totalTasks > 0 ? (_totalCompletedTasks / _totalTasks * 100).round() : 100;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Plant Passport', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'serif', color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _sharePassport,
            child: const Text('Share', style: TextStyle(color: Color(0xFF154212), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Passport Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF154212), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF154212),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: const Text(
                      'DIGITAL CONSERVATORY PLANT PASSPORT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.plant.imageUrl.isNotEmpty
                        ? Image.network(
                            widget.plant.imageUrl,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 120,
                            height: 120,
                            color: const Color(0xFFE8F5E9),
                            child: const Icon(Icons.eco, size: 48, color: Color(0xFF154212)),
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    widget.plant.name,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF154212),
                    ),
                  ),
                  
                  Text(
                    widget.plant.commonName.isNotEmpty ? widget.plant.commonName : 'Unknown Species',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  // Stats Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.calendar_today,
                            label: 'Joined Collection',
                            value: DateFormat.yMMM().format(widget.plant.dateAdded),
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.favorite,
                            label: 'Health Score',
                            value: widget.plant.healthScore.toString(),
                            valueColor: _getScoreColor(widget.plant.healthScore),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.water_drop,
                            label: 'Times Watered',
                            value: _totalWaterings.toString(),
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.book,
                            label: 'Journal Entries',
                            value: _totalGrowthEntries.toString(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.shield,
                            label: 'Disease History',
                            value: _diseaseStatusText,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.star,
                            label: 'Care Consistency',
                            value: '$consistency%',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  // AI Summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome, color: Color(0xFF154212), size: 14),
                            const SizedBox(width: 4),
                            const Text(
                              'AI SUMMARY',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF154212),
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _isGeneratingSummary
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF154212)),
                                ),
                              )
                            : Text(
                                _summaryText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade700,
                                  height: 1.5,
                                ),
                              ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Timeline
                  if (_timeline.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Care Timeline',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF154212),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: _timeline.map((entry) {
                          final notes = entry['notes'] as String;
                          final truncatedNotes = notes.length > 60 ? '${notes.substring(0, 60)}...' : notes;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF154212),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Container(
                                      width: 2,
                                      height: 30, // Rough height
                                      color: Colors.grey.shade300,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(entry['date'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Text(
                                        truncatedNotes.isEmpty ? 'Checked in' : truncatedNotes,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Fake QR Code Element
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.qr_code_2, size: 48, color: Colors.black87),
                        const SizedBox(height: 4),
                        Text(
                          widget.plant.id.length > 8 ? widget.plant.id.substring(0, 8).toUpperCase() : widget.plant.id.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateListingScreen(
                        initialPlantName: widget.plant.name,
                        initialDescription: _summaryText,
                        initialHealthScore: widget.plant.healthScore,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF154212),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('List on Swap Market', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _sharePassport,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF154212),
                  side: const BorderSide(color: Color(0xFF154212), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Share Passport', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value, Color? valueColor}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor ?? Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
