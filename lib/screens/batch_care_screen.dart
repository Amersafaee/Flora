import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';
import '../services/care_intelligence_service.dart';
import '../theme/app_theme.dart';
import '../utils/care_type_style.dart';

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
        if (uid != null && !_completedTaskIds.contains(task.id)) {
          await FirestoreService().markTaskCompleted(task.id);
          _completedTaskIds.add(task.id);
          
          int baseInterval = 7;
          if (task.taskType == 'Fertilizing') baseInterval = 30;
          if (task.taskType == 'Repotting') baseInterval = 365;

          final intelligence = CareIntelligenceService();
          final nextCare = await intelligence.computeNextCareDate(
            plantId: '',
            plantName: task.plantName,
            category: 'General',
            baseIntervalDays: baseInterval,
            lastWateredDate: DateTime.now(),
            userUid: uid,
          );
          
          final nextDate = nextCare['nextDate'] as DateTime;
          
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
    final l = AppLocalizations.of(context);

    if (_isAllDone) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(l.quickCare, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.bone900)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.bone900),
          leading: IconButton(
            icon: const Icon(CupertinoIcons.chevron_back, color: AppColors.forest700),
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
                  color: AppColors.forest100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 80),
              ),
              const SizedBox(height: 24),
              Text(
                l.allDone,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'serif'),
              ),
              const SizedBox(height: 8),
              Text(
                l.plantsCaredFor,
                style: const TextStyle(fontSize: 16, color: AppColors.bone500),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSummaryPill(Icons.check, '$_completedCount ${l.completed}', Colors.green),
                  const SizedBox(width: 16),
                  _buildSummaryPill(Icons.close, '$_skippedCount ${l.skipped}', Colors.red),
                ],
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(l.backToCare, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    final currentTask = widget.tasks[_currentIndex];
    final progress = (_currentIndex) / widget.tasks.length;

    final style = careTypeStyle(currentTask.taskType);

    String careTip;
    switch (currentTask.taskType) {
      case 'Watering':
        careTip = l.checkSoilBeforeWatering;
        break;
      case 'Fertilizing':
        careTip = l.useDilutedFertilizer;
        break;
      case 'Repotting':
        careTip = l.choosePot2InchesLarger;
        break;
      default:
        careTip = l.careForPlantGently;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l.quickCare, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.bone900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.bone900),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back, color: AppColors.forest700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Text(l.swipeToCompleteOrSkip, style: const TextStyle(color: AppColors.bone500, fontSize: 14)),
            const SizedBox(height: 16),
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.forest900),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(l.ofCounterLabel((_currentIndex + 1).toString(), widget.tasks.length.toString()), style: const TextStyle(color: AppColors.bone500, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            // Task Card
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! > 0) {
                    _handleSwipe(true);
                  } else if (details.primaryVelocity! < 0) {
                    _handleSwipe(false);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
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
                                  color: style.tileColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getLocalizedTaskType(currentTask.taskType, l),
                                  style: TextStyle(
                                    color: style.iconColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Due ${currentTask.dueDate.month}/${currentTask.dueDate.day}',
                                style: const TextStyle(color: AppColors.bone500, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                careTip,
                                style: const TextStyle(
                                  color: AppColors.forest900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirestoreService().currentUserId)
                              .collection('plants')
                              .doc(currentTask.plantId)
                              .get(),
                          builder: (context, snapshot) {
                            String? imageUrl;
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data() as Map<String, dynamic>?;
                              imageUrl = data?['imageUrl'] as String?;
                            }
                            
                            if (imageUrl != null && imageUrl.isNotEmpty) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 200,
                                    color: AppColors.forest50,
                                    child: const Icon(Icons.local_florist, size: 64, color: AppColors.forest300),
                                  ),
                                ),
                              );
                            } else {
                              return Container(
                                height: 200,
                                color: AppColors.forest50,
                                child: const Icon(Icons.local_florist, size: 64, color: AppColors.forest300),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.xmark, size: 14, color: AppColors.bone500),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context).skip,
                        style: const TextStyle(
                          color: AppColors.bone500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context).completed,
                        style: const TextStyle(
                          color: AppColors.forest600,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(CupertinoIcons.check_mark, size: 14, color: AppColors.forest600),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
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

  String _getLocalizedTaskType(String taskType, AppLocalizations l) {
    switch (taskType.toLowerCase()) {
      case 'watering': return l.watering;
      case 'fertilizing': return l.fertilizing;
      case 'repotting': return l.repotting;
      case 'pruning': return l.pruning;
      case 'misting': return l.misting;
      case 'inspecting': return l.inspecting;
      case 'treating': return l.treating;
      default: return taskType;
    }
  }
}
