import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'plant_detail_screen.dart';

class VitalsDashboardScreen extends StatefulWidget {
  const VitalsDashboardScreen({super.key});

  @override
  State<VitalsDashboardScreen> createState() => _VitalsDashboardScreenState();
}

class _VitalsDashboardScreenState extends State<VitalsDashboardScreen> {
  Color _getScoreColor(int score) {
    if (score > 70) return const Color(0xFF154212); // Green
    if (score >= 40) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final plants = snapshot.data?.docs.map((d) => d.data() as Map<String, dynamic>).toList() ?? [];
          
          for (var i = 0; i < plants.length; i++) {
            plants[i]['id'] = snapshot.data!.docs[i].id;
            if (!plants[i].containsKey('healthScore')) {
              plants[i]['healthScore'] = 100;
            }
          }

          // Sort ascending
          plants.sort((a, b) => (a['healthScore'] as int).compareTo(b['healthScore'] as int));

          int totalScore = 0;
          int thrivingCount = 0;
          int needHelpCount = 0;

          for (var p in plants) {
            final score = p['healthScore'] as int;
            totalScore += score;
            if (score > 70) thrivingCount++;
            if (score < 40) needHelpCount++;
          }

          final avgScore = plants.isNotEmpty ? (totalScore / plants.length).round() : 0;
          final avgColor = _getScoreColor(avgScore);

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Plant Vitals',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                          color: Color(0xFF154212),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your collection health overview',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Summary Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(avgScore.toString(), 'Collection Health', avgColor),
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        _buildStatColumn(thrivingCount.toString(), 'Thriving', const Color(0xFF154212)),
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        _buildStatColumn(needHelpCount.toString(), 'Need Help', Colors.red.shade600),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Your Plants',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1B),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Plant List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: plants.length,
                    itemBuilder: (context, index) {
                      final plant = plants[index];
                      final score = plant['healthScore'] as int;
                      final prevScore = plant['previousHealthScore'] as int?;
                      final color = _getScoreColor(score);
                      
                      Widget trendIcon = Icon(Icons.arrow_forward, color: Colors.grey.shade400, size: 20);
                      if (prevScore != null) {
                        if (score > prevScore + 5) {
                          trendIcon = const Icon(Icons.arrow_upward, color: Color(0xFF154212), size: 20);
                        } else if (score < prevScore - 5) {
                          trendIcon = Icon(Icons.arrow_downward, color: Colors.red.shade600, size: 20);
                        }
                      }

                      String statusText = plant['healthStatus']?.toString() ?? 'Healthy';
                      if (plant.containsKey('lastAssessment') && plant['lastAssessment'] != null) {
                        statusText = plant['lastAssessment']['condition']?.toString() ?? statusText;
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlantDetailScreen(
                                plantId: plant['id'],
                                plantName: plant['name'],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: CustomPaint(
                                      painter: HealthRingPainter(
                                        percentage: score / 100,
                                        color: color,
                                      ),
                                      child: Center(
                                        child: Text(
                                          score.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plant['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF191C1B),
                                          ),
                                        ),
                                        Text(
                                          plant['category'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trendIcon,
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 4,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: constraints.maxWidth * (score / 100),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

class HealthRingPainter extends CustomPainter {
  final double percentage;
  final Color color;

  HealthRingPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 4;
    
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
      
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
