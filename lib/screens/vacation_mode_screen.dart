import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';

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
              primary: AppColors.forest900,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.pleaseSelectDates), backgroundColor: Colors.red),
      );
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
    buffer.writeln('- Sent from Digital Conservatory');

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
    const Color primaryColor = AppColors.forest900;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    const Color terracotta = AppColors.terracotta900;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    const Color lightGreen = AppColors.forest100;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l.vacationMode, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.wb_sunny, size: 64, color: terracotta),
              const SizedBox(height: 16),
              Text(
                l.goingSomewhere,
                style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'serif'),
              ),
              const SizedBox(height: 8),
              Text(
                l.takeCareOfReminders,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.bone500, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Enable Toggle Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isEnabled ? lightGreen : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.enableVacationMode, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(l.pausesAllNotifications, style: const TextStyle(color: AppColors.bone500, fontSize: 13)),
                        ],
                      ),
                    ),
                    Switch(value: _isEnabled, onChanged: _toggleVacationMode, activeColor: primaryColor),
                  ],
                ),
              ),

              if (_isEnabled) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.yourTrip, style: const TextStyle(color: AppColors.bone500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 16),
                      // Start Date
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.bone500, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(l.startDate, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15))),
                          GestureDetector(
                            onTap: () => _selectDate(context, true),
                            child: Text(
                              _startDate != null ? DateFormat('MMM d, yyyy').format(_startDate!) : l.selectDate,
                              style: TextStyle(color: _startDate != null ? primaryColor : AppColors.bone500, fontWeight: FontWeight.w600, fontSize: 15),
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
                          Expanded(child: Text(l.endDate, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15))),
                          GestureDetector(
                            onTap: () => _selectDate(context, false),
                            child: Text(
                              _endDate != null ? DateFormat('MMM d, yyyy').format(_endDate!) : l.selectDate,
                              style: TextStyle(color: _endDate != null ? primaryColor : AppColors.bone500, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Generate Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isGenerating ? null : _generateCarePlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isGenerating
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(l.generateCarePlanAction, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      if (_generatedPlanController.text.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        TextField(
                          controller: _generatedPlanController,
                          maxLines: 12,
                          decoration: InputDecoration(
                            labelText: l.yourCarePlan,
                            labelStyle: const TextStyle(color: primaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            hintText: l.editCarePlanHint,
                          ),
                          style: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.share, color: Colors.white),
                            label: Text(l.shareEmoji, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              final text = _generatedPlanController.text.trim();
                              if (text.isNotEmpty) {
                                SharePlus.instance.share(ShareParams(text: text, subject: 'Plant Care Plan from Digital Conservatory'));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.copy, size: 18),
                          label: Text(l.copyToClipboard),
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
