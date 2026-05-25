import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 20.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double xxl = 64.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
}

class AppRadius {
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double pill = 999.0;
}

// =============================================================================
// COLORS
// =============================================================================

class SmartColors {
  // Taxi Gold/Amber Variants
  static const primaryLight = Color(0xFFFFB300); // Amber 600
  static const primaryDark = Color(0xFFFFCA28); // Amber 400
  
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkSurfaceVariant = Color(0xFF2C2C2C);
  
  static const lightBackground = Color(0xFFF8F9FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF0F2F5);

  static const error = Color(0xFFE53935);
  static const success = Color(0xFF43A047);
}

// =============================================================================
// THEMES
// =============================================================================

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: SmartColors.primaryLight,
    onPrimary: Colors.black, // Yellow needs black text
    secondary: Colors.black87,
    onSecondary: Colors.white,
    surface: SmartColors.lightSurface,
    onSurface: Colors.black87,
    error: SmartColors.error,
    surfaceContainerHighest: SmartColors.lightSurfaceVariant,
  ),
  scaffoldBackgroundColor: SmartColors.lightBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    foregroundColor: Colors.black87,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: SmartColors.lightSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: Colors.black12, width: 1),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: SmartColors.lightSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: Colors.black12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: SmartColors.primaryLight, width: 2),
    ),
    contentPadding: const EdgeInsets.all(AppSpacing.md),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: SmartColors.primaryLight,
      foregroundColor: Colors.black,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, 
        vertical: AppSpacing.md
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      textStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  ),
  textTheme: _buildTextTheme(Colors.black87),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: SmartColors.primaryDark,
    onPrimary: Colors.black,
    secondary: Colors.white,
    onSecondary: Colors.black,
    surface: SmartColors.darkSurface,
    onSurface: Colors.white,
    error: SmartColors.error,
    surfaceContainerHighest: SmartColors.darkSurfaceVariant,
  ),
  scaffoldBackgroundColor: SmartColors.darkBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    foregroundColor: Colors.white,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: SmartColors.darkSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: Colors.white10, width: 1),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: SmartColors.darkSurfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: SmartColors.primaryDark, width: 2),
    ),
    contentPadding: const EdgeInsets.all(AppSpacing.md),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: SmartColors.primaryDark,
      foregroundColor: Colors.black,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, 
        vertical: AppSpacing.md
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      textStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  ),
  textTheme: _buildTextTheme(Colors.white),
);

TextTheme _buildTextTheme(Color baseColor) {
  return TextTheme(
    displayLarge: GoogleFonts.outfit( // Modern, geometric font
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: baseColor,
      height: 1.1,
    ),
    displayMedium: GoogleFonts.outfit(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      color: baseColor,
      height: 1.2,
    ),
    headlineLarge: GoogleFonts.outfit(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: baseColor,
    ),
    titleLarge: GoogleFonts.outfit(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: baseColor,
    ),
    bodyLarge: GoogleFonts.inter( // Good for reading
      fontSize: 16,
      color: baseColor,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      color: baseColor.withValues(alpha: 0.8),
      height: 1.5,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: baseColor,
    ),
  );
}
