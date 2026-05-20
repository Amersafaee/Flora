import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../services/care_intelligence_service.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

class CareInsightsScreen extends StatefulWidget {
  const CareInsightsScreen({super.key});

  @override
  State<CareInsightsScreen> createState() => _CareInsightsScreenState();
}

class _CareInsightsScreenState extends State<CareInsightsScreen> {
  final CareIntelligenceService _intelligenceService = CareIntelligenceService();
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = true;
  bool _isGeneratingPlan = false;
  List<Map<String, dynamic>> _carePlan = [];

  @override
  void initState() {
    super.initState();
    _loadCarePlan();
  }

  Future<void> _loadCarePlan() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final plan = await _intelligenceService.generateWeeklyCarePlan(uid);

      // Filter for next 14 days only
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final maxDate = today.add(const Duration(days: 14));

      final filteredPlan = plan.where((task) {
        final date = task['recommendedDate'] as DateTime;
        final taskDate = DateTime(date.year, date.month, date.day);
        return !taskDate.isBefore(today) && taskDate.isBefore(maxDate);
      }).toList();

      if (mounted) {
        setState(() {
          _carePlan = filteredPlan;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generatePersonalizedPlan() async {
    final l = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isGeneratingPlan = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('plants')
          .get();

      if (snap.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.addSomePlantsForPlan),
              backgroundColor: AppColors.forest900,
            ),
          );
        }
        setState(() => _isGeneratingPlan = false);
        return;
      }

      final plants = snap.docs.map((d) => d.data()).toList();
      final String planTextRaw = await _geminiService.generatePersonalizedWeeklyPlan(plants);
      final String planText = (planTextRaw.trim().isEmpty)
          ? "Unable to generate plan. Make sure you have plants added to your collection."
          : planTextRaw;

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          showDragHandle: true,
          builder: (ctx) {
            final lSheet = AppLocalizations.of(ctx);
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lSheet.yourWeeklyCarePlan,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest900,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.bone500),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          planText,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        final lErr = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lErr.failedToGeneratePlan),
            backgroundColor: AppColors.terracotta900,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPlan = false);
    }
  }

  void _showReasoningSheet(String reasoning) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.forest100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco,
                      color: AppColors.forest900,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        reasoning,
                        style: const TextStyle(
                          color: AppColors.forest900,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Group tasks by date
    final groupedTasks = <DateTime, List<Map<String, dynamic>>>{};
    for (var task in _carePlan) {
      final date = task['recommendedDate'] as DateTime;
      final taskDate = DateTime(date.year, date.month, date.day);
      if (!groupedTasks.containsKey(taskDate)) {
        groupedTasks[taskDate] = [];
      }
      groupedTasks[taskDate]!.add(task);
    }

    // List of dates with tasks
    final taskDates = groupedTasks.keys.toSet();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.smartCarePlan,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'serif',
                            color: AppColors.forest900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.smartCarePlanSubtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.bone500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isGeneratingPlan ? null : _generatePersonalizedPlan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forest900,
                              disabledBackgroundColor: const Color(0x8C14301E),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: _isGeneratingPlan
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome, color: Colors.white),
                            label: Text(
                              _isGeneratingPlan ? l.generating : l.getPersonalizedPlan,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 14-day scrollable strip
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 14,
                      itemBuilder: (context, index) {
                        final date = today.add(Duration(days: index));
                        final isToday = index == 0;
                        final hasTask = taskDates.contains(date);
                        final dayLetter = DateFormat('E').format(date).substring(0, 1);
                        final dateNumber = DateFormat('d').format(date);

                        Widget dateWidget;
                        if (isToday) {
                          dateWidget = Container(
                            width: 50,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.forest900,
                              shape: BoxShape.circle,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(dayLetter, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                Text(dateNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          );
                        } else {
                          dateWidget = Container(
                            width: 50,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: hasTask ? AppColors.forest900 : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: hasTask ? null : Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayLetter,
                                  style: TextStyle(color: hasTask ? Colors.white : AppColors.bone500, fontSize: 12),
                                ),
                                Text(
                                  dateNumber,
                                  style: TextStyle(
                                    color: hasTask ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return dateWidget;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Task list
                  Expanded(
                    child: groupedTasks.isEmpty
                        ? Center(
                            child: Text(
                              l.noTasksNext14Days,
                              style: const TextStyle(color: AppColors.bone500),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: groupedTasks.length,
                            itemBuilder: (context, index) {
                              final sortedDates = groupedTasks.keys.toList()..sort();
                              final date = sortedDates[index];
                              final tasks = groupedTasks[date]!;

                              String dateHeader;
                              if (date == today) {
                                dateHeader = l.today;
                              } else if (date == today.add(const Duration(days: 1))) {
                                dateHeader = l.tomorrow;
                              } else {
                                dateHeader = DateFormat('EEEE, MMM d').format(date);
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12, top: 8),
                                    child: Text(
                                      dateHeader,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.bone500,
                                      ),
                                    ),
                                  ),
                                  ...tasks.map((task) {
                                    final type = task['taskType'] as String;

                                    final isDark = Theme.of(context).brightness == Brightness.dark;
                                    Color iconBg = isDark ? AppColors.darkForestSubtle : AppColors.forest100;
                                    Color iconColor = isDark ? AppColors.darkForestPrimary : AppColors.forest500;
                                    IconData iconData = Icons.water_drop;

                                    if (type.contains('Fertiliz')) {
                                      iconBg = isDark ? AppColors.darkTerracottaSubtle : AppColors.terracotta100;
                                      iconColor = isDark ? AppColors.errorDark : AppColors.errorLight;
                                      iconData = Icons.science;
                                    } else if (type.contains('Repot')) {
                                      iconBg = isDark ? AppColors.darkSurfaceElevated : AppColors.forest50;
                                      iconColor = isDark ? AppColors.darkForestPrimary : AppColors.forest600;
                                      iconData = Icons.yard;
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.03),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                                                child: Icon(iconData, color: iconColor, size: 20),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      task['plantName'],
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    ),
                                                    Text(
                                                      type,
                                                      style: const TextStyle(color: AppColors.bone500, fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.forest900),
                                                onPressed: () => _showReasoningSheet(task['reasoning']),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            task['reasoning'],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.bone500,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
