import 'dart:io';
import 'dart:convert';

void main() {
  final dir = Directory('lib/l10n');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb')).toList();

  final missingKeys = {
    'askVerdoroAboutThis': 'Ask Verdoro about this',
    'plantNameFieldHint': 'e.g. Monstera',
    'recoveringStatus': 'Recovering',
    'ofCounterLabel': 'of',
    'couldNotGenerateCarePlan': 'Could not generate care plan',
    'thisWeekLabel': 'This Week',
    'addFirstPlantForPersonalizedPlan': 'Add your first plant to get a personalized plan',
    'showingCachedPlanRefreshHint': 'Showing cached plan. Pull to refresh.',
    'aiGeneratedForPlantsThisWeek': 'AI generated for your plants this week',
    'restDayNoTasksNeeded': 'Rest day. No tasks needed.',
    'unknownPlantFallback': 'Unknown Plant',
    'chartMaxLabel': 'Max',
    'chartMinLabel': 'Min',
    'joinedLabel': 'Joined',
  };

  for (final file in files) {
    String content = file.readAsStringSync(encoding: utf8);
    Map<String, dynamic> json = jsonDecode(content);
    
    // Add missing keys
    for (final entry in missingKeys.entries) {
      if (!json.containsKey(entry.key)) {
        json[entry.key] = entry.value;
      }
    }
    
    // Also add joinedLabel if I accidentally renamed it to joinedBadgeLabel
    if (json.containsKey('joinedBadgeLabel') && !json.containsKey('joinedLabel')) {
        json['joinedLabel'] = 'Joined';
    }

    final encoder = JsonEncoder.withIndent('  ');
    final newContent = encoder.convert(json);
    file.writeAsStringSync(newContent, encoding: utf8);
  }
  print('Added missing keys to ARB files.');
}
