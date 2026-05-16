import '../services/badges_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'care_screen.dart';

import 'global_search_screen.dart';
import 'profile_screen.dart';
import 'add_plant_screen.dart';
import 'identify_screen.dart';
import 'plant_detail_screen.dart';
import 'post_comments_screen.dart';
import 'wiki_screen.dart';
import 'flora_chats_list_screen.dart';
import 'all_plants_screen.dart';
import '../services/firestore_service.dart';
import '../models/plant_model.dart';
import '../models/task_model.dart';

import 'vitals_dashboard_screen.dart';
import '../services/milestone_service.dart';
import '../services/weekly_report_service.dart';
import 'weekly_report_screen.dart';
import '../utils/user_utils.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;
  const HomeScreen({super.key, this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Static guard: weekly report fires at most once per app process lifetime
  static bool _weeklyCheckDone = false;

  @override
  void initState() {
    super.initState();
    _computeHealthScores();
  }

  Future<void> _computeHealthScores() async {
    try {
      final uid = FirestoreService().currentUserId;
      if (uid != null) {
        await FirestoreService().computeAllHealthScores(uid);
        await MilestoneService().checkMilestones(uid);

        if (!_weeklyCheckDone) {
          _weeklyCheckDone = true;
          final reportService = WeeklyReportService();
          final shouldShow = await reportService.shouldShowWeeklyReport();
          if (shouldShow && mounted) {
            final reportData = await reportService.generateWeeklyReport(uid);
            await reportService.markWeeklyReportShown();
            if (mounted) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => WeeklyReportScreen(reportData: reportData),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error computing health scores: $e');
    }
  }


  Widget _buildCompactStatCard(BuildContext context, String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          if (value.isNotEmpty) const SizedBox(height: 8),
          if (value.isNotEmpty)
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    const Color softGreen = Color(0xFFE8F3EA);
    
    final firestoreService = FirestoreService();
    
    final userId = firestoreService.currentUserId;
    if (userId != null) {
      BadgesService().checkAndAwardBadges(userId);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPlantScreen()),
          );
        },
        backgroundColor: const Color(0xFF154212),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileScreen(onThemeChanged: widget.onThemeChanged)),
                      );
                    },
                    child: buildUserAvatar(radius: 18),
                    ),
                    const Text(
                      'Digital Conservatory',
                      style: TextStyle(
                        color: Color(0xFF154212),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        fontSize: 18,
                      ),
                    ),
                  IconButton(icon: Icon(Icons.search, color: Theme.of(context).primaryColor), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen())); }),
                ],
              ),
              const SizedBox(height: 16),
              
              // Greeting & Flora Observation
              StreamBuilder<DocumentSnapshot>(
                stream: userId != null ? FirebaseFirestore.instance.collection('users').doc(userId).snapshots() : const Stream.empty(),
                builder: (context, userSnapshot) {
                  String name = '';
                  int careStreak = 0;
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (data != null) {
                      name = data['displayName'] ?? data['fullName'] ?? '';
                      careStreak = (data['careStreak'] as num?)?.toInt() ?? 0;
                      if (name.contains(' ')) {
                        name = name.split(' ')[0];
                      }
                    }
                  }

                  final greeting = () {
                    final hour = DateTime.now().hour;
                    final timeStr = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
                    return name.isNotEmpty ? '$timeStr, $name' : timeStr;
                  }();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.onSurface : primaryColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Flora Observation Card
                      FutureBuilder(
                        future: Future.wait([
                          FirebaseFirestore.instance.collection('users').doc(userId).collection('plants').get(),
                          FirebaseFirestore.instance.collection('users').doc(userId).collection('tasks').get(),
                        ]),
                        builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                ShimmerBox(width: double.infinity, height: 80, borderRadius: 16),
                                SizedBox(height: 12),
                                ShimmerBox(width: double.infinity, height: 70, borderRadius: 16),
                              ],
                            );
                          }
                          
                          if (snapshot.hasError || !snapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          final plants = snapshot.data![0].docs.map((d) {
                            try { return Plant.fromMap(d.data() as Map<String, dynamic>); } catch (_) { return null; }
                          }).whereType<Plant>().where((p) => !p.isDeceased).toList();
                          
                          final tasks = snapshot.data![1].docs.map((d) {
                            try { return Task.fromMap(d.data() as Map<String, dynamic>); } catch (_) { return null; }
                          }).whereType<Task>().toList();
                          
                          final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                          
                          // Priority 1: Watering overdue > 2 days
                          Task? overdueWatering;
                          for (var t in tasks) {
                            if (!t.isCompleted && t.taskType.toLowerCase().contains('water')) {
                              final due = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
                              if (today.difference(due).inDays > 2) {
                                overdueWatering = t;
                                break;
                              }
                            }
                          }
                          
                          // Priority 2: Plant healthScore < 60 and has lastAssessment
                          Plant? urgentPlant;
                          for (var d in snapshot.data![0].docs) {
                            final data = d.data() as Map<String, dynamic>;
                            final p = Plant.fromMap(data);
                            if (!p.isDeceased && p.healthScore < 60 && data.containsKey('lastAssessment')) {
                              urgentPlant = p;
                              break;
                            }
                          }
                          
                          // Priority 3: Tasks due today
                          int tasksToday = 0;
                          for (var t in tasks) {
                            if (!t.isCompleted) {
                              final due = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
                              if (due.isAtSameMomentAs(today) || due.isBefore(today)) {
                                tasksToday++;
                              }
                            }
                          }

                          Widget card;
                          if (overdueWatering != null) {
                            final daysOverdue = today.difference(DateTime(overdueWatering.dueDate.year, overdueWatering.dueDate.month, overdueWatering.dueDate.day)).inDays;
                            card = GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CareScreen())),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.water_drop, color: Colors.blue.shade700, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '💧 ${overdueWatering.plantName} is thirsty — watering overdue by $daysOverdue days',
                                        style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue.shade700),
                                  ],
                                ),
                              ),
                            );
                          } else if (urgentPlant != null) {
                            card = GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: urgentPlant!.id))),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '🚨 ${urgentPlant.name} needs urgent attention',
                                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red.shade700),
                                  ],
                                ),
                              ),
                            );
                          } else if (tasksToday > 0) {
                            card = GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CareScreen())),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F3EA),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.checklist, color: primaryColor, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '📋 You have $tasksToday care task${tasksToday == 1 ? '' : 's'} today',
                                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 14, color: primaryColor),
                                  ],
                                ),
                              ),
                            );
                          } else if (plants.isEmpty) {
                            // New user with no plants — never say "All 0 plants are thriving"
                            card = GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPlantScreen())),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F3EA),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle_outline, color: primaryColor, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '🌱 Add your first plant to get started',
                                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 14, color: primaryColor),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            // plants.length > 0 and nothing urgent
                            card = GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VitalsDashboardScreen())),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F3EA),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.eco, color: primaryColor, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '🌿 All ${plants.length} plant${plants.length == 1 ? '' : 's'} are thriving today',
                                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 14, color: primaryColor),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: [
                              card,
                              const SizedBox(height: 12),
                              // Care Streak Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3ED),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_fire_department, color: Color(0xFFFF6B35), size: 36),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$careStreak day care streak',
                                            style: const TextStyle(color: Color(0xFF8D3A15), fontWeight: FontWeight.bold, fontSize: 18),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            careStreak == 0 
                                              ? 'Start your streak — complete a care task today'
                                              : (tasksToday > 0 ? 'Keep it going — you have tasks today' : 'Perfect — nothing due today'),
                                            style: const TextStyle(color: Color(0xFFB55730), fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),

              // Daily Care Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Care',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    'VIEW ALL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              StreamBuilder<List<Task>>(
                stream: firestoreService.getTasksForYesterdayAndToday(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: ShimmerBox(width: double.infinity, height: 80, borderRadius: 16),
                    );
                  }
                  if (snapshot.hasError) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off, color: Colors.amber.shade800, size: 16),
                          const SizedBox(width: 8),
                          Text('You are offline — showing cached data', style: TextStyle(color: Colors.amber.shade800, fontSize: 12)),
                        ],
                      ),
                    );
                  }
                  final allTasks = snapshot.data ?? [];
                  final now = DateTime.now();
                  final startOfToday = DateTime(now.year, now.month, now.day);
                  
                  final tasks = allTasks.where((t) {
                    if (t.dueDate.isBefore(startOfToday)) {
                      return !t.isCompleted;
                    }
                    return true;
                  }).toList();
                  
                  tasks.sort((a, b) {
                    if (a.dueDate.isBefore(startOfToday) && !b.dueDate.isBefore(startOfToday)) return -1;
                    if (!a.dueDate.isBefore(startOfToday) && b.dueDate.isBefore(startOfToday)) return 1;
                    return a.dueDate.compareTo(b.dueDate);
                  });

                  if (tasks.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No tasks for today.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: tasks.map((task) {
                      IconData icon = Icons.check_circle_outline;
                      Color iconColor = Colors.grey;
                      if (task.taskType.toLowerCase().contains('water')) {
                        icon = Icons.water_drop;
                        iconColor = Colors.redAccent;
                      } else if (task.taskType.toLowerCase().contains('mist')) {
                        icon = Icons.air;
                        iconColor = Colors.green;
                      } else if (task.taskType.toLowerCase().contains('fertiliz')) {
                        icon = Icons.science;
                        iconColor = Colors.redAccent;
                      } else if (task.taskType.toLowerCase().contains('repot')) {
                        icon = Icons.yard;
                        iconColor = primaryColor;
                      }
                      
                      final isOverdue = task.dueDate.isBefore(startOfToday) && !task.isCompleted;
                      final cardBg = isOverdue ? const Color(0xFF8D3220).withValues(alpha: 0.1) : Theme.of(context).cardColor;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: iconColor, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.taskType,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      task.plantName,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (isOverdue) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8D3220),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Overdue', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  task.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                                  color: task.isCompleted ? Colors.green : Colors.grey,
                                ),
                                onPressed: () {
                                  if (!task.isCompleted) {
                                    firestoreService.markTaskCompleted(task.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
              ),
              const SizedBox(height: 24),

              // This Week Summary Row
              Row(
                children: [
                  Expanded(
                    child: FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(userId).collection('tasks')
                        .where('isCompleted', isEqualTo: true)
                        .where('dueDate', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 7)))
                        .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const ShimmerBox(width: double.infinity, height: 60, borderRadius: 12);
                        }
                        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return _buildCompactStatCard(context, 'Tasks Done', '$count', Icons.check_circle_outline, Colors.green);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: firestoreService.getLightweightPlants(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const ShimmerBox(width: double.infinity, height: 60, borderRadius: 12);
                        }
                        final plants = snapshot.data?.where((p) => p['isDeceased'] != true).toList() ?? [];
                        final count = plants.length;
                        return _buildCompactStatCard(context, 'Plants', '$count', Icons.energy_savings_leaf, primaryColor);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: firestoreService.getLightweightPlants(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const ShimmerBox(width: double.infinity, height: 60, borderRadius: 12);
                        }
                        final plantsData = snapshot.data ?? [];
                        final assessed = plantsData.where((p) => p['isDeceased'] != true && p.containsKey('lastAssessmentDate')).toList();
                        if (assessed.isEmpty) {
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IdentifyScreen())),
                            child: _buildCompactStatCard(context, 'Assess a plant', '', Icons.camera_alt, Colors.grey),
                          );
                        }
                        int sum = 0;
                        for (var p in assessed) { sum += (p['healthScore'] as num?)?.toInt() ?? 100; }
                        final avgHealth = assessed.isNotEmpty ? (sum / assessed.length).round() : 0;
                        return _buildCompactStatCard(context, 'Avg Health', '$avgHealth', Icons.favorite, Colors.red);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Quick Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAction(context, Icons.search, 'Identify 🔍', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IdentifyScreen()))),
                  _buildQuickAction(context, Icons.chat_bubble_outline, 'Ask Flora 🌿', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FloraChatsListScreen()))),
                  _buildQuickAction(context, Icons.menu_book_outlined, 'Journal 📖', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllPlantsScreen()))),
                ],
              ),
              const SizedBox(height: 16),
              
              // My Plants Section
              Text(
                'My Plants',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              
              StreamBuilder<List<Plant>>(
                stream: firestoreService.getPlants(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off, color: Colors.amber.shade800, size: 16),
                          const SizedBox(width: 8),
                          Text('You are offline — showing cached data', style: TextStyle(color: Colors.amber.shade800, fontSize: 12)),
                        ],
                      ),
                    );
                  }
                  final allPlants = snapshot.data ?? [];
                  final plants = allPlants.where((p) => !p.isDeceased).toList();
                  
                  // Only show empty state when data has actually loaded (not just waiting)
                  if (plants.isEmpty && snapshot.connectionState == ConnectionState.active) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF154212).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.eco, color: Color(0xFF154212), size: 80),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Your conservatory is empty',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Add your first plant and Flora will build a personalised care plan for it automatically',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPlantScreen()));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF154212),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Add Your First Plant 🌱', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const IdentifyScreen()));
                              },
                              child: const Text('Or identify a plant with your camera', style: TextStyle(color: Color(0xFF154212))),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: plants.length,
                      itemBuilder: (context, index) {
                        final plant = plants[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 16, bottom: 4),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PlantDetailScreen()),
                              );
                            },
                            child: Container(
                              width: 160,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 120,
                                    width: double.infinity,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: plant.imageUrl.isNotEmpty
                                          ? Image.network(
                                              plant.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: const Color(0xFFE8F5E9),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.eco,
                                                    size: 48,
                                                    color: const Color(0xFF154212).withValues(alpha: 0.4),
                                                  ),
                                                ),
                                              ),
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Container(
                                                  color: const Color(0xFFE8F5E9),
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.eco,
                                                      size: 48,
                                                      color: const Color(0xFF154212).withValues(alpha: 0.4),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: const Color(0xFFE8F5E9),
                                              child: Center(
                                                child: Icon(
                                                  Icons.eco,
                                                  size: 48,
                                                  color: const Color(0xFF154212).withValues(alpha: 0.4),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plant.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E9),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            plant.category.isEmpty ? 'Plant' : plant.category,
                                            style: const TextStyle(
                                              color: Color(0xFF154212),
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              ),

              const SizedBox(height: 16),

              // ── From the Community ──────────────────────────────────────
              Text(
                'From the Community',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('timestamp', descending: true)
                    .limit(2)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('No community posts yet.',
                          style: TextStyle(color: Colors.grey.shade500)),
                    );
                  }
                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title = (data['title'] ?? '').toString();
                      final author = (data['authorName'] ?? 'Anonymous').toString();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PostCommentsScreen(postId: doc.id, postTitle: title)),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: softGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.people_outline, color: primaryColor, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'by $author',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Learn Something New ─────────────────────────────────────
              Text(
                'Learn Something New',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('blogs')
                    .orderBy('createdAt', descending: true)
                    .limit(2)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Plant guides loading…',
                          style: TextStyle(color: Colors.grey.shade500)),
                    );
                  }
                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title = (data['title'] ?? '').toString();
                      final summary = (data['summary'] ?? '').toString();
                      final readMinutes = (data['readMinutes'] as num?)?.toInt() ?? 5;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WikiScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: softGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.article_outlined, color: primaryColor, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      if (summary.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          summary,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.access_time, size: 10, color: Color(0xFF2E7D32)),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$readMinutes min',
                                        style: const TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}





