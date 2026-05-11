import 'package:flutter/material.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
abstract final class AppColors {
  // Primary Brand: Deep Forest Green (#154212)
  static const forestGreen  = Color(0xFF154212);
  // Secondary/Soft Brand: Light Sage Green (#E8F3EA)
  static const lightSage    = Color(0xFFE8F3EA);
  // Accent/Alert: Soft Terracotta (#8D3220)
  static const terracotta   = Color(0xFF8D3220);

  // Backgrounds & Surfaces
  static const backgroundOffWhite = Color(0xFFF8FAF8);
  static const surfaceWhite       = Color(0xFFFFFFFF);

  // Text
  static const textPrimary   = Color(0xFF1F2937); // Dark Charcoal
  static const textSecondary = Color(0xFF6B7280); // Medium Gray

  // Aliases for compatibility with existing code where appropriate
  static const leafGreen    = forestGreen;
  static const sage         = lightSage;
  static const mist         = lightSage;
  static const dew          = lightSage;
  static const moss         = textSecondary;
  static const bark         = textPrimary;
  static const cream        = backgroundOffWhite;

  // Dark mode surfaces
  static const darkBackground = Color(0xFF111827); // Darker charcoal for dark mode bg
  static const darkSurface    = Color(0xFF1F2937); // Dark Charcoal for surface
  static const darkBorder     = Color(0xFF374151);
  static const darkTextPrimary   = Color(0xFFFBFBFB);
  static const darkTextSecondary = Color(0xFF9CA3AF);

  // Semantic
  static const success = Color(0xFF4A7C2F);
  static const warning = Color(0xFFC4622D);
  static const error   = Color(0xFFB00020);
  static const info    = Color(0xFF1565C0);
}

// ─── Spacing ──────────────────────────────────────────────────────────────────
abstract final class AppSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}

// ─── Border Radius ────────────────────────────────────────────────────────────
abstract final class AppRadius {
  static const double sm     = 8;
  static const double md     = 12;
  static const double lg     = 20;
  static const double pill   = 100;
  static const double circle = 9999;

  static const borderSm   = BorderRadius.all(Radius.circular(sm));
  static const borderMd   = BorderRadius.all(Radius.circular(md));
  static const borderLg   = BorderRadius.all(Radius.circular(lg));
  static const borderPill = BorderRadius.all(Radius.circular(pill));
}

// ─── Shadows ──────────────────────────────────────────────────────────────────
abstract final class AppShadows {
  static const cardShadow = [
    BoxShadow(
      color: Color(0x0D000000), // 5% black (Color(0x0D...) is roughly 5% opacity, 0.05 * 255 = 12.75 -> 0D)
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  static const buttonShadow = [
    BoxShadow(
      color: Color(0x1F2D5016), // 12% forest green
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const navShadow = [
    BoxShadow(
      color: Color(0x1A000000), // 10% black
      blurRadius: 8,
      offset: Offset(0, -2),
    ),
  ];
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
// Note: actual font families are applied in app_theme.dart via google_fonts.
abstract final class AppText {
  static const double displayLargeSize  = 32;
  static const double displayMediumSize = 28;
  static const double displaySmallSize  = 24;
  static const double headlineMediumSize = 20;
  static const double bodyLargeSize     = 16;
  static const double bodyMediumSize    = 14;
  static const double bodySmallSize     = 12;
  static const double labelLargeSize    = 16;
  static const double labelMediumSize   = 14;
}

