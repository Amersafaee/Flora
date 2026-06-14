import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import '../utils/toast_utils.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/primary_button.dart';
import '../widgets/shared/section_header.dart';

class VacationModeScreen extends StatefulWidget {
  const VacationModeScreen({super.key});

  @override
  State<VacationModeScreen> createState() => _VacationModeScreenState();
}

class _VacationModeScreenState extends State<VacationModeScreen> {
  bool _isEnabled = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isGenerating = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _generatedPlanController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEnabled = prefs.getBool('vacation_mode_enabled') ?? false;
      final startStr = prefs.getString('vacation_start_date');
      final endStr = prefs.getString('vacation_end_date');
      if (startStr != null) _startDate = DateTime.parse(startStr);
      if (endStr != null) _endDate = DateTime.parse(endStr);
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vacation_mode_enabled', _isEnabled);
    if (_startDate != null) {
      await prefs.setString('vacation_start_date', _startDate!.toIso8601String());
    } else {
      await prefs.remove('vacation_start_date');
    }
    if (_endDate != null) {
      await prefs.setString('vacation_end_date', _endDate!.toIso8601String());
    } else {
      await prefs.remove('vacation_end_date');
    }
  }

  Future<void> _toggleVacationMode(bool value) async {
    setState(() { _isEnabled = value; });
    await _saveState();
    if (_isEnabled) {
      await _notificationService.cancelAllNotifications();
    } else {
      await _rescheduleAllTasks();
    }
  }

  Future<void> _rescheduleAllTasks() async {
    final uid = _firestoreService.currentUserId;
    if (uid == null) return;

    final vacationDays = (_startDate != null && _endDate != null)
        ? _endDate!.difference(_startDate!).inDays : 0;
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('tasks')
        .where('isCompleted', isEqualTo: false).get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshot.docs) {
      final task = Task.fromMap(doc.data());
      final shiftedDate = task.dueDate.add(Duration(days: vacationDays));
      final rescheduleDate = shiftedDate.isBefore(DateTime.now()) ? tomorrow : shiftedDate;
      batch.update(doc.reference, {'dueDate': Timestamp.fromDate(rescheduleDate)});
      await _notificationService.scheduleTaskNotification(
          task.id, task.plantName, task.taskType, rescheduleDate);
    }
    await batch.commit();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? (_startDate ?? DateTime.now()));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.forest700,
              onPrimary: Colors.white,
              onSurface: AppColors.bone900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) _endDate = _startDate;
        } else {
          _endDate = picked;
          if (_startDate != null && _startDate!.isAfter(_endDate!)) _startDate = _endDate;
        }
      });
      await _saveState();
    }
  }

  Future<void> _generateCarePlan() async {
    final l = AppLocalizations.of(context);
    final uid = _firestoreService.currentUserId;
    if (uid == null) return;

    if (_startDate == null || _endDate == null) {
      showToast(context, l.pleaseSelectDates, isError: true);
      return;
    }

    setState(() => _isGenerating = true);

    final startStr = DateFormat('MMM d, yyyy').format(_startDate!);
    final endStr = DateFormat('MMM d, yyyy').format(_endDate!);
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Your';
    final userEmail = user?.email ?? 'Unknown';

    final snapshot = await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('plants').get();

    final buffer = StringBuffer();
    buffer.writeln("Care plan for $userName's plants while away $startStr to $endStr:");

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final name = data['name'] ?? 'Unknown Plant';

      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('tasks')
          .where('plantName', isEqualTo: name).get();

      if (tasksSnapshot.docs.isEmpty) {
        buffer.writeln('• $name: Water when soil feels dry.');
      } else {
        final tasks = tasksSnapshot.docs.map((d) => d.data()).toList();
        final taskTypes = tasks.map((t) => t['taskType'] as String).toSet();

        for (final type in taskTypes) {
          final typeTasks = tasks.where((t) => t['taskType'] == type).toList();
          final pending = typeTasks.where((t) => t['isCompleted'] == false).toList();
          final completed = typeTasks.where((t) => t['isCompleted'] == true).toList();

          completed.sort((a, b) {
            final tA = a['dueDate'] as Timestamp?;
            final tB = b['dueDate'] as Timestamp?;
            if (tA == null || tB == null) return 0;
            return tB.compareTo(tA);
          });

          final scheduleTask = pending.isNotEmpty ? pending.first : typeTasks.first;
          final repeatType = scheduleTask['repeatType'] as String? ?? 'none';

          String repeatStr = '';
          if (repeatType == 'daily') {
            repeatStr = '1';
          } else if (repeatType == 'every2days') {
            repeatStr = '2';
          } else if (repeatType == 'weekly') {
            repeatStr = '7';
          } else if (repeatType == 'biweekly') {
            repeatStr = '14';
          } else if (repeatType == 'monthly') {
            repeatStr = '30';
          } else if (repeatType == 'custom' || repeatType == '') {
            final days = (scheduleTask['repeatDays'] as num?)?.toInt() ?? 0;
            repeatStr = days > 0 ? '$days' : 'needed';
          } else {
            repeatStr = repeatType;
          }

          String lastDateStr = 'never';
          if (completed.isNotEmpty) {
            final lastDate = (completed.first['dueDate'] as Timestamp?)?.toDate();
            if (lastDate != null) lastDateStr = DateFormat('MMM d').format(lastDate);
          }

          buffer.writeln('• $name: $type every $repeatStr days. Last done: $lastDateStr.');
        }
      }
    }

    buffer.writeln();
    buffer.writeln('Emergency contact: $userEmail');
    buffer.writeln('- Sent from Verdoro');

    setState(() {
      _generatedPlanController.text = buffer.toString();
      _isGenerating = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _generatedPlanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color backgroundColor = isDark ? AppColors.darkBackground : AppColors.bone50;
    final Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.forest900;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back, size: 20, color: AppColors.forest700),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l.vacationMode,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.wb_sunny, size: 64, color: AppColors.terracotta500),
              const SizedBox(height: 16),
              Text(
                l.goingSomewhere,
                style: GoogleFonts.outfit(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.takeCareOfReminders,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.bone500, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Enable Toggle Card
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.enableVacationMode,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l.pausesAllNotifications,
                            style: const TextStyle(color: AppColors.bone500, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isEnabled,
                      onChanged: _toggleVacationMode,
                      activeTrackColor: AppColors.switchActiveTrack,
                      activeThumbColor: AppColors.switchThumb,
                      inactiveTrackColor: AppColors.switchInactiveTrack,
                      inactiveThumbColor: AppColors.switchThumb,
                      trackOutlineColor: AppColors.switchTrackOutline,
                    ),
                  ],
                ),
              ),

              if (_isEnabled) ...[
                const SizedBox(height: 24),
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(l.yourTrip),
                      const SizedBox(height: 16),
                      // Start Date
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.bone500, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l.startDate,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _selectDate(context, true),
                            child: Text(
                              _startDate != null ? DateFormat('MMM d, yyyy').format(_startDate!) : l.selectDate,
                              style: TextStyle(
                                color: _startDate != null ? AppColors.forest700 : AppColors.bone500,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // End Date
                      Row(
                        children: [
                          const Icon(Icons.event, color: AppColors.bone500, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l.endDate,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _selectDate(context, false),
                            child: Text(
                              _endDate != null ? DateFormat('MMM d, yyyy').format(_endDate!) : l.selectDate,
                              style: TextStyle(
                                color: _endDate != null ? AppColors.forest700 : AppColors.bone500,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Generate Button
                      PrimaryButton(
                        label: l.generateCarePlanAction,
                        onPressed: _generateCarePlan,
                        isLoading: _isGenerating,
                      ),
                      
                      if (_generatedPlanController.text.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.bone50,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.yourCarePlan,
                                style: const TextStyle(
                                  color: AppColors.forest700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                _generatedPlanController.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.bone900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: l.shareEmoji,
                          onPressed: () {
                            final text = _generatedPlanController.text.trim();
                            if (text.isNotEmpty) {
                              SharePlus.instance.share(ShareParams(text: text, subject: 'Plant Care Plan from Verdoro'));
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.copy, size: 18, color: AppColors.forest700),
                          label: Text(l.copyToClipboard, style: const TextStyle(color: AppColors.forest700)),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await Clipboard.setData(ClipboardData(text: _generatedPlanController.text));
                            messenger.showSnackBar(
                              SnackBar(content: Text(l.copiedToClipboard), backgroundColor: AppColors.forest900),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
