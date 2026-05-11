import 'package:shared_preferences/shared_preferences.dart';

class DemoConfigService {
  static const _mockKey = 'use_mock_data';
  static const _firstLoginKey = 'first_login_done';

  /// Returns true if the app should use mock data. Defaults to true for demo.
  static Future<bool> useMockData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mockKey) ?? true;
  }

  static Future<void> setMockData(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mockKey, value);
  }

  /// Returns true if the first login flow has already been completed.
  static Future<bool> isFirstLoginDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLoginKey) ?? false;
  }

  static Future<void> setFirstLoginDone(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLoginKey, value);
  }
}

