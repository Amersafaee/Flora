import 'dart:io';
import 'dart:convert';

void main() async {
  final jsonFile = File('tool/arb_translations_10.json');
  final jsonStr = await jsonFile.readAsString();
  final Map<String, dynamic> translations =
      jsonDecode(jsonStr) as Map<String, dynamic>;

  final langs = [
    'de', 'es', 'fr', 'ar', 'fa', 'hi',
    'it', 'ja', 'ko', 'nl', 'pl', 'pt', 'sv', 'tr'
  ];
  final keys = [
    'welcomeTourTitle1', 'welcomeTourBody1',
    'welcomeTourTitle2', 'welcomeTourBody2',
    'welcomeTourTitle3', 'welcomeTourBody3',
    'welcomeTourTitle4', 'welcomeTourBody4',
    'welcomeTourTitle5', 'welcomeTourBody5',
    'startExploring', 'detectAutomatically', 'usesYourIpAddress',
  ];

  for (final lang in langs) {
    final arbFile = File('lib/l10n/app_$lang.arb');
    var content = await arbFile.readAsString();

    // Strip previously appended block if present
    const markerKey = '"welcomeTourTitle1"';
    final markerIdx = content.lastIndexOf(markerKey);
    if (markerIdx >= 0) {
      final cutIdx = content.lastIndexOf(',', markerIdx);
      if (cutIdx >= 0) content = content.substring(0, cutIdx);
    }

    // Trim and remove trailing closing brace
    content = content.trimRight();
    if (content.endsWith('}')) {
      content = content.substring(0, content.length - 1).trimRight();
    }

    // Append new keys with proper UTF-8 JSON encoding
    final buf = StringBuffer(content);
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final keyData = translations[key] as Map<String, dynamic>?;
      final val = (keyData?[lang] ?? keyData?['en'] ?? '') as String;
      final encoded = jsonEncode(val);
      buf.write(',\n  "$key": $encoded');
    }
    buf.write('\n}\n');

    await arbFile.writeAsString(buf.toString(), encoding: utf8);
    stdout.writeln('Updated $lang');
  }
  stdout.writeln('All done.');
}
