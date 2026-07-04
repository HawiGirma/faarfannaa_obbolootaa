import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';
import '../../providers/auth_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    Future.microtask(() {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.user != null) {
          print('Loading notes for user: ${authProvider.user!.uid}');
          context.read<NoteProvider>().loadNotes();
        } else {
          print('No user logged in');
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
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        appBar: AppBar(
          title: const Text('Notes'),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: isDark ? Colors.grey[600] : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Please sign in to use notes',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  DefaultTabController.of(context).animateTo(3);
                },
                child: const Text('Go to Profile'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Notes'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show menu
            },
          ),
        ],
      ),
      body: Consumer<NoteProvider>(
        builder: (context, noteProvider, child) {
          if (noteProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (noteProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Error: ${noteProvider.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.redAccent : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => noteProvider.loadNotes(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notes = noteProvider.notes;

          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    size: 80,
                    color: isDark ? Colors.grey[700] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notes yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first note',
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => noteProvider.loadNotes(),
            child: MasonryGridView(notes: notes, isDark: isDark),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(context),
        child: const Icon(Icons.add),
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
      context.read<NoteProvider>().loadNotes();
    }
  }
}

// Masonry Grid View for notes
class MasonryGridView extends StatelessWidget {
  final List<NoteModel> notes;
  final bool isDark;

  const MasonryGridView({
    super.key,
    required this.notes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final regularNotes = notes.where((n) => !n.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        if (pinnedNotes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'PINNED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          StaggeredGrid(notes: pinnedNotes, isDark: isDark),
          const SizedBox(height: 16),
        ],
        if (regularNotes.isNotEmpty) ...[
          if (pinnedNotes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'OTHERS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          StaggeredGrid(notes: regularNotes, isDark: isDark),
        ],
      ],
    );
  }
}

// Staggered grid
class StaggeredGrid extends StatelessWidget {
  final List<NoteModel> notes;
  final bool isDark;

  const StaggeredGrid({
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
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) => NoteCard(
        note: notes[index],
        isDark: isDark,
      ),
    );
  }
}

// Individual note card
class NoteCard extends StatelessWidget {
  final NoteModel note;
  final bool isDark;

  const NoteCard({
    super.key,
    required this.note,
    required this.isDark,
  });

  // Adjust card color for dark mode
  Color _adjustColorForTheme(Color color) {
    if (!isDark) return color;

    // For dark mode, darken bright colors
    final hsl = HSLColor.fromColor(color);
    if (hsl.lightness > 0.6) {
      return hsl.withLightness(0.3).toColor();
    }
    return color;
  }

  // Get text color based on background
  Color _getTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _adjustColorForTheme(note.color);
    final textColor = _getTextColor(cardColor);

    return GestureDetector(
      onTap: () => _navigateToEditor(context, note),
      onLongPress: () => _showNoteOptions(context, note),
      child: Card(
        color: cardColor,
        elevation: isDark ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDark
              ? BorderSide(color: Colors.white.withOpacity(0.1), width: 1)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.title.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isPinned)
                      Icon(
                        Icons.push_pin,
                        size: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Expanded(
                child: Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.87),
                  ),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEditor(BuildContext context, NoteModel note) async {
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

  void _showNoteOptions(BuildContext context, NoteModel note) {
    final provider = context.read<NoteProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: isDark ? Colors.white : Colors.black87,
              ),
              title: Text(
                note.isPinned ? 'Unpin' : 'Pin',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                provider.togglePin(note);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.archive_outlined,
                color: isDark ? Colors.white : Colors.black87,
              ),
              title: Text(
                'Archive',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                provider.archiveNote(note.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, note, provider);
              },
            ),
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
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Delete Note',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this note?',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteNote(note.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
