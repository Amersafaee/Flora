import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:verdoro/l10n/app_localizations.dart';
import 'add_plant_screen.dart';
import 'verdoro_chats_list_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/shared/app_card.dart';
import '../widgets/shared/primary_button.dart';

class WikiPlantDetailScreen extends StatelessWidget {
  final Map<String, dynamic> plantData;

  const WikiPlantDetailScreen({super.key, required this.plantData});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String name = plantData['name'] ?? 'Unknown';
    final String commonName = plantData['commonName'] ?? '';
    final String category = plantData['category'] ?? '';
    final List<String> tags = List<String>.from(plantData['tags'] ?? []);
    final String lightRequirement = plantData['lightRequirement'] ?? 'Unknown';
    final String wateringFrequency = plantData['wateringFrequency'] ?? 'Unknown';
    final String soilType = plantData['soilType'] ?? 'Unknown';
    final String funFact = plantData['funFact'] ?? '';
    final List<String> careTips = List<String>.from(plantData['careTips'] ?? plantData['caretips'] ?? []);

    final Color backgroundColor = isDark ? AppColors.darkBackground : AppColors.bone50;
    final Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.bone900;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Image Area
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  color: isDark ? AppColors.darkForestSubtle : AppColors.forest100,
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          CupertinoIcons.chevron_back,
                          size: 20,
                          color: AppColors.forest700,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 24, left: 24, right: 24,
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 32,
                      fontWeight: FontWeight.bold, fontFamily: 'serif',
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Common Name & Category Card
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (commonName.isNotEmpty)
                          Text(commonName, style: const TextStyle(color: AppColors.bone500, fontSize: 16, fontStyle: FontStyle.italic)),
                        if (commonName.isNotEmpty)
                          const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceElevated : AppColors.bone100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(category, style: const TextStyle(color: AppColors.bone400, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: tags.map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.bone100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(t, style: const TextStyle(
                                color: AppColors.forest700,
                                fontSize: 12, fontWeight: FontWeight.w600,
                              )),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Rows Card
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.wb_sunny_outlined, l.lightLabel, lightRequirement, textColor),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, thickness: 1, color: AppColors.bone200),
                        ),
                        _buildInfoRow(Icons.water_drop_outlined, l.wateringLabel, wateringFrequency, textColor),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, thickness: 1, color: AppColors.bone200),
                        ),
                        _buildInfoRow(Icons.grass, l.soilLabel, soilType, textColor),
                      ],
                    ),
                  ),

                  if (funFact.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline, color: isDark ? AppColors.warningDark : AppColors.warningLight, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.didYouKnow,
                                  style: TextStyle(
                                    color: isDark ? AppColors.warningDark : AppColors.warningLight,
                                    fontWeight: FontWeight.bold, fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  funFact,
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.bone700,
                                    fontSize: 14, height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (careTips.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.careGuidelines,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...careTips.map((tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle, color: AppColors.forest600, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.bone900, fontSize: 14, height: 1.4)
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Add to My Collection Button
                  PrimaryButton(
                    label: l.addToMyCollection,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddPlantScreen(
                            initialPlantName: name,
                            initialCommonName: commonName,
                            initialCategory: category.isNotEmpty ? category : null,
                            initialHealthStatus: 'Healthy',
                            initialWateringDays: RegExp(r'\d+').firstMatch(wateringFrequency)?.group(0) ?? '7',
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Ask Verdoro Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const VerdoroChatsListScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.forest700, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        l.askVerdoroAboutThisPlant,
                        style: GoogleFonts.outfit(color: AppColors.forest700, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color textColor) {
    return Row(
      children: [
        Icon(icon, color: AppColors.bone500, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.bone500, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
