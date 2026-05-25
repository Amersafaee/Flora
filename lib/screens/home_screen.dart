import '../services/badges_service.dart';
import '../services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'care_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import 'profile_screen.dart';
import 'add_plant_screen.dart';
import 'identify_screen.dart';
import 'plant_detail_screen.dart';
import '../services/firestore_service.dart';
import '../models/plant_model.dart';
import '../models/task_model.dart';

import 'vitals_dashboard_screen.dart';
import '../services/milestone_service.dart';
import '../services/weekly_report_service.dart';
import 'weekly_report_screen.dart';
import '../utils/user_utils.dart';
import '../theme/app_theme.dart';
import '../services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;
  final ValueChanged<Locale>? onLocaleChanged;
  const HomeScreen({super.key, this.onThemeChanged, this.onLocaleChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Static guard: weekly report fires at most once per app process lifetime
  static bool _weeklyCheckDone = false;

  WeatherData? _weatherData;
  bool _weatherLoading = true;

  Future<void> _loadWeather() async {
    setState(() => _weatherLoading = true);
    final weather = await WeatherService().getCurrentWeather();
    if (mounted) {
      setState(() {
        _weatherData = weather;
        _weatherLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _computeHealthScores();
    _loadWeather();
  }

  Future<void> _computeHealthScores() async {
    try {
      final uid = FirestoreService().currentUserId;
      if (uid != null) {
        await FirestoreService().computeAllHealthScores(uid);
        await MilestoneService().checkMilestones(uid);
        await BadgesService().checkAndAwardBadges(uid).catchError((_) {});

        // Check if a badge was earned — show celebration dialog after first frame
        try {
          final prefs = await SharedPreferences.getInstance();
          final pendingBadge = prefs.getString('pending_badge_celebration');
          if (pendingBadge != null && mounted) {
            await prefs.remove('pending_badge_celebration');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showBadgeCelebrationDialog(pendingBadge);
            });
          }
        } catch (_) {}

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

  void _showBadgeCelebrationDialog(String badgeName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 64,
              color: Color(0xFFC8893A),
            ),
            const SizedBox(height: 16),
            const Text(
              'Badge Earned!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              badgeName,
              style: const TextStyle(fontSize: 16, color: AppColors.bone500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(WeatherData? weather, bool isLoading) {

    if (isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.wb_cloudy_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context).loadingWeather, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    if (weather == null) return const SizedBox.shrink();

    final tempC = weather.temperatureCelsius.round();
    final humidity = weather.humidity.round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.wb_cloudy_outlined, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather.cityName.isNotEmpty ? weather.cityName : AppLocalizations.of(context).currentLocation,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  weather.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$tempC°C', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              )),
              Text('💧 $humidity%', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
        final firestoreService = FirestoreService();
    final userId = firestoreService.currentUserId;

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPlantScreen()),
          );
        },
        backgroundColor: AppColors.forest900,
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
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileScreen(
                          onThemeChanged: widget.onThemeChanged,
                          onLocaleChanged: widget.onLocaleChanged,
                        )),
                      );
                    },
                    child: buildUserAvatar(radius: 18),
                  ),
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

                  final l10n = AppLocalizations.of(context);
                  final greeting = () {
                    final hour = DateTime.now().hour;
                    final timeStr = hour < 12 ? l10n.goodMorning : hour < 17 ? l10n.goodAfternoon : l10n.goodEvening;
                    return name.isNotEmpty ? '$timeStr, $name' : timeStr;
                  }();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.bone900,
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
                                        AppLocalizations.of(context).thirstyOverdueByDays(overdueWatering.plantName, daysOverdue),
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
                                        AppLocalizations.of(context).needsUrgentAttention(urgentPlant.name),
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
                                  color: AppColors.forest100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.checklist, color: primaryColor, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context).careTasksToday(tasksToday),
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
                                  color: AppColors.forest100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle_outline, color: primaryColor, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context).addFirstPlantToGetStarted,
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
                                  color: AppColors.forest100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.eco, color: primaryColor, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context).allPlantsThrivingToday(plants.length),
                                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 14, color: primaryColor),
                                  ],
                                ),
                              ),
                            );
                          }

                          final isDark = Theme.of(context).brightness == Brightness.dark;

                          return Column(
                            children: [
                              card,
                              const SizedBox(height: 12),
                              // Care Streak Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkTerracottaSubtle : AppColors.terracotta100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: (isDark ? AppColors.darkTerracotta : AppColors.terracotta500).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.local_fire_department, color: isDark ? AppColors.darkTerracotta : AppColors.terracotta500, size: 36),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            careStreak == 0
                                              ? AppLocalizations.of(context).startYourStreakToday
                                              : '$careStreak ${AppLocalizations.of(context).dayCareStreak}',
                                            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.terracotta900, fontWeight: FontWeight.bold, fontSize: 18),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            careStreak == 0
                                              ? AppLocalizations.of(context).completeACareTaskToday
                                              : (tasksToday > 0 ? AppLocalizations.of(context).keepItGoingTasksToday : AppLocalizations.of(context).perfectNothingDueToday),
                                            style: TextStyle(color: isDark ? AppColors.darkTerracotta : AppColors.terracotta700, fontSize: 13),
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

              _buildWeatherCard(_weatherData, _weatherLoading),
              const SizedBox(height: 8),

              // Daily Care Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).dailyCare,
                    style: GoogleFonts.notoSerif(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.bone900,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).viewAll,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.bone500,
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
                  
                  // BUG 3 FIX: exclude ALL completed tasks — previously only
                  // overdue completed tasks were filtered, letting today's
                  // completed tasks bleed through.
                  final tasks = allTasks.where((t) {
                    if (t.isCompleted) return false;  // always hide completed
                    return true;
                  }).toList();
                  
                  tasks.sort((a, b) {
                    if (a.dueDate.isBefore(startOfToday) && !b.dueDate.isBefore(startOfToday)) return -1;
                    if (!a.dueDate.isBefore(startOfToday) && b.dueDate.isBefore(startOfToday)) return 1;
                    return a.dueDate.compareTo(b.dueDate);
                  });

                  if (tasks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          AppLocalizations.of(context).noTasksForToday,
                          style: const TextStyle(color: AppColors.bone500),
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: tasks.map((task) {
                      IconData icon = Icons.check_circle_outline;
                      Color iconColor = AppColors.bone500;
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
                      final cardBg = isOverdue ? Color(0x1A8D3220) : Theme.of(context).cardColor;

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
                                        color: AppColors.bone500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (isOverdue) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.terracotta900,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(AppLocalizations.of(context).overdue, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  task.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                                  color: task.isCompleted ? Colors.green : AppColors.bone500,
                                ),
                                onPressed: () async {
                                  if (!task.isCompleted) {
                                    await firestoreService.markTaskCompleted(task.id);
                                    // BUG 3 FIX: cancel any scheduled notification for this task
                                    try {
                                      await NotificationService().cancelTaskNotification(task.id);
                                    } catch (_) {}
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

              const SizedBox(height: 24),
              
              // My Plants Section
              Text(
                AppLocalizations.of(context).myPlants,
                style: GoogleFonts.notoSerif(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.bone900,
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
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.forest50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_florist, size: 64, color: AppColors.forest300),
                          const SizedBox(height: 20),
                          Text(
                            AppLocalizations.of(context).yourConservatoryIsWaiting,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSerif(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.bone900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context).addFirstPlantDescription,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.bone500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPlantScreen()));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.forest700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                AppLocalizations.of(context).addYourFirstPlant,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const IdentifyScreen()));
                            },
                            child: Text(
                              AppLocalizations.of(context).orIdentifyWithCamera,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.darkForestPrimary : AppColors.forest600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
                                                color: AppColors.forest100,
                                                child: Center(
                                                  child: Icon(
                                                    Icons.eco,
                                                    size: 48,
                                                    color: Color(0x6614301E),
                                                  ),
                                                ),
                                              ),
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Container(
                                                  color: AppColors.forest100,
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.eco,
                                                      size: 48,
                                                      color: Color(0x6614301E),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: AppColors.forest100,
                                              child: Center(
                                                child: Icon(
                                                  Icons.eco,
                                                  size: 48,
                                                  color: Color(0x6614301E),
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
                                            color: AppColors.forest100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            plant.category.isEmpty ? AppLocalizations.of(context).plantFallbackCategory : plant.category,
                                            style: const TextStyle(
                                              color: AppColors.forest900,
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}





