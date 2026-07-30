import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/bible_provider.dart';
import '../../models/bible_models.dart';
import 'widgets/verse_widget.dart';
import 'widgets/chapter_selector.dart';
import 'widgets/book_selector.dart';
import 'widgets/reading_settings_panel.dart';
import 'widgets/search_dialog.dart';
import 'widgets/bookmarks_dialog.dart';
import 'widgets/notes_dialog.dart';
import 'widgets/selection_action_bar.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimationController;
  bool _showFab = true;
  bool _userScrolled = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimationController.forward();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<BibleProvider>();

    // Stop auto-scroll if user manually scrolls
    if (provider.isAutoScrolling && !_userScrolled) {
      _userScrolled = true;
      provider.stopAutoScroll();
    }

    // Hide/show FAB based on scroll direction
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.forward) {
      if (!_showFab) {
        setState(() => _showFab = true);
        _fabAnimationController.forward();
      }
    } else if (direction == ScrollDirection.reverse) {
      if (_showFab) {
        setState(() => _showFab = false);
        _fabAnimationController.reverse();
      }
    }

    // Save scroll position
    if (_scrollController.hasClients) {
      provider.updateScrollOffset(_scrollController.offset);
    }
  }

  void _startAutoScroll() {
    final provider = context.read<BibleProvider>();
    provider.startAutoScroll();
    _userScrolled = false;

    // Calculate scroll duration based on speed preference
    final speed = provider.preferences.autoScrollSpeed;
    final scrollDistance =
        _scrollController.position.maxScrollExtent - _scrollController.offset;

    // Speed mapping: 1.0 (slow) = 30 seconds per screen height
    // Higher speeds scroll faster
    final Duration duration = Duration(
      milliseconds: (scrollDistance * 30000 / speed).round(),
    );

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: duration,
      curve: Curves.linear,
    );
  }

  void _stopAutoScroll() {
    final provider = context.read<BibleProvider>();
    provider.stopAutoScroll();
    _scrollController.animateTo(
      _scrollController.offset,
      duration: const Duration(milliseconds: 1),
      curve: Curves.linear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Consumer<BibleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load Bible',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.currentChapter == null) {
            return const Center(child: Text('No chapter loaded'));
          }

          return SafeArea(
            child: Stack(
              children: [
                // Main content
                Column(
                  children: [
                    // Header
                    _buildHeader(context, provider, isDark),

                    // Chapter content
                    Expanded(
                      child: provider.isLoadingChapter
                          ? const Center(child: CircularProgressIndicator())
                          : _buildChapterContent(context, provider, isDark),
                    ),
                  ],
                ),

                // Selection action bar
                if (provider.selectedVerseCount > 0)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: SelectionActionBar(
                      selectedCount: provider.selectedVerseCount,
                      onCopy: () => _copySelectedVerses(provider),
                      onShare: () => _shareSelectedVerses(provider),
                      onHighlight: () =>
                          _showHighlightOptions(context, provider),
                      onRemoveHighlight: () => _removeHighlight(provider),
                      onSelectAll: () => provider.selectAllVerses(),
                      onClear: () => provider.clearSelection(),
                    ),
                  ),

                // Auto-scroll controls
                if (provider.isAutoScrolling)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: _buildAutoScrollControls(provider),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<BibleProvider>(
        builder: (context, provider, _) {
          if (provider.selectedVerseCount > 0 || provider.isAutoScrolling) {
            return const SizedBox.shrink();
          }

          return ScaleTransition(
            scale: _fabAnimationController,
            child: FloatingActionButton(
              heroTag: 'bible_settings_fab',
              onPressed: () => _showReadingSettings(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.settings, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    BibleProvider provider,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Title and actions
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showBookSelector(context, provider),
                  child: Row(
                    children: [
                      Text(
                        provider.currentBook?.name ?? '',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_drop_down,
                        color:
                            isDark ? AppColors.textPrimary : AppColors.textDark,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearch(context),
                color: isDark ? AppColors.textPrimary : AppColors.textDark,
              ),
              IconButton(
                icon: const Icon(Icons.bookmarks_outlined),
                onPressed: () => _showBookmarks(context),
                color: isDark ? AppColors.textPrimary : AppColors.textDark,
              ),
              IconButton(
                icon: const Icon(Icons.note_outlined),
                onPressed: () => _showNotes(context),
                color: isDark ? AppColors.textPrimary : AppColors.textDark,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Chapter navigation
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: provider.isLoadingChapter
                    ? null
                    : () => provider.goToPreviousChapter(),
                color: isDark ? AppColors.textPrimary : AppColors.textDark,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showChapterSelector(context, provider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Chapter ${provider.currentChapter?.number ?? 1}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: provider.isLoadingChapter
                    ? null
                    : () => provider.goToNextChapter(),
                color: isDark ? AppColors.textPrimary : AppColors.textDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChapterContent(
    BuildContext context,
    BibleProvider provider,
    bool isDark,
  ) {
    final chapter = provider.currentChapter!;
    final preferences = provider.preferences;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: chapter.verses.length,
      itemBuilder: (context, index) {
        final verse = chapter.verses[index];
        return VerseWidget(
          verse: verse,
          fontSize: preferences.fontSize,
          fontFamily: preferences.fontFamily,
          customFontPath: preferences.customFontPath,
          onTap: () => provider.toggleVerseSelection(verse.number),
          onLongPress: () => _showVerseOptions(context, provider, verse),
        );
      },
    );
  }

  Widget _buildAutoScrollControls(BibleProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.isAutoScrollPaused)
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              onPressed: () {
                provider.resumeAutoScroll();
                _startAutoScroll();
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.pause, color: Colors.white),
              onPressed: () => provider.pauseAutoScroll(),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.white),
            onPressed: () => _stopAutoScroll(),
          ),
        ],
      ),
    );
  }

  // ── Action Methods ──────────────────────────────────────────────────────

  void _showBookSelector(BuildContext context, BibleProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const BookSelector(),
      ),
    );
  }

  void _showChapterSelector(BuildContext context, BibleProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const ChapterSelector(),
      ),
    );
  }

  void _showReadingSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReadingSettingsPanel(),
    );
  }

  void _showSearch(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const SearchDialog(),
    );
  }

  void _showBookmarks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BookmarksDialog(),
    );
  }

  void _showNotes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotesDialog(),
    );
  }

  Future<void> _copySelectedVerses(BibleProvider provider) async {
    final text = provider.getSelectedVersesText();
    await Clipboard.setData(ClipboardData(text: text));
    provider.clearSelection();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verses copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareSelectedVerses(BibleProvider provider) async {
    final text = provider.getSelectedVersesText();
    await Share.share(text);
    provider.clearSelection();
  }

  void _showHighlightOptions(BuildContext context, BibleProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Highlight Color',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildColorOption(
                    context, provider, 'yellow', Colors.yellow.shade300),
                _buildColorOption(
                    context, provider, 'green', Colors.green.shade300),
                _buildColorOption(
                    context, provider, 'blue', Colors.blue.shade300),
                _buildColorOption(
                    context, provider, 'pink', Colors.pink.shade300),
                _buildColorOption(
                    context, provider, 'purple', Colors.purple.shade300),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(
    BuildContext context,
    BibleProvider provider,
    String colorName,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        provider.highlightSelectedVerses(colorName);
        Navigator.pop(context);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeHighlight(BibleProvider provider) async {
    await provider.removeHighlightFromSelectedVerses();
  }

  void _showVerseOptions(
    BuildContext context,
    BibleProvider provider,
    BibleVerse verse,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.bookmark_outline, color: AppColors.primary),
              title: const Text('Bookmark'),
              onTap: () {
                provider.toggleBookmark(verse.number);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.note_add_outlined, color: AppColors.primary),
              title: const Text('Add Note'),
              onTap: () {
                Navigator.pop(context);
                _showAddNoteDialog(context, provider, verse);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppColors.primary),
              title: const Text('Copy'),
              onTap: () {
                final text =
                    '${provider.currentBook!.name} ${provider.currentChapter!.number}:${verse.number}\n"${verse.text}"';
                Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verse copied')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNoteDialog(
    BuildContext context,
    BibleProvider provider,
    BibleVerse verse,
  ) {
    final controller = TextEditingController();

    // Load existing note if any
    provider.getVerseNote(verse.number).then((existingNote) {
      if (existingNote != null) {
        controller.text = existingNote.note;
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${provider.currentBook!.name} ${provider.currentChapter!.number}:${verse.number}',
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your note...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.addOrUpdateNote(verse.number, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
