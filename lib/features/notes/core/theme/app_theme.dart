import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class NotesAppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: NotesAppColors.primary,
        secondary: NotesAppColors.secondary,
        surface: NotesAppColors.surfaceLight,
        error: NotesAppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: NotesAppColors.textPrimaryLight,
      ),
      scaffoldBackgroundColor: NotesAppColors.backgroundLight,
      textTheme: GoogleFonts.interTextTheme(AppTextStyles.lightTextTheme),

      // App Bar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: NotesAppColors.textPrimaryLight,
        titleTextStyle: AppTextStyles.h6Light,
        iconTheme: const IconThemeData(
          color: NotesAppColors.textPrimaryLight,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: NotesAppColors.cardLight,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: NotesAppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NotesAppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: NotesAppColors.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: NotesAppColors.surfaceLight,
        selectedColor: NotesAppColors.primary,
        labelStyle: AppTextStyles.bodySmallLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: NotesAppColors.primaryLight,
        secondary: NotesAppColors.secondaryLight,
        surface: NotesAppColors.surfaceDark,
        error: NotesAppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: NotesAppColors.textPrimaryDark,
      ),
      scaffoldBackgroundColor: NotesAppColors.backgroundDark,
      textTheme: GoogleFonts.interTextTheme(AppTextStyles.darkTextTheme),

      // App Bar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: NotesAppColors.textPrimaryDark,
        titleTextStyle: AppTextStyles.h6Dark,
        iconTheme: const IconThemeData(
          color: NotesAppColors.textPrimaryDark,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: NotesAppColors.cardDark,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: NotesAppColors.primaryLight,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NotesAppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: NotesAppColors.primaryLight,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: NotesAppColors.surfaceDark,
        selectedColor: NotesAppColors.primaryLight,
        labelStyle: AppTextStyles.bodySmallDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
