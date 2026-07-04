import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/note_service.dart';

class NoteProvider with ChangeNotifier {
  final NoteService _noteService = NoteService();

  List<NoteModel> _notes = [];
  List<NoteModel> _archivedNotes = [];
  bool _isLoading = false;
  String? _error;

  List<NoteModel> get notes => _notes;
  List<NoteModel> get archivedNotes => _archivedNotes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Get pinned notes ───────────────────────────────────────────────────
  List<NoteModel> get pinnedNotes =>
      _notes.where((note) => note.isPinned).toList();

  // ── Get regular notes (not pinned) ─────────────────────────────────────
  List<NoteModel> get regularNotes =>
      _notes.where((note) => !note.isPinned).toList();

  // ── Load all notes ─────────────────────────────────────────────────────
  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _noteService.fetchNotes();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Load archived notes ────────────────────────────────────────────────
  Future<void> loadArchivedNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _archivedNotes = await _noteService.fetchArchivedNotes();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Create a new note ──────────────────────────────────────────────────
  Future<NoteModel?> createNote({
    required String title,
    required String content,
    required Color color,
  }) async {
    try {
      final colorHex =
          '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
      final note = await _noteService.createNote(
        title: title,
        content: content,
        colorHex: colorHex,
      );

      _notes.insert(0, note);
      notifyListeners();
      return note;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── Update an existing note ────────────────────────────────────────────
  Future<bool> updateNote({
    required String noteId,
    String? title,
    String? content,
    Color? color,
    bool? isPinned,
    bool? isArchived,
  }) async {
    try {
      String? colorHex;
      if (color != null) {
        colorHex =
            '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
      }

      final updatedNote = await _noteService.updateNote(
        noteId: noteId,
        title: title,
        content: content,
        colorHex: colorHex,
        isPinned: isPinned,
        isArchived: isArchived,
      );

      final index = _notes.indexWhere((note) => note.id == noteId);
      if (index != -1) {
        _notes[index] = updatedNote;

        // Re-sort if pin status changed
        if (isPinned != null) {
          _notes.sort((a, b) {
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            return b.updatedAt.compareTo(a.updatedAt);
          });
        }

        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Delete a note ──────────────────────────────────────────────────────
  Future<bool> deleteNote(String noteId) async {
    try {
      await _noteService.deleteNote(noteId);
      _notes.removeWhere((note) => note.id == noteId);
      _archivedNotes.removeWhere((note) => note.id == noteId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Toggle pin status ──────────────────────────────────────────────────
  Future<bool> togglePin(NoteModel note) async {
    return updateNote(
      noteId: note.id,
      isPinned: !note.isPinned,
    );
  }

  // ── Archive a note ─────────────────────────────────────────────────────
  Future<bool> archiveNote(String noteId) async {
    try {
      await _noteService.archiveNote(noteId);
      final note = _notes.firstWhere((n) => n.id == noteId);
      _notes.removeWhere((n) => n.id == noteId);
      _archivedNotes.insert(0, note.copyWith(isArchived: true));
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Unarchive a note ───────────────────────────────────────────────────
  Future<bool> unarchiveNote(String noteId) async {
    try {
      await _noteService.unarchiveNote(noteId);
      final note = _archivedNotes.firstWhere((n) => n.id == noteId);
      _archivedNotes.removeWhere((n) => n.id == noteId);
      _notes.insert(0, note.copyWith(isArchived: false));
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Search notes ───────────────────────────────────────────────────────
  Future<List<NoteModel>> searchNotes(String query) async {
    if (query.isEmpty) return _notes;

    try {
      return await _noteService.searchNotes(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // ── Clear error ────────────────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
