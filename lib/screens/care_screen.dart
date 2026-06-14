import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_model.dart';
import '../services/badges_service.dart';
import '../services/care_intelligence_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';
import '../utils/care_type_style.dart';
import '../utils/toast_utils.dart';
import '../utils/user_utils.dart';
import '../widgets/shared/empty_state.dart';
import 'add_plant_screen.dart';
import 'add_task_screen.dart';
import 'batch_care_screen.dart';
import 'care_insights_screen.dart';
import 'climate_screen.dart';
import 'community_screen.dart';
import 'global_search_screen.dart';
import 'light_meter_screen.dart';
import 'onboarding_overlay_screen.dart';
import 'profile_screen.dart';

class CareScreen extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;
  const CareScreen({super.key, this.onThemeChanged});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  int _selectedTab = 0; // 0 = Upcoming, 1 = History
  late DateTime currentWeekStart;
  int _selectedDayTabIndex = 0; // index within the current week row (0=Mon … 6=Sun)
  final FirestoreService _firestoreService = FirestoreService();

  // Cache task dates for dots
  Map<String, List<Color>> _taskDots = {};

  Map<String, String> _plantHealthMapCache = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Find Monday of current week
    currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    currentWeekStart = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
    // Default selected day tab to today
    _selectedDayTabIndex = now.weekday - 1; // 0=Mon … 6=Sun
    _loadTasksForWeek();

    final uid = _firestoreService.currentUserId;
    if (uid != null) {
      _maybeRunInspectionCheck(uid);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await OnboardingService.shouldShow('care_screen')) {
        await OnboardingService.markShown('care_screen');
        if (mounted) _showFeatureOnboarding();
      }
    });
  }

  void _showFeatureOnboarding() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => OnboardingOverlayScreen(
          title: AppLocalizations.of(ctx).careCalendar,
          description: AppLocalizations.of(ctx).monitoringEnvironment,
          tips: [
            AppLocalizations.of(ctx).checkSoilBeforeWatering,
            AppLocalizations.of(ctx).careHistory,
            AppLocalizations.of(ctx).weeklyChallenge,
          ],
          featureKey: 'care_screen',
        ),
      ),
    );
  }

  Future<void> _maybeRunInspectionCheck(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final lastCheckStr = prefs.getString('last_inspection_check_date');
      if (lastCheckStr == todayStr) return; // Already ran today
      await _firestoreService.checkAndCreateInspectionTasks(uid);
    } catch (e) {
      debugPrint('Inspection check error: $e');
    }
  }

  Future<Map<String, String>> _getPlantHealthMap() async {
    final uid = _firestoreService.currentUserId;
    if (uid == null) return {};
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('plants').get();
    final map = <String, String>{};
    for (var doc in snap.docs) {
      final data = doc.data();
      map[data['name']?.toString() ?? ''] = data['healthStatus']?.toString() ?? 'Healthy';
    }
    return map;
  }

  Future<void> _loadTasksForWeek() async {
    final uid = _firestoreService.currentUserId;
    if (uid == null) return;
    final endOfWeek = currentWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(currentWeekStart))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
        .get();
    
    final dots = <String, List<Color>>{};
    for (var doc in snap.docs) {
      final task = Task.fromMap(doc.data());
      if (task.isCompleted) continue;
      final d = task.dueDate;
      final key = '${d.year}-${d.month}-${d.day}';
      final color = careTypeStyle(task.taskType).iconColor;
      dots.putIfAbsent(key, () => []);
      if (!dots[key]!.contains(color)) dots[key]!.add(color);
    }
    if (mounted) setState(() => _taskDots = dots);
  }

  void _prevWeek() {
    setState(() {
      currentWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    });
    _loadTasksForWeek();
  }

  void _nextWeek() {
    setState(() {
      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
    });
    _loadTasksForWeek();
  }

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => currentWeekStart.add(Duration(days: i)));

  List<Color> _getDotsForDate(DateTime date) {
    final list = _taskDots['${date.year}-${date.month}-${date.day}'] ?? [];
    if (list.isEmpty) return [];
    final today = DateTime.now();
    final compareDate = DateTime(date.year, date.month, date.day);
    final compareToday = DateTime(today.year, today.month, today.day);
    if (compareDate.isBefore(compareToday)) {
      return const [AppColors.terracotta500];
    } else {
      return const [AppColors.forest700];
    }
  }


  String get _monthYearTitle {
    final days = _weekDays;
    final first = days.first;
    final last = days.last;
    if (first.month == last.month) {
      return DateFormat('MMMM yyyy').format(first);
    }
    return '${DateFormat('MMM').format(first)} – ${DateFormat('MMM yyyy').format(last)}';
  }

  static const List<String> _dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.bone50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ProfileScreen(onThemeChanged: widget.onThemeChanged),
                ));
              },
              child: buildUserAvatar(radius: 18),
            ),
          ),
        ),
        title: Text(
          'Verdoro',
          style: GoogleFonts.outfit(
            color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.forest700),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskScreen()));
              },
              backgroundColor: AppColors.forest700,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildTab(AppLocalizations.of(context).upcoming, 0),
                  const SizedBox(width: 24),
                  _buildTab(AppLocalizations.of(context).historyTab, 1),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedTab == 0) ...[
              // Calendar Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _monthYearTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.bone900,
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _prevWeek,
                          child: _buildCircleArrow(Icons.chevron_left),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _nextWeek,
                          child: _buildCircleArrow(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Day tab row — Mon to Sun
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (i) {
                    final day = _weekDays[i];
                    final isToday = DateTime(day.year, day.month, day.day) ==
                        DateTime(today.year, today.month, today.day);
                    final isSelected = _selectedDayTabIndex == i;
                    final dotColors = _getDotsForDate(day);
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedDayTabIndex = i);
                      },
                      child: _buildDayColumn(
                        _dayNames[i],
                        '${day.day}',
                        isToday: isToday,
                        isSelected: isSelected,
                        dotColors: dotColors,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Tasks label for selected day
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Builder(builder: (context) {
                  final selectedDay = _weekDays[_selectedDayTabIndex];
                  final isToday = DateTime(selectedDay.year, selectedDay.month, selectedDay.day) ==
                      DateTime(today.year, today.month, today.day);
                  final label = isToday
                      ? AppLocalizations.of(context).todaysTasks
                      : DateFormat('EEEE\'s Tasks').format(selectedDay);
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Text(
                    label,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.bone900,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        // Show tasks for the selected day tab
                        StreamBuilder<List<Task>>(
                          stream: _firestoreService.getTasksForDay(_weekDays[_selectedDayTabIndex]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Center(child: Text(AppLocalizations.of(context).somethingWentWrong, style: const TextStyle(color: AppColors.bone500, fontSize: 12))),
                              );
                            }
                            final tasks = snapshot.data ?? [];
                            return FutureBuilder<Map<String, String>>(
                              future: _getPlantHealthMap(),
                              builder: (context, healthSnap) {
                                if (healthSnap.connectionState == ConnectionState.waiting && _plantHealthMapCache.isEmpty) {
                                  return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: CircularProgressIndicator()));
                                }
                                if (healthSnap.hasData) {
                                  _plantHealthMapCache = healthSnap.data!;
                                }
                                
                                final pendingTasks = List<Task>.from(tasks.where((t) => !t.isCompleted));
                                final completedCount = tasks.where((t) => t.isCompleted).length;
                                
                                final scoredTasks = pendingTasks.map((t) {
                                  int score = 100;
                                  final healthStatus = _plantHealthMapCache[t.plantName] ?? 'Healthy';
                                  if (healthStatus != 'Healthy' && healthStatus != 'Thriving') score += 50;
                                  final today = DateTime.now();
                                  final due = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
                                  final diff = DateTime(today.year, today.month, today.day).difference(due).inDays;
                                  if (diff == 1) {
                                    score += 30;
                                  } else if (diff == 2) {
                                    score += 60;
                                  } else if (diff >= 3) {
                                    score += 100;
                                  }
                                  if (t.taskType == 'Inspection' || t.taskType == 'Treatment') {
                                    score += 20;
                                  }
                                  if (t.taskType == 'Watering') {
                                    score += 10;
                                  }
                                  return MapEntry(t, score);
                                }).toList();
                                
                                scoredTasks.sort((a, b) => b.value.compareTo(a.value));
                                
                                return Column(
                                  children: [
                                    FutureBuilder<QuerySnapshot>(
                                      future: FirebaseFirestore.instance.collection('challenges').where('isActive', isEqualTo: true).limit(1).get(),
                                      builder: (context, challengeSnap) {
                                        if (!challengeSnap.hasData || challengeSnap.data!.docs.isEmpty) return const SizedBox();
                                        final challenge = challengeSnap.data!.docs.first.data() as Map<String, dynamic>;
                                        final title = challenge['title'] ?? 'Community Challenge';
                                        final progress = (completedCount / 15.0).clamp(0.0, 1.0);
                                        return GestureDetector(
                                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen())),
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 16),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).cardColor,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.amber.shade200),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                                                    const SizedBox(width: 8),
                                                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                                    Text(AppLocalizations.of(context).tasksDoneThisWeek(completedCount), style: const TextStyle(color: AppColors.bone500, fontSize: 12)),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                LinearProgressIndicator(
                                                  value: progress,
                                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                  color: Colors.green,
                                                  minHeight: 4,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    if (pendingTasks.isEmpty)
                                      EmptyState(
                                        icon: Icons.calendar_today,
                                        title: AppLocalizations.of(context).noCareTasksYet,
                                        subtitle: AppLocalizations.of(context).addPlantForCareSchedule,
                                        buttonLabel: AppLocalizations.of(context).addAPlant,
                                        onButtonTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const AddPlantScreen()),
                                        ),
                                      )
                                    else ...[
                                      if (pendingTasks.length >= 2)
                                        GestureDetector(
                                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BatchCareScreen(tasks: pendingTasks))),
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 16),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppColors.darkForestSubtle : AppColors.forest50,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isDark ? AppColors.darkBorderDefault : AppColors.bone200,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? AppColors.darkTerracottaSubtle : AppColors.terracotta100,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.flash_on, color: AppColors.terracotta500, size: 24),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Quick Care Mode',
                                                        style: TextStyle(
                                                          color: isDark ? AppColors.darkForestPrimary : AppColors.forest700,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        AppLocalizations.of(context).swipeThroughTasksFast,
                                                        style: const TextStyle(
                                                          color: AppColors.bone500,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: isDark ? AppColors.darkForestPrimary : AppColors.forest700,
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ...scoredTasks.map((entry) {
                                      final task = entry.key;
                                      final score = entry.value;
                                      final style = careTypeStyle(task.taskType);
                                      final isOverdue = !task.isCompleted && task.dueDate.isBefore(DateTime(today.year, today.month, today.day));
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: _buildTaskCard(
                                          context: context,
                                          task: task,
                                          icon: style.icon,
                                          iconBgColor: style.tileColor,
                                          iconColor: style.iconColor,
                                          title: task.taskType,
                                          subtitle: '${task.plantName}${task.notes.isNotEmpty ? ' (${task.notes})' : ''}${isOverdue ? ' • Overdue' : ''}',
                                          isOverdue: isOverdue,
                                          priorityScore: score,
                                        ),
                                      );
                                    }),
                                    ],
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        // Climate & Light Meter
                        Row(
                          children: [
                            Expanded(child: _buildQuickButton(context, Icons.thermostat, AppLocalizations.of(context).roomClimate, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClimateScreen())))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildQuickButton(context, Icons.wb_sunny_outlined, AppLocalizations.of(context).lightMeter, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LightMeterScreen())))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CareInsightsScreen())),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkForestSubtle : AppColors.forest50,
                              borderRadius: BorderRadius.circular(16),
                              border: const Border(left: BorderSide(color: AppColors.forest200, width: 4)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkForestSubtle : AppColors.forest100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.psychology,
                                    color: isDark ? AppColors.darkForestPrimary : AppColors.forest900,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context).smartCarePlan,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isDark ? AppColors.darkForestPrimary : AppColors.forest900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppLocalizations.of(context).personalizedScheduleBasedOnHome,
                                        style: const TextStyle(color: AppColors.bone500, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.bone300),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              // History Tab
              Expanded(
                child: _buildHistoryTab(),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildTab(String label, int index) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.bone900 : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.bone900 : AppColors.bone500,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final uid = _firestoreService.currentUserId;
    if (uid == null) {
      return Center(child: Text(AppLocalizations.of(context).notSignedIn, style: const TextStyle(color: AppColors.bone500)));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('task_history')
          .orderBy('completedAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(AppLocalizations.of(context).somethingWentWrong, style: const TextStyle(color: AppColors.bone500)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.eco, size: 64, color: AppColors.forest200),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).noCompletedTasksYet,
                  style: GoogleFonts.outfit(color: AppColors.bone500, fontSize: 16),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final plantName = data['plantName'] as String? ?? AppLocalizations.of(context).unknownPlantFallback;
            final taskType = data['taskType'] as String? ?? '';
            DateTime? completedAt;
            final ts = data['completedAt'];
            if (ts is Timestamp) completedAt = ts.toDate();
            final dateStr = completedAt != null ? DateFormat('MMM d, yyyy').format(completedAt) : '—';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.bone900)),
                        const SizedBox(height: 2),
                        Text(taskType, style: const TextStyle(color: AppColors.bone500, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text(dateStr, style: const TextStyle(color: AppColors.bone500, fontSize: 12)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCircleArrow(IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: isDark ? Colors.white.withValues(alpha: 0.70) : AppColors.bone900),
    );
  }

  Widget _buildDayColumn(String dayName, String date, {bool isToday = false, bool isSelected = false, List<Color> dotColors = const []}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Selected (today or future): forest700 filled circle, white text.
    // Today when NOT selected: forest700 ring/border, normal text.
    // Neither: transparent, normal text.
    final Color bgColor = isSelected
        ? AppColors.forest700
        : Colors.transparent;
    final Color textColor = isSelected
        ? Colors.white
        : (isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87);
    final bool showRing = isToday && !isSelected;
    final Color dayNameColor = isDark ? AppColors.darkTextTertiary : AppColors.bone500;

    return Column(
      children: [
        Text(dayName, style: TextStyle(color: dayNameColor, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: showRing
                ? Border.all(color: AppColors.forest700, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            date,
            style: TextStyle(
              color: textColor,
              fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 6,
          child: dotColors.isNotEmpty
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: dotColors.take(3).map((c) => Container(
                    width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  )).toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildQuickButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color chipBg = isDark ? AppColors.darkChipSurface : AppColors.forest100;
    final Color iconCircleBg = isDark ? AppColors.darkSurfaceElevated : Theme.of(context).cardColor;
    final Color iconColor = isDark ? AppColors.forest400 : Theme.of(context).primaryColor;
    final Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.bone900;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(20),
          border: isDark
              ? Border.all(color: AppColors.darkCardBorder, width: 1)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconCircleBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard({
    required BuildContext context,
    required Task task,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isOverdue = false,
    int priorityScore = 0,
  }) {
    Border? customBorder;
    if (priorityScore > 150) {
      customBorder = const Border(left: BorderSide(color: AppColors.terracotta900, width: 2));
    } else if (priorityScore > 100) {
      customBorder = Border(left: BorderSide(color: Colors.amber.shade700, width: 2));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark && customBorder == null
            ? Border.all(color: AppColors.darkCardBorder, width: 1)
            : customBorder,
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.taskType,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.bone900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${task.plantName}${isOverdue ? ' • Overdue' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.bone500,
                  ),
                ),
                if (task.climateNote.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.climateNote,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.bone500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (task.isCompleted)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Text('Done', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          GestureDetector(
            onTap: () async {
              if (!task.isCompleted) {
                await _firestoreService.markTaskCompleted(task.id);
                await NotificationService().cancelTaskNotification(task.id);
                
                final daysLate = DateTime.now().difference(DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day)).inDays;
                if (daysLate >= 3 && context.mounted) {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(AppLocalizations.of(context).rescheduleCare(task.plantName)),
                      content: Text(AppLocalizations.of(context).completedDaysLateReschedule(task.taskType.toLowerCase(), daysLate)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, 'keep'), child: Text(AppLocalizations.of(context).keepSchedule)),
                        TextButton(onPressed: () => Navigator.pop(ctx, 'today'), child: Text(AppLocalizations.of(context).fromToday)),
                      ],
                    ),
                  );
                  if (result == 'today') {
                    final uid = _firestoreService.currentUserId;
                    if (uid != null) {
                      final tasksSnap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('tasks')
                        .where('plantId', isEqualTo: task.plantId)
                        .where('taskType', isEqualTo: task.taskType)
                        .where('isCompleted', isEqualTo: false)
                        .get();
                      
                      for (var nextDoc in tasksSnap.docs) {
                        final nextData = nextDoc.data();
                        if (nextData['dueDate'] is Timestamp) {
                          final due = (nextData['dueDate'] as Timestamp).toDate();
                          if (due.isAfter(DateTime.now())) {
                            final interval = due.difference(task.dueDate).inDays;
                            await nextDoc.reference.update({'dueDate': Timestamp.fromDate(DateTime.now().add(Duration(days: interval)))});
                            break;
                          }
                        }
                      }
                    }
                  }
                }

                try {
                  final badgesService = BadgesService();
                  final uid = _firestoreService.currentUserId;
                  if (uid != null) await badgesService.checkAndAwardBadges(uid);
                } catch (e) { /* ignore */ }

                final uid = _firestoreService.currentUserId;
                if (uid != null) {
                  try {
                    final plantsSnap = await FirebaseFirestore.instance
                        .collection('users').doc(uid).collection('plants')
                        .where('name', isEqualTo: task.plantName).limit(1).get();
                    if (plantsSnap.docs.isNotEmpty) {
                      final plantDoc = plantsSnap.docs.first;
                      final plantData = plantDoc.data();
                      int baseDays = 7;
                      if (task.taskType.toLowerCase().contains('fertiliz')) baseDays = 30;
                      if (task.taskType.toLowerCase().contains('repot')) baseDays = 365;
                      final nextData = await CareIntelligenceService().computeNextCareDate(
                        plantId: plantDoc.id,
                        plantName: task.plantName,
                        category: plantData['category']?.toString() ?? '',
                        baseIntervalDays: baseDays,
                        lastWateredDate: DateTime.now(),
                        userUid: uid,
                      );
                      await FirebaseFirestore.instance
                          .collection('users').doc(uid).collection('tasks').doc(task.id)
                          .update({
                        'dueDate': nextData['nextDate'],
                        'isCompleted': false,
                        'lastSchedulingReason': nextData['reasoning'],
                      });
                      if (context.mounted) {
                        showToast(context, 'Next ${task.taskType.toLowerCase()} in ${nextData['adjustedInterval']} days: ${nextData['reasoning']}', isError: false);
                      }
                    }
                  } catch (e) {
                    debugPrint('Error computing next care date: $e');
                  }
                }
              }
            },
            child: Icon(
              task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: task.isCompleted ? Colors.green : AppColors.bone300,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

}
