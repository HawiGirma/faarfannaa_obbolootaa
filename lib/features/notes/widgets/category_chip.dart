import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Modern category chip for horizontal scrolling
class CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const CategoryChip({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? (isDark ? NotesAppColors.primaryLight : NotesAppColors.primary)
        : (isDark ? NotesAppColors.surfaceDark : NotesAppColors.surfaceLight);

    final textColor = isSelected
        ? Colors.white
        : (isDark
            ? NotesAppColors.textPrimaryDark
            : NotesAppColors.textSecondaryLight);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: !isSelected
              ? Border.all(
                  color: isDark
                      ? NotesAppColors.dividerDark
                      : NotesAppColors.dividerLight,
                  width: 1,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark
                            ? NotesAppColors.primaryLight
                            : NotesAppColors.primary)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: textColor,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
