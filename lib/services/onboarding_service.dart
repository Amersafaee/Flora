import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _prefix = 'feature_onboarding_';
  
  // Returns true if this feature onboarding has never been shown
  static Future<bool> shouldShow(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('$_prefix$featureKey') ?? false);
  }
  
  // Mark a feature onboarding as shown — never show again
  static Future<void> markShown(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$featureKey', true);
  }
  
  // Reset all onboarding — for testing only
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
  
  // Call this when a new user signs up — clears any existing flags
  // so they see all onboarding fresh
  static Future<void> initForNewUser() async {
    await resetAll();
  }
}
