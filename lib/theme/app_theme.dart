import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFF8FAF8);
  static const Color primaryLight = Color(0xFF154212);
  static const Color secondaryLight = Color(0xFF8D3220);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF191C1B);
  static const Color hintLight = Color(0xFF9E9E9E); // fallback

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E211E);
  static const Color surfaceDark = Color(0xFF1E211E);
  static const Color primaryDark = Color(0xFFA1D494);
  static const Color onPrimaryDark = Color(0xFF121212);
  static const Color secondaryDark = Color(0xFF8D3220);
  static const Color onSurfaceDark = Color(0xFFE8F0E8);
  static const Color hintDark = Color(0xFF6B6B6B);

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: backgroundLight,
      cardColor: cardLight,
      hintColor: hintLight,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        surface: cardLight,
        onSurface: textLight,
        onPrimary: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textLight),
        bodyMedium: TextStyle(color: textLight),
        titleLarge: TextStyle(color: textLight),
        headlineSmall: TextStyle(color: textLight),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: textLight,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: primaryLight),
      useMaterial3: true,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: backgroundDark,
      cardColor: cardDark,
      hintColor: hintDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        surface: surfaceDark,
        onSurface: onSurfaceDark,
        onPrimary: onPrimaryDark,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: onSurfaceDark),
        bodyMedium: TextStyle(color: onSurfaceDark),
        titleLarge: TextStyle(color: onSurfaceDark),
        headlineSmall: TextStyle(color: onSurfaceDark),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: onSurfaceDark,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: primaryDark),
      useMaterial3: true,
    );
  }
}



