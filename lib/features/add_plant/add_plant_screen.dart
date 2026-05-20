import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
          SnackBar(content: Text('${AppLocalizations.of(context).errorPrefix}$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addPlant),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.saveAction, style: const TextStyle(
                    color: AppColors.forestGreen, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(l10n.pickAnIcon, style: tt.labelLarge),
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
                      border: sel ? Border.all(color: AppColors.forestGreen, width: 2) : null,
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 26)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _field(context, _nameCtrl,    l10n.plantNameAsterisk, required: true),
            _field(context, _speciesCtrl, l10n.speciesVariety),
            _field(context, _locationCtrl, l10n.locationEgLivingRoom),
            _field(context, _freqCtrl,    l10n.wateringFrequencyEg),
            _field(context, _notesCtrl,   l10n.notesLabel, maxLines: 3),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
              ),
              icon: const Icon(Icons.check),
              label: Text(l10n.addToMyGarden),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(BuildContext context, TextEditingController ctrl, String label,
      {bool required = false, int maxLines = 1}) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? l10n.requiredValidator : null
            : null,
      ),
    );
  }
}
