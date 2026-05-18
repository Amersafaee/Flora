import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const List<String> supportedLanguageCodes = [
    'en', 'es', 'fr', 'de', 'pt', 'ar', 'fa', 'ja', 'ko', 'it', 'nl', 'tr', 'pl', 'sv', 'hi'
  ];

  static Future<Locale> getInitialLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('app_language');
    
    if (savedCode != null && supportedLanguageCodes.contains(savedCode)) {
      return Locale(savedCode);
    }
    
    final systemLocale = Platform.localeName;
    final systemLanguageCode = systemLocale.split('_').first;
    
    if (supportedLanguageCodes.contains(systemLanguageCode)) {
      await saveLocale(systemLanguageCode);
      return Locale(systemLanguageCode);
    }
    
    await saveLocale('en');
    return const Locale('en');
  }

  static Future<void> saveLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', languageCode);
  }
}
