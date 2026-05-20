import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;
  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  late TextEditingController _plantNameController;
  late TextEditingController _notesController;

  String? _selectedTaskType;
  DateTime _selectedDate = DateTime.now();
  String _repeatType = 'none';

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
      _showNameError = _plantNameController.text.trim().isEmpty;
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
        plantId: lookedUpPlantId,
        plantName: _plantNameController.text.trim(),
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
      }

      await NotificationService().scheduleTaskNotification(taskId, task.plantName, task.taskType, task.dueDate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.task != null ? l.taskUpdatedSuccessfully : l.taskAddedSuccessfully),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).somethingWentWrong),
            backgroundColor: AppColors.bone500,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.task != null ? l.editTask : l.addTask,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 32),

              Text(l.plantNameLabel, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              TextField(
                controller: _plantNameController,
                decoration: InputDecoration(
                  hintText: l.plantNameHint,
                  hintStyle: const TextStyle(color: AppColors.bone300),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.forest900, width: 2)),
                ),
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
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDate(_selectedDate), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
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
                decoration: InputDecoration(
                  hintText: l.notesHint,
                  hintStyle: const TextStyle(color: AppColors.bone300),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bone300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.forest900, width: 2)),
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          widget.task != null ? l.updateTask : l.saveTask,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
    final bool isSelected = _selectedTaskType == value;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTaskType = value;
        _showTypeError = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
      ),
    );
  }

  Widget _buildRepeatTypeChip(String label, String value) {
    final bool isSelected = _repeatType == value;
    return GestureDetector(
      onTap: () => setState(() => _repeatType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
      ),
    );
  }
}
