import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/care_intelligence_service.dart';
import '../theme/app_theme.dart';

class CareInsightsScreen extends StatefulWidget {
  const CareInsightsScreen({super.key});

  @override
  State<CareInsightsScreen> createState() => _CareInsightsScreenState();
}

class _CareInsightsScreenState extends State<CareInsightsScreen> {
  static const _cacheKey = 'smart_care_plan_cache';
  static const _timestampKey = 'smart_care_plan_timestamp';
  static const _cacheTtlHours = 24;

  final CareIntelligenceService _intelligenceService = CareIntelligenceService();

  bool _isLoading = true;
  String? _errorMessage;
  String _rawPlan = '';
  bool _noPlants = false;
  bool _fromCache = false;

  @override
  void initState() {
    super.initState();
    _loadFromCacheOrGenerate();
  }

  // -- Cache helpers ------------------------------------------------

  Future<String?> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    final ts = prefs.getInt(_timestampKey);
    if (cached == null || ts == null) return null;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > const Duration(hours: _cacheTtlHours).inMilliseconds) return null;
    return cached;
  }

  Future<void> _writeCache(String plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, plan);
    await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_timestampKey);
  }

  // -- Load logic ---------------------------------------------------

  Future<void> _loadFromCacheOrGenerate({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _noPlants = false;
      _fromCache = false;
    });

    // Step 3: Try cache first (unless refresh forced)
    if (!forceRefresh) {
      final cached = await _readCache();
      if (cached != null && cached.isNotEmpty) {
        if (mounted) {
          setState(() {
            _rawPlan = cached;
            _isLoading = false;
            _fromCache = true;
          });
        }
        return;
      }
    }

    await _generatePlan();
  }

  Future<void> _generatePlan() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final plan = await _intelligenceService.generateWeeklyCarePlan(uid);

      if (!mounted) return;

      if (plan.isEmpty) {
        setState(() {
          _noPlants = true;
          _isLoading = false;
        });
        return;
      }

      await _writeCache(plan);
      setState(() {
        _rawPlan = plan;
        _isLoading = false;
        _fromCache = false;
      });
    } catch (e) {
      debugPrint('CareInsightsScreen: error generating plan: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context).couldNotGenerateCarePlan;
        });
      }
    }
  }

  // -- Parse DAY sections from Gemini response -----------------------

  List<_DaySection> _parseDaySections(String raw) {
    final sections = <_DaySection>[];

    // Split on "DAY N" pattern
    final dayRegex = RegExp(
      r'DAY\s+(\d+)\s*[-ï¿½]\s*([^\n:]+):?\s*\n(.*?)(?=DAY\s+\d+|$)',
      dotAll: true,
      caseSensitive: false,
    );

    for (final match in dayRegex.allMatches(raw)) {
      final dayNum = int.tryParse(match.group(1) ?? '0') ?? 0;
      final dayLabel = (match.group(2) ?? '').trim();
      final body = (match.group(3) ?? '').trim();

      final isRestDay = body.toLowerCase().contains('rest day') ||
          body.toLowerCase().contains('no tasks');

      final tasks = <String>[];
      if (!isRestDay) {
        for (final line in body.split('\n')) {
          final trimmed = line
              .replaceAll(RegExp(r'^[ï¿½\-\*]\s*'), '')
              .trim();
          if (trimmed.isNotEmpty) tasks.add(trimmed);
        }
      }

      sections.add(_DaySection(
        dayNumber: dayNum,
        dayLabel: dayLabel,
        tasks: tasks,
        isRestDay: isRestDay,
      ));
    }

    // Fallback: if regex found nothing, show raw text in one card
    if (sections.isEmpty && raw.isNotEmpty) {
      sections.add(_DaySection(
        dayNumber: 1,
        dayLabel: AppLocalizations.of(context).thisWeekLabel,
        tasks: raw
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList(),
        isRestDay: false,
      ));
    }

    return sections;
  }

  // -- Build ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back, color: AppColors.forest700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.smartCarePlan,
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.forest900,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(Icons.refresh,
                  color: isDark
                      ? AppColors.darkForestPrimary
                      : AppColors.forest700),
              tooltip: l.regeneratePlan,
              onPressed: () async {
                await _clearCache();
                _loadFromCacheOrGenerate(forceRefresh: true);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _errorMessage != null
                ? _buildError()
                : _noPlants
                    ? _buildNoPlants()
                    : _buildPlan(isDark),
      ),
    );
  }

  // -- States --------------------------------------------------------

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.forest700),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context).verdoroIsAnalyzingPlants,
            style: const TextStyle(
              color: AppColors.bone500,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppColors.bone300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.bone500, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadFromCacheOrGenerate(forceRefresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child:
                  Text(AppLocalizations.of(context).retry, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPlants() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_florist_outlined,
                size: 56, color: AppColors.bone300),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).addFirstPlantForPersonalizedPlan,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: AppColors.bone500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlan(bool isDark) {
    final sections = _parseDaySections(_rawPlan);
    final l = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtitle / cache badge
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: [
              const Icon(Icons.eco, size: 14, color: AppColors.forest500),
              const SizedBox(width: 6),
              Text(
                _fromCache
                    ? l.showingCachedPlanRefreshHint
                    : l.aiGeneratedForPlantsThisWeek,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.bone500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: sections.length,
            itemBuilder: (context, index) =>
                _buildDayCard(sections[index], isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(_DaySection section, bool isDark) {
    final isRestDay = section.isRestDay;

    final cardColor = isRestDay
        ? (isDark ? AppColors.darkSurface : const Color(0xFFF7F7F7))
        : (isDark ? AppColors.darkSurfaceElevated : AppColors.bone50);

    final borderColor = isRestDay
        ? (isDark ? AppColors.darkBorderSubtle : AppColors.bone200)
        : AppColors.forest700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: borderColor, width: 3),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header
            Text(
              section.dayLabel,
              style: GoogleFonts.notoSerif(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isRestDay
                    ? (isDark ? AppColors.darkTextSecondary : AppColors.bone500)
                    : (isDark
                        ? AppColors.darkForestPrimary
                        : AppColors.forest700),
              ),
            ),

            if (isRestDay) ...[
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).restDayNoTasksNeeded,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.bone300,
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              ...section.tasks.map((task) => _buildTaskRow(task, isDark)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskRow(String task, bool isDark) {
    // Separate "PlantName: task description" if Gemini followed the format
    final colonIdx = task.indexOf(':');
    String plantName = '';
    String taskBody = task;
    if (colonIdx > 0 && colonIdx < 40) {
      plantName = task.substring(0, colonIdx).trim();
      taskBody = task.substring(colonIdx + 1).trim();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.eco,
                size: 16,
                color: isDark ? AppColors.darkForestPrimary : AppColors.forest500),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: plantName.isNotEmpty
                ? RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$plantName: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.bone900,
                          ),
                        ),
                        TextSpan(
                          text: taskBody,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.bone700,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    taskBody,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.bone700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// -- Data class ----------------------------------------------------

class _DaySection {
  final int dayNumber;
  final String dayLabel;
  final List<String> tasks;
  final bool isRestDay;

  const _DaySection({
    required this.dayNumber,
    required this.dayLabel,
    required this.tasks,
    required this.isRestDay,
  });
}
