import 'package:flutter/material.dart';
import 'package:study_deck/core/theme/royal_design_system.dart';

export 'package:study_deck/core/theme/royal_design_system.dart';
export 'package:study_deck/core/theme/animated_glass_background.dart';

/// Design tokens and color definitions for StudyDeck.
/// Visual direction: Royal Midnight Navy, Antique Metallic Gold, Warm Ivory, and Pearl White.
class AppColors {
  AppColors._();

  // Core Royal Palette
  static const Color midnightNavy = RoyalColors.midnightNavy;
  static const Color midnightNavyDark = RoyalColors.midnightNavyDark;
  static const Color deepNavy = RoyalColors.midnightNavy;
  static const Color deepNavyDark = RoyalColors.midnightNavyDark;
  static const Color navySurface = RoyalColors.midnightNavySurface;
  static const Color navyCard = RoyalColors.midnightNavySurface;

  static const Color royalGold = RoyalColors.royalGold;
  static const Color antiqueGold = RoyalColors.antiqueGold;
  static const Color metallicGold = RoyalColors.metallicGold;
  static const Color goldLight = RoyalColors.lightGold;
  static const Color goldMuted = RoyalColors.antiqueGold;
  static const Color champagne = RoyalColors.champagne;
  static const Color warmIvory = RoyalColors.warmIvory;
  static const Color pearlWhite = RoyalColors.pearlWhite;

  // Compatibility tokens mapped to the royal palette (No blue/purple)
  static const Color electricPurple = RoyalColors.royalGold;
  static const Color electricPurpleLight = RoyalColors.champagne;
  static const Color electricPurpleSoft = RoyalColors.paleGold;
  static const Color electricPurpleGlow = RoyalColors.metallicGold;

  static const Color white = RoyalColors.pearlWhite;
  static const Color slateLight = RoyalColors.warmIvory;
  static const Color slateBorder = RoyalColors.ivoryBorder;
  static const Color slateBorderDark = Color(0xFF233258);

  // Typography Neutrals
  static const Color textPrimaryLight = RoyalColors.textNavy;
  static const Color textSecondaryLight = RoyalColors.textNavyMuted;
  static const Color textPrimaryDark = RoyalColors.pearlWhite;
  static const Color textSecondaryDark = RoyalColors.textMutedDark;
}

/// Material 3 theme configurations for StudyDeck with royal aesthetic.
class AppTheme {
  AppTheme._();

  /// Light theme for StudyDeck featuring warm ivory, royal navy, and antique gold.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: RoyalColors.royalGold,
      onPrimary: RoyalColors.midnightNavy,
      primaryContainer: RoyalColors.paleGold,
      onPrimaryContainer: RoyalColors.midnightNavy,
      secondary: RoyalColors.midnightNavy,
      onSecondary: RoyalColors.pearlWhite,
      secondaryContainer: const Color(0xFFF0EBE1),
      onSecondaryContainer: RoyalColors.midnightNavy,
      surface: RoyalColors.creamCard,
      onSurface: RoyalColors.textNavy,
      surfaceContainerLowest: RoyalColors.pearlWhite,
      surfaceContainerLow: RoyalColors.warmIvory,
      surfaceContainer: const Color(0xFFF2ECE1),
      outline: RoyalColors.ivoryBorder,
      outlineVariant: const Color(0xFFDCD5C3),
      error: const Color(0xFFDC2626),
      onError: RoyalColors.pearlWhite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: RoyalColors.warmIvory,
      cardTheme: const CardThemeData(
        color: RoyalColors.creamCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: RoyalColors.ivoryBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: RoyalColors.warmIvory,
        foregroundColor: RoyalColors.midnightNavy,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RoyalColors.royalGold,
          foregroundColor: RoyalColors.midnightNavy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: RoyalColors.royalGold,
          foregroundColor: RoyalColors.midnightNavy,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: RoyalColors.paleGold,
        labelStyle: const TextStyle(
          color: RoyalColors.midnightNavy,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }

  /// Dark theme for StudyDeck featuring deep royal midnight navy and metallic gold.
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: RoyalColors.champagne,
      onPrimary: RoyalColors.midnightNavy,
      primaryContainer: RoyalColors.midnightNavySurface,
      onPrimaryContainer: RoyalColors.champagne,
      secondary: RoyalColors.pearlWhite,
      onSecondary: RoyalColors.midnightNavy,
      secondaryContainer: RoyalColors.midnightNavySubtle,
      onSecondaryContainer: RoyalColors.pearlWhite,
      surface: RoyalColors.midnightNavy,
      onSurface: RoyalColors.textWhite,
      surfaceContainerLowest: RoyalColors.midnightNavyDark,
      surfaceContainerLow: RoyalColors.midnightNavy,
      surfaceContainer: RoyalColors.midnightNavySurface,
      outline: RoyalColors.glassGoldBorder,
      outlineVariant: const Color(0xFF283B6A),
      error: const Color(0xFFEF4444),
      onError: RoyalColors.pearlWhite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: RoyalColors.midnightNavyDark,
      cardTheme: const CardThemeData(
        color: RoyalColors.midnightNavySurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: RoyalColors.glassGoldBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: RoyalColors.midnightNavyDark,
        foregroundColor: RoyalColors.textWhite,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RoyalColors.royalGold,
          foregroundColor: RoyalColors.midnightNavy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: RoyalColors.royalGold,
          foregroundColor: RoyalColors.midnightNavy,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x33C5A04A),
        labelStyle: const TextStyle(
          color: RoyalColors.champagne,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }
}
