import 'package:flutter/material.dart';
import 'package:digital_conservatory/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../services/weekly_report_service.dart';
import '../theme/app_theme.dart';

class WeeklyReportScreen extends StatelessWidget {
  final Map<String, dynamic> reportData;

  const WeeklyReportScreen({super.key, required this.reportData});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final start = reportData['weekStartDate'] as DateTime;
    final end = reportData['weekEndDate'] as DateTime;
    final dateRangeStr = '${DateFormat.MMMd().format(start)} - ${DateFormat.MMMd().format(end)}';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).scaffoldBackgroundColor, AppColors.forest100],
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
                width: 40, height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: AppColors.forest100, shape: BoxShape.circle),
                child: const Icon(Icons.eco, color: AppColors.forest900, size: 32),
              ),
              const SizedBox(height: 24),
              Text(
                reportData['headline'] ?? '',
                style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface, fontFamily: 'serif',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${l.weekOf} $dateRangeStr',
                style: const TextStyle(fontSize: 14, color: AppColors.bone500, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 32),
              // Stats Grid
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
                      iconColor: isDark ? AppColors.successDark : AppColors.successLight,
                      value: reportData['completedTasks'].toString(),
                      valueColor: isDark ? AppColors.successDark : AppColors.successLight,
                      label: l.tasksDone,
                    ),
                    _buildStatBox(
                      icon: Icons.cancel,
                      iconColor: isDark ? AppColors.errorDark : AppColors.errorLight,
                      value: reportData['skippedTasks'].toString(),
                      valueColor: isDark ? AppColors.errorDark : AppColors.errorLight,
                      label: l.skipped,
                    ),
                    _buildStatBox(
                      icon: Icons.book,
                      iconColor: AppColors.forest900,
                      value: reportData['newGrowthEntries'].toString(),
                      valueColor: AppColors.forest900,
                      label: l.journalEntries,
                    ),
                    _buildStatBox(
                      icon: Icons.favorite,
                      iconColor: _getScoreColor(reportData['collectionHealthAvg'] as int, context),
                      value: '${reportData['collectionHealthAvg']}%',
                      valueColor: _getScoreColor(reportData['collectionHealthAvg'] as int, context),
                      label: l.collectionHealth,
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
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.bone50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorderDefault : AppColors.warningLight, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: isDark ? AppColors.warningDark : AppColors.warningLight),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.starOfTheWeek,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF57C00)),
                            ),
                            Text(
                              reportData['mostImprovedPlant'],
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest900, fontSize: 16),
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
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.home, color: AppColors.bone500),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your home averaged ${(reportData['avgTemperature'] as double).toStringAsFixed(1)}° and ${(reportData['avgHumidity'] as double).toStringAsFixed(0)}% humidity this week',
                          style: const TextStyle(color: AppColors.bone500, fontSize: 13),
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
                    backgroundColor: AppColors.forest900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(l.closeReport, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.generatedByFlora,
                style: const TextStyle(color: AppColors.bone500, fontSize: 11, fontStyle: FontStyle.italic),
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
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: valueColor)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.bone500, fontSize: 12)),
      ],
    );
  }

  Color _getScoreColor(int score, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (score >= 80) return isDark ? AppColors.successDark : AppColors.successLight;
    if (score >= 60) return isDark ? AppColors.darkTerracotta : AppColors.terracotta700;
    return isDark ? AppColors.errorDark : AppColors.errorLight;
  }
}
