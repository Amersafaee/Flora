import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:verdoro/theme/app_theme.dart';

class AnalysisCardView extends StatelessWidget {
  final String rawText;

  const AnalysisCardView({
    super.key,
    required this.rawText,
  });

  /// Returns true only when [text] contains a structured plant-analysis
  /// response from Verdoro — identified by the presence of BOTH the
  /// "Health score:" and "What I can see:" labels (case-insensitive).
  /// Casual conversational messages will never match both labels and
  /// therefore return false.
  static bool isStructuredAnalysis(String text) {
    final lower = text.toLowerCase();
    return lower.contains('health score:') && lower.contains('what i can see:');
  }

  static final RegExp _scorePattern = RegExp(
    r'(?:health\s+score[:\s]+|score[:\s]+)?(\d{1,3})\s*(?:\/\s*100|out\s+of\s+100)',
    caseSensitive: false,
  );

  int? _extractHealthScore() {
    final match = _scorePattern.firstMatch(rawText);
    if (match != null) {
      final value = int.tryParse(match.group(1) ?? '');
      if (value != null && value >= 0 && value <= 100) return value;
    }
    return null;
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.forest500;
    if (score >= 50) return const Color(0xFFE8A020);
    return AppColors.terracotta500;
  }

  String _scoreLabel(int score, AppLocalizations l) {
    if (score >= 80) return l.healthy;
    if (score >= 50) return l.needsAttention;
    return l.critical;
  }

  Map<String, String> _parseSections() {
    final raw = rawText;
    final labels = [
      'Plant identified:',
      'Health score:',
      'Status:',
      'What I can see:',
      'Most urgent action:',
      'Care tip:',
    ];

    final result = <String, String>{};

    for (int i = 0; i < labels.length; i++) {
      final label = labels[i];
      final labelIdx = raw.toLowerCase().indexOf(label.toLowerCase());
      if (labelIdx == -1) continue;

      final contentStart = labelIdx + label.length;
      int contentEnd = raw.length;
      for (int j = i + 1; j < labels.length; j++) {
        final nextIdx = raw.toLowerCase().indexOf(labels[j].toLowerCase(), contentStart);
        if (nextIdx != -1 && nextIdx < contentEnd) {
          contentEnd = nextIdx;
        }
      }

      final key = label.replaceAll(':', '').trim();
      result[key] = raw.substring(contentStart, contentEnd).trim();
    }

    return result;
  }

  String? _extractCommonName() {
    final sections = _parseSections();
    if (sections.containsKey('Plant identified')) {
      final val = sections['Plant identified']!.split('\n').first.trim();
      if (val.isNotEmpty && val.length < 60) return val;
    }
    final pattern = RegExp(r'(?:common\s+name)[:\s*]+([A-Z][^\n,\.]{2,40})', caseSensitive: false);
    final m = pattern.firstMatch(rawText);
    if (m != null) {
      final candidate = m.group(1)?.trim() ?? '';
      if (candidate.isNotEmpty && candidate.length < 40) return candidate;
    }
    return null;
  }

  String? _extractScientificName() {
    final pattern = RegExp(
      r'(?:scientific\s+name|species)[:\s*]+([A-Z][a-z]+(?:\s+[a-z]+)+)',
      caseSensitive: false,
    );
    final m = pattern.firstMatch(rawText);
    if (m != null) {
      final candidate = m.group(1)?.trim() ?? '';
      if (candidate.isNotEmpty && candidate.length < 60) return candidate;
    }
    return null;
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String label,
    required String body,
    required IconData icon,
    required Color borderColor,
    required Color iconColor,
    required Color bgColor,
    bool boldBody = false,
  }) {
    if (body.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A224A1E),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.bone400,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: boldBody ? FontWeight.w600 : FontWeight.w400,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.forest800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final int? healthScore = _extractHealthScore();
    final sections = _parseSections();

    final commonName = _extractCommonName();
    final scientificName = _extractScientificName();

    final whatICanSee = sections['What I can see'] ?? '';
    final urgentAction = sections['Most urgent action'] ?? '';
    final careTip = sections['Care tip'] ?? '';
    final hasSections = whatICanSee.isNotEmpty || urgentAction.isNotEmpty || careTip.isNotEmpty;

    final Color statusColor = healthScore != null ? _scoreColor(healthScore) : AppColors.forest500;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A224A1E),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (healthScore != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                  colors: [
                    statusColor.withValues(alpha: 0.15),
                    statusColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$healthScore',
                        style: GoogleFonts.outfit(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/100',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: statusColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _scoreLabel(healthScore, l),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // PLANT IDENTITY SECTION
          if (commonName != null || scientificName != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.bone50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLANT IDENTIFIED',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.bone400,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (commonName != null)
                      Text(
                        commonName,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
                        ),
                      ),
                    if (scientificName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        scientificName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.bone500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else
            const SizedBox(height: 4),

          // THREE INFO CARDS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _buildInfoCard(
                  context: context,
                  label: 'WHAT I CAN SEE',
                  body: whatICanSee,
                  icon: Icons.visibility_outlined,
                  borderColor: AppColors.forest400,
                  iconColor: AppColors.forest600,
                  bgColor: isDark ? AppColors.darkSurfaceElevated : AppColors.forest50,
                ),
                _buildInfoCard(
                  context: context,
                  label: 'MOST URGENT ACTION',
                  body: urgentAction,
                  icon: Icons.priority_high,
                  borderColor: AppColors.terracotta500,
                  iconColor: AppColors.terracotta700,
                  bgColor: isDark ? AppColors.darkTerracottaSubtle : AppColors.terracotta100,
                  boldBody: true,
                ),
                _buildInfoCard(
                  context: context,
                  label: 'CARE TIP',
                  body: careTip,
                  icon: Icons.lightbulb_outline,
                  borderColor: const Color(0xFF7BA5D4),
                  iconColor: const Color(0xFF4A7AB5),
                  bgColor: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEAF2FF),
                ),
                if (!hasSections) ...[
                  Text(
                    rawText,
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
