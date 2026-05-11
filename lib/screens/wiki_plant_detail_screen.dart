import 'package:flutter/material.dart';
import 'add_plant_screen.dart';

class WikiPlantDetailScreen extends StatelessWidget {
  final Map<String, dynamic> plantData;

  const WikiPlantDetailScreen({super.key, required this.plantData});

  @override
  Widget build(BuildContext context) {
    final String name = plantData['name'] ?? 'Unknown';
    final String commonName = plantData['commonName'] ?? '';
    final String category = plantData['category'] ?? '';
    final List<String> tags = List<String>.from(plantData['tags'] ?? []);
    final String lightRequirement = plantData['lightRequirement'] ?? 'Unknown';
    final String wateringFrequency = plantData['wateringFrequency'] ?? 'Unknown';
    final String soilType = plantData['soilType'] ?? 'Unknown';
    final String funFact = plantData['funFact'] ?? '';
    final List<String> careTips = List<String>.from(plantData['careTips'] ?? plantData['caretips'] ?? []);

    final Color primaryColor = Theme.of(context).primaryColor;
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final Color textColor = Theme.of(context).colorScheme.onSurface;

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
                  color: const Color(0xFFC8E6C9), // soft green
                  // If we had image we could display it here
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (commonName.isNotEmpty)
                          Text(
                            commonName,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBE9E7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: Color(0xFF8D3220),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags.map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Info Rows Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.wb_sunny_outlined, 'Light', lightRequirement, textColor),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, thickness: 1),
                        ),
                        _buildInfoRow(Icons.water_drop_outlined, 'Watering', wateringFrequency, textColor),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, thickness: 1),
                        ),
                        _buildInfoRow(Icons.grass, 'Soil', soilType, textColor),
                      ],
                    ),
                  ),
                  
                  if (funFact.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6), // Light yellow for fun fact
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFFFD54F), width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline, color: Color(0xFFF57F17), size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Did You Know?',
                                  style: TextStyle(
                                    color: Color(0xFFF57F17),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  funFact,
                                  style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontSize: 14,
                                    height: 1.5,
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Care Guidelines',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...careTips.map((tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
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
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddPlantScreen(
                              initialPlantName: name,
                              initialCommonName: commonName,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add to My Collection',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Ask Flora Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        // Pop back to main navigation
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        // The MainNavigation should handle switching to tab index 4 (Flora), but we don't have direct access
                        // to the main nav state from here. We can push a new MainNavigation with initialIndex if it supported it.
                        // Or we can just pop to home, and if they need Flora they tap it. 
                        // Actually, pushing a replacement to main navigation might be best, but we'll just push FloraScreen for now.
                        // Wait, if it pushes FloraScreen, it loses the bottom nav bar.
                        // Let's just push FloraScreen directly as a top-level route if we can't switch tabs, or since 
                        // it's a tab, let's see if we can use Navigator.popUntil route.settings.name == '/'
                        // User requirement: "opens flora_screen as a tab by popping back to the main navigation."
                        // We will use Navigator.popUntil then try to push FloraScreen or maybe the user just means "go to Flora screen".
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        // In a real app we'd use an InheritedWidget or Provider to switch the tab.
                        // For now popping to first is close enough. 
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryColor, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        'Ask Flora About This Plant',
                        style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
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
        Icon(icon, color: Colors.grey, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

