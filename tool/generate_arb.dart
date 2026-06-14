// tool/generate_arb.dart
//
// Reads translate.json from the project root and generates one ARB file per
// supported language in lib/l10n/.  Every string value comes directly from
// translate.json — nothing is invented or hardcoded here.
//
// Usage:  dart run tool/generate_arb.dart

import 'dart:convert';
import 'dart:io';

// ---------------------------------------------------------------------------
// Label → ARB-key mapping (preserves the exact ordering given in the spec)
// ---------------------------------------------------------------------------
const Map<String, String> labelToKey = {
  'Navigation': 'navHome',
  'Garden': 'garden',
  'Verdoro': 'verdoro',
  'Discover': 'discover',
  'Profile': 'profile',
  'Sign In': 'signIn',
  'Sign Up': 'signUp',
  'Email': 'email',
  'Password': 'password',
  'Forgot Password': 'forgotPassword',
  'Create Account': 'createAccount',
  'Already have an account': 'alreadyHaveAccount',
  'New here': 'newHere',
  'Google Sign In': 'googleSignIn',
  'Or continue with': 'orContinueWith',
  'Welcome back': 'welcomeBack',
  'Create your account': 'createYourAccount',
  'Identify any plant': 'identifyAnyPlant',
  'Never miss a watering': 'neverMissAWatering',
  'Swap with plant lovers': 'swapWithPlantLovers',
  'Point your camera and Verdoro names it': 'cameraVerdoroNames',
  'Verdoro reminds you exactly when to care': 'verdoroRemindsWhenToCare',
  'Trade cuttings and seeds locally': 'tradeCuttingsLocally',
  'Get Started': 'getStarted',
  'Next': 'nextLabel',
  'Skip': 'skip',
  'Good morning': 'goodMorning',
  'Good afternoon': 'goodAfternoon',
  'Good evening': 'goodEvening',
  "Today's care": 'todaysCare',
  'See all': 'seeAll',
  'day care streak': 'dayCareStreak',
  'Start your streak': 'startYourStreak',
  'complete a care task today': 'completeACareTaskToday',
  'Keep it going, you have tasks today': 'keepItGoingTasksToday',
  'Perfect, nothing due today': 'perfectNothingDueToday',
  'plants in your garden': 'plantsInYourGarden',
  'Good watering day': 'goodWateringDay',
  'My Garden': 'myGarden',
  'Add Plant': 'addPlant',
  'All Plants': 'allPlants',
  'No plants yet': 'noPlantsYet',
  'Add your first plant': 'addYourFirstPlant',
  'Search plants': 'searchPlants',
  'Filter': 'filter',
  'Sort by': 'sortBy',
  'Health Score': 'healthScore',
  'Last Watered': 'lastWatered',
  'Date Added': 'dateAdded',
  'Water': 'waterAction',
  'Fertilise': 'fertilise',
  'Repot': 'repot',
  'Prune': 'prune',
  'Mist': 'mist',
  'Inspect': 'inspect',
  'Treat': 'treat',
  'Growth Journal': 'growthJournal',
  'Treatment Cases': 'treatmentCases',
  'Family Tree': 'familyTree',
  'Care History': 'careHistory',
  'Next watering': 'nextWatering',
  'Light requirement': 'lightRequirement',
  'Watering frequency': 'wateringFrequency',
  'Soil type': 'soilType',
  'Add to collection': 'addToCollection',
  'Ask Verdoro': 'askVerdoro',
  'Care Tips': 'careTips',
  'Fun Fact': 'funFact',
  'Healthy': 'healthy',
  'Needs Attention': 'needsAttention',
  'Critical': 'critical',
  'Care Calendar': 'careCalendar',
  'Today': 'today',
  'Upcoming': 'upcoming',
  'Overdue': 'overdue',
  'Mark Complete': 'markComplete',
  'Batch Care': 'batchCare',
  'Care Streak': 'careStreak',
  'Weekly Report': 'weeklyReport',
  'Smart Care Plan': 'smartCarePlan',
  'Care Insights': 'careInsights',
  'Complete all': 'completeAll',
  'tasks due today': 'tasksDueToday',
  'tasks completed': 'tasksCompleted',
  'Ask Verdoro anything': 'askVerdoroAnything',
  'Type a message': 'typeAMessage',
  'Verdoro is thinking': 'verdoroIsThinking',
  'New Chat': 'newChat',
  'Chat History': 'chatHistory',
  'Based on your garden': 'basedOnYourGarden',
  'Send': 'send',
  'Identify Plant': 'identifyPlant',
  'Take Photo': 'takePhoto',
  'Choose from Gallery': 'chooseFromGallery',
  'Analyze with Verdoro': 'analyzeWithVerdoro',
  'Identifying': 'identifying',
  'Add to My Collection': 'addToMyCollection',
  'Analyze Another': 'analyzeAnother',
  'Continue with Verdoro': 'continueWithVerdoro',
  'Health Status': 'healthStatus',
  'Common Name': 'commonName',
  'Scientific Name': 'scientificName',
  'Category': 'category',
  'Community': 'community',
  'Create Post': 'createPost',
  'Like': 'like',
  'Comment': 'comment',
  'Reply': 'reply',
  'Share': 'share',
  'Report': 'report',
  'Weekly Challenge': 'weeklyChallenge',
  'Categories': 'categories',
  'All': 'all',
  'Questions': 'questions',
  'Tips': 'tips',
  'Showcase': 'showcase',
  'Trending': 'trending',
  'Wiki': 'wiki',
  'Blog': 'blog',
  'Search species': 'searchSpecies',
  'Read more': 'readMore',
  'Care Guide': 'careGuide',
  'Read the full care guide': 'readFullCareGuide',
  'Swap Market': 'swapMarket',
  'Create Listing': 'createListing',
  'Plant Passport': 'plantPassport',
  'Make an Offer': 'makeAnOffer',
  'Message Seller': 'messageSeller',
  'Available': 'available',
  'Traded': 'traded',
  'My Listings': 'myListings',
  'Browse': 'browse',
  'Edit Profile': 'editProfile',
  'Settings': 'settings',
  'Badges': 'badges',
  'Memorial Garden': 'memorialGarden',
  'Vacation Mode': 'vacationMode',
  'Sign Out': 'signOut',
  'Dark Mode': 'darkMode',
  'Language': 'language',
  'Notifications': 'notifications',
  'City': 'city',
  'About': 'about',
  'Select Language': 'selectLanguage',
  'Theme': 'theme',
  'Light Mode': 'lightMode',
  'System Default': 'systemDefault',
  'Notification Settings': 'notificationSettings',
  'Privacy Policy': 'privacyPolicy',
  'Terms of Service': 'termsOfService',
  'Version': 'version',
  'Delete Account': 'deleteAccount',
  'Active': 'active',
  'Edit Care Plan': 'editCarePlan',
  'days away': 'daysAway',
  'Your plants are in good hands': 'plantsInGoodHands',
  'Earned': 'earned',
  'Locked': 'locked',
  'Collection': 'collection',
  'Joined': 'joined',
  'Passed': 'passed',
  'May this plant rest peacefully in the soil': 'memorialMessage',
  'Save': 'save',
  'Cancel': 'cancel',
  'Delete': 'delete',
  'Edit': 'edit',
  'Done': 'done',
  'Back': 'back',
  'Close': 'close',
  'Loading': 'loading',
  'Error': 'error',
  'Retry': 'retry',
  'Yes': 'yes',
  'No': 'no',
  'OK': 'ok',
  'Confirm': 'confirm',
  'Sort': 'sort',
  'Copy': 'copy',
  'Paste': 'paste',
  'Select': 'selectAction',
  'Remove': 'remove',
  'Add': 'add',
  'Create': 'create',
  'Update': 'update',
  'Submit': 'submit',
  'Continue': 'continueAction',
  'Finish': 'finish',
  'Previous': 'previous',
  'Yesterday': 'yesterday',
  'days ago': 'daysAgo',
  'day': 'day',
  'days': 'days',
  'week': 'week',
  'weeks': 'weeks',
  'month': 'month',
  'months': 'months',
  'Something went wrong': 'somethingWentWrong',
  'Please try again': 'pleaseTryAgain',
  'No internet connection': 'noInternetConnection',
  'Add some plants first': 'addSomePlantsFirst',
  'Due today': 'dueToday',
  'Completed': 'completed',
  'Skipped': 'skipped',
  'Watering': 'watering',
  'Fertilizing': 'fertilizing',
  'Repotting': 'repotting',
  'Pruning': 'pruning',
  'Misting': 'misting',
  'Inspecting': 'inspecting',
  'Treating': 'treating',
};

const List<String> supportedLocales = [
  'en', 'es', 'fr', 'de', 'pt', 'ar', 'fa', 'ja', 'ko', 'it',
  'nl', 'tr', 'pl', 'sv', 'hi',
];

void main() async {
  // ── 1. Load translate.json ───────────────────────────────────────────────
  final jsonFile = File('translate.json');
  if (!jsonFile.existsSync()) {
    stderr.writeln('ERROR: translate.json not found in the current directory.');
    stderr.writeln('       Run this script from the project root.');
    exit(1);
  }

  final Map<String, dynamic> translations =
      jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;

  // ── 2. Ensure output directory exists ────────────────────────────────────
  final outDir = Directory('lib/l10n');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  // ── 3. Build one ARB per locale ──────────────────────────────────────────
  var totalMissing = 0;

  for (final locale in supportedLocales) {
    final arbEntries = <String, String>{};

    for (final MapEntry<String, String> mapping in labelToKey.entries) {
      final label = mapping.key;
      final arbKey = mapping.value;

      final labelData = translations[label];
      if (labelData == null) {
        stderr.writeln('  WARN [$locale]: label "$label" not found in translate.json');
        totalMissing++;
        continue;
      }

      final value = (labelData as Map<String, dynamic>)[locale];
      if (value == null) {
        stderr.writeln('  WARN [$locale]: locale "$locale" missing for label "$label"');
        totalMissing++;
        continue;
      }

      arbEntries[arbKey] = value as String;
    }

    // Build a proper ARB map (@@locale first, then entries)
    final arb = <String, dynamic>{'@@locale': locale};
    arb.addAll(arbEntries);

    final encoder = JsonEncoder.withIndent('  ');
    final content = encoder.convert(arb);

    final outFile = File('lib/l10n/app_$locale.arb');
    outFile.writeAsStringSync('$content\n');
    stdout.writeln('  ✅  Written: ${outFile.path}  (${arbEntries.length} keys)');
  }

  if (totalMissing > 0) {
    stderr.writeln('\n⚠️  $totalMissing missing value(s) — check warnings above.');
  } else {
    stdout.writeln('\n🎉  All ${supportedLocales.length} ARB files generated with no missing values.');
  }
}
