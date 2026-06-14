import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import '../models/plant_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class MemorialGardenScreen extends StatelessWidget {
  const MemorialGardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sepiaBg = isDark ? AppColors.darkCanvas : AppColors.bone25;
    final sepiaCard = isDark ? AppColors.darkSurface : AppColors.bone50;
    final sepiaText = isDark ? AppColors.darkTextPrimary : AppColors.bone900;
    final sepiaMuted = isDark ? AppColors.darkTextSecondary : AppColors.bone500;
    final sepiaBorder = isDark ? AppColors.darkBorderDefault : AppColors.bone200;
    final sepiaQuoteBg = isDark ? AppColors.darkSurfaceElevated : AppColors.bone25;

    return Scaffold(
      backgroundColor: sepiaBg,
      appBar: AppBar(
        title: Text(l.memorialGarden),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: sepiaText),
        titleTextStyle: TextStyle(
          color: sepiaText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'serif',
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Plant>>(
          stream: FirestoreService().getPlants(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(l.somethingWentWrong, style: const TextStyle(color: AppColors.bone500)));
            }

            final deceasedPlants = (snapshot.data ?? []).where((p) => p.isDeceased).toList();

            if (deceasedPlants.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    l.memorialGardenEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: sepiaMuted, fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              );
            }

            // Sort by deceasedDate descending
            deceasedPlants.sort((a, b) {
              if (a.deceasedDate == null && b.deceasedDate == null) return 0;
              if (a.deceasedDate == null) return 1;
              if (b.deceasedDate == null) return -1;
              return b.deceasedDate!.compareTo(a.deceasedDate!);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: deceasedPlants.length,
              itemBuilder: (context, index) {
                final plant = deceasedPlants[index];
                final dateJoinedStr = DateFormat.yMMMMd().format(plant.dateAdded);
                final datePassedStr = plant.deceasedDate != null
                    ? DateFormat.yMMMMd().format(plant.deceasedDate!)
                    : l.unknownDate;

                final note = plant.memorialNote?.isNotEmpty == true
                    ? plant.memorialNote!
                    : (plant.eulogy?.isNotEmpty == true ? plant.eulogy! : l.memorialMessage);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: sepiaCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sepiaBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
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
                          Icon(Icons.local_florist, color: sepiaMuted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              plant.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'serif',
                                color: sepiaText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${l.joinedLabel}: $dateJoinedStr',
                            style: TextStyle(
                              color: sepiaMuted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${l.passedLabel}: $datePassedStr',
                            style: TextStyle(
                              color: sepiaMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: sepiaQuoteBg.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '"$note"',
                          style: TextStyle(
                            color: sepiaText,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                            fontSize: 15,
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
      ),
    );
  }
}
