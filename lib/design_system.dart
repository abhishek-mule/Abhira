// ==================== DESIGN SYSTEM ====================
// This file defines the design system for the Abhira app, including
// color system, typography, spacing, and other design tokens.

import 'package:flutter/material.dart';

// ==================== COLOR SYSTEM ====================
class AppColors {
  // Primary color: Purple Heart #6527BE
  static const Color primary = Color(0xFF6527BE);

  // Destructive/error color: #FF3E3E
  static const Color destructive = Color(0xFFFF3E3E);

  // Success color: Green #10B981
  static const Color success = Color(0xFF10B981);

  // Neutral background modes
  static const Color background = Colors.white;
  static const Color lightBackground = Colors.white;
  static const Color darkBackground = Color(0xFF121212);

  // Text colors
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color lightText = Colors.black;
  static const Color darkText = Colors.white;

  // Surface and border colors
  static const Color surface = Color(0xFFF9FAFB);
  static const Color border = Color(0xFFE5E7EB);

  // Additional colors
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color gray = Color(0xFFE0E0E0);
  static const Color darkGray = Color(0xFF757575);
  static const Color disabled = Color(0xFFBDBDBD);
}

// ==================== TYPOGRAPHY SYSTEM ====================
class AppTypography {
  // Font family: Inter (preferred) or Roboto
  static const String fontFamily = 'Inter';

  // Type scale with exact values
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: 32,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: 24,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: 20,
    height: 1.4,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.normal,
    fontSize: 14,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.normal,
    fontSize: 12,
    height: 1.5,
  );
}

// ==================== SPACING & LAYOUT ====================
class AppSpacing {
  // Grid system: 8px baseline
  static const double baseline = 8;

  // Spacing tokens
  static const double xSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xLarge = 24;
  static const double xxLarge = 32;
  static const double xxxLarge = 48;
}

// ==================== RADIUS SYSTEM ====================
class AppRadius {
  // Border radius tokens
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xLarge = 24;
}

// ==================== THEME DATA ====================
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.lightBackground,
    textTheme: const TextTheme(
      displayLarge: AppTypography.h1,
      displayMedium: AppTypography.h2,
      displaySmall: AppTypography.h3,
      titleLarge: AppTypography.subtitle,
      bodyMedium: AppTypography.body,
      labelSmall: AppTypography.caption,
    ),
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      error: AppColors.destructive,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.lightText,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxLarge,
          vertical: AppSpacing.medium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.small),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxLarge,
          vertical: AppSpacing.medium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.small),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.small),
        borderSide: const BorderSide(color: AppColors.gray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.small),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.small),
        borderSide: const BorderSide(color: AppColors.destructive),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.small),
        borderSide: const BorderSide(color: AppColors.destructive),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBackground,
    textTheme: const TextTheme(
      displayLarge: AppTypography.h1,
      displayMedium: AppTypography.h2,
      displaySmall: AppTypography.h3,
      titleLarge: AppTypography.subtitle,
      bodyMedium: AppTypography.body,
      labelSmall: AppTypography.caption,
    ).apply(
      bodyColor: AppColors.darkText,
      displayColor: AppColors.darkText,
    ),
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      error: AppColors.destructive,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.darkText,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxLarge,
          vertical: AppSpacing.medium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.small),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxLarge,
          vertical: AppSpacing.medium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.small),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.small),
        borderSide: const BorderSide(color: AppColors.gray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.small),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.small),
        borderSide: const BorderSide(color: AppColors.destructive),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.small),
        borderSide: const BorderSide(color: AppColors.destructive),
      ),
    ),
  );
}

// ==================== ACCESSIBILITY ====================
class AppAccessibility {
  // Minimum touch target: 48 × 48 dp
  static const double minTouchTarget = 48;

  // Focus states
  static const OutlineInputBorder focusBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
    borderSide: BorderSide(color: AppColors.primary, width: 2),
  );

  // Reduced motion
  static const Duration motionDuration = Duration(milliseconds: 200);
}

// ==================== LOCATION SEARCH FEATURE ====================
class LocationSearch {
  static InputDecoration searchBarDecoration = InputDecoration(
    hintText: 'Search location...',
    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.small),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.small),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.small),
      borderSide: const BorderSide(color: AppColors.destructive),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.small),
      borderSide: const BorderSide(color: AppColors.destructive, width: 2),
    ),
  );
}
