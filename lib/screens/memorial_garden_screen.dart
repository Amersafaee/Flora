import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plant_model.dart';
import '../services/firestore_service.dart';

class MemorialGardenScreen extends StatelessWidget {
  const MemorialGardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const sepiaBg = Color(0xFFFAF8F5);
    const sepiaCard = Color(0xFFF3EFE9);
    const sepiaText = Color(0xFF5D4037);

    return Scaffold(
      backgroundColor: sepiaBg,
      appBar: AppBar(
        title: const Text('Memorial Garden'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: sepiaText),
        titleTextStyle: const TextStyle(
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
              return const Center(child: Text('Something went wrong', style: TextStyle(color: Colors.grey)));
            }

            final deceasedPlants = (snapshot.data ?? []).where((p) => p.isDeceased).toList();
            
            if (deceasedPlants.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No plants in the memorial garden yet — every plant lives a full life here first 🌿',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF8D6E63), fontSize: 16, fontStyle: FontStyle.italic),
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
                    : 'Unknown date';
                
                final note = plant.memorialNote?.isNotEmpty == true ? plant.memorialNote! : (plant.eulogy?.isNotEmpty == true ? plant.eulogy! : 'May this plant rest peacefully in the soil.');

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: sepiaCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8DCC4)),
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
                          const Icon(Icons.local_florist, color: Color(0xFF8D6E63)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              plant.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'serif',
                                color: Color(0xFF5D4037),
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
                            'Joined: $dateJoinedStr',
                            style: const TextStyle(
                              color: Color(0xFF8D6E63),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Passed: $datePassedStr',
                            style: const TextStyle(
                              color: Color(0xFF8D6E63),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF8F5).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '"$note"',
                          style: const TextStyle(
                            color: Color(0xFF5D4037),
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
