import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';
import '../../providers/auth_provider.dart';
import '../../features/notes/core/theme/app_colors.dart';
import '../../features/notes/widgets/modern_note_card.dart';
import '../../features/notes/widgets/category_chip.dart';
import '../../features/notes/widgets/section_header.dart';
import '../../features/notes/widgets/empty_notes_state.dart';
import '../auth/login_screen.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedCategory = 'All Notes';
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadNotes() {
    Future.microtask(() {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.user != null) {
          context.read<NoteProvider>().loadNotes();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if user is logged in
    if (authProvider.user == null) {
      return _buildLoginPrompt(isDark);
    }

    return Scaffold(
      backgroundColor: isDark
          ? NotesAppColors.backgroundDark
          : NotesAppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            _buildHeader(context, isDark),

            // Category Filter Chips
            _buildCategoryFilter(isDark),

            // Notes List
            Expanded(
              child: Consumer<NoteProvider>(
                builder: (context, noteProvider, child) {
                  if (noteProvider.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: isDark
                            ? NotesAppColors.primaryLight
                            : NotesAppColors.primary,
                      ),
                    );
                  }

                  if (noteProvider.error != null) {
                    return _buildErrorState(noteProvider, isDark);
                  }

                  final notes = noteProvider.notes;

                  if (notes.isEmpty) {
                    return EmptyNotesState(isDark: isDark);
                  }

                  return RefreshIndicator(
                    onRefresh: () => noteProvider.loadNotes(),
                    color: isDark
                        ? NotesAppColors.primaryLight
                        : NotesAppColors.primary,
                    child: ModernNotesGrid(notes: notes, isDark: isDark),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context, isDark),
    );
  }

  Widget _buildLoginPrompt(bool isDark) {
    return Scaffold(
      backgroundColor: isDark
          ? NotesAppColors.backgroundDark
          : NotesAppColors.backgroundLight,
      body: SafeArea(
        child: Center(
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
                    Icons.lock_outline_rounded,
                    size: 64,
                    color: isDark
                        ? NotesAppColors.textTertiaryDark
                        : NotesAppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sign in to use notes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? NotesAppColors.textPrimaryDark
                        : NotesAppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create an account to save and sync\nyour notes across devices',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? NotesAppColors.textSecondaryDark
                        : NotesAppColors.textSecondaryLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? NotesAppColors.primaryLight
                        : NotesAppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: (isDark
                            ? NotesAppColors.primaryLight
                            : NotesAppColors.primary)
                        .withValues(alpha: 0.4),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: isDark
            ? NotesAppColors.surfaceDark.withValues(alpha: 0.5)
            : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? NotesAppColors.dividerDark
                : NotesAppColors.dividerLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? NotesAppColors.textPrimaryDark
                        : NotesAppColors.textPrimaryLight,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<NoteProvider>(
                  builder: (context, noteProvider, child) {
                    final count = noteProvider.notes.length;
                    return Text(
                      '$count ${count == 1 ? 'note' : 'notes'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? NotesAppColors.textSecondaryDark
                            : NotesAppColors.textSecondaryLight,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: isDark
                  ? NotesAppColors.textPrimaryDark
                  : NotesAppColors.textPrimaryLight,
            ),
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
            },
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? NotesAppColors.cardDark
                  : NotesAppColors.surfaceLight,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark
                  ? NotesAppColors.textPrimaryDark
                  : NotesAppColors.textPrimaryLight,
            ),
            onPressed: () {
              // Show menu
            },
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? NotesAppColors.cardDark
                  : NotesAppColors.surfaceLight,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    final categories = [
      {'label': 'All Notes', 'icon': Icons.grid_view_rounded},
      {'label': 'Favorites', 'icon': Icons.star_rounded},
      {'label': 'Work', 'icon': Icons.work_rounded},
      {'label': 'Personal', 'icon': Icons.person_rounded},
      {'label': 'Ideas', 'icon': Icons.lightbulb_rounded},
      {'label': 'Archived', 'icon': Icons.archive_rounded},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryChip(
            label: category['label'] as String,
            icon: category['icon'] as IconData,
            isSelected: _selectedCategory == category['label'],
            onTap: () {
              setState(() {
                _selectedCategory = category['label'] as String;
              });
            },
            isDark: isDark,
          );
        },
      ),
    );
  }

  Widget _buildErrorState(NoteProvider noteProvider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: NotesAppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? NotesAppColors.textPrimaryDark
                    : NotesAppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              noteProvider.error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? NotesAppColors.textSecondaryDark
                    : NotesAppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => noteProvider.loadNotes(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? NotesAppColors.primaryLight
                    : NotesAppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context, bool isDark) {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToEditor(context),
      backgroundColor:
          isDark ? NotesAppColors.primaryLight : NotesAppColors.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'New Note',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  void _navigateToEditor(BuildContext context, {NoteModel? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: note),
      ),
    );

    if (result == true && mounted) {
      if (mounted) {
        context.read<NoteProvider>().loadNotes();
      }
    }
  }
}

// Modern Masonry Grid View for notes
class ModernNotesGrid extends StatelessWidget {
  final List<NoteModel> notes;
  final bool isDark;

  const ModernNotesGrid({
    super.key,
    required this.notes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final regularNotes = notes.where((n) => !n.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (pinnedNotes.isNotEmpty) ...[
          SectionHeader(
            title: 'Pinned',
            count: pinnedNotes.length,
            isDark: isDark,
          ),
          StaggeredNotesGrid(notes: pinnedNotes, isDark: isDark),
          const SizedBox(height: 8),
        ],
        if (regularNotes.isNotEmpty) ...[
          if (pinnedNotes.isNotEmpty)
            SectionHeader(
              title: 'All Notes',
              count: regularNotes.length,
              isDark: isDark,
            ),
          StaggeredNotesGrid(notes: regularNotes, isDark: isDark),
        ],
        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }
}

// Staggered grid for dynamic note heights
class StaggeredNotesGrid extends StatelessWidget {
  final List<NoteModel> notes;
  final bool isDark;

  const StaggeredNotesGrid({
    super.key,
    required this.notes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) => ModernNoteCard(
        note: notes[index],
        isDark: isDark,
      ),
    );
  }
}
