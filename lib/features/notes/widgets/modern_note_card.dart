import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/note_model.dart';
import '../../../providers/note_provider.dart';
import '../../../screens/notes/note_editor_screen.dart';
import '../core/theme/app_colors.dart';

/// Modern premium note card with glassmorphism and soft shadows
class ModernNoteCard extends StatelessWidget {
  final NoteModel note;
  final bool isDark;

  const ModernNoteCard({
    super.key,
    required this.note,
    required this.isDark,
  });

  Color _getTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? NotesAppColors.textPrimaryLight : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _getTextColor(note.color);
    final secondaryTextColor = textColor.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: () => _navigateToEditor(context),
      onLongPress: () => _showNoteOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: note.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : note.color.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with title and pin icon
                    if (note.title.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              note.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                height: 1.3,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (note.isPinned) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: textColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.push_pin_rounded,
                                size: 16,
                                color: textColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Content preview
                    if (note.content.isNotEmpty)
                      Expanded(
                        child: Text(
                          note.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                            height: 1.5,
                          ),
                          maxLines: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Footer with timestamp
                    const SizedBox(height: 8),
                    Text(
                      _formatDateTime(note.updatedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Subtle gradient overlay for better text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _navigateToEditor(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: note),
      ),
    );

    if (result == true && context.mounted) {
      context.read<NoteProvider>().loadNotes();
    }
  }

  void _showNoteOptions(BuildContext context) {
    final provider = context.read<NoteProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? NotesAppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark
                    ? NotesAppColors.dividerDark
                    : NotesAppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            _OptionTile(
              icon: note.isPinned
                  ? Icons.push_pin_outlined
                  : Icons.push_pin_rounded,
              title: note.isPinned ? 'Unpin' : 'Pin to top',
              onTap: () {
                Navigator.pop(context);
                provider.togglePin(note);
              },
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _OptionTile(
              icon: Icons.archive_outlined,
              title: 'Archive',
              onTap: () {
                Navigator.pop(context);
                provider.archiveNote(note.id);
              },
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _OptionTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete',
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, note, provider);
              },
              isDark: isDark,
              isDestructive: true,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, NoteModel note, NoteProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? NotesAppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Note?',
          style: TextStyle(
            color: isDark
                ? NotesAppColors.textPrimaryDark
                : NotesAppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This note will be permanently deleted.',
          style: TextStyle(
            color: isDark
                ? NotesAppColors.textSecondaryDark
                : NotesAppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? NotesAppColors.textSecondaryDark
                    : NotesAppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteNote(note.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: NotesAppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? NotesAppColors.error
        : (isDark
            ? NotesAppColors.textPrimaryDark
            : NotesAppColors.textPrimaryLight);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark
              ? NotesAppColors.cardDark.withValues(alpha: 0.5)
              : NotesAppColors.surfaceLight,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
