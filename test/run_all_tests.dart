// run with 'flutter test' for all tests, 'flutter test --tags integration' for integration tests only, 'flutter test test/models/' for model tests only
//
// What each test file covers:
// - test/models/task_model_test.dart: Task.fromMap and Task.toMap edge cases and defaults.
// - test/models/plant_model_test.dart: Plant.fromMap and Plant.toMap edge cases and defaults.
// - test/services/task_recurrence_test.dart: Task recurrence calculation logic isolated from Firestore.
// - test/services/gemini_service_test.dart: GeminiService instantiation, API key validation, and smoke integration testing.
// - test/services/verdoro_context_test.dart: VerdoroContextService string generation and logic testing.
// - test/services/weekly_report_test.dart: Pure unit tests for shouldShowWeeklyReport gates (weekday, account age, date guard).
// - test/services/notification_test.dart: Pure logic tests for NotificationService skip guard and ID computation.
// - test/navigation_test.dart: MainTabScreen tab-to-screen mapping and label expectations.
// - test/widget/verdoro_screen_smoke_test.dart: UI interactions in VerdoroScreen (send button states, default chips).
//
// What must be tested manually and why:
// - Firestore Security Rules (see test/integration/firestore_rules_test.dart): Automated testing of security rules requires setting up and running the local Firebase emulator suite, which is outside the scope of CI and standard test runs here. These should be tested using the Firebase Console Simulator or a local emulator.
// - GeminiService real API calls: The integration test uses real network resources and API limits, so it should be run manually (with --tags integration) to avoid flakiness and exhaustion of quota in regular CI.

import 'package:flutter_test/flutter_test.dart';

import 'models/task_model_test.dart' as task_model_test;
import 'models/plant_model_test.dart' as plant_model_test;
import 'services/task_recurrence_test.dart' as task_recurrence_test;
import 'services/gemini_service_test.dart' as gemini_service_test;
import 'services/verdoro_context_test.dart' as verdoro_context_test;
import 'services/weekly_report_test.dart' as weekly_report_test;
import 'services/notification_test.dart' as notification_test;
import 'navigation_test.dart' as navigation_test;
import 'widget/verdoro_screen_smoke_test.dart' as verdoro_screen_smoke_test;

void main() {
  group('All Tests', () {
    task_model_test.main();
    plant_model_test.main();
    task_recurrence_test.main();
    gemini_service_test.main();
    verdoro_context_test.main();
    weekly_report_test.main();
    notification_test.main();
    navigation_test.main();
    verdoro_screen_smoke_test.main();
  });
}
