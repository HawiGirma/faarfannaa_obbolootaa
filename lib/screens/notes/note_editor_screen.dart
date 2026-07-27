import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';
import '../../features/notes/core/theme/app_colors.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late Color _selectedColor;
  bool _isModified = false;
  bool _isSaving = false;
  final FocusNode _contentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    _selectedColor = widget.note?.color ?? NoteModel.noteColors[0];

    _titleController.addListener(() => setState(() => _isModified = true));
    _contentController.addListener(() => setState(() => _isModified = true));

    // Auto-focus content field for new notes
    if (widget.note == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _contentFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => _isSaving = true);

    final provider = context.read<NoteProvider>();
    bool success;

    if (widget.note == null) {
      // Create new note
      final result = await provider.createNote(
        title: _titleController.text,
        content: _contentController.text,
        color: _selectedColor,
      );
      success = result != null;
    } else {
      // Update existing note
      success = await provider.updateNote(
        noteId: widget.note!.id,
        title: _titleController.text,
        content: _contentController.text,
        color: _selectedColor,
      );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save note')),
        );
      }
    }
  }

  void _showColorPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? NotesAppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark
                      ? NotesAppColors.dividerDark
                      : NotesAppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Choose Color',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? NotesAppColors.textPrimaryDark
                    : NotesAppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: NoteModel.noteColors.length,
              itemBuilder: (context, index) {
                final color = NoteModel.noteColors[index];
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                      _isModified = true;
                    });
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? (isDark
                                ? NotesAppColors.primaryLight
                                : NotesAppColors.primary)
                            : (isDark
                                ? NotesAppColors.dividerDark
                                : NotesAppColors.dividerLight),
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black87
                                : Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = _selectedColor.computeLuminance() > 0.5
        ? NotesAppColors.textPrimaryLight
        : Colors.white;
    final secondaryTextColor = textColor.withValues(alpha: 0.6);

    return PopScope(
      canPop: !_isModified || _isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _isModified && !_isSaving) {
          await _saveNote();
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
        }
      },
      child: Scaffold(
        backgroundColor: _selectedColor,
        body: SafeArea(
          child: Column(
            children: [
              // Modern Top Bar
              _buildTopBar(context, textColor, isDark),

              // Metadata Section
              if (widget.note != null) _buildMetadata(secondaryTextColor),

              // Editor Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Field
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: TextStyle(
                            color: secondaryTextColor,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.3,
                          letterSpacing: -0.5,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 20),

                      // Content Field
                      TextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Start typing...',
                          hintStyle: TextStyle(
                            color: secondaryTextColor,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                          height: 1.6,
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Toolbar
              _buildBottomToolbar(context, textColor, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _selectedColor,
        border: Border(
          bottom: BorderSide(
            color: textColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textColor),
            onPressed: () async {
              if (_isModified && !_isSaving) {
                await _saveNote();
              } else {
                Navigator.pop(context, false);
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: textColor.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const Spacer(),

          // Favorite Button (placeholder for future)
          IconButton(
            icon: Icon(Icons.star_outline_rounded, color: textColor),
            onPressed: () {
              // TODO: Toggle favorite
            },
            style: IconButton.styleFrom(
              backgroundColor: textColor.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 8),

          // Reminder Button (placeholder for future)
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: textColor),
            onPressed: () {
              // TODO: Set reminder
            },
            style: IconButton.styleFrom(
              backgroundColor: textColor.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 8),

          // More Menu
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: textColor),
            onPressed: () {
              _showMoreMenu(context, isDark);
            },
            style: IconButton.styleFrom(
              backgroundColor: textColor.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _MetadataChip(
            icon: Icons.edit_outlined,
            label: _formatDateTime(widget.note!.updatedAt),
            textColor: textColor,
          ),
          if (widget.note!.createdAt != widget.note!.updatedAt)
            _MetadataChip(
              icon: Icons.access_time_rounded,
              label: 'Created ${_formatDate(widget.note!.createdAt)}',
              textColor: textColor,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar(
      BuildContext context, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _selectedColor,
        border: Border(
          top: BorderSide(
            color: textColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Color Picker
          IconButton(
            icon: Icon(Icons.palette_outlined, color: textColor),
            onPressed: _showColorPicker,
            style: IconButton.styleFrom(
              backgroundColor: textColor.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(width: 8),

          // Formatting buttons (placeholders)
          IconButton(
            icon: Icon(Icons.format_bold_rounded, color: textColor),
            onPressed: () {
              // TODO: Bold formatting
            },
            style: IconButton.styleFrom(
              backgroundColor: textColor.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.format_list_bulleted_rounded, color: textColor),
            onPressed: () {
              // TODO: List formatting
            },
            style: IconButton.styleFrom(
              backgroundColor: textColor.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(10),
            ),
          ),

          const Spacer(),

          // Save Button
          _isSaving
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: _saveNote,
                  icon: Icon(Icons.check_rounded, size: 20),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? NotesAppColors.primaryLight
                        : NotesAppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context, bool isDark) {
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

            _MoreMenuItem(
              icon: Icons.share_outlined,
              title: 'Share',
              onTap: () {
                Navigator.pop(context);
                // TODO: Share functionality
              },
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _MoreMenuItem(
              icon: Icons.content_copy_rounded,
              title: 'Make a copy',
              onTap: () {
                Navigator.pop(context);
                // TODO: Copy functionality
              },
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _MoreMenuItem(
              icon: Icons.archive_outlined,
              title: 'Archive',
              onTap: () {
                Navigator.pop(context);
                // TODO: Archive functionality
              },
              isDark: isDark,
            ),
            if (widget.note != null) ...[
              const SizedBox(height: 8),
              _MoreMenuItem(
                icon: Icons.delete_outline_rounded,
                title: 'Delete',
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
                isDark: isDark,
                isDestructive: true,
              ),
            ],
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
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
              if (widget.note != null) {
                context.read<NoteProvider>().deleteNote(widget.note!.id);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Return to notes list
              }
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Edited just now';
    } else if (difference.inHours < 1) {
      return 'Edited ${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return 'Edited ${difference.inHours}h ago';
    } else {
      return 'Edited ${_formatDate(dateTime)}';
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;

  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;

  const _MoreMenuItem({
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
