import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';
import 'widgets/drawing_canvas.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isModified = false;
  bool _isSaving = false;
  final FocusNode _contentFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();

  // Formatting state
  Color _textColor = Colors.black;
  Color _backgroundColor = Colors.white;
  double _fontSize = 16.0;
  String _fontFamily = 'Inter';
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  // Drawing state
  bool _isDrawingMode = false;
  final GlobalKey<DrawingCanvasState> _drawingKey = GlobalKey();
  DrawingTool _currentDrawingTool = DrawingTool.pen;
  Color _drawingColor = Colors.black;
  double _drawingStrokeWidth = 3.0;

  final List<String> _availableFonts = [
    'Inter',
    'Roboto',
    'Montserrat',
    'Lato',
    'Open Sans',
    'Playfair Display',
    'Merriweather',
    'Courier New',
    'Kalam',
    'Dancing Script',
  ];

  final List<Color> _textColors = [
    Colors.black,
    const Color(0xFF1A1A2E),
    const Color(0xFF6B4CE6),
    const Color(0xFFFF6B9D),
    const Color(0xFFEF4444),
    const Color(0xFFF59E0B),
    const Color(0xFF10B981),
    const Color(0xFF3B82F6),
  ];

  final List<Color> _backgroundColors = [
    Colors.white,
    const Color(0xFFFFE5E5), // Soft Pink
    const Color(0xFFFFEBCC), // Soft Orange
    const Color(0xFFFFF9CC), // Soft Yellow
    const Color(0xFFD4F1D4), // Soft Green
    const Color(0xFFD4E8FF), // Soft Blue
    const Color(0xFFE8D4FF), // Soft Purple
    const Color(0xFFFFD4E8), // Soft Rose
    const Color(0xFFD4FFF4), // Soft Mint
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');

    _titleController.addListener(() => setState(() => _isModified = true));
    _contentController.addListener(() => setState(() => _isModified = true));

    // Set initial text and background colors based on theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      setState(() {
        _textColor = isDark ? Colors.white : Colors.black;
        _backgroundColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
        _drawingColor = isDark ? Colors.white : Colors.black;
      });

      if (widget.note == null) {
        _titleFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    _titleFocusNode.dispose();
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
      final result = await provider.createNote(
        title: _titleController.text,
        content: _contentController.text,
        color: Colors.white,
      );
      success = result != null;
    } else {
      success = await provider.updateNote(
        noteId: widget.note!.id,
        title: _titleController.text,
        content: _contentController.text,
        color: Colors.white,
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

  String _formatLastEdit() {
    if (widget.note == null) return 'Last edit: Just now';
    final updated = widget.note!.updatedAt;
    final now = DateTime.now();
    final formatter = DateFormat('hh:mma');

    if (now.difference(updated).inHours < 24) {
      return 'Last edit: ${formatter.format(updated).toLowerCase()}';
    } else {
      return 'Last edit: ${DateFormat('MMM dd, yyyy').format(updated)}';
    }
  }

  void _showBackgroundColorPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Background Color',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _backgroundColors.map((color) {
                final isSelected = _backgroundColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _backgroundColor = color;
                      _isModified = true;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6B4CE6)
                            : (isDark ? Colors.white24 : Colors.black12),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF6B4CE6).withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Color(0xFF6B4CE6),
                            size: 24,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: _backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () async {
              if (_isModified && !_isSaving) {
                await _saveNote();
              } else {
                Navigator.pop(context, false);
              }
            },
          ),
          title: Text(
            'Note',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.palette_outlined,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onPressed: _showBackgroundColorPicker,
            ),
            IconButton(
              icon: Icon(
                _isDrawingMode ? Icons.edit : Icons.draw_outlined,
                color: _isDrawingMode
                    ? const Color(0xFF6B4CE6)
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
              onPressed: () {
                setState(() {
                  _isDrawingMode = !_isDrawingMode;
                  if (!_isDrawingMode) {
                    // Hide keyboard when entering drawing mode
                    FocusScope.of(context).unfocus();
                  }
                });
              },
            ),
            PopupMenuButton(
              icon: Icon(
                Icons.more_vert,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        Icons.bookmark_outline,
                        size: 20,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Bookmark',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {},
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Share',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {},
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Last edit timestamp
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatLastEdit(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ),

            // Editor area with drawing overlay
            Expanded(
              child: Stack(
                children: [
                  // Text editor
                  if (!_isDrawingMode)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title input
                          TextField(
                            controller: _titleController,
                            focusNode: _titleFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Enter note title…',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white24 : Colors.black26,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: TextStyle(
                              fontSize: 24,
                              fontFamily: _fontFamily,
                              color: _textColor,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: null,
                          ),
                          const SizedBox(height: 16),
                          // Content input
                          TextField(
                            controller: _contentController,
                            focusNode: _contentFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Start typing…',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white24 : Colors.black26,
                                fontSize: _fontSize,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: TextStyle(
                              fontSize: _fontSize,
                              fontFamily: _fontFamily,
                              color: _textColor,
                              fontWeight:
                                  _isBold ? FontWeight.bold : FontWeight.normal,
                              fontStyle: _isItalic
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              decoration: _isUnderline
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                              height: 1.6,
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                          ),
                        ],
                      ),
                    ),

                  // Drawing canvas
                  if (_isDrawingMode)
                    DrawingCanvas(
                      key: _drawingKey,
                      tool: _currentDrawingTool,
                      color: _drawingColor,
                      strokeWidth: _drawingStrokeWidth,
                      backgroundColor: _backgroundColor,
                    ),
                ],
              ),
            ),

            // Bottom toolbar
            _isDrawingMode ? _buildDrawingToolbar() : _buildFormattingToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242438) : const Color(0xFFF5F5FF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color and size row
          Row(
            children: [
              // Color label
              Text(
                'Color',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              // Color circles
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _textColors.length,
                    itemBuilder: (context, index) {
                      final color = _textColors[index];
                      final isSelected = _textColor == color;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _textColor = color),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6B4CE6)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Size controls
              Text(
                'Size',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: () {
                  if (_fontSize > 10) {
                    setState(() => _fontSize -= 2);
                  }
                },
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _fontSize.toInt().toString(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: () {
                  if (_fontSize < 36) {
                    setState(() => _fontSize += 2);
                  }
                },
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Font selector row
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableFonts.length,
              itemBuilder: (context, index) {
                final font = _availableFonts[index];
                final isSelected = _fontFamily == font;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _fontFamily = font),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6B4CE6)
                            : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6B4CE6)
                              : (isDark ? Colors.white24 : Colors.black12),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          font,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: font,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Formatting buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _formatButton(
                icon: Icons.format_bold,
                isActive: _isBold,
                onTap: () => setState(() => _isBold = !_isBold),
                isDark: isDark,
              ),
              _formatButton(
                icon: Icons.format_italic,
                isActive: _isItalic,
                onTap: () => setState(() => _isItalic = !_isItalic),
                isDark: isDark,
              ),
              _formatButton(
                icon: Icons.format_underline,
                isActive: _isUnderline,
                onTap: () => setState(() => _isUnderline = !_isUnderline),
                isDark: isDark,
              ),
              _formatButton(
                icon: Icons.format_list_bulleted,
                onTap: () {},
                isDark: isDark,
              ),
              _formatButton(
                icon: Icons.format_list_numbered,
                onTap: () {},
                isDark: isDark,
              ),
              _formatButton(
                icon: Icons.link,
                onTap: () {},
                isDark: isDark,
              ),
              _formatButton(
                icon: Icons.image_outlined,
                onTap: () {},
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingToolbar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242438) : const Color(0xFFF5F5FF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drawing tools
          Row(
            children: [
              _drawingToolButton(
                icon: Icons.edit,
                tool: DrawingTool.pen,
                label: 'Pen',
                isDark: isDark,
              ),
              _drawingToolButton(
                icon: Icons.brush,
                tool: DrawingTool.pencil,
                label: 'Pencil',
                isDark: isDark,
              ),
              _drawingToolButton(
                icon: Icons.highlight,
                tool: DrawingTool.marker,
                label: 'Marker',
                isDark: isDark,
              ),
              _drawingToolButton(
                icon: Icons.auto_fix_high,
                tool: DrawingTool.eraser,
                label: 'Eraser',
                isDark: isDark,
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.undo,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: () {
                  _drawingKey.currentState?.undo();
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.redo,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: () {
                  _drawingKey.currentState?.redo();
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: () {
                  _drawingKey.currentState?.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Drawing color picker
          Row(
            children: [
              Text(
                'Color',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _textColors.length,
                    itemBuilder: (context, index) {
                      final color = _textColors[index];
                      final isSelected = _drawingColor == color;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _drawingColor = color),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6B4CE6)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Width',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _drawingStrokeWidth,
                  min: 1.0,
                  max: 20.0,
                  divisions: 19,
                  activeColor: const Color(0xFF6B4CE6),
                  onChanged: (value) {
                    setState(() => _drawingStrokeWidth = value);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _drawingStrokeWidth.toInt().toString(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drawingToolButton({
    required IconData icon,
    required DrawingTool tool,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentDrawingTool == tool;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _currentDrawingTool = tool),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6B4CE6)
                : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6B4CE6)
                  : (isDark ? Colors.white24 : Colors.black12),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    bool isActive = false,
  }) {
    return IconButton(
      icon: Icon(icon),
      color: isActive
          ? const Color(0xFF6B4CE6)
          : (isDark ? Colors.white70 : Colors.black54),
      onPressed: onTap,
      iconSize: 24,
    );
  }
}
