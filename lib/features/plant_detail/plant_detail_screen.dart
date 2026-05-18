import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/plant_providers.dart';
import 'add_growth_entry_sheet.dart';
import '../../theme/app_theme.dart';

class PlantDetailScreen extends ConsumerWidget {
  final String plantId;
  const PlantDetailScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantAsync = ref.watch(plantByIdProvider(plantId));
    final growthAsync = ref.watch(growthJournalProvider(plantId));
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return plantAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (plant) {
        if (plant == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Plant not found')),
            body: const Center(child: Text('This plant no longer exists.')),
          );
        }

        final growthEntries = growthAsync.valueOrNull ?? [];

        return Scaffold(
          // ── App Bar ──────────────────────────────────────────────────
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(
              plant.nickname.isNotEmpty ? plant.nickname : plant.commonName,
              style: const TextStyle(fontFamily: 'NotoSerif', fontWeight: FontWeight.w700),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (val) {
                  if (val == 'ask_flora') {
                    context.push('/flora-chat', extra: 'Tell me about my ${plant.nickname.isNotEmpty ? plant.nickname : plant.commonName}.');
                  }
                  if (val == 'edit') _editNickname(context, plant);
                  if (val == 'delete') _deletePlant(context, plant);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'ask_flora', child: Text('Ask Flora about this plant')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit nickname')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete plant', style: TextStyle(color: AppColors.error))),
                ],
              ),
            ],
          ),

          // ── FAB ──────────────────────────────────────────────────────
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddGrowthEntry(context, plantId),
            backgroundColor: AppColors.forestGreen,
            child: const Icon(Icons.add, color: Colors.white),
          ),

          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            children: [
              // ── Photo ─────────────────────────────────────────────────
              if (plant.photoBase64.isNotEmpty)
                ClipRRect(
                  borderRadius: AppRadius.borderLg,
                  child: Image.memory(
                    base64Decode(plant.photoBase64),
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                )
              else
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.dew,
                    borderRadius: AppRadius.borderLg,
                  ),
                  child: const Center(child: Text('🪴', style: TextStyle(fontSize: 72))),
                ),
              const SizedBox(height: 20),

              // ── Names ─────────────────────────────────────────────────
              Text(plant.commonName, style: TextStyle(
                fontFamily: 'NotoSerif', fontSize: 26, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.forestGreen,
              )),
              if (plant.scientificName.isNotEmpty)
                Text(plant.scientificName, style: TextStyle(
                  fontStyle: FontStyle.italic, fontSize: 15, color: AppColors.moss,
                )),
              const SizedBox(height: 20),

              // ── Stat Tiles ────────────────────────────────────────────
              Row(
                children: [
                  _StatTile(
                    icon: Icons.straighten,
                    label: 'Height',
                    value: _latestHeight(growthEntries),
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    icon: Icons.book_outlined,
                    label: 'Entries',
                    value: '${growthEntries.length}',
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Growth Journal Header ─────────────────────────────────
              Text('Growth Journal', style: TextStyle(
                fontFamily: 'NotoSerif', fontSize: 20, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.forestGreen,
              )),
              const SizedBox(height: 12),

              // ── Growth Entries ─────────────────────────────────────────
              if (growthEntries.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: AppRadius.borderMd,
                    boxShadow: AppShadows.cardShadow,
                  ),
                  child: Column(
                    children: [
                      const Text('📝', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text('No entries yet', style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Tap + to add your first growth entry', style: tt.bodySmall?.copyWith(color: cs.outline)),
                    ],
                  ),
                )
              else
                ...growthEntries.map((entry) => _GrowthCard(entry: entry)),
            ],
          ),
        );
      },
    );
  }

  String _latestHeight(List<GrowthEntry> entries) {
    for (final e in entries) {
      if (e.heightCm != null) return '${e.heightCm!.toStringAsFixed(0)} cm';
    }
    return '—';
  }

  void _showAddGrowthEntry(BuildContext context, String plantId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddGrowthEntrySheet(plantId: plantId),
    );
  }

  // ── Edit Nickname Dialog ────────────────────────────────────────────────
  void _editNickname(BuildContext context, PlantDoc plant) {
    final ctrl = TextEditingController(text: plant.nickname);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Nickname'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nickname',
            border: OutlineInputBorder(borderRadius: AppRadius.borderSm),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;
              await FirebaseFirestore.instance
                  .collection('users').doc(uid)
                  .collection('plants').doc(plant.id)
                  .update({'nickname': newName});
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.forestGreen),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Delete Plant ────────────────────────────────────────────────────────
  void _deletePlant(BuildContext context, PlantDoc plant) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete plant?'),
        content: Text('This will permanently remove "${plant.nickname.isNotEmpty ? plant.nickname : plant.commonName}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;
              await FirebaseFirestore.instance
                  .collection('users').doc(uid)
                  .collection('plants').doc(plant.id)
                  .delete();
              if (context.mounted) {
                Navigator.pop(context); // close dialog
                context.pop(); // go back
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Stat tile ─────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadius.borderMd,
          boxShadow: AppShadows.cardShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.forestGreen),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: cs.outline)),
          ],
        ),
      ),
    );
  }
}

// ── Growth journal card ───────────────────────────────────────────────────────
class _GrowthCard extends StatelessWidget {
  final GrowthEntry entry;
  const _GrowthCard({required this.entry});

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date label
          Text(_formatDate(entry.createdAt), style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.moss,
          )),
          const SizedBox(height: 6),
          // Card
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: AppRadius.borderMd,
              boxShadow: AppShadows.cardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.photoBase64.isNotEmpty)
                  Image.memory(
                    base64Decode(entry.photoBase64),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.note.isNotEmpty)
                        Text(entry.note, style: tt.bodyMedium),
                      if (entry.heightCm != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.straighten, size: 14, color: AppColors.moss),
                            const SizedBox(width: 4),
                            Text('${entry.heightCm!.toStringAsFixed(0)} cm',
                              style: TextStyle(fontSize: 13, color: AppColors.moss, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

