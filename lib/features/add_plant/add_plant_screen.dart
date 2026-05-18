import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/plant.dart';
import '../../data/plant_repository.dart';
import '../../theme/app_theme.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _speciesCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _freqCtrl    = TextEditingController();
  final _notesCtrl   = TextEditingController();
  String _emoji = '🪴';
  bool _saving = false;

  static const _emojis = [
    '🪴', '🌵', '🌿', '🎋', '🌴', '🌱', '🌺', '🌸',
    '🌻', '🌹', '🍀', '🌾', '🎍', '🌲', '🌳', '🍃',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _speciesCtrl.dispose(); _locationCtrl.dispose();
    _freqCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await PlantRepository.instance.add(Plant(
        id:           '',
        name:         _nameCtrl.text.trim(),
        species:      _speciesCtrl.text.trim(),
        emoji:        _emoji,
        location:     _locationCtrl.text.trim(),
        wateringFreq: _freqCtrl.text.trim(),
        notes:        _notesCtrl.text.trim(),
        addedAt:      DateTime.now(),
      ));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Plant'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(
                    color: AppColors.forestGreen, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── Emoji picker ────────────────────────────────────────────────
            Text('Pick an icon', style: tt.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((e) {
                final sel = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.dew : cs.surfaceContainerHighest,
                      borderRadius: AppRadius.borderSm,
                      border: sel ? Border.all(
                          color: AppColors.forestGreen, width: 2) : null,
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 26)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Fields ──────────────────────────────────────────────────────
            _field(_nameCtrl,    'Plant name *',   required: true),
            _field(_speciesCtrl, 'Species / variety'),
            _field(_locationCtrl,'Location (e.g. Living room)'),
            _field(_freqCtrl,    'Watering frequency (e.g. Every 3 days)'),
            _field(_notesCtrl,   'Notes', maxLines: 3),

            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMd),
              ),
              icon: const Icon(Icons.check),
              label: const Text('Add to my garden'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }
}

