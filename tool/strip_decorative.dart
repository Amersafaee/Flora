import 'dart:io';
import 'dart:convert';

void main() {
  final dir = Directory('lib/l10n');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb')).toList();

  final decorativeKeys = {
    'memorialGardenEmpty', 'letsGrowSomething', 'gotItLetsGo', 'notSureAskFlora', 'notSureAskVerdoro',
    'floraNoticedSomething', 'verdoroNoticedSomething', 'askFloraAboutTopic', 'askVerdoroAboutTopic', 
    'saveToPlant', 'generateCarePlanAction', 'copiedToClipboard', 'askFloraForAdvice', 'askVerdoroForAdvice', 
    'careScheduleSaved', 'listCuttingForSwap', 'askTheCommunity', 'recoveryComplete', 'recoveryMessage', 
    'noPostsAboutYourPlants', 'syncedTasksToCalendar', 'newGrowthDetected', 'propagatedFrom', 'propagationsFromThisPlant',
    'citySetTo', 'noNewNotifications', 'welcomeToFloraSnackbar', 'welcomeToVerdoroSnackbar', 'listingPostedSuccessfully',
    'growthEntryAdded', 'farewellToPlant', 'floraIsAnalyzingPlants', 'verdoroIsAnalyzingPlants', 'challengeComplete',
    'floraAnalyzingPlants', 'verdoroAnalyzingPlants', 'restDayNoTasks'
  };

  final emojiPattern = RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true);

  for (final file in files) {
    String content = file.readAsStringSync(encoding: utf8);
    Map<String, dynamic> json = jsonDecode(content);
    Map<String, dynamic> newJson = {};

    for (final key in json.keys) {
      dynamic value = json[key];
      if (value is String) {
        if (decorativeKeys.contains(key)) {
          value = value.replaceAll(emojiPattern, '').trim();
        }
      }
      newJson[key] = value;
    }

    final encoder = JsonEncoder.withIndent('  ');
    final newContent = encoder.convert(newJson);
    file.writeAsStringSync(newContent, encoding: utf8);
  }
  print('Removed decorative emojis.');
}
