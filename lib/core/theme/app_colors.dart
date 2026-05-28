import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - Purple/Lavender Gospel Theme
  static const Color primary = Color(0xFF7C4DFF);
  static const Color primaryLight = Color(0xFFB47CFF);
  static const Color primaryDark = Color(0xFF4A00E0);

  // Accent
  static const Color accent = Color(0xFFFFD700); // Gold
  static const Color accentLight = Color(0xFFFFE57F);

  // Dark Theme
  static const Color darkBackground = Color(0xFF0A0A0F);
  static const Color darkSurface = Color(0xFF13131A);
  static const Color darkCard = Color(0xFF1C1C28);
  static const Color darkCardElevated = Color(0xFF252535);
  static const Color darkDivider = Color(0xFF2A2A3A);

  // Light Theme
  static const Color lightBackground = Color(0xFFF5F5FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFEEEEFF);
  static const Color lightCardElevated = Color(0xFFE8E8FF);
  static const Color lightDivider = Color(0xFFDDDDEE);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color textMuted = Color(0xFF6B6B8A);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textDarkSecondary = Color(0xFF4A4A6A);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF2196F3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFF4A00E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1C1C28), Color(0xFF0A0A0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF252535), Color(0xFF1C1C28)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient playerGradient = LinearGradient(
    colors: [Color(0xFF4A00E0), Color(0xFF0A0A0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient featuredGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFFB47CFF), Color(0xFF4A00E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism
  static Color glassWhite = Colors.white.withOpacity(0.08);
  static Color glassBorder = Colors.white.withOpacity(0.15);
}
