import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Light Theme Text Styles
  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: NotesAppColors.textPrimaryLight,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: NotesAppColors.textPrimaryLight,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: NotesAppColors.textPrimaryLight,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: NotesAppColors.textPrimaryLight,
      letterSpacing: -0.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: NotesAppColors.textPrimaryLight,
      letterSpacing: -0.3,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: NotesAppColors.textPrimaryLight,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: NotesAppColors.textPrimaryLight,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: NotesAppColors.textPrimaryLight,
      height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: NotesAppColors.textSecondaryLight,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: NotesAppColors.textTertiaryLight,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: NotesAppColors.textPrimaryLight,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: NotesAppColors.textSecondaryLight,
    ),
  );

  // Dark Theme Text Styles
  static const TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: NotesAppColors.textPrimaryDark,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: NotesAppColors.textPrimaryDark,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: NotesAppColors.textPrimaryDark,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: NotesAppColors.textPrimaryDark,
      letterSpacing: -0.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: NotesAppColors.textPrimaryDark,
      letterSpacing: -0.3,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: NotesAppColors.textPrimaryDark,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: NotesAppColors.textPrimaryDark,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: NotesAppColors.textPrimaryDark,
      height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: NotesAppColors.textSecondaryDark,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: NotesAppColors.textTertiaryDark,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: NotesAppColors.textPrimaryDark,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: NotesAppColors.textSecondaryDark,
    ),
  );

  // Convenience Getters for Light Theme
  static TextStyle get h1Light => lightTextTheme.displayLarge!;
  static TextStyle get h2Light => lightTextTheme.displayMedium!;
  static TextStyle get h3Light => lightTextTheme.displaySmall!;
  static TextStyle get h4Light => lightTextTheme.headlineMedium!;
  static TextStyle get h5Light => lightTextTheme.headlineSmall!;
  static TextStyle get h6Light => lightTextTheme.titleLarge!;
  static TextStyle get bodyLargeLight => lightTextTheme.bodyLarge!;
  static TextStyle get bodyMediumLight => lightTextTheme.bodyMedium!;
  static TextStyle get bodySmallLight => lightTextTheme.bodySmall!;

  // Convenience Getters for Dark Theme
  static TextStyle get h1Dark => darkTextTheme.displayLarge!;
  static TextStyle get h2Dark => darkTextTheme.displayMedium!;
  static TextStyle get h3Dark => darkTextTheme.displaySmall!;
  static TextStyle get h4Dark => darkTextTheme.headlineMedium!;
  static TextStyle get h5Dark => darkTextTheme.headlineSmall!;
  static TextStyle get h6Dark => darkTextTheme.titleLarge!;
  static TextStyle get bodyLargeDark => darkTextTheme.bodyLarge!;
  static TextStyle get bodyMediumDark => darkTextTheme.bodyMedium!;
  static TextStyle get bodySmallDark => darkTextTheme.bodySmall!;
}
