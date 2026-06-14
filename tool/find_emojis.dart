import 'dart:io';
import 'dart:convert';

void main() {
  final dir = Directory('lib/l10n');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb')).toList();
  // Regex to match ??, emoji escapes, or actual emojis
  final emojiRegex = RegExp(r'(\\uD83C|\\uD83E|\\uD83F|\\u2600-\\u27FF|\?\?|[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}])', unicode: true);
  
  Set<String> keysWithEmojis = {};
  for (final file in files) {
    final content = file.readAsStringSync();
    final Map<String, dynamic> json = jsonDecode(content);
    json.forEach((key, value) {
      if (value is String && emojiRegex.hasMatch(value)) {
        keysWithEmojis.add(key);
      }
    });
  }
  
  print('Keys with emojis or ?? or escapes:');
  for (final key in keysWithEmojis) {
    print('\nKey: $key');
    for (final file in files) {
      final content = file.readAsStringSync();
      final Map<String, dynamic> json = jsonDecode(content);
      if (json.containsKey(key)) {
        final val = json[key] as String;
        if (emojiRegex.hasMatch(val)) {
          print('  ${file.path.split(Platform.pathSeparator).last}: $val');
        }
      }
    }
  }
}
