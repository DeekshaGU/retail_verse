import 'package:flutter/material.dart';
import 'package:retail_verse_pos/core/theme/app_colors.dart';
import 'package:retail_verse_pos/core/theme/app_typography.dart';

/// Premium theme for Retail Verse
/// Enterprise-grade, clean, and professional UI theme
class AppTheme {
  AppTheme._();

  static const double borderRadiusSM = 4.0;
  static const double borderRadiusMD = 8.0;
  static const double borderRadiusLG = 16.0;
  static const double borderRadiusXL = 24.0;
  static const double borderRadiusPill = 999.0;

  static List<BoxShadow> get shadowSM => [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.accent,
        onSecondary: AppColors.textOnPrimary,
        error: AppColors.error,
        surface: AppColors.background,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),

      scaffoldBackgroundColor: AppColors.background,

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        titleTextStyle: AppTypography.headlineMedium.copyWith(color: Colors.white),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLG),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle: AppTypography.labelLarge,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),

      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),
    );
  }

  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F1419),
      // Extend as needed for dark mode
    );
  }
}
