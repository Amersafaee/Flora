// ignore_for_file: avoid_print, unused_local_variable
import 'dart:io';

Future<void> main() async {
  bool allPassed = true;
  int checksPassed = 0;
  int checksFailed = 0;

  void pass(String msg) {
    print('✅ PASS — $msg');
    checksPassed++;
  }

  void fail(String msg) {
    print('❌ FAIL — $msg');
    checksFailed++;
    allPassed = false;
  }

  // 0. Check for hardcoded AIzaSy keys in lib/
  try {
    bool hasHardcodedKey = false;
    final libDir = Directory('lib');
    if (libDir.existsSync()) {
      final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].contains('AIzaSy')) {
            fail('Hardcoded key found in ${file.path} at line ${i + 1}');
            hasHardcodedKey = true;
          }
        }
      }
    }
    if (!hasHardcodedKey) {
      pass('No dart file contains hardcoded AIzaSy key');
    }
  } catch (e) {
    fail('Could not check for hardcoded keys: $e');
  }

  // 1. Check that the Gemini API key is present in .env
  try {
    final envFile = File('.env');
    if (!envFile.existsSync()) {
      fail('.env file not found');
    } else {
      final envContent = await envFile.readAsString();
      final keyMatch = RegExp(r'GEMINI_API_KEY=(.+)').firstMatch(envContent);
      if (keyMatch == null) {
        fail('GEMINI_API_KEY not found in .env');
      } else {
        final key = keyMatch.group(1)!.trim();
        if (key.isEmpty || key == 'PASTE_YOUR_KEY_HERE') {
          fail('GEMINI_API_KEY is missing or placeholder');
        } else {
          pass('Gemini API key is configured in .env');
        }
      }
    }
  } catch (e) {
    fail('Could not read .env: $e');
  }

  // 2. Check that all required Firestore collections are mentioned in firestore.rules
  try {
    final rulesFile = File('firestore.rules');
    final rulesContent = await rulesFile.readAsString();
    final requiredCollections = [
      'blogs', 'species', 'posts', 'swap_listings', 
      'swap_conversations', 'users', 'challenges', 'reports'
    ];
    
    List<String> missing = [];
    for (var col in requiredCollections) {
      if (!rulesContent.contains(col)) {
        missing.add(col);
      }
    }
    
    if (missing.isNotEmpty) {
      fail('Firestore rules missing collections: ${missing.join(", ")}');
    } else {
      pass('Firestore rules contain all required collections');
    }
  } catch (e) {
    fail('Could not read firestore.rules: $e');
  }

  // 3. Check that flora_context_service.dart does NOT use orderBy combined with where on the same query
  try {
    final contextFile = File('lib/services/flora_context_service.dart');
    final contextLines = await contextFile.readAsLines();
    bool found = false;
    for (int i = 0; i < contextLines.length; i++) {
      final line = contextLines[i];
      if (line.contains('.where(') && line.contains('.orderBy(')) {
        fail('orderBy+where combination found in FloraContextService line ${i + 1}');
        found = true;
      }
    }
    if (!found) {
      pass('No orderBy+where combinations in FloraContextService');
    }
  } catch (e) {
    fail('Could not read flora_context_service.dart: $e');
  }

  // 4. Check that task_model.dart fromMap uses safe parsing for repeatDays
  try {
    final modelFile = File('lib/models/task_model.dart');
    final modelContent = await modelFile.readAsString();
    
    final isSafe = modelContent.contains('as num?') || modelContent.contains('toInt()');
    final isUnsafeDirect = modelContent.contains("map['repeatDays'] as int") || modelContent.contains('List.from');
    
    if (isUnsafeDirect) {
       fail('Task model fromMap uses unsafe parsing for repeatDays or List.from');
    } else if (isSafe) {
       pass('Task model uses safe repeatDays parsing');
    } else {
       fail('Task model repeatDays parsing pattern not found or unsafe');
    }
  } catch (e) {
    fail('Could not read task_model.dart: $e');
  }

  // 5. Check that main.dart caches the auth stream
  try {
    final mainFile = File('lib/main.dart');
    final mainContent = await mainFile.readAsString();
    if (mainContent.contains('_authStream')) {
      if (mainContent.contains('stream: FirebaseAuth.instance.authStateChanges()')) {
         fail('main.dart StreamBuilder uses authStateChanges() inline');
      } else {
         pass('main.dart caches auth stream securely');
      }
    } else {
      fail('main.dart does not contain _authStream field');
    }
  } catch (e) {
    fail('Could not read main.dart: $e');
  }

  // 6. Check that no screen files contain the string 'Coming soon' shown to users
  try {
    final dir = Directory('lib/screens');
    final files = dir.listSync(recursive: true).whereType<File>();
    bool hasComingSoon = false;
    for (var file in files) {
      if (!file.path.endsWith('.dart')) continue;
      final lines = await file.readAsLines();
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains("'Coming soon'") || lines[i].contains('"Coming soon"')) {
          fail("Coming soon string found in ${file.path} on line ${i + 1}");
          hasComingSoon = true;
        }
      }
    }
    if (!hasComingSoon) {
      pass('No Coming soon placeholders in screens');
    }
  } catch (e) {
    fail('Could not read screens directory: $e');
  }

  // 8. Check that identify_screen.dart does not contain user-visible text saying 'Gemini'
  try {
    final identifyFile = File('lib/screens/identify_screen.dart');
    final identifyLines = await identifyFile.readAsLines();
    bool foundGemini = false;
    for (int i = 0; i < identifyLines.length; i++) {
      if ((identifyLines[i].contains("'") || identifyLines[i].contains('"')) && identifyLines[i].contains('Gemini')) {
        fail("Gemini text found in identify_screen.dart on line ${i + 1}");
        foundGemini = true;
      }
    }
    if (!foundGemini) {
      pass('No user-visible Gemini text in identify_screen.dart');
    }
  } catch (e) {
    fail('Could not read identify_screen.dart: $e');
  }

  // 7. Check that flutter analyze returns zero issues
  try {
    final result = await Process.run('flutter', ['analyze'], runInShell: true);
    if (result.stdout.toString().contains('No issues found') || result.stderr.toString().contains('No issues found')) {
      pass('Flutter analyze returned no issues');
    } else {
      fail('Flutter analyze found issues:\\n${result.stdout}');
    }
  } catch (e) {
    fail('Could not run flutter analyze: $e');
  }

  // 9. Check Gemini API connectivity
  try {
    final envFile = File('.env');
    final envContents = envFile.existsSync() ? envFile.readAsStringSync() : '';
    final keyMatch = RegExp(r'GEMINI_API_KEY=(.+)').firstMatch(envContents);
    final apiKey = keyMatch?.group(1)?.trim() ?? '';

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    final request = await client.getUrl(Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'));
    final response = await request.close();
    if (response.statusCode == 200) {
      final responseBody = await response.transform(SystemEncoding().decoder).join();
      if (responseBody.toLowerCase().contains('gemini')) {
        pass('Gemini API is reachable and responding correctly');
      } else {
        fail('Gemini API responded 200 but did not contain expected data');
      }
    } else {
      final responseBody = await response.transform(SystemEncoding().decoder).join();
      fail('Gemini API responded with status ${response.statusCode}. Body: $responseBody');
    }
    client.close();
  } catch (e) {
    fail('Could not connect to Gemini API: $e');
  }

  print('');
  if (allPassed) {
    print('🟢 ALL CHECKS PASSED — Safe to build and install APK');
    exit(0);
  } else {
    print('🔴 $checksFailed CHECKS FAILED — Fix issues above before installing APK');
    exit(1);
  }
}
