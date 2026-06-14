import 'dart:io';
import 'dart:convert';

void main() {
  final dir = Directory('lib/l10n');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb')).toList();

  final decorativeKeys = {
    'memorialGardenEmpty', 'letsGrowSomething', 'gotItLetsGo', 'notSureAskVerdoro',
    'verdoroNoticedSomething', 'askVerdoroAboutTopic', 'saveToPlant', 'generateCarePlanAction',
    'copiedToClipboard', 'askVerdoroForAdvice', 'careScheduleSaved', 'listCuttingForSwap',
    'askTheCommunity', 'recoveryComplete', 'recoveryMessage', 'noPostsAboutYourPlants',
    'syncedTasksToCalendar', 'newGrowthDetected', 'propagatedFrom', 'propagationsFromThisPlant',
    'citySetTo', 'noNewNotifications', 'welcomeToVerdoroSnackbar', 'listingPostedSuccessfully',
    'growthEntryAdded', 'farewellToPlant', 'verdoroIsAnalyzingPlants', 'challengeComplete',
    'verdoroAnalyzingPlants', 'restDayNoTasks'
  };

  final meaningfulKeys = {
    'shareEmoji': '📤',
    'messageSellerEmoji': '💬',
    'addYourFirstPlantEmoji': '🌱',
    'identifyEmoji': '🔍',
    'careEmoji': '💚',
    'communityEmoji': '🌍',
    'listForSwapEmoji': '🔄',
    'thirstyOverdueByDays': '⚠️',
    'needsUrgentAttention': '🚨',
    'careTasksToday': '📅',
    'addFirstPlantToGetStarted': '🌱',
    'allPlantsThrivingToday': '✨',
  };

  final emojiPattern = RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true);

  for (final file in files) {
    final bytes = file.readAsBytesSync();
    String content = utf8.decode(bytes, allowMalformed: true);

    Map<String, dynamic> json = jsonDecode(content);
    Map<String, dynamic> newJson = {};

    for (final key in json.keys) {
      dynamic value = json[key];
      if (value is String) {
        // Fix corrupted em-dash
        value = value.replaceAll('\uFFFD', '-');

        if (decorativeKeys.contains(key)) {
          value = value.replaceAll(emojiPattern, '');
          value = value.replaceAll(RegExp(r' \?{1,3}$'), '');
          value = value.replaceAll(RegExp(r'^\?{1,3} '), '');
          if (value == '??' || value == '???') value = '';
          value = value.trim();
        } else if (meaningfulKeys.containsKey(key)) {
          final emojiToUse = meaningfulKeys[key]!;
          
          if (value.contains('??') || value.contains('???') || value.contains('?')) {
            value = value.replaceAll(RegExp(r'^\?{1,3} '), '$emojiToUse ');
            value = value.replaceAll(RegExp(r' \?{1,3}$'), ' $emojiToUse');
            if (value == '??' || value == '???') value = emojiToUse;
          } else {
            if (emojiPattern.hasMatch(value)) {
              value = value.replaceAll(emojiPattern, emojiToUse);
            } else if (!value.contains(emojiToUse)) {
               if (key.endsWith('Emoji')) {
                  value = '$value $emojiToUse';
               } else {
                  value = '$emojiToUse $value';
               }
            }
          }
        }
      }
      newJson[key] = value;
    }

    final encoder = JsonEncoder.withIndent('  ');
    final newContent = encoder.convert(newJson);
    file.writeAsBytesSync(utf8.encode(newContent));
  }
  print('Fixed all ARB files.');
}
