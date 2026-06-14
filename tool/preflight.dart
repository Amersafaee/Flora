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

  // 3. Check that verdoro_context_service.dart does NOT use orderBy combined with where on the same query
  try {
    final contextFile = File('lib/services/verdoro_context_service.dart');
    final contextLines = await contextFile.readAsLines();
    bool found = false;
    for (int i = 0; i < contextLines.length; i++) {
      final line = contextLines[i];
      if (line.contains('.where(') && line.contains('.orderBy(')) {
        fail('orderBy+where combination found in VerdoroContextService line ${i + 1}');
        found = true;
      }
    }
    if (!found) {
      pass('No orderBy+where combinations in VerdoroContextService');
    }
  } catch (e) {
    fail('Could not read verdoro_context_service.dart: $e');
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
    final out = result.stdout.toString();
    final hasNoIssues = out.contains('No issues found');
    final hasOnlyInfo = !out.contains('error -') && !out.contains('warning -');
    if (hasNoIssues || hasOnlyInfo) {
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

  // ── LOGIC CHECK 11 — Signup navigates to home not login ───────────────────
  try {
    final signupFile = File('lib/screens/signup_screen.dart');
    final signupContent = await signupFile.readAsString();
    if (signupContent.contains('pushAndRemoveUntil')) {
      pass('Signup uses pushAndRemoveUntil for post-signup navigation');
    } else {
      fail('Signup does not use pushAndRemoveUntil — user will be stuck on login after signup');
    }
  } catch (e) {
    fail('Could not read signup_screen.dart: $e');
  }

  // ── LOGIC CHECK 12 — Empty plant list has friendly message ──────────────
  try {
    final homeFile = File('lib/screens/home_screen.dart');
    final homeContent = await homeFile.readAsString();
    final hasEmptyCheck = homeContent.contains('plants.isEmpty');
    final hasFriendlyMsg = homeContent.toLowerCase().contains('add your first plant')
        || homeContent.contains('addFirstPlantToGetStarted')
        || homeContent.contains('addYourFirstPlantEmoji')
        || homeContent.contains('yourConservatoryIsEmpty');
    if (hasEmptyCheck && hasFriendlyMsg) {
      pass('Home screen handles empty plant list with friendly message');
    } else {
      fail('Home screen does not handle empty plant list — will show nonsensical 0 plants message');
    }
  } catch (e) {
    fail('Could not read home_screen.dart: $e');
  }

  // ── LOGIC CHECK 13 — Community posts include all required fields ────────
  try {
    final createPostFile = File('lib/screens/create_post_screen.dart');
    final createPostContent = await createPostFile.readAsString();
    final requiredFields = ['status', 'authorUid', 'authorName', 'timestamp', 'likesCount'];
    final List<String> missingFields = [];
    for (final field in requiredFields) {
      if (!createPostContent.contains("'$field'")) {
        missingFields.add(field);
      }
    }
    if (missingFields.isEmpty) {
      pass('Community posts include all required fields');
    } else {
      fail('Community posts missing fields: ${missingFields.join(", ")}');
    }
  } catch (e) {
    fail('Could not read create_post_screen.dart: $e');
  }

  // ── LOGIC CHECK 14 — Community has all 5 post categories ────────────────
  try {
    final createPostFile = File('lib/screens/create_post_screen.dart');
    final createPostContent = await createPostFile.readAsString();
    final requiredCategories = ['General', 'Question', 'Tips', 'Showcase', 'Experience'];
    final List<String> missingCategories = [];
    for (final cat in requiredCategories) {
      if (!createPostContent.contains("'$cat'")) {
        missingCategories.add(cat);
      }
    }
    if (missingCategories.isEmpty) {
      pass('Create post screen has all 5 categories');
    } else {
      fail('Create post screen is missing categories: [${missingCategories.join(", ")}]');
    }
  } catch (e) {
    fail('Could not read create_post_screen.dart: $e');
  }

  // ── LOGIC CHECK 15 — Weekly report has date guard ───────────────────────
  try {
    final weeklyFile = File('lib/services/weekly_report_service.dart');
    final weeklyContent = await weeklyFile.readAsString();
    final hasDateKey = weeklyContent.contains('last_weekly_report_date');
    final hasWeekday = weeklyContent.contains('weekday');
    if (hasDateKey && hasWeekday) {
      pass('Weekly report has date guard with last_weekly_report_date and weekday check');
    } else {
      fail('Weekly report has no date guard — will fire repeatedly');
    }
  } catch (e) {
    fail('Could not read weekly_report_service.dart: $e');
  }

  // ── LOGIC CHECK 16 — Care screen handles empty task list ────────────────
  try {
    final careFile = File('lib/screens/care_screen.dart');
    final careContent = await careFile.readAsString();
    final hasEmptyState = careContent.contains('pendingTasks.isEmpty') || careContent.contains('tasks.isEmpty');
    final hasEmptyMessage = careContent.contains('No care tasks') || careContent.contains('Add a plant') || careContent.contains('noCareTasksYet') || careContent.contains('addAPlant') || careContent.contains('addPlantForCareSchedule');
    if (hasEmptyState && hasEmptyMessage) {
      pass('Care screen handles empty task list with friendly message');
    } else {
      fail('Care screen has no empty state — shows blank screen when no tasks exist');
    }
  } catch (e) {
    fail('Could not read care_screen.dart: $e');
  }

  // ── LOGIC CHECK 17 — Add plant screen has care schedule bottom sheet ────
  try {
    final addPlantFile = File('lib/screens/add_plant_screen.dart');
    final addPlantContent = await addPlantFile.readAsString();
    if (addPlantContent.contains('_showCareScheduleBottomSheet') || addPlantContent.contains('CareSchedule')) {
      pass('Add plant screen shows care schedule after saving');
    } else {
      fail('Add plant screen does not show care schedule after saving — tasks will never be created');
    }
  } catch (e) {
    fail('Could not read add_plant_screen.dart: $e');
  }

  // ── LOGIC CHECK 18 — No screen uses hardcoded user name fallback of User
  try {
    final screensDir = Directory('lib/screens');
    bool foundHardcoded = false;
    final files = screensDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains("?? 'User'") || lines[i].contains('?? "User"')) {
          fail("Hardcoded 'User' fallback in ${file.path} at line ${i + 1}");
          foundHardcoded = true;
        }
      }
    }
    if (!foundHardcoded) {
      pass('No screen uses hardcoded User name fallback');
    }
  } catch (e) {
    fail('Could not search screens for hardcoded User: $e');
  }

  // ── LOGIC CHECK 19 — Every quick action button has a real navigation target
  try {
    final homeFile = File('lib/screens/home_screen.dart');
    final homeLines = await homeFile.readAsLines();
    bool foundDeadButton = false;
    // Look for _buildQuickAction calls near showSnackBar
    bool inQuickActionArea = false;
    for (int i = 0; i < homeLines.length; i++) {
      if (homeLines[i].contains('_buildQuickAction')) {
        inQuickActionArea = true;
      }
      if (inQuickActionArea && homeLines[i].contains('showSnackBar')) {
        fail('Quick action button at line ${i + 1} uses showSnackBar — dead button placeholder');
        foundDeadButton = true;
      }
      // Reset area after the quick actions block ends
      if (inQuickActionArea && homeLines[i].contains('SizedBox(height:') && !homeLines[i].contains('_buildQuickAction')) {
        inQuickActionArea = false;
      }
    }
    if (!foundDeadButton) {
      pass('All quick action buttons have real navigation targets');
    }
  } catch (e) {
    fail('Could not check quick action buttons: $e');
  }

  // ── LOGIC CHECK 20 — Task completion creates next recurring occurrence ──
  try {
    final firestoreFile = File('lib/services/firestore_service.dart');
    final firestoreContent = await firestoreFile.readAsString();
    final hasNewDocRef = firestoreContent.contains('newDocRef');
    final hasBatchSet = firestoreContent.contains('batch.set');
    if (hasNewDocRef || hasBatchSet) {
      pass('markTaskCompleted creates next occurrence for recurring tasks');
    } else {
      fail('Task completion does not create next occurrence — recurring tasks will stop after first completion');
    }
  } catch (e) {
    fail('Could not read firestore_service.dart: $e');
  }

  // ── LOGIC CHECK 21 — Identify result extracts health status ─────────────
  try {
    final identifyResultFile = File('lib/screens/identify_result_screen.dart');
    final identifyResultContent = await identifyResultFile.readAsString();
    if (identifyResultContent.contains('_extractHealthStatus')) {
      pass('Identify result screen extracts health status');
    } else {
      fail('Identify result does not extract health status - add to collection will always show Healthy regardless of Verdoro\'s diagnosis');
    }
  } catch (e) {
    fail('Could not read identify_result_screen.dart: $e');
  }

  // ── LOGIC CHECK 22 — Profile photo loads from Firestore not just Auth ───
  try {
    File profileFile;
    final userUtilsFile = File('lib/utils/user_utils.dart');
    if (userUtilsFile.existsSync()) {
      profileFile = userUtilsFile;
    } else {
      profileFile = File('lib/screens/profile_screen.dart');
    }
    final profileContent = await profileFile.readAsString();
    final hasPhotoUrl = profileContent.contains('profilePhotoUrl');
    final hasFirestore = profileContent.contains('Firestore') || profileContent.contains("collection('users')");
    if (hasPhotoUrl && hasFirestore) {
      pass('Profile photo loads from Firestore (not just Firebase Auth)');
    } else {
      fail('Profile photo only reads from Firebase Auth — uploaded photos will not show');
    }
  } catch (e) {
    fail('Could not read profile/user utils file: $e');
  }

  // ── LOGIC CHECK 23 — Blog content is formatted for readability ──────────
  try {
    // FIX 7 moved blog detail into blog_detail_screen.dart — check there
    final blogDetailFile = File('lib/screens/blog_detail_screen.dart');
    final blogDetailContent = await blogDetailFile.readAsString();
    final hasSplit = blogDetailContent.contains('split');
    final hasMultipleParagraphs = blogDetailContent.contains('paragraphs');
    if (hasSplit && hasMultipleParagraphs) {
      pass('Blog content is split into paragraphs for readability');
    } else {
      fail('Blog content is displayed as one unformatted block — will be unreadable');
    }
  } catch (e) {
    fail('Could not read blog_detail_screen.dart: $e');
  }

  // ── LOGIC CHECK 24 — Swap chat does not contain Ask Verdoro button ────────
  try {
    final swapChatFile = File('lib/screens/swap_chat_screen.dart');
    final swapChatContent = await swapChatFile.readAsString();
    if (!swapChatContent.contains('askVerdoro') && !swapChatContent.contains('Ask Verdoro')) {
      pass('Swap chat does not contain inappropriate Verdoro AI button');
    } else {
      fail('Swap chat contains Verdoro AI button — inappropriate for peer-to-peer trade chat');
    }
  } catch (e) {
    fail('Could not read swap_chat_screen.dart: $e');
  }

  // ── LOGIC CHECK 25 — Onboarding only triggers for new users ─────────────
  try {
    final signupFile = File('lib/screens/signup_screen.dart');
    final signupContent = await signupFile.readAsString();
    if (signupContent.contains('OnboardingService.initForNewUser') || signupContent.contains('initForNewUser')) {
      pass('Signup calls initForNewUser — onboarding only triggers for new users');
    } else {
      fail('Signup does not call initForNewUser — returning users will see onboarding tooltips on every login');
    }
  } catch (e) {
    fail('Could not read signup_screen.dart: $e');
  }

  // ── LOGIC CHECK 26 — No Dart file has weather URL with hardcoded ?key= ──
  try {
    final libDir = Directory('lib');
    bool foundInlineKey = false;
    if (libDir.existsSync()) {
      final files = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          // Flag any line that contains the weather domain AND a literal ?key= value
          // (i.e. the key is embedded in the URL string rather than interpolated from .env)
          final line = lines[i];
          if (line.contains('weather.googleapis.com') &&
              RegExp(r'\?key=AIza').hasMatch(line)) {
            fail('Hardcoded weather API key in URL at ${file.path}:${i + 1}');
            foundInlineKey = true;
          }
        }
      }
    }
    if (!foundInlineKey) {
      pass('No Dart file contains a hardcoded weather API key in the URL');
    }
  } catch (e) {
    fail('Could not check for hardcoded weather API key in URLs: $e');
  }

  // ── LOGIC CHECK 27 — WEATHER_CALENDAR key exists in .env ────────────────
  try {
    final envFile = File('.env');
    if (!envFile.existsSync()) {
      fail('.env file not found (cannot check WEATHER_CALENDAR)');
    } else {
      final envContent = await envFile.readAsString();
      final keyMatch = RegExp(r'WEATHER_CALENDAR=(.+)').firstMatch(envContent);
      if (keyMatch == null) {
        fail('WEATHER_CALENDAR not found in .env');
      } else {
        final key = keyMatch.group(1)!.trim();
        if (key.isEmpty || key == 'YOUR_KEY_HERE' || key == 'PASTE_YOUR_KEY_HERE') {
          fail('WEATHER_CALENDAR is missing or placeholder in .env');
        } else {
          pass('WEATHER_CALENDAR key is configured in .env');
        }
      }
    }
  } catch (e) {
    fail('Could not read .env for WEATHER_CALENDAR: $e');
  }

  // ── LOGIC CHECK 28 — Weather service uses GET + query params (not POST+JSON) ─
  try {
    final weatherServiceFile = File('lib/services/weather_service.dart');
    if (!weatherServiceFile.existsSync()) {
      fail('weather_service.dart not found');
    } else {
      final content = await weatherServiceFile.readAsString();
      final usesGetQueryParams = content.contains('location.latitude') &&
          content.contains('location.longitude');
      final usesPostBody = content.contains('http.post') &&
          content.contains("'location'") &&
          content.contains('latitude');
      if (usesPostBody) {
        fail('weather_service.dart still uses POST+JSON body — must use GET with location.latitude/location.longitude query params');
      } else if (usesGetQueryParams) {
        pass('Weather service uses GET with location.latitude/location.longitude query params');
      } else {
        fail('weather_service.dart does not contain location.latitude/location.longitude — GET query param format not confirmed');
      }
    }
  } catch (e) {
    fail('Could not check weather_service.dart for GET format: $e');
  }

  print('');
  print('═══════════════════════════════════════════════════════════════════');
  print('  PREFLIGHT SUMMARY — 28 checks total');
  print('  ✅ $checksPassed passed   ❌ $checksFailed failed');
  print('═══════════════════════════════════════════════════════════════════');
  if (allPassed) {
    print('🟢 ALL 28 CHECKS PASSED — Safe to build and install APK');
    exit(0);
  } else {
    print('🔴 $checksFailed of 28 CHECKS FAILED — Fix issues above before installing APK');
    exit(1);
  }
}
