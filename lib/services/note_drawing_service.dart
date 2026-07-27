import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/note_drawing_model.dart';

class NoteDrawingService {
  final _supabase = Supabase.instance.client;
  final String _tableName = 'note_drawings';
  final _uuid = const Uuid();

  String? get _userId => _supabase.auth.currentUser?.id;
  bool get _isAuthenticated => _userId != null;

  /// Save drawing data to database
  Future<NoteDrawingModel> saveDrawing({
    required String noteId,
    required DrawingData drawingData,
    int? position,
  }) async {
    if (!_isAuthenticated) throw Exception('User not authenticated');

    try {
      final drawingDataJson = {
        'note_id': noteId,
        'user_id': _userId!,
        'drawing_data': drawingData.toJson(),
        'position': position ?? 0,
      };

      final response = await _supabase
          .from(_tableName)
          .insert(drawingDataJson)
          .select()
          .single();

      return NoteDrawingModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save drawing: $e');
    }
  }

  /// Update existing drawing
  Future<NoteDrawingModel> updateDrawing({
    required String drawingId,
    required DrawingData drawingData,
  }) async {
    if (!_isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from(_tableName)
          .update({'drawing_data': drawingData.toJson()})
          .eq('id', drawingId)
          .eq('user_id', _userId!)
          .select()
          .single();

      return NoteDrawingModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update drawing: $e');
    }
  }

  /// Fetch drawing for a note
  Future<NoteDrawingModel?> fetchDrawingForNote(String noteId) async {
    if (!_isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('note_id', noteId)
          .eq('user_id', _userId!)
          .order('position', ascending: false)
          .limit(1);

      if ((response as List).isEmpty) return null;

      return NoteDrawingModel.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to fetch drawing: $e');
    }
  }

  /// Delete drawing
  Future<void> deleteDrawing(String drawingId) async {
    if (!_isAuthenticated) throw Exception('User not authenticated');

    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', drawingId)
          .eq('user_id', _userId!);
    } catch (e) {
      throw Exception('Failed to delete drawing: $e');
    }
  }

  /// Check if note has drawings
  Future<bool> noteHasDrawings(String noteId) async {
    if (!_isAuthenticated) return false;

    try {
      final response = await _supabase
          .from(_tableName)
          .select('id')
          .eq('note_id', noteId)
          .eq('user_id', _userId!)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
