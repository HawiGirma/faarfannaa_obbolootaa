import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Empty state widget for when no notes exist
class EmptyNotesState extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;

  const EmptyNotesState({
    super.key,
    required this.isDark,
    this.title = 'No notes yet',
    this.subtitle = 'Tap + to create your first note',
    this.icon = Icons.note_add_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark
                    ? NotesAppColors.surfaceDark
                    : NotesAppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: isDark
                    ? NotesAppColors.textTertiaryDark
                    : NotesAppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? NotesAppColors.textPrimaryDark
                    : NotesAppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? NotesAppColors.textSecondaryDark
                    : NotesAppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
