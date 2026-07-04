import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note_model.dart';

class NoteService {
  final _supabase = Supabase.instance.client;
  final String _tableName = 'notes';

  // ── Get current user ID ────────────────────────────────────────────────
  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Check if user is authenticated ─────────────────────────────────────
  bool get _isAuthenticated => _userId != null;

  // ── Fetch all notes (excluding archived) ───────────────────────────────
  Future<List<NoteModel>> fetchNotes({bool includeArchived = false}) async {
    try {
      if (!_isAuthenticated) {
        print('NoteService: User not authenticated');
        throw Exception('User not authenticated');
      }

      print('NoteService: Fetching notes for user: $_userId');

      var query = _supabase.from(_tableName).select().eq('user_id', _userId!);

      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }

      final response = await query
          .order('is_pinned', ascending: false)
          .order('updated_at', ascending: false);

      print('NoteService: Received ${(response as List).length} notes');

      return (response as List)
          .map((json) => NoteModel.fromJson(json))
          .toList();
    } catch (e) {
      print('NoteService: Error fetching notes: $e');
      throw Exception('Failed to fetch notes: $e');
    }
  }

  // ── Fetch archived notes only ──────────────────────────────────────────
  Future<List<NoteModel>> fetchArchivedNotes() async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', _userId!)
          .eq('is_archived', true)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => NoteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch archived notes: $e');
    }
  }

  // ── Create a new note ──────────────────────────────────────────────────
  Future<NoteModel> createNote({
    required String title,
    required String content,
    required String colorHex,
  }) async {
    try {
      if (!_isAuthenticated) {
        print('NoteService: User not authenticated for create');
        throw Exception('User not authenticated');
      }

      print('NoteService: Creating note for user: $_userId');
      print(
          'Title: $title, Content length: ${content.length}, Color: $colorHex');

      final noteData = {
        'user_id': _userId!,
        'title': title.isEmpty ? 'Untitled' : title,
        'content': content,
        'color': colorHex,
        'is_pinned': false,
        'is_archived': false,
      };

      print('NoteService: Inserting data: $noteData');

      final response =
          await _supabase.from(_tableName).insert(noteData).select().single();

      print('NoteService: Note created successfully: ${response['id']}');

      return NoteModel.fromJson(response);
    } catch (e) {
      print('NoteService: Error creating note: $e');
      throw Exception('Failed to create note: $e');
    }
  }

  // ── Update an existing note ────────────────────────────────────────────
  Future<NoteModel> updateNote({
    required String noteId,
    String? title,
    String? content,
    String? colorHex,
    bool? isPinned,
    bool? isArchived,
  }) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{};
      if (title != null)
        updateData['title'] = title.isEmpty ? 'Untitled' : title;
      if (content != null) updateData['content'] = content;
      if (colorHex != null) updateData['color'] = colorHex;
      if (isPinned != null) updateData['is_pinned'] = isPinned;
      if (isArchived != null) updateData['is_archived'] = isArchived;

      final response = await _supabase
          .from(_tableName)
          .update(updateData)
          .eq('id', noteId)
          .eq('user_id', _userId!)
          .select()
          .single();

      return NoteModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  // ── Delete a note permanently ──────────────────────────────────────────
  Future<void> deleteNote(String noteId) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', noteId)
          .eq('user_id', _userId!);
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  // ── Toggle pin status ──────────────────────────────────────────────────
  Future<NoteModel> togglePin(String noteId, bool currentPinStatus) async {
    return updateNote(noteId: noteId, isPinned: !currentPinStatus);
  }

  // ── Archive a note ─────────────────────────────────────────────────────
  Future<NoteModel> archiveNote(String noteId) async {
    return updateNote(noteId: noteId, isArchived: true);
  }

  // ── Unarchive a note ───────────────────────────────────────────────────
  Future<NoteModel> unarchiveNote(String noteId) async {
    return updateNote(noteId: noteId, isArchived: false);
  }

  // ── Search notes ───────────────────────────────────────────────────────
  Future<List<NoteModel>> searchNotes(String query) async {
    try {
      if (!_isAuthenticated) throw Exception('User not authenticated');

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', _userId!)
          .eq('is_archived', false)
          .or('title.ilike.%$query%,content.ilike.%$query%')
          .order('is_pinned', ascending: false)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => NoteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search notes: $e');
    }
  }
}
