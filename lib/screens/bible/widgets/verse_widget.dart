import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/bible_models.dart';

class VerseWidget extends StatelessWidget {
  final BibleVerse verse;
  final double fontSize;
  final String fontFamily;
  final String? customFontPath;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const VerseWidget({
    super.key,
    required this.verse,
    required this.fontSize,
    required this.fontFamily,
    this.customFontPath,
    required this.onTap,
    required this.onLongPress,
  });

  Color? _getHighlightColor() {
    if (verse.highlightColor == null) return null;

    switch (verse.highlightColor) {
      case 'yellow':
        return Colors.yellow.shade200;
      case 'green':
        return Colors.green.shade200;
      case 'blue':
        return Colors.blue.shade200;
      case 'pink':
        return Colors.pink.shade200;
      case 'purple':
        return Colors.purple.shade200;
      default:
        return null;
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.textPrimary : AppColors.textDark;

    // Get font family
    String effectiveFontFamily;
    if (fontFamily == 'Default') {
      effectiveFontFamily = 'Poppins';
    } else if (fontFamily == 'Serif') {
      effectiveFontFamily = 'Georgia';
    } else if (fontFamily == 'Sans Serif') {
      effectiveFontFamily = 'Arial';
    } else {
      effectiveFontFamily = fontFamily;
    }

    return TextStyle(
      fontSize: fontSize,
      fontFamily: effectiveFontFamily,
      color: baseColor,
      height: 1.8,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlightColor = _getHighlightColor();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: verse.isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : highlightColor?.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: verse.isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verse number
            Container(
              width: 32,
              margin: const EdgeInsets.only(right: 12, top: 2),
              child: Text(
                '${verse.number}',
                style: TextStyle(
                  fontSize: fontSize * 0.8,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textDarkSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),

            // Verse text
            Expanded(
              child: Text(
                verse.text,
                style: _getTextStyle(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
