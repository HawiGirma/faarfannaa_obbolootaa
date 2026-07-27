import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/note_image_model.dart';

class NoteImageService {
  final _supabase = Supabase.instance.client;
  final String _tableName = 'note_images';
  final String _bucketName = 'note-images';
  final _uuid = const Uuid();

  String? get _userId => _supabase.auth.currentUser?.id;
  bool get _isAuthenticated => _userId != null;

  /// Upload an image file to storage and create database record
  Future<NoteImageModel> uploadImage({
    required String noteId,
    required File imageFile,
    String? caption,
    int? position,
  }) async {
    if (!_isAuthenticated) throw Exception('User not authenticated');

    try {
      // Generate unique filename
      final extension = imageFile.path.split('.').last;
      final filename = '${_uuid.v4()}.$extension';
      final path = '$_userId/$noteId/$filename';

      // Upload to storage
      await _supabase.storage.from(_bucketName).upload(
            path,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get public URL
      final imageUrl = _supabase.storage.from(_bucketName).getPublicUrl(path);

      // Create database record
      final imageData = {
        'note_id': noteId,
        'user_id': _userId!,
        'image_url': imageUrl,
        'caption': caption,
        'position': position ?? 0,
      };

      final response =
          await _supabase.from(_tableName).insert(imageData).select().single();

      return NoteImageModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Fetch all images for a note
  Future<List<NoteImageModel>> fetchImagesForNote(String noteId) async {
    if (!_isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('note_id', noteId)
          .eq('user_id', _userId!)
          .order('position', ascending: true);

      return (response as List)
          .map((json) => NoteImageModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch images: $e');
    }
  }

  /// Update image caption
  Future<NoteImageModel> updateImageCaption({
    required String imageId,
    required String caption,
  }) async {
    if (!_isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from(_tableName)
          .update({'caption': caption})
          .eq('id', imageId)
          .eq('user_id', _userId!)
          .select()
          .single();

      return NoteImageModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update image caption: $e');
    }
  }

  /// Delete image from storage and database
  Future<void> deleteImage(String imageId, String imageUrl) async {
    if (!_isAuthenticated) throw Exception('User not authenticated');

    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final path = uri.pathSegments.last;

      // Delete from storage
      await _supabase.storage.from(_bucketName).remove([path]);

      // Delete from database
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', imageId)
          .eq('user_id', _userId!);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Reorder images
  Future<void> reorderImages(List<String> imageIds) async {
    if (!_isAuthenticated) throw Exception('User not authenticated');

    try {
      for (var i = 0; i < imageIds.length; i++) {
        await _supabase
            .from(_tableName)
            .update({'position': i})
            .eq('id', imageIds[i])
            .eq('user_id', _userId!);
      }
    } catch (e) {
      throw Exception('Failed to reorder images: $e');
    }
  }
}
