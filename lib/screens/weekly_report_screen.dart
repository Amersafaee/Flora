import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/weekly_report_service.dart';

class WeeklyReportScreen extends StatelessWidget {
  final Map<String, dynamic> reportData;

  const WeeklyReportScreen({super.key, required this.reportData});

  @override
  Widget build(BuildContext context) {
    final start = reportData['weekStartDate'] as DateTime;
    final end = reportData['weekEndDate'] as DateTime;
    final dateRangeStr = '${DateFormat.MMMd().format(start)} - ${DateFormat.MMMd().format(end)}';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).scaffoldBackgroundColor, const Color(0xFFF0F8F0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // Drag handle
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 24),
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, color: Color(0xFF154212), size: 32),
              ),
              const SizedBox(height: 24),
              // Headline
              Text(
                reportData['headline'] ?? '',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'serif',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'Week of $dateRangeStr',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32),
              // Stats Grid
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildStatBox(
                      icon: Icons.check_circle,
                      iconColor: Colors.green,
                      value: reportData['completedTasks'].toString(),
                      valueColor: Colors.green,
                      label: 'Tasks Done',
                    ),
                    _buildStatBox(
                      icon: Icons.cancel,
                      iconColor: Colors.red,
                      value: reportData['skippedTasks'].toString(),
                      valueColor: Colors.red,
                      label: 'Skipped',
                    ),
                    _buildStatBox(
                      icon: Icons.book,
                      iconColor: const Color(0xFF154212),
                      value: reportData['newGrowthEntries'].toString(),
                      valueColor: const Color(0xFF154212),
                      label: 'Journal Entries',
                    ),
                    _buildStatBox(
                      icon: Icons.favorite,
                      iconColor: _getScoreColor(reportData['collectionHealthAvg'] as int),
                      value: '${reportData['collectionHealthAvg']}%',
                      valueColor: _getScoreColor(reportData['collectionHealthAvg'] as int),
                      label: 'Collection Health',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Most Improved
              if (reportData['mostImprovedPlant'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFA000)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Star of the Week',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF57C00)),
                            ),
                            Text(
                              reportData['mostImprovedPlant'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF154212),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Environment
              if (reportData['avgTemperature'] > 0 && reportData['avgHumidity'] > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.home, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your home averaged ${(reportData['avgTemperature'] as double).toStringAsFixed(1)}° and ${(reportData['avgHumidity'] as double).toStringAsFixed(0)}% humidity this week',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await WeeklyReportService().markWeeklyReportShown();
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF154212),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Close Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Generated by Flora every Sunday',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required Color iconColor,
    required String value,
    required Color valueColor,
    required String label,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: valueColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return const Color(0xFF8D3220); // Terracotta for okay
    return Colors.red;
  }
}
