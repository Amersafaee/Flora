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
import '../services/firestore_service.dart';
import '../models/plant_model.dart';
import '../models/task_model.dart';

import 'vitals_dashboard_screen.dart';
import 'memorial_garden_screen.dart';
import '../services/milestone_service.dart';
import '../services/weekly_report_service.dart';
import 'weekly_report_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;
  const HomeScreen({super.key, this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        
        final reportService = WeeklyReportService();
        final shouldShow = await reportService.shouldShowWeeklyReport();
        if (shouldShow && mounted) {
          final reportData = await reportService.generateWeeklyReport(uid);
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
    } catch (e) {
      debugPrint('Error computing health scores: $e');
    }
  }

  Widget _buildSmallStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color primaryColor,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
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
                                          child: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        radius: 18,
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
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
              
              // Greeting
              Text(
                () {
                  final hour = DateTime.now().hour;
                  if (hour < 12) return 'Good Morning.';
                  if (hour < 17) return 'Good Afternoon.';
                  return 'Good Evening.';
                }(),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.onSurface : primaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Plant>>(
                stream: firestoreService.getPlants(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Loading observations...', style: TextStyle(color: Colors.grey, fontSize: 14));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('Add your first plant to get observations.', style: TextStyle(color: Colors.grey, fontSize: 14));
                  }
                  
                  final plants = snapshot.data!.where((p) => !p.isDeceased).toList();
                  Plant? needsAttention;
                  for (var p in plants) {
                    if (p.healthStatus != 'Healthy' || p.healthScore < 70) {
                      needsAttention = p;
                      break;
                    }
                  }
                  
                  if (needsAttention != null) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: needsAttention!.id)));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F3EA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.energy_savings_leaf, color: primaryColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your ${needsAttention.name} needs attention — health score dropped to ${needsAttention.healthScore}',
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 12, color: primaryColor),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3EA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.eco, color: primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'All your plants are looking great today 🌿',
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<List<Task>>(
                      stream: firestoreService.getTasksForToday(),
                      builder: (context, snapshot) {
                        int taskCount = 0;
                        if (snapshot.hasData) {
                          taskCount = snapshot.data!.where((t) => !t.isCompleted).length;
                        }
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CareScreen()));
                          },
                          child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E211E) : Colors.white,
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
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: softGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.water_drop, color: primaryColor),
                              ),
                              const SizedBox(height: 12),
                              if (snapshot.connectionState == ConnectionState.waiting)
                                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              else if (snapshot.hasError)
                                const Text('Something went wrong', style: TextStyle(color: Colors.grey, fontSize: 12))
                              else
                                Text(
                                  "$taskCount",
                                  style: const TextStyle(
                                    color: Color(0xFF154212),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tasks today',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        );
                      }
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StreamBuilder<List<Plant>>(
                      stream: firestoreService.getPlants(),
                      builder: (context, snapshot) {
                        int plantCount = snapshot.hasData ? snapshot.data!.length : 0;
                        int totalScore = 0;
                        if (snapshot.hasData) {
                          for (var p in snapshot.data!) { totalScore += p.healthScore; }
                        }
                        int avgScore = plantCount > 0 ? (totalScore / plantCount).round() : 0;
                        Color barColor = Colors.grey;
                        if (plantCount > 0) {
                          if (avgScore > 70) { barColor = const Color(0xFF154212); }
                          else if (avgScore >= 40) { barColor = Colors.orange.shade600; }
                          else { barColor = Colors.red.shade600; }
                        }
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const VitalsDashboardScreen()));
                          },
                          child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E211E) : Colors.white,
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
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: softGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.eco, color: primaryColor),
                              ),
                              const SizedBox(height: 12),
                              if (snapshot.connectionState == ConnectionState.waiting)
                                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              else if (snapshot.hasError)
                                const Text('Something went wrong', style: TextStyle(color: Colors.grey, fontSize: 12))
                              else
                                Text(
                                  "$plantCount",
                                  style: const TextStyle(
                                    color: Color(0xFF154212),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              const Text(
                                'Total Plants',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (plantCount > 0)
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
                                          width: constraints.maxWidth * (avgScore / 100),
                                          decoration: BoxDecoration(
                                            color: barColor,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        );
                      }
                    ),
                  ),
                ],
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
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Something went wrong',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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
                        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return _buildSmallStatCard(
                          title: 'Done This Week',
                          value: '$count',
                          icon: Icons.check_circle_outline,
                          primaryColor: primaryColor,
                          context: context,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FutureBuilder<int>(
                      future: firestoreService.getTotalJournalEntriesCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return _buildSmallStatCard(
                          title: 'Journal Entries',
                          value: '$count',
                          icon: Icons.book_outlined,
                          primaryColor: primaryColor,
                          context: context,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StreamBuilder<List<Plant>>(
                      stream: firestoreService.getPlants(),
                      builder: (context, snapshot) {
                        int avgHealth = 0;
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          final plants = snapshot.data!;
                          int sum = 0;
                          for (var p in plants) { sum += p.healthScore; }
                          avgHealth = (sum / plants.length).round();
                        }
                        return _buildSmallStatCard(
                          title: 'Avg Health',
                          value: '$avgHealth',
                          icon: Icons.favorite_outline,
                          primaryColor: primaryColor,
                          context: context,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Identify Plant Card
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const IdentifyScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E3A1E) : const Color(0xFF154212),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Identify Plant',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Scan and add to collection',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
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
                    return const Center(
                      child: Text(
                        'Something went wrong',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    );
                  }
                  final allPlants = snapshot.data ?? [];
                  final plants = allPlants.where((p) => !p.isDeceased).toList();
                  
                  if (plants.isEmpty) {
                    return Column(
                      children: [
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'No active plants yet. Tap Identify to add your first plant.',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        if (allPlants.any((p) => p.isDeceased))
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MemorialGardenScreen()));
                            },
                            child: const Text('Memorial Garden', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                          ),
                      ],
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
              StreamBuilder<List<Plant>>(
                stream: firestoreService.getPlants(),
                builder: (context, snapshot) {
                  final allPlants = snapshot.data ?? [];
                  if (allPlants.any((p) => p.isDeceased)) {
                    return Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MemorialGardenScreen()));
                        },
                        child: const Text('Memorial Garden', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
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
                    .collection('species')
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
                      child: Text('Wiki loading…',
                          style: TextStyle(color: Colors.grey.shade500)),
                    );
                  }
                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString();
                      final commonName = (data['commonName'] ?? '').toString();
                      final difficulty = (data['difficulty'] ?? 'Easy').toString();
                      Color difficultyColor;
                      switch (difficulty.toLowerCase()) {
                        case 'hard':
                          difficultyColor = Colors.red.shade400;
                          break;
                        case 'medium':
                          difficultyColor = Colors.orange.shade400;
                          break;
                        default:
                          difficultyColor = const Color(0xFF2E7D32);
                      }
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
                                  child: Icon(Icons.eco, color: primaryColor, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      if (commonName.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          commonName,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
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
                                    color: difficultyColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    difficulty,
                                    style: TextStyle(
                                      color: difficultyColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
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












