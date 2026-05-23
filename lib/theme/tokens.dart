// ─────────────────────────────────────────────────────────────────────────────
// tokens.dart — AppText font-size constants only.
//
// All colour, spacing, radius, and shadow tokens live in app_theme.dart
// (AppColors, AppSpacing, AppRadius, AppShadows).  Import that file instead.
// ─────────────────────────────────────────────────────────────────────────────

// ─── Text Size Constants ──────────────────────────────────────────────────────
// Actual font families are applied in app_theme.dart via google_fonts.
// These raw size values are kept here for use in custom text-style overrides
// outside of the Material TextTheme.
abstract final class AppText {
  static const double displayLargeSize   = 32;
  static const double displayMediumSize  = 28;
  static const double displaySmallSize   = 24;
  static const double headlineMediumSize = 20;
  static const double bodyLargeSize      = 16;
  static const double bodyMediumSize     = 14;
  static const double bodySmallSize      = 12;
  static const double labelLargeSize     = 16;
  static const double labelMediumSize    = 14;
}

