import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/task_providers.dart';
import '../../theme/app_theme.dart';

class CareScreen extends ConsumerStatefulWidget {
  const CareScreen({super.key});

  @override
  ConsumerState<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends ConsumerState<CareScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateTime _focusedDay  = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.forestGreen,
          indicatorColor: AppColors.forestGreen,
          unselectedLabelColor: AppColors.moss,
          tabs: [
            Tab(text: l10n.upcoming),
            Tab(text: l10n.historyTab),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _UpcomingTab(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                onDaySelected: (sel, foc) => setState(() {
                  _selectedDay = sel;
                  _focusedDay  = foc;
                }),
              ),
              const _HistoryTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Upcoming Tab ──────────────────────────────────────────────────────────────
class _UpcomingTab extends ConsumerWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime, DateTime) onDaySelected;

  const _UpcomingTab({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Center(child: Text(l10n.notSignedIn));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allTasksStream = FirebaseFirestore.instance
        .collectionGroup('tasks')
        .where('completed', isEqualTo: false)
        .snapshots();

    return StreamBuilder(
      stream: allTasksStream,
      builder: (context, snap) {
        final allTasks = (snap.data?.docs ?? [])
            .where((d) => d.reference.path.contains('users/$uid'))
            .map((d) => CareTask.fromDoc(d))
            .toList();

        final pendingDays = <DateTime>{};
        for (final t in allTasks) {
          final d = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
          pendingDays.add(d);
        }

        final sel    = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
        final selEnd = sel.add(const Duration(days: 1));
        final todayTasks = allTasks
            .where((t) => !t.dueDate.isBefore(sel) && t.dueDate.isBefore(selEnd))
            .toList();

        final isToday = isSameDay(selectedDay, DateTime.now());

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: focusedDay,
              selectedDayPredicate: (d) => isSameDay(d, selectedDay),
              onDaySelected: onDaySelected,
              calendarStyle: CalendarStyle(
                defaultTextStyle: TextStyle(color: isDark ? Colors.white : AppColors.bark),
                weekendTextStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.bark),
                outsideTextStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                todayDecoration: const BoxDecoration(color: AppColors.forestGreen, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: AppColors.leafGreen.withAlpha(80), shape: BoxShape.circle),
                markerDecoration: const BoxDecoration(color: AppColors.terracotta, shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  final d = DateTime(day.year, day.month, day.day);
                  if (pendingDays.contains(d)) {
                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: AppColors.terracotta, shape: BoxShape.circle),
                      ),
                    );
                  }
                  return null;
                },
              ),
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                isToday ? l10n.todaysTasks : _formatHeaderDate(selectedDay),
                style: TextStyle(
                  fontFamily: 'NotoSerif',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.forestGreen,
                ),
              ),
            ),
            if (todayTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
                child: Column(
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text(
                      l10n.everythingsThrivingToday,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'NotoSerif', fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.forestGreen),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isToday ? l10n.plantsAreHappyHealthy : l10n.noTasksScheduledForDay,
                      style: const TextStyle(fontSize: 14, color: AppColors.moss),
                    ),
                  ],
                ),
              )
            else
              ...todayTasks.map((t) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _TaskCard(task: t),
              )),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  String _formatHeaderDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

// ── Task Card ─────────────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final CareTask task;
  const _TaskCard({required this.task});

  Color get _iconColor {
    switch (task.type) {
      case 'fertilize': return Colors.amber.shade700;
      case 'repot':     return const Color(0xFF795548);
      case 'mist':      return Colors.lightBlue;
      default:          return Colors.blue;
    }
  }

  IconData get _icon {
    switch (task.type) {
      case 'fertilize': return Icons.eco;
      case 'repot':     return Icons.yard;
      case 'mist':      return Icons.water;
      default:          return Icons.water_drop;
    }
  }

  String _label(AppLocalizations l10n) {
    switch (task.type) {
      case 'fertilize': return l10n.fertilise;
      case 'repot':     return l10n.repot;
      case 'mist':      return l10n.mist;
      default:          return l10n.waterAction;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final label = _label(l10n);

    return GestureDetector(
      onLongPress: () => _showSnoozeMenu(context, l10n),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadius.borderMd,
          boxShadow: AppShadows.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: _iconColor.withAlpha(25), shape: BoxShape.circle),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontFamily: 'NotoSerif', fontSize: 16, fontWeight: FontWeight.w600)),
                  if (task.plantNickname.isNotEmpty)
                    Text(task.plantNickname, style: const TextStyle(fontSize: 13, color: AppColors.moss)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _complete(context, label),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.leafGreen, width: 2)),
                child: const Icon(Icons.check, size: 20, color: AppColors.leafGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _complete(BuildContext context, String label) async {
    await completeTask(task);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).taskDoneNextScheduled(label)),
        backgroundColor: AppColors.leafGreen,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showSnoozeMenu(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.snooze),
              title: Text(l10n.snoozeOneDay),
              onTap: () async {
                Navigator.pop(context);
                await snoozeTask(task, 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.snooze),
              title: Text(l10n.snoozeThreeDays),
              onTap: () async {
                Navigator.pop(context);
                await snoozeTask(task, 3);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── History Tab ───────────────────────────────────────────────────────────────
class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Center(child: Text(l10n.notSignedIn));

    final completedStream = FirebaseFirestore.instance
        .collectionGroup('tasks')
        .where('completed', isEqualTo: true)
        .orderBy('completedAt', descending: true)
        .snapshots();

    return StreamBuilder(
      stream: completedStream,
      builder: (context, snap) {
        final tasks = (snap.data?.docs ?? [])
            .where((d) => d.reference.path.contains('users/$uid'))
            .map((d) => CareTask.fromDoc(d))
            .toList();

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📋', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(l10n.noCompletedTasksYet, style: const TextStyle(color: AppColors.moss)),
              ],
            ),
          );
        }

        final grouped = <String, List<CareTask>>{};
        for (final t in tasks) {
          final key = _dateKey(context, t.completedAt ?? t.dueDate);
          grouped.putIfAbsent(key, () => []).add(t);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: grouped.entries.map((e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.moss, fontSize: 13)),
              ),
              ...e.value.map((t) => _HistoryTile(task: t)),
            ],
          )).toList(),
        );
      },
    );
  }

  String _dateKey(BuildContext context, DateTime d) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return l10n.today;
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) return l10n.yesterday;
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _HistoryTile extends StatelessWidget {
  final CareTask task;
  const _HistoryTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: cs.surface, borderRadius: AppRadius.borderMd, boxShadow: AppShadows.cardShadow),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.leafGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${task.type[0].toUpperCase()}${task.type.substring(1)}',
              style: const TextStyle(fontFamily: 'NotoSerif', fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            task.completedAt != null ? _fmt(task.completedAt!) : '',
            style: const TextStyle(fontSize: 12, color: AppColors.moss),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
