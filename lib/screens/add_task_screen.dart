import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/task_model.dart';

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
  String _repeatType = 'Does Not Repeat';
  List<String> _repeatDays = [];
  
  bool _isLoading = false;
  bool _showNameError = false;
  bool _showTypeError = false;
  
  final FirestoreService _firestoreService = FirestoreService();
  final List<String> _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<String> _fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _plantNameController = TextEditingController(text: widget.task?.plantName ?? '');
    _notesController = TextEditingController(text: widget.task?.notes ?? '');
    
    if (widget.task != null) {
      _selectedTaskType = widget.task!.taskType;
      _selectedDate = widget.task!.dueDate;
      if (widget.task!.repeatType != null) {
        _repeatType = widget.task!.repeatType!;
      }
      if (widget.task!.repeatDays != null) {
        _repeatDays = List.from(widget.task!.repeatDays!);
      }
    }
  }

  @override
  void dispose() {
    _plantNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveTask() async {
    setState(() {
      _showNameError = _plantNameController.text.trim().isEmpty;
      _showTypeError = _selectedTaskType == null;
    });
    
    if (_showNameError || _showTypeError) return;
    
    setState(() => _isLoading = true);
    
    try {
      final taskId = widget.task?.id ?? FirebaseFirestore.instance.collection('dummy').doc().id;

      final task = Task(
        id: taskId,
        plantName: _plantNameController.text.trim(),
        taskType: _selectedTaskType!,
        dueDate: _selectedDate,
        isCompleted: widget.task?.isCompleted ?? false,
        notes: _notesController.text.trim(),
        repeatType: _repeatType == 'Does Not Repeat' ? null : _repeatType,
        repeatDays: _repeatType == 'Custom Days' ? _repeatDays : null,
      );
      
      if (widget.task != null) {
        await _firestoreService.updateTask(task);
      } else {
        await _firestoreService.addTask(task);
      }
      
      await NotificationService().scheduleTaskNotification(
        taskId,
        task.plantName,
        task.taskType,
        task.dueDate,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.task != null ? 'Task updated successfully' : 'Task added successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.grey,
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    
    return '//';
  }

  @override
  Widget build(BuildContext context) {
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
                        widget.task != null ? 'Edit Task' : 'Add Task',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 32),
              
              Text('Plant Name', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              TextField(
                controller: _plantNameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Monstera Deliciosa',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E211E) : const Color(0xFFFFFFFF),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCCCCCC))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCCCCCC))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF154212), width: 2)),
                ),
              ),
              if (_showNameError)
                const Padding(padding: EdgeInsets.only(top: 6, left: 4), child: Text('Plant name is required.', style: TextStyle(color: Colors.red, fontSize: 12))),
              const SizedBox(height: 24),
              
              Text('Task Type', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTaskTypeChip('Watering'),
                  const SizedBox(width: 12),
                  _buildTaskTypeChip('Fertilizing'),
                  const SizedBox(width: 12),
                  _buildTaskTypeChip('Repotting'),
                ],
              ),
              if (_showTypeError)
                const Padding(padding: EdgeInsets.only(top: 6, left: 4), child: Text('Please select a task type.', style: TextStyle(color: Colors.red, fontSize: 12))),
              const SizedBox(height: 24),
              
              Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDate(_selectedDate), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
                      Icon(Icons.calendar_today, color: Colors.grey.shade500, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text('Repeat', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRepeatTypeChip('Does Not Repeat'),
                    const SizedBox(width: 8),
                    _buildRepeatTypeChip('Daily'),
                    const SizedBox(width: 8),
                    _buildRepeatTypeChip('Weekly'),
                    const SizedBox(width: 8),
                    _buildRepeatTypeChip('Monthly'),
                    const SizedBox(width: 8),
                    _buildRepeatTypeChip('Custom Days'),
                  ],
                ),
              ),
              if (_repeatType == 'Custom Days') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final day = _fullDays[index];
                    final isSelected = _repeatDays.contains(day);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _repeatDays.remove(day);
                          } else {
                            _repeatDays.add(day);
                          }
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? primaryColor : Theme.of(context).cardColor,
                          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            _weekDays[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 24),
              
              Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Any additional notes...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E211E) : const Color(0xFFFFFFFF),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCCCCCC))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCCCCCC))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF154212), width: 2)),
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
                          widget.task != null ? 'Update Task' : 'Save Task',
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

  Widget _buildTaskTypeChip(String label) {
    final bool isSelected = _selectedTaskType == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTaskType = label;
          _showTypeError = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14),
        ),
      ),
    );
  }
  
  Widget _buildRepeatTypeChip(String label) {
    final bool isSelected = _repeatType == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _repeatType = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
        ),
      ),
    );
  }
}









