import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Forest (Primary)
  static const forest900 = Color(0xFF14301E);
  static const forest800 = Color(0xFF1F4A2C);
  static const forest700 = Color(0xFF2F5D3A);
  static const forest600 = Color(0xFF3D7349);
  static const forest500 = Color(0xFF4F8B5C);
  static const forest400 = Color(0xFF7AAB85);
  static const forest300 = Color(0xFFA8C8B0);
  static const forest200 = Color(0xFFCEE0D3);
  static const forest100 = Color(0xFFE6EFE9);
  static const forest50  = Color(0xFFF2F7F3);

  // Terracotta (Accent)
  static const terracotta900 = Color(0xFF6B2F1E);
  static const terracotta700 = Color(0xFFB8553A);
  static const terracotta500 = Color(0xFFD97757);
  static const terracotta300 = Color(0xFFE8A88E);
  static const terracotta100 = Color(0xFFF8E5DA);

  // Bone (Neutral)
  static const bone950 = Color(0xFF1C1B17);
  static const bone900 = Color(0xFF2A2925);
  static const bone700 = Color(0xFF5B5953);
  static const bone500 = Color(0xFF8B8982);
  static const bone300 = Color(0xFFBFBDB5);
  static const bone200 = Color(0xFFD8D6CE);
  static const bone100 = Color(0xFFE8E6DE);
  static const bone50  = Color(0xFFF4F1EA);
  static const bone25  = Color(0xFFFAF8F4);
  static const white   = Color(0xFFFFFFFF);
  static const parchment = Color(0xFFEDEAE0); // warm cream baseline

  // Dark mode surfaces
  static const darkCanvas          = Color(0xFF0E1411);
  static const darkSurface         = Color(0xFF18201B);
  static const darkSurfaceElevated = Color(0xFF232C25);
  static const darkSurfaceHigh     = Color(0xFF2D362F);
  static const darkBorderSubtle    = Color(0xFF2A3328);
  static const darkBorderDefault   = Color(0xFF3A4338);
  static const darkBorderStrong    = Color(0xFF525B4F);
  static const darkForestPrimary   = Color(0xFF6FAF7E);
  static const darkForestHover     = Color(0xFF8FC79C);
  static const darkForestSubtle    = Color(0xFF1F3525);
  static const darkTerracotta      = Color(0xFFE89578);
  static const darkTerracottaSubtle= Color(0xFF3D2419);
  static const darkTextPrimary     = Color(0xFFF0EDE5);
  static const darkTextSecondary   = Color(0xFFB8B5AB);
  static const darkTextTertiary    = Color(0xFF7D7A72);
  static const darkTextDisabled    = Color(0xFF4A4844);

  // Semantic
  static const successLight = Color(0xFF4F8B5C);
  static const successDark  = Color(0xFF6FAF7E);
  static const warningLight = Color(0xFFC8893A);
  static const warningDark  = Color(0xFFE0A862);
  static const errorLight   = Color(0xFFC24E47);
  static const errorDark    = Color(0xFFE07670);
  // Semantic shorthand aliases (used across screens)
  static const success = Color(0xFF4F8B5C);
  static const error   = Color(0xFFC24E47);
  static const warning = Color(0xFFC8893A);

  // ── Backward-compat aliases from tokens.dart ─────────────────────────────
  // These map old token names to the new design system values.
  static const forestGreen  = forest900;  // 0xFF14301E → 0xFF14301E (same deep green)
  static const leafGreen    = forest900;
  static const lightSage    = forest100;
  static const sage         = forest100;
  static const mist         = forest100;
  static const dew          = forest100;
  static const cream        = bone25;
  static const bark         = bone900;
  static const moss         = bone500;
  static const terracotta   = terracotta900;
  static const darkBackground = darkCanvas;
  static const darkBorder     = darkBorderDefault;
}


class AppRadius {
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 24;
  static const double xl2 = 32;
  static const double pill = 999;
  // Backward-compat aliases (tokens.dart naming)
  static const BorderRadius borderSm   = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd   = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg   = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(pill));
}

class AppSpacing {
  static const double s1  = 4;
  static const double s2  = 8;
  static const double s3  = 12;
  static const double s4  = 16;
  static const double s5  = 20;
  static const double s6  = 24;
  static const double s7  = 32;
  static const double s8  = 40;
  static const double s9  = 48;
  static const double s10 = 64;
  // Backward-compat aliases (tokens.dart naming)
  static const double xs  = 4;
  static const double sm  = 8;
  // Note: 'md' is 16 in tokens.dart but could conflict with s4; we use 16 for consistency
  static const double md  = 16;
  static const double lgS = 24;  // 'lg' shadows AppRadius.lg — use lgS for spacing
  static const double xl  = 32;
  static const double xxl = 48;
}

/// Drop shadows reused across components (from tokens.dart).
class AppShadows {
  static const cardShadow = [
    BoxShadow(
      color: Color(0x0D000000), // 5% black
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



class AppTheme {
  static TextTheme _buildTextTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: GoogleFonts.notoSerif(fontSize: 40, height: 48/40, fontWeight: FontWeight.w600, letterSpacing: -0.02 * 40, color: primaryText),
      displayMedium: GoogleFonts.notoSerif(fontSize: 32, height: 40/32, fontWeight: FontWeight.w600, letterSpacing: -0.015 * 32, color: primaryText),
      displaySmall: GoogleFonts.notoSerif(fontSize: 24, height: 32/24, fontWeight: FontWeight.w600, letterSpacing: -0.01 * 24, color: primaryText),
      headlineLarge: GoogleFonts.notoSerif(fontSize: 24, height: 32/24, fontWeight: FontWeight.w600, color: primaryText),
      headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 20, height: 28/20, fontWeight: FontWeight.w600, color: primaryText),
      headlineSmall: GoogleFonts.plusJakartaSans(fontSize: 17, height: 24/17, fontWeight: FontWeight.w600, color: primaryText),
      titleLarge: GoogleFonts.plusJakartaSans(fontSize: 17, height: 26/17, fontWeight: FontWeight.w400, color: primaryText),
      titleMedium: GoogleFonts.plusJakartaSans(fontSize: 15, height: 22/15, fontWeight: FontWeight.w400, color: primaryText),
      titleSmall: GoogleFonts.plusJakartaSans(fontSize: 13, height: 20/13, fontWeight: FontWeight.w400, color: secondaryText),
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 17, height: 26/17, fontWeight: FontWeight.w400, color: primaryText),
      bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 15, height: 22/15, fontWeight: FontWeight.w400, color: primaryText),
      bodySmall: GoogleFonts.plusJakartaSans(fontSize: 13, height: 20/13, fontWeight: FontWeight.w400, color: secondaryText),
      labelLarge: GoogleFonts.plusJakartaSans(fontSize: 15, height: 22/15, fontWeight: FontWeight.w600, color: primaryText),
      labelMedium: GoogleFonts.plusJakartaSans(fontSize: 12, height: 16/12, fontWeight: FontWeight.w500, letterSpacing: 0.005 * 12, color: secondaryText),
      labelSmall: GoogleFonts.plusJakartaSans(fontSize: 11, height: 14/11, fontWeight: FontWeight.w600, letterSpacing: 0.08 * 11, color: secondaryText),
    );
  }

  static ThemeData get light {
    final textTheme = _buildTextTheme(AppColors.bone900, AppColors.bone700);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.forest700,
      scaffoldBackgroundColor: AppColors.bone50,
      cardColor: AppColors.white,
      textTheme: textTheme,
      colorScheme: ColorScheme.light(
        primary: AppColors.forest700,
        onPrimary: AppColors.white,
        secondary: AppColors.terracotta500,
        onSecondary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.bone900,
        surfaceContainerHighest: AppColors.bone50,
        outline: AppColors.bone100,
        outlineVariant: AppColors.bone200,
        error: AppColors.errorLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bone25,
        foregroundColor: AppColors.bone900,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.bone900),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.forest700,
        unselectedItemColor: AppColors.bone500,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w400),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest700,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6, vertical: AppSpacing.s4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest700,
          side: const BorderSide(color: AppColors.forest700, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6, vertical: AppSpacing.s4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forest700,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bone50,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.bone100)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.bone100)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.forest700, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.errorLight)),
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.bone500),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.bone700),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bone50,
        selectedColor: AppColors.forest200,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
        side: const BorderSide(color: AppColors.bone100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s1),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.bone100, thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: AppColors.forest700),
    );
  }

  static ThemeData get dark {
    final textTheme = _buildTextTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.darkForestPrimary,
      scaffoldBackgroundColor: AppColors.darkCanvas,
      cardColor: AppColors.darkSurface,
      textTheme: textTheme,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkForestPrimary,
        onPrimary: AppColors.darkCanvas,
        secondary: AppColors.darkTerracotta,
        onSecondary: AppColors.darkCanvas,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkSurfaceElevated,
        outline: AppColors.darkBorderDefault,
        outlineVariant: AppColors.darkBorderSubtle,
        error: AppColors.errorDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkCanvas,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkForestPrimary,
        unselectedItemColor: AppColors.darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w400),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkForestPrimary,
          foregroundColor: AppColors.darkCanvas,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6, vertical: AppSpacing.s4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkForestPrimary,
          side: const BorderSide(color: AppColors.darkForestPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6, vertical: AppSpacing.s4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkForestPrimary,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.darkBorderDefault)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.darkBorderDefault)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.darkForestPrimary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.errorDark)),
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.darkTextTertiary),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.darkTextSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        selectedColor: AppColors.darkForestSubtle,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkTextPrimary),
        side: const BorderSide(color: AppColors.darkBorderDefault),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s1),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorderSubtle, thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: AppColors.darkForestPrimary),
    );
  }
}
