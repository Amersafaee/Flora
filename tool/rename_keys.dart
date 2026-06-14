import 'dart:io';
import 'dart:convert';

void main() {
  final dir = Directory('lib/l10n');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb')).toList();

  final keyReplacements = {
    'flora': 'verdoro',
    'askFlora': 'askVerdoro',
    'askFloraAnything': 'askVerdoroAnything',
    'floraIsThinking': 'verdoroIsThinking',
    'continueWithFlora': 'continueWithVerdoro',
    'analyzeWithFlora': 'analyzeWithVerdoro',
    'askFloraAboutTopic': 'askVerdoroAboutTopic',
    'askFloraForAdvice': 'askVerdoroForAdvice',
    'askFloraAboutThisPlant': 'askVerdoroAboutThisPlant',
    'notSureAskFlora': 'notSureAskVerdoro',
    'floraNoticedSomething': 'verdoroNoticedSomething',
    'couldNotOpenFloraPrefix': 'couldNotOpenVerdoroPrefix',
    'pleaseLogInToUseFlora': 'pleaseLogInToUseVerdoro',
    'floraIsAnalyzingPlants': 'verdoroIsAnalyzingPlants',
    'floraAnalyzingPlants': 'verdoroAnalyzingPlants',
    'floraIsReviewingYourPlants': 'verdoroIsReviewingYourPlants',
    'floraChatMessages': 'verdoroChatMessages',
    'welcomeToFlora': 'welcomeToVerdoro',
    'welcomeToFloraSnackbar': 'welcomeToVerdoroSnackbar',
    'floraKnowsPlantsDesc': 'verdoroKnowsPlantsDesc',
    'floraAiExpertAnswer': 'verdoroAiExpertAnswer',
    'hiIAmFlora': 'hiIAmVerdoro',
    'generatedByFlora': 'generatedByVerdoro',
    'aboutFlora': 'aboutVerdoro',
    'askFloraShort': 'askVerdoroShort',
    'askFloraCTA': 'askVerdoroCTA',
    'joinedLabel': 'joinedBadgeLabel',
  };

  for (final file in files) {
    String content = file.readAsStringSync(encoding: utf8);
    Map<String, dynamic> json = jsonDecode(content);
    Map<String, dynamic> newJson = {};

    for (final key in json.keys) {
      final newKey = keyReplacements[key] ?? key;
      newJson[newKey] = json[key];
    }

    final encoder = JsonEncoder.withIndent('  ');
    final newContent = encoder.convert(newJson);
    file.writeAsStringSync(newContent, encoding: utf8);
  }
  print('Renamed keys in ARB files.');
}
