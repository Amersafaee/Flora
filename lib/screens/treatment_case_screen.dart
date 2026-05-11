import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/treatment_case_model.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';

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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Analyzing progress...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );

    try {
      final file = File(pickedFile.path);
      final url = await _storageService.uploadGrowthPhoto(
          file, widget.plantId, context);
      
      if (url == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final daysSince =
          DateTime.now().difference(tCase.detectedDate).inDays;

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
      if (mounted) Navigator.pop(context); // Close loading dialog
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
        final score = (assessment['progressScore'] as num?)?.toInt() ?? 50;
        final trend = assessment['trend']?.toString() ?? 'Stable';
        final observation =
            assessment['comparisonObservation']?.toString() ?? '';
        final recommendation =
            assessment['adjustedRecommendation']?.toString() ?? '';

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
                'Progress Report',
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
                        'out of 100',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (observation.isNotEmpty) ...[
                Text(
                  'Observation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  observation,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),
                const SizedBox(height: 16),
              ],
              if (recommendation.isNotEmpty) ...[
                Text(
                  'Adjusted Recommendation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recommendation,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),
                const SizedBox(height: 24),
              ],
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF154212),
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
                child: const Text(
                  'Save Progress',
                  style: TextStyle(
                    color: Colors.white,
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
                },
                child: Text(
                  'Mark as Resolved',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Plant Health Cases',
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
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF154212),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No health issues recorded.\nYour plant appears to be doing well.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF154212),
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
                  color: Colors.white,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
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
                      'Detected ${DateFormat('MMM d, yyyy').format(tCase.detectedDate)}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${e.key + 1}. ${e.value}',
                              style: const TextStyle(
                                color: Color(0xFF154212),
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
                                Text('Before',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500)),
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
                                Text('After',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if (tCase.progressNotes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        '"${tCase.progressNotes.last}"',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (isResolved && tCase.resolvedDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.celebration,
                                color: Color(0xFF154212), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Recovered in ${tCase.resolvedDate!.difference(tCase.detectedDate).inDays} days',
                              style: const TextStyle(
                                color: Color(0xFF154212),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF154212),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _checkProgress(tCase),
                        child: const Text(
                          'Check Progress',
                          style: TextStyle(
                            color: Colors.white,
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
