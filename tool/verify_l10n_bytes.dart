// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final l10nDir = Directory('lib/l10n');
  final files = l10nDir.listSync().whereType<File>().where((f) {
    final name = f.uri.pathSegments.last;
    return name.startsWith('app_localizations_') && name.endsWith('.dart');
  }).toList();

  files.sort((a, b) => a.path.compareTo(b.path));

  print('| Locale | BOM Present? | Non-ASCII Byte Seq | Classification |');
  print('|---|---|---|---|');

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final locale = name.replaceAll('app_localizations_', '').replaceAll('.dart', '');
    
    final bytes = file.readAsBytesSync();
    final hasBom = bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF;
    
    int? nonAsciiIndex;
    for (int i = (hasBom ? 3 : 0); i < bytes.length; i++) {
      if (bytes[i] > 0x7F) {
        nonAsciiIndex = i;
        break;
      }
    }

    String byteSeqStr = 'N/A';
    String classification = 'N/A';

    if (nonAsciiIndex != null) {
      int b1 = bytes[nonAsciiIndex];
      List<int> seq = [b1];
      
      if ((b1 & 0xE0) == 0xC0) {
        if (nonAsciiIndex + 1 < bytes.length) seq.add(bytes[nonAsciiIndex + 1]);
      } else if ((b1 & 0xF0) == 0xE0) {
        if (nonAsciiIndex + 1 < bytes.length) seq.add(bytes[nonAsciiIndex + 1]);
        if (nonAsciiIndex + 2 < bytes.length) seq.add(bytes[nonAsciiIndex + 2]);
      } else if ((b1 & 0xF8) == 0xF0) {
        if (nonAsciiIndex + 1 < bytes.length) seq.add(bytes[nonAsciiIndex + 1]);
        if (nonAsciiIndex + 2 < bytes.length) seq.add(bytes[nonAsciiIndex + 2]);
        if (nonAsciiIndex + 3 < bytes.length) seq.add(bytes[nonAsciiIndex + 3]);
      }

      byteSeqStr = seq.map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0')).join(' ');

      bool isValidUtf8 = true;
      if (seq.length == 1 && b1 > 0x7F) {
        isValidUtf8 = false; // single byte > 0x7F is invalid utf8 start byte unless it matches a sequence, but length is 1 meaning no continuation bytes were expected OR we didn't add them. Wait, if it didn't match prefix rules above, it's just a single byte seq.
      } else {
        // basic continuation byte check
        for (int i = 1; i < seq.length; i++) {
          if ((seq[i] & 0xC0) != 0x80) isValidUtf8 = false;
        }
      }

      if (!isValidUtf8) {
        classification = 'Single high byte / Windows-1252 (Corrupted)';
      } else if (b1 == 0xC3 && seq.length > 1 && seq[1] == 0x83) {
        classification = 'Double-encoded C3-prefix (Corrupted)';
      } else {
        classification = 'Valid UTF-8 multi-byte (Correct)';
      }
      
      // Let's refine single byte vs multi byte checking
      if (seq.length == 1 && !isValidUtf8) {
         // if it's an expected multi-byte but missing continuation, or just invalid prefix
         if ((b1 & 0xE0) == 0xC0 || (b1 & 0xF0) == 0xE0 || (b1 & 0xF8) == 0xF0) {
            classification = 'Incomplete multi-byte (Corrupted)';
         }
      }
      
      // Double check single high byte:
      if (!isValidUtf8 && seq.length == 1) {
         classification = 'Single high byte / Windows-1252 (Corrupted)';
      }
    }
    
    print('| $locale | ${hasBom ? 'Yes' : 'No'} | $byteSeqStr | $classification |');
  }
}
