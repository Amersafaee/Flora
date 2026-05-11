import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plant_model.dart';
import '../services/firestore_service.dart';

class MemorialGardenScreen extends StatelessWidget {
  const MemorialGardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Memorial Garden'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
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
              return const Center(child: Text('Your memorial garden is empty.', style: TextStyle(color: Colors.grey)));
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
                final dateStr = plant.deceasedDate != null 
                    ? DateFormat.yMMMMd().format(plant.deceasedDate!)
                    : 'Unknown date';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF2A2A2A) 
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_florist, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              plant.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'serif',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rested on $dateStr',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        plant.eulogy ?? 'May this plant rest peacefully in the soil.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
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
