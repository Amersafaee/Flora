import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../models/plant_model.dart';
import '../theme/app_theme.dart';
import '../utils/care_type_style.dart';
import '../utils/toast_utils.dart';

class CarePlanScreen extends StatefulWidget {
  const CarePlanScreen({super.key});

  @override
  State<CarePlanScreen> createState() => _CarePlanScreenState();
}

class _CarePlanScreenState extends State<CarePlanScreen> {
  bool _isGenerating = false;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _regeneratePlan() async {
    setState(() => _isGenerating = true);
    try {
      final gemini = GeminiService();
      final plantsStream = _firestoreService.getPlants();
      final plants = await plantsStream.first;

      final String plan = await gemini.generatePersonalizedWeeklyPlan(
        plants.map((p) => p.toMap()).toList()
      );
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) {
          final l2 = AppLocalizations.of(ctx);
          return SafeArea(
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.8,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l2.aiCarePlan, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(plan, style: const TextStyle(fontSize: 16, height: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.forest700),
                    child: Text(l2.close, style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      final l2 = AppLocalizations.of(context);
      showToast(context, '${l2.errorGeneratingPlanPrefix}$e', isError: true);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Scaffold(body: Center(child: Text(l.notLoggedIn)));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l.myCarePlan),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back, color: AppColors.forest700),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _regeneratePlan,
                icon: _isGenerating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? l.generating : l.regeneratePlan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Plant>>(
              stream: _firestoreService.getPlants(),
              builder: (context, plantSnapshot) {
                if (plantSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!plantSnapshot.hasData || plantSnapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      l.addPlantsToSeePlan,
                      style: const TextStyle(fontSize: 16, color: AppColors.bone500),
                    ),
                  );
                }

                final plants = plantSnapshot.data!;

                return ListView.builder(
                  itemCount: plants.length,
                  itemBuilder: (context, index) {
                    final plant = plants[index];
                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('tasks')
                          .where('plantName', isEqualTo: plant.name)
                          .where('isCompleted', isEqualTo: false)
                          .orderBy('dueDate')
                          .get(),
                      builder: (context, taskSnapshot) {
                        if (!taskSnapshot.hasData) return const SizedBox();
                        final tasks = taskSnapshot.data!.docs;
                        if (tasks.isEmpty) return const SizedBox();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(plant.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.forest900)),
                            ),
                            ...tasks.map((doc) {
                              final taskData = doc.data() as Map<String, dynamic>;
                              final type = taskData['taskType'] ?? 'Task';
                              final dueDate = (taskData['dueDate'] as Timestamp).toDate();
                              final dateStr = DateFormat.MMMd().format(dueDate);

                              return ListTile(
                                leading: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: careTypeStyle(type).iconColor),
                                ),
                                title: Text(type),
                                trailing: Text(dateStr, style: const TextStyle(color: AppColors.bone500)),
                              );
                            }),
                            const Divider(),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
