import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';
import '../services/care_intelligence_service.dart';

class BatchCareScreen extends StatefulWidget {
  final List<Task> tasks;

  const BatchCareScreen({super.key, required this.tasks});

  @override
  State<BatchCareScreen> createState() => _BatchCareScreenState();
}

class _BatchCareScreenState extends State<BatchCareScreen> {
  int _currentIndex = 0;
  int _completedCount = 0;
  int _skippedCount = 0;
  bool _isAllDone = false;
  final Set<Task> _completedTasks = {};
  final Set<String> _completedTaskIds = {};

  void _handleSwipe(bool isCompleted) async {
    if (_currentIndex >= widget.tasks.length) return;

    final task = widget.tasks[_currentIndex];
    
    if (isCompleted) {
      _completedCount++;
      _completedTasks.add(task);
      try {
        final uid = FirestoreService().currentUserId;
        if (uid != null) {
          await FirestoreService().markTaskCompleted(task.id);
          _completedTaskIds.add(task.id);
          
          int baseInterval = 7;
          if (task.taskType == 'Fertilizing') baseInterval = 30;
          if (task.taskType == 'Repotting') baseInterval = 365;

          final intelligence = CareIntelligenceService();
          final nextCare = await intelligence.computeNextCareDate(
            plantId: '', // Default since Task doesn't store plantId
            plantName: task.plantName,
            category: 'General', // Fallback
            baseIntervalDays: baseInterval,
            lastWateredDate: DateTime.now(),
            zoneUid: 'main_zone', // Assumed for now
            userUid: uid,
          );
          
          final nextDate = nextCare['nextDate'] as DateTime;
          
          // Re-create the task for the future
          await FirestoreService().addTask(Task(
            id: '',
            plantName: task.plantName,
            taskType: task.taskType,
            dueDate: nextDate,
            isCompleted: false,
            notes: task.notes,
          ));
        }
      } catch (e) {
        debugPrint('Error marking task completed: $e');
      }
    } else {
      _skippedCount++;
    }

    if (mounted) {
      setState(() {
        if (_currentIndex < widget.tasks.length - 1) {
          _currentIndex++;
        } else {
          _isAllDone = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAllDone) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Quick Care', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 80),
              ),
              const SizedBox(height: 24),
              const Text(
                'All done',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'serif'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your plants have been taken care of',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSummaryPill(Icons.check, '$_completedCount Completed', Colors.green),
                  const SizedBox(width: 16),
                  _buildSummaryPill(Icons.close, '$_skippedCount Skipped', Colors.red),
                ],
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF154212),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Back to Care', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    final currentTask = widget.tasks[_currentIndex];
    final progress = (_currentIndex) / widget.tasks.length;

    Color chipColor;
    switch (currentTask.taskType) {
      case 'Watering':
        chipColor = Colors.green;
        break;
      case 'Fertilizing':
        chipColor = const Color(0xFF8D3220); // Terracotta
        break;
      case 'Repotting':
        chipColor = Colors.blue;
        break;
      default:
        chipColor = Colors.grey;
    }

    String careTip;
    switch (currentTask.taskType) {
      case 'Watering':
        careTip = 'Check soil moisture before watering.';
        break;
      case 'Fertilizing':
        careTip = 'Use diluted liquid fertilizer.';
        break;
      case 'Repotting':
        careTip = 'Choose a pot 2 inches larger.';
        break;
      default:
        careTip = 'Care for your plant gently.';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quick Care', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Text('Swipe right to complete, swipe left to skip', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF154212)),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('${_currentIndex + 1} of ${widget.tasks.length}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            // Task Card
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! > 0) {
                    // Swipe right
                    _handleSwipe(true);
                  } else if (details.primaryVelocity! < 0) {
                    // Swipe left
                    _handleSwipe(false);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentTask.plantName,
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: chipColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  currentTask.taskType,
                                  style: TextStyle(
                                    color: chipColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Due ${currentTask.dueDate.month}/${currentTask.dueDate.day}',
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                careTip,
                                style: const TextStyle(
                                  color: Color(0xFF154212),
                                  fontStyle: FontStyle.italic,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: const Color(0xFFE8F5E9),
                            child: const Center(
                              child: Icon(Icons.eco, size: 100, color: Color(0xFF154212)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _handleSwipe(false),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close, color: Colors.red, size: 32),
                  ),
                ),
                const SizedBox(width: 48),
                GestureDetector(
                  onTap: () => _handleSwipe(true),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF154212),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
