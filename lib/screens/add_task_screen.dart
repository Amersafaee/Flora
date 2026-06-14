import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/calendar_service.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import '../utils/toast_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;
  final String? initialPlantId;
  final String? initialPlantName;
  const AddTaskScreen({super.key, this.task, this.initialPlantId, this.initialPlantName});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  late TextEditingController _plantNameController;
  late TextEditingController _notesController;

  String? _selectedTaskType;
  DateTime _selectedDate = DateTime.now();
  String _repeatType = 'none';
  String? _selectedPlantName;

  bool _isLoading = false;
  bool _showNameError = false;
  bool _showTypeError = false;
  String _selectedPlantId = '';

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _plantNameController = TextEditingController(text: widget.task?.plantName ?? '');
    _notesController = TextEditingController(text: widget.task?.notes ?? '');
    _selectedPlantName = widget.task?.plantName.isEmpty == false
        ? widget.task!.plantName
        : widget.initialPlantName;
    if (widget.initialPlantId != null && widget.initialPlantId!.isNotEmpty) {
      _selectedPlantId = widget.initialPlantId!;
    }

    if (widget.task != null) {
      _selectedPlantId = widget.task!.plantId;
      _selectedTaskType = widget.task!.taskType;
      _selectedDate = widget.task!.dueDate;
      _repeatType = widget.task!.repeatType;
    }
  }

  @override
  void dispose() {
    _plantNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveTask() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _showNameError = (_selectedPlantName == null || _selectedPlantName!.trim().isEmpty);
      _showTypeError = _selectedTaskType == null;
    });

    if (_showNameError || _showTypeError) return;

    setState(() => _isLoading = true);

    try {
      final taskId = widget.task?.id ??
          FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('tasks')
              .doc()
              .id;

      String lookedUpPlantId = _selectedPlantId;
      if (lookedUpPlantId.isEmpty && _plantNameController.text.trim().isNotEmpty) {
        final uid = _firestoreService.currentUserId;
        if (uid != null) {
          final query = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('plants')
              .where('name', isEqualTo: _plantNameController.text.trim())
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            lookedUpPlantId = query.docs.first.id;
            _selectedPlantId = lookedUpPlantId;
          }
        }
      }

      final task = Task(
        id: taskId,
        plantId: _selectedPlantId,
        plantName: _selectedPlantName ?? '',
        taskType: _selectedTaskType!,
        dueDate: _selectedDate,
        isCompleted: widget.task?.isCompleted ?? false,
        notes: _notesController.text.trim(),
        repeatType: _repeatType,
        repeatDays: 0,
      );

      if (widget.task != null) {
        await _firestoreService.updateTask(task);
      } else {
        await _firestoreService.addTask(task);
        try {
          final eventId = await CalendarService.createEvent(
            title: task.taskType,
            description: '${task.plantName} - ${task.taskType}',
            date: task.dueDate,
          );
          if (eventId != null) {
            final uid = _firestoreService.currentUserId;
            if (uid != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('tasks')
                  .doc(task.id)
                  .update({'calendarEventId': eventId});
            }
          }
        } catch (e) {
          debugPrint('Warning: could not create calendar event: $e');
        }
      }

      // Notification failure must never crash the save flow
      try {
        await NotificationService().scheduleTaskNotification(
            task.id, task.plantName, task.taskType, task.dueDate);
      } catch (e) {
        debugPrint('Warning: could not schedule task notification: $e');
      }

      if (mounted) {
        showToast(context, widget.task != null ? l.taskUpdatedSuccessfully : l.taskAddedSuccessfully, isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, AppLocalizations.of(context).somethingWentWrong, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.bone50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back, size: 20, color: AppColors.forest700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.task != null ? l.editTask : l.addTask,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Text(l.plantNameLabel, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseAuth.instance.currentUser != null
                    ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection('plants')
                        .where('isDeceased', isEqualTo: false)
                        .get()
                    : null,
                builder: (context, snapshot) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final inputDecoration = InputDecoration(
                    filled: true,
                    fillColor: AppColors.bone100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.forest700, width: 1.5)),
                  );

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return DropdownButtonFormField<String>(
                      initialValue: null,
                      items: const [],
                      onChanged: null,
                      decoration: inputDecoration.copyWith(
                        hintText: '...',
                        hintStyle: GoogleFonts.outfit(color: AppColors.bone300),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return DropdownButtonFormField<String>(
                      initialValue: null,
                      items: const [],
                      onChanged: null,
                      decoration: inputDecoration.copyWith(
                        hintText: AppLocalizations.of(context).addAPlantFirst,
                        hintStyle: GoogleFonts.outfit(color: AppColors.bone300),
                      ),
                    );
                  }

                  final plantItems = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final commonName = (data['commonName'] as String?)?.trim() ?? '';
                    final name = (data['name'] as String?)?.trim() ?? '';
                    final displayName = commonName.isNotEmpty ? commonName : name;
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
                        ),
                      ),
                    );
                  }).toList();

                  // Ensure the pre-filled value from an existing task actually exists in the list
                  final validValues = docs.map((d) => ((d.data() as Map<String, dynamic>)['name'] as String?)?.trim() ?? '').toSet();
                  if (_selectedPlantName != null && !validValues.contains(_selectedPlantName)) {
                    _selectedPlantName = null;
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedPlantName,
                    items: plantItems,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedPlantName = value;
                        _showNameError = false;
                        // Look up plantId for the selected plant name
                        for (final doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          if ((data['name'] as String?)?.trim() == value) {
                            _selectedPlantId = doc.id;
                            break;
                          }
                        }
                      });
                    },
                    style: GoogleFonts.outfit(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
                    ),
                    decoration: inputDecoration.copyWith(
                      hintText: l.plantNameHint,
                      hintStyle: GoogleFonts.outfit(color: AppColors.bone300),
                    ),
                  );
                },
              ),
              if (_showNameError)
                Padding(padding: const EdgeInsets.only(top: 6, left: 4), child: Text(l.plantNameRequired, style: const TextStyle(color: Colors.red, fontSize: 12))),
              const SizedBox(height: 24),

              Text(l.taskType, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTaskTypeChip(l.watering, 'Watering'),
                  const SizedBox(width: 12),
                  _buildTaskTypeChip(l.fertilizing, 'Fertilizing'),
                  const SizedBox(width: 12),
                  _buildTaskTypeChip(l.repotting, 'Repotting'),
                ],
              ),
              if (_showTypeError)
                Padding(padding: const EdgeInsets.only(top: 6, left: 4), child: Text(l.pleaseSelectTaskType, style: const TextStyle(color: Colors.red, fontSize: 12))),
              const SizedBox(height: 24),

              Text(l.dueDate, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorderDefault : AppColors.bone200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_selectedDate),
                        style: GoogleFonts.outfit(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: AppColors.bone500, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(l.repeat, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 24),
                child: Row(
                  children: [
                    _buildRepeatTypeChip(l.doesNotRepeat, 'none'),
                    const SizedBox(width: 8),
                    _buildRepeatTypeChip(l.daily, 'daily'),
                    const SizedBox(width: 8),
                    _buildRepeatTypeChip(l.everyTwoDays, 'every2days'),
                    const SizedBox(width: 8),
                    _buildRepeatTypeChip(l.weekly, 'weekly'),
                    const SizedBox(width: 8),
                    _buildRepeatTypeChip(l.everyTwoWeeks, 'biweekly'),
                    const SizedBox(width: 8),
                    _buildRepeatTypeChip(l.monthly, 'monthly'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(l.notesLabel, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                style: GoogleFonts.outfit(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
                ),
                decoration: InputDecoration(
                  hintText: l.notesHint,
                  hintStyle: const TextStyle(color: AppColors.bone300),
                  filled: true,
                  fillColor: AppColors.bone100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone200, width: 1)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.forest700, width: 1.5)),
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          widget.task != null ? l.updateTask : l.saveTask,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTypeChip(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSelected = _selectedTaskType == value;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTaskType = value;
        _showTypeError = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forest700 : (isDark ? AppColors.darkSurface : AppColors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.forest700 : (isDark ? AppColors.darkBorderDefault : AppColors.bone200)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.forest900),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRepeatTypeChip(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSelected = _repeatType == value;
    return GestureDetector(
      onTap: () => setState(() => _repeatType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forest700 : (isDark ? AppColors.darkSurface : AppColors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.forest700 : (isDark ? AppColors.darkBorderDefault : AppColors.bone200)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.forest900),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
