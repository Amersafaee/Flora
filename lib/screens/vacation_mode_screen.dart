import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/task_model.dart';
import 'care_plan_screen.dart';

class VacationModeScreen extends StatefulWidget {
  const VacationModeScreen({super.key});

  @override
  State<VacationModeScreen> createState() => _VacationModeScreenState();
}

class _VacationModeScreenState extends State<VacationModeScreen> {
  bool _isEnabled = false;
  DateTime? _startDate;
  DateTime? _endDate;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
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
    setState(() {
      _isEnabled = value;
    });
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
    
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where('isCompleted', isEqualTo: false)
        .get();
        
    for (var doc in snapshot.docs) {
      final task = Task.fromMap(doc.data());
      await _notificationService.scheduleTaskNotification(
        task.id,
        task.plantName,
        task.taskType,
        task.dueDate,
      );
    }
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
              primary: Color(0xFF154212),
              onPrimary: Colors.white,
              onSurface: Color(0xFF191C1B),
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
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = _endDate;
          }
        }
      });
      await _saveState();
    }
  }

  Future<void> _generateCarePlan() async {
    final uid = _firestoreService.currentUserId;
    if (uid == null) return;

    final sitterName = _nameController.text.trim();
    if (sitterName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a sitter name.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates.'), backgroundColor: Colors.red),
      );
      return;
    }

    final startStr = DateFormat('MMM d, yyyy').format(_startDate!);
    final endStr = DateFormat('MMM d, yyyy').format(_endDate!);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('plants')
        .get();

    final buffer = StringBuffer();
    buffer.writeln('Plant Care Guide for $sitterName');
    buffer.writeln('Dates: $startStr to $endStr\n');

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final name = data['name'] ?? 'Unknown Plant';
      final category = data['category']?.toString().toLowerCase() ?? '';
      
      buffer.write('$name: ');
      
      if (category.contains('tropical')) {
        buffer.writeln('Water every 7 days and keep in bright indirect light.');
      } else if (category.contains('succulent')) {
        buffer.writeln('Water every 14 days and keep in direct sunlight.');
      } else if (category.contains('fern')) {
        buffer.writeln('Water every 3 days and keep away from direct sun.');
      } else if (category.contains('herb')) {
        buffer.writeln('Water when soil feels dry and keep in a sunny spot.');
      } else {
        buffer.writeln('Check soil before watering and keep in a suitable light spot.');
      }
    }

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CarePlanScreen(carePlanText: buffer.toString()),
        ),
      );
    }

    // Send email to sitter if email is provided
    final sitterEmail = _emailController.text.trim();
    if (sitterEmail.isNotEmpty) {
      await _sendEmailToSitter(sitterEmail, buffer.toString());
    }
  }

  Future<void> _sendEmailToSitter(String email, String carePlanText) async {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Your Plant Parent';
    final subject = Uri.encodeComponent('Plant Care Guide from $displayName');
    final body = Uri.encodeComponent(carePlanText);
    final mailtoUri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    if (await canLaunchUrl(mailtoUri)) {
      await launchUrl(mailtoUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email app.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF154212);
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    const Color terracotta = Color(0xFF8D3220);
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    const Color lightGreen = Color(0xFFE8F3EA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Vacation Mode', style: TextStyle(color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
              // Illustration Area
              const SizedBox(height: 16),
              const Icon(Icons.wb_sunny, size: 64, color: terracotta),
              const SizedBox(height: 16),
              Text(
                'Going somewhere?', style: TextStyle(color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We will take care of your reminders while you are away.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Enable Toggle Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isEnabled ? lightGreen : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Vacation Mode', style: TextStyle(color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pauses all plant care notifications.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isEnabled,
                      onChanged: _toggleVacationMode,
                      activeColor: primaryColor,
                    ),
                  ],
                ),
              ),
              
              if (_isEnabled) ...[
                const SizedBox(height: 24),
                // Trip Settings Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR TRIP',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Start Date
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Start Date',
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
                              _startDate != null ? DateFormat('MMM d, yyyy').format(_startDate!) : 'Select Date',
                              style: TextStyle(
                                color: _startDate != null ? primaryColor : Colors.grey.shade500,
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
                          const Icon(Icons.event, color: Colors.grey, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'End Date',
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
                              _endDate != null ? DateFormat('MMM d, yyyy').format(_endDate!) : 'Select Date',
                              style: TextStyle(
                                color: _endDate != null ? primaryColor : Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(height: 1, thickness: 1),
                      ),
                      
                      Text(
                        'PLANT SITTER',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Sitter Name
                      Text(
                        'Sitter Name', style: TextStyle(color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Sarah',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Sitter Email
                      Text(
                        'Sitter Email', style: TextStyle(color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'e.g. sarah@email.com',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Generate Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _generateCarePlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Generate Care Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
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







