import '../services/badges_service.dart';
import 'add_task_screen.dart';
import 'package:flutter/material.dart';
import 'global_search_screen.dart';
import 'climate_screen.dart';
import 'light_meter_screen.dart';
import 'profile_screen.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/task_model.dart';
import 'care_insights_screen.dart';
import '../services/care_intelligence_service.dart';
import 'batch_care_screen.dart';
import 'add_plant_screen.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CareScreen extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;
  const CareScreen({super.key, this.onThemeChanged});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  int _selectedTab = 0; // 0 = Upcoming, 1 = History
  late DateTime currentWeekStart;
  DateTime? _selectedDate;
  final FirestoreService _firestoreService = FirestoreService();

  // Cache task dates for dots
  Map<String, List<Color>> _taskDots = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Find Monday of current week
    currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    currentWeekStart = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
    _loadTasksForWeek();
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
      final d = task.dueDate;
      final key = '${d.year}-${d.month}-${d.day}';
      final color = _taskTypeColors(task.taskType).$2;
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
    return _taskDots['${date.year}-${date.month}-${date.day}'] ?? [];
  }


  Future<void> _showTasksForDate(DateTime date) async {
    setState(() => _selectedDate = date);
    final uid = _firestoreService.currentUserId;
    if (uid == null) return;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('dueDate')
        .get();

    if (!mounted) return;

    final tasks = snap.docs.map((d) => Task.fromMap(d.data())).toList();
    final dateLabel = DateFormat('EEEE, MMMM d').format(date);
    final primaryColor = Theme.of(context).primaryColor;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Date title
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        dateLabel,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Task list or empty state
                  if (tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No tasks scheduled for this day 🌿',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final task = tasks[i];
                          final done = task.isCompleted;
                          final tc = _taskTypeColors(task.taskType);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 6),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: done
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : tc.$2.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                done ? Icons.check_circle : tc.$1,
                                color: done ? Colors.green : tc.$2,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              task.taskType,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                decoration: done ? TextDecoration.lineThrough : null,
                                color: done ? Colors.grey : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              task.plantName,
                              style: TextStyle(
                                fontSize: 13,
                                decoration: done ? TextDecoration.lineThrough : null,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            trailing: done
                                ? const Icon(Icons.check_circle, color: Colors.green, size: 26)
                                : GestureDetector(
                                    onTap: () async {
                                      await _firestoreService.markTaskCompleted(task.id);
                                      // Refresh the sheet list
                                      final updatedSnap = await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(uid)
                                          .collection('tasks')
                                          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                                          .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
                                          .orderBy('dueDate')
                                          .get();
                                      final updated = updatedSnap.docs.map((d) => Task.fromMap(d.data())).toList();
                                      setSheetState(() {
                                        tasks
                                          ..clear()
                                          ..addAll(updated);
                                      });
                                      // Refresh dot cache
                                      _loadTasksForWeek();
                                    },
                                    child: Icon(
                                      Icons.radio_button_unchecked,
                                      color: Colors.grey.shade400,
                                      size: 26,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
                ],
              ),
            );
          },
        );
      },
    );
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
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskScreen()));
              },
              backgroundColor: primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ProfileScreen(onThemeChanged: widget.onThemeChanged),
                      ));
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
                  IconButton(
                    icon: Icon(Icons.search, color: primaryColor),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen())),
                  ),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildTab('Upcoming', 0),
                  const SizedBox(width: 24),
                  _buildTab('History', 1),
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
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191C1B),
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

              // Calendar Days Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (i) {
                    final day = _weekDays[i];
                    final isToday = DateTime(day.year, day.month, day.day) == todayKey;
                    final isSelected = _selectedDate != null &&
                        DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day) ==
                            DateTime(day.year, day.month, day.day);
                    final dotColors = _getDotsForDate(day);
                    return GestureDetector(
                      onTap: () => _showTasksForDate(day),
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

              // Tasks Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  "Tasks for the Week",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF191C1B)),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        StreamBuilder<List<Task>>(
                          stream: _firestoreService.getTasksForWeek(currentWeekStart),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (snapshot.hasError) {
                              return const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(child: Text('Something went wrong', style: TextStyle(color: Colors.grey, fontSize: 12))),
                              );
                            }
                            final tasks = snapshot.data ?? [];
                            if (tasks.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today, size: 60, color: Color(0xFF154212)),
                                    const SizedBox(height: 20),
                                    Text(
                                      'No care tasks yet',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Add a plant to get a care schedule built automatically by Flora',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPlantScreen()));
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF154212),
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text('Add a Plant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Column(
                              children: [
                                if (tasks.length >= 2)
                                  GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BatchCareScreen(tasks: tasks))),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF154212),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                            child: const Icon(Icons.flash_on, color: Colors.white),
                                          ),
                                          const SizedBox(width: 16),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Quick Care Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                                SizedBox(height: 4),
                                                Text('Swipe through all tasks fast', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                ...tasks.map((task) {
                                  final colors = _taskTypeColors(task.taskType);
                                  final isOverdue = !task.isCompleted && task.dueDate.isBefore(DateTime(today.year, today.month, today.day));
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildTaskCard(
                                      context: context,
                                      task: task,
                                      icon: colors.$1,
                                      iconBgColor: colors.$2.withValues(alpha: 0.15),
                                      iconColor: colors.$2,
                                      title: task.taskType,
                                      subtitle: '${task.plantName}${task.notes.isNotEmpty ? ' (${task.notes})' : ''}${isOverdue ? ' • Overdue' : ''}',
                                      isOverdue: isOverdue,
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        // Climate & Light Meter
                        Row(
                          children: [
                            Expanded(child: _buildQuickButton(context, Icons.thermostat, 'Room\nClimate', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClimateScreen())))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildQuickButton(context, Icons.wb_sunny_outlined, 'Light\nMeter', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LightMeterScreen())))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CareInsightsScreen())),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: const Border(left: BorderSide(color: Color(0xFF154212), width: 4)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                                  child: const Icon(Icons.psychology, color: Color(0xFF154212), size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Smart Care Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF154212))),
                                      const SizedBox(height: 4),
                                      Text('Personalized schedule based on your home', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
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

  /// Returns the canonical (IconData, Color) pair for a given task type.
  /// Used by both the task card builder and anywhere else that needs task colour.
  (IconData, Color) _taskTypeColors(String taskType) {
    final t = taskType.toLowerCase();
    if (t.contains('water'))    return (Icons.water_drop,          const Color(0xFF2196F3)); // blue
    if (t.contains('fertiliz')) return (Icons.science,             const Color(0xFF8BC34A)); // light green
    if (t.contains('repot'))    return (Icons.yard,                const Color(0xFF795548)); // brown
    if (t.contains('prun'))     return (Icons.content_cut,         const Color(0xFF4CAF50)); // green
    if (t.contains('mist'))     return (Icons.air,                 const Color(0xFF00BCD4)); // cyan
    if (t.contains('inspect'))  return (Icons.search,              const Color(0xFFFF9800)); // orange
    if (t.contains('treat'))    return (Icons.medical_services,    const Color(0xFFE91E63)); // pink
    return (Icons.check_circle_outline,                            const Color(0xFF154212)); // app primary
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
              color: isActive ? const Color(0xFF191C1B) : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF191C1B) : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final uid = _firestoreService.currentUserId;
    if (uid == null) {
      return const Center(child: Text('Not signed in.', style: TextStyle(color: Colors.grey)));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .where('isCompleted', isEqualTo: true)
          .orderBy('dueDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong', style: TextStyle(color: Colors.grey)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No completed tasks yet.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final plantName = data['plantName'] as String? ?? 'Unknown Plant';
            final taskType = data['taskType'] as String? ?? '';
            DateTime? dueDate;
            final ts = data['dueDate'];
            if (ts is Timestamp) dueDate = ts.toDate();
            final dateStr = dueDate != null ? DateFormat('MMM d, yyyy').format(dueDate) : '—';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
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
                        Text(plantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF191C1B))),
                        const SizedBox(height: 2),
                        Text(taskType, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCircleArrow(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: const Color(0xFF191C1B)),
    );
  }

  Widget _buildDayColumn(String dayName, String date, {bool isToday = false, bool isSelected = false, List<Color> dotColors = const []}) {
    final bool highlight = isToday || isSelected;
    final Color bgColor = isToday
        ? const Color(0xFF154212)
        : isSelected
            ? const Color(0xFF154212).withValues(alpha: 0.15)
            : Colors.transparent;
    final Color textColor = isToday ? Colors.white : Colors.black87;

    return Column(
      children: [
        Text(dayName, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: isSelected && !isToday
                ? Border.all(color: const Color(0xFF154212), width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            date,
            style: TextStyle(
              color: textColor,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
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
    const Color softGreen = Color(0xFFE8F3EA);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(color: softGreen, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
              child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF191C1B))),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isOverdue ? Colors.red : const Color(0xFF191C1B))),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: isOverdue ? Colors.red.shade300 : Colors.grey.shade600, fontSize: 13)),
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
                        zoneUid: 'main_zone',
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
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            'Next ${task.taskType.toLowerCase()} in ${nextData['adjustedInterval']} days: ${nextData['reasoning']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF154212),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 4),
                        ));
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
              color: task.isCompleted ? Colors.green : Colors.grey.shade400,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
