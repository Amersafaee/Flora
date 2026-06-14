import 'dart:io';
import 'dart:convert';

void main() {
  final dir = Directory('lib/l10n');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb')).toList();

  for (final file in files) {
    String content = file.readAsStringSync(encoding: utf8);
    Map<String, dynamic> json = jsonDecode(content);
    
    // Fix ofCounterLabel
    json['ofCounterLabel'] = '{current} of {total}';
    json['@ofCounterLabel'] = {
      'placeholders': {
        'current': {'type': 'String'},
        'total': {'type': 'String'}
      }
    };
    
    // Add missing verdoroIsAnalyzingPlants
    if (!json.containsKey('verdoroIsAnalyzingPlants')) {
        json['verdoroIsAnalyzingPlants'] = 'Verdoro is analyzing your plants...';
    }

    final encoder = JsonEncoder.withIndent('  ');
    final newContent = encoder.convert(json);
    file.writeAsStringSync(newContent, encoding: utf8);
  }
  print('Fixed remaining ARB issues.');
}
