// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final l10nDir = Directory('lib/l10n');
  if (!l10nDir.existsSync()) {
    print('Directory lib/l10n not found.');
    return;
  }

  final files = l10nDir.listSync().whereType<File>().where((f) {
    final name = f.uri.pathSegments.last;
    return name.startsWith('app_localizations') && name.endsWith('.dart');
  }).toList();

  int updatedCount = 0;
  int alreadyBomCount = 0;

  for (final file in files) {
    final bytes = file.readAsBytesSync();
    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      print('Skipped: ${file.uri.pathSegments.last} (already has BOM)');
      alreadyBomCount++;
    } else {
      final newBytes = <int>[0xEF, 0xBB, 0xBF, ...bytes];
      file.writeAsBytesSync(newBytes);
      print('Updated: ${file.uri.pathSegments.last} (added BOM)');
      updatedCount++;
    }
  }

  print('\nSummary:');
  print('Total files scanned: ${files.length}');
  print('Updated (BOM added): $updatedCount');
  print('Skipped (BOM present): $alreadyBomCount');
}
