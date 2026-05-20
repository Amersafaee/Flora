import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
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
            appBar: AppBar(title: Text(l10n.plantNotFound)),
            body: Center(child: Text(l10n.plantNoLongerExists)),
          );
        }

        final growthEntries = growthAsync.valueOrNull ?? [];

        return Scaffold(
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
                  PopupMenuItem(value: 'ask_flora', child: Text(AppLocalizations.of(context).askFloraAboutThisPlant)),
                  PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context).editNicknameMenu)),
                  PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context).deletePlantMenu, style: const TextStyle(color: AppColors.error))),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddGrowthEntry(context, plantId),
            backgroundColor: AppColors.forestGreen,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            children: [
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
                  decoration: BoxDecoration(color: AppColors.dew, borderRadius: AppRadius.borderLg),
                  child: const Center(child: Text('🪴', style: TextStyle(fontSize: 72))),
                ),
              const SizedBox(height: 20),
              Text(plant.commonName, style: TextStyle(
                fontFamily: 'NotoSerif', fontSize: 26, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.forestGreen,
              )),
              if (plant.scientificName.isNotEmpty)
                Text(plant.scientificName, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15, color: AppColors.moss)),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StatTile(icon: Icons.straighten, label: l10n.heightStat, value: _latestHeight(growthEntries)),
                  const SizedBox(width: 12),
                  _StatTile(icon: Icons.book_outlined, label: l10n.entriesStat, value: '${growthEntries.length}'),
                ],
              ),
              const SizedBox(height: 28),
              Text(l10n.growthJournal, style: TextStyle(
                fontFamily: 'NotoSerif', fontSize: 20, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.forestGreen,
              )),
              const SizedBox(height: 12),
              if (growthEntries.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(color: cs.surface, borderRadius: AppRadius.borderMd, boxShadow: AppShadows.cardShadow),
                  child: Column(
                    children: [
                      const Text('📝', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(l10n.noEntriesYet, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(l10n.tapPlusToAddGrowthEntry, style: tt.bodySmall?.copyWith(color: cs.outline)),
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

  void _editNickname(BuildContext context, PlantDoc plant) {
    final ctrl = TextEditingController(text: plant.nickname);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).editNicknameTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(ctx).nicknameField,
            border: OutlineInputBorder(borderRadius: AppRadius.borderSm),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(ctx).cancel)),
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
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.forestGreen),
            child: Text(AppLocalizations.of(ctx).save),
          ),
        ],
      ),
    );
  }

  void _deletePlant(BuildContext context, PlantDoc plant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).deletePlantTitle),
        content: Text(AppLocalizations.of(ctx).deletePlantBody(
          plant.nickname.isNotEmpty ? plant.nickname : plant.commonName,
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(ctx).cancel)),
          TextButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;
              await FirebaseFirestore.instance
                  .collection('users').doc(uid)
                  .collection('plants').doc(plant.id)
                  .delete();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                context.pop();
              }
            },
            child: Text(AppLocalizations.of(ctx).delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

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
        decoration: BoxDecoration(color: cs.surface, borderRadius: AppRadius.borderMd, boxShadow: AppShadows.cardShadow),
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

class _GrowthCard extends StatelessWidget {
  final GrowthEntry entry;
  const _GrowthCard({required this.entry});

  String _formatDate(BuildContext context, DateTime d) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return l10n.today;
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) return l10n.yesterday;
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
          Text(_formatDate(context, entry.createdAt), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.moss)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(color: cs.surface, borderRadius: AppRadius.borderMd, boxShadow: AppShadows.cardShadow),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.photoBase64.isNotEmpty)
                  Image.memory(base64Decode(entry.photoBase64), width: double.infinity, height: 200, fit: BoxFit.cover, gaplessPlayback: true),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.note.isNotEmpty) Text(entry.note, style: tt.bodyMedium),
                      if (entry.heightCm != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.straighten, size: 14, color: AppColors.moss),
                            const SizedBox(width: 4),
                            Text('${entry.heightCm!.toStringAsFixed(0)} cm',
                              style: const TextStyle(fontSize: 13, color: AppColors.moss, fontWeight: FontWeight.w600)),
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
