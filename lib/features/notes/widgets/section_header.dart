import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Section header widget for organizing notes
class SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final bool isDark;

  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 12),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isDark
                  ? NotesAppColors.textTertiaryDark
                  : NotesAppColors.textTertiaryLight,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? NotesAppColors.surfaceDark
                    : NotesAppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? NotesAppColors.textSecondaryDark
                      : NotesAppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
