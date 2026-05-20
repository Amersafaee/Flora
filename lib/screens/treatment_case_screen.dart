import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart' as import_share;

import '../models/treatment_case_model.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import 'create_post_screen.dart' as import_create_post;
import '../theme/app_theme.dart';

class TreatmentCaseScreen extends StatefulWidget {
  final String plantId;
  final String plantName;

  const TreatmentCaseScreen({
    super.key,
    required this.plantId,
    required this.plantName,
  });

  @override
  State<TreatmentCaseScreen> createState() => _TreatmentCaseScreenState();
}

class _TreatmentCaseScreenState extends State<TreatmentCaseScreen> {
  final ImagePicker _picker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  Future<void> _checkProgress(TreatmentCase tCase) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    if (!mounted) return;

    final l = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(l.analyzingProgress, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );

    try {
      final file = File(pickedFile.path);
      final url = await _storageService.uploadGrowthPhoto(file, widget.plantId, context);

      if (url == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final daysSince = DateTime.now().difference(tCase.detectedDate).inDays;

      final assessment = await GeminiService().assessTreatmentProgress(
        initialPhotoUrl: tCase.initialPhotoUrl,
        currentPhotoUrl: url,
        diagnosis: tCase.diagnosis,
        treatmentSteps: tCase.treatmentSteps,
        daysSinceDiagnosis: daysSince,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      _showProgressSheet(tCase, assessment, url);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error checking progress: $e');
    }
  }

  void _showProgressSheet(
      TreatmentCase tCase, Map<String, dynamic> assessment, String newPhotoUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l = AppLocalizations.of(context);
        final score = (assessment['progressScore'] as num?)?.toInt() ?? 50;
        final trend = assessment['trend']?.toString() ?? 'Stable';
        final observation = assessment['comparisonObservation']?.toString() ?? '';
        final recommendation = assessment['adjustedRecommendation']?.toString() ?? '';

        final Color scoreColor = score >= 70
            ? Colors.green.shade700
            : score >= 40
                ? Colors.orange.shade700
                : Colors.red.shade700;

        IconData trendIcon = Icons.arrow_forward;
        if (trend == 'Improving') trendIcon = Icons.arrow_upward;
        if (trend == 'Worsening') trendIcon = Icons.arrow_downward;

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.progressReport,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(trendIcon, color: scoreColor, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            trend,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        l.outOf100,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.bone500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (observation.isNotEmpty) ...[
                Text(
                  l.observationLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  observation,
                  style: const TextStyle(color: AppColors.bone700, height: 1.5),
                ),
                const SizedBox(height: 16),
              ],
              if (recommendation.isNotEmpty) ...[
                Text(
                  l.adjustedRecommendation,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recommendation,
                  style: const TextStyle(color: AppColors.bone700, height: 1.5),
                ),
                const SizedBox(height: 24),
              ],
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest900,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await _firestoreService.updateTreatmentCaseProgress(
                    caseId: tCase.id,
                    progressNote: observation,
                    photoUrl: newPhotoUrl,
                    newStatus: 'Monitoring',
                  );
                },
                child: Text(
                  l.saveProgress,
                  style: TextStyle(
                    color: Theme.of(context).cardColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.green.shade700, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await _firestoreService.updateTreatmentCaseProgress(
                    caseId: tCase.id,
                    progressNote: observation,
                    photoUrl: newPhotoUrl,
                    newStatus: 'Resolved',
                  );
                  await _firestoreService.resolveTreatmentCase(tCase.id);
                  if (!mounted) return;
                  _showRecoveryCelebration(
                      this.context, tCase.initialPhotoUrl, newPhotoUrl, tCase.diagnosis);
                },
                child: Text(
                  l.markAsResolved,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRecoveryCelebration(BuildContext context, String initialPhotoUrl,
      String latestPhotoUrl, String diagnosis) async {
    final uid = _firestoreService.currentUserId;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .add({
        'type': 'recovery',
        'message': '${widget.plantName} has fully recovered from $diagnosis!',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RecoveryCelebrationDialog(
        plantName: widget.plantName,
        diagnosis: diagnosis,
        initialPhotoUrl: initialPhotoUrl,
        latestPhotoUrl: latestPhotoUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.plantHealthCases,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<TreatmentCase>>(
        stream: _firestoreService.getTreatmentCases(widget.plantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final cases = snapshot.data ?? [];

          if (cases.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.forest100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.forest900,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l.noHealthIssuesRecorded,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.forest900,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: cases.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final tCase = cases[index];
              final isResolved = tCase.status == 'Resolved';

              Color badgeColor;
              if (tCase.status == 'Active') {
                badgeColor = Colors.red.shade600;
              } else if (tCase.status == 'Monitoring') {
                badgeColor = Colors.orange.shade600;
              } else {
                badgeColor = Colors.green.shade600;
              }

              return Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            tCase.diagnosis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            // Status values ('Active', 'Monitoring', 'Resolved') are internal
                            // Firestore-stored enum strings — not localized to avoid DB mismatches
                            tCase.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l.detectedPrefix}${DateFormat('MMM d, yyyy').format(tCase.detectedDate)}',
                      style: const TextStyle(
                        color: AppColors.bone500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: tCase.treatmentSteps.asMap().entries.map((e) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.forest100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${e.key + 1}. ${e.value}',
                              style: const TextStyle(
                                color: AppColors.forest900,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (tCase.latestPhotoUrl.isNotEmpty &&
                        tCase.latestPhotoUrl != tCase.initialPhotoUrl)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    tCase.initialPhotoUrl,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(l.beforeLabel,
                                    style: const TextStyle(fontSize: 11, color: AppColors.bone500)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    tCase.latestPhotoUrl,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(l.afterLabel,
                                    style: const TextStyle(fontSize: 11, color: AppColors.bone500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if (tCase.progressNotes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        '"${tCase.progressNotes.last}"',
                        style: const TextStyle(
                          color: AppColors.bone500,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (isResolved && tCase.resolvedDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.forest100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.celebration, color: AppColors.forest900, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l.recoveredInDays(
                                tCase.resolvedDate!.difference(tCase.detectedDate).inDays,
                              ),
                              style: const TextStyle(
                                color: AppColors.forest900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest900,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _checkProgress(tCase),
                        child: Text(
                          l.checkProgress,
                          style: TextStyle(
                            color: Theme.of(context).cardColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.forest900, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final daysTreated =
                            DateTime.now().difference(tCase.detectedDate).inDays;
                        final body =
                            'My ${widget.plantName} has been diagnosed with ${tCase.diagnosis}. I have been treating it for $daysTreated days. Has anyone dealt with this before? Any advice would be appreciated.';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => import_create_post.CreatePostScreen(
                              initialCategory: 'Question',
                              initialTitle: 'Help with ${widget.plantName}: ${tCase.diagnosis}',
                              initialBody: body,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        l.askTheCommunity,
                        style: const TextStyle(
                          color: AppColors.forest900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RecoveryCelebrationDialog extends StatefulWidget {
  final String plantName;
  final String diagnosis;
  final String initialPhotoUrl;
  final String latestPhotoUrl;

  const _RecoveryCelebrationDialog({
    required this.plantName,
    required this.diagnosis,
    required this.initialPhotoUrl,
    required this.latestPhotoUrl,
  });

  @override
  State<_RecoveryCelebrationDialog> createState() => _RecoveryCelebrationDialogState();
}

class _RecoveryCelebrationDialogState extends State<_RecoveryCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Dialog.fullscreen(
      backgroundColor: AppColors.forest100,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: const Icon(Icons.check_circle, color: AppColors.forest900, size: 100),
              ),
              const SizedBox(height: 32),
              Text(
                l.recoveryComplete,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forest900,
                ),
              ),
              const SizedBox(height: 32),
              if (widget.initialPhotoUrl.isNotEmpty && widget.latestPhotoUrl.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              widget.initialPhotoUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l.beforeLabel,
                            style: const TextStyle(
                              color: AppColors.bone700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              widget.latestPhotoUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l.afterLabel,
                            style: const TextStyle(
                              color: AppColors.bone700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x3314301E)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.recoveryMessage(widget.plantName, widget.diagnosis),
                        style: const TextStyle(
                          color: AppColors.forest900,
                          fontSize: 16,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: Text(
                    l.shareRecoveryStory,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest900,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    // ignore: deprecated_member_use
                    import_share.Share.share(
                        'My ${widget.plantName} just recovered from ${widget.diagnosis} at Digital Conservatory! 🌿 #PlantCare #DigitalConservatory');
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // pop dialog
                  Navigator.pop(context); // pop screen
                },
                child: Text(
                  l.continueAction,
                  style: const TextStyle(
                    color: AppColors.forest900,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
