import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'isDarkMode';

  Future<void> saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  Future<bool> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to false (light) — never fall through to system dark mode
    return prefs.getBool(_themeKey) ?? false;
  }

  /// Returns the saved [ThemeMode], defaulting to [ThemeMode.light] when no
  /// preference has been persisted yet.  Never returns [ThemeMode.system].
  Future<ThemeMode> getThemeMode() async {
    final isDark = await loadThemeMode();
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }
}

