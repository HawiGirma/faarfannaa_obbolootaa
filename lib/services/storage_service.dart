import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';

/// Storage service that stores files directly in Supabase database
/// Uses a separate 'file_storage' table instead of Supabase Storage
class StorageService {
  SupabaseClient get _client => Supabase.instance.client;

  // ── Audio ─────────────────────────────────────────────────────────────

  Future<String> uploadAudioWithProgress(
    String fileName, {
    File? file,
    Uint8List? bytes,
    required void Function(double) onProgress,
  }) {
    // Determine MIME type from file extension
    String mimeType = 'audio/mpeg'; // default
    if (fileName.toLowerCase().endsWith('.mp3')) {
      mimeType = 'audio/mpeg';
    } else if (fileName.toLowerCase().endsWith('.m4a')) {
      mimeType = 'audio/mp4';
    } else if (fileName.toLowerCase().endsWith('.aac')) {
      mimeType = 'audio/aac';
    } else if (fileName.toLowerCase().endsWith('.wav')) {
      mimeType = 'audio/wav';
    } else if (fileName.toLowerCase().endsWith('.ogg')) {
      mimeType = 'audio/ogg';
    }

    return _upload(
      folder: AppConstants.audioFolder,
      fileName: fileName,
      mimeType: mimeType,
      file: file,
      bytes: bytes,
      onProgress: onProgress,
    );
  }

  // ── Images ────────────────────────────────────────────────────────────

  Future<String> uploadImageWithProgress(
    String fileName, {
    File? file,
    Uint8List? bytes,
    required void Function(double) onProgress,
  }) {
    return _upload(
      folder: AppConstants.imagesFolder,
      fileName: fileName,
      mimeType: 'image/jpeg',
      file: file,
      bytes: bytes,
      onProgress: onProgress,
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────

  Future<void> deleteFile(String fileId) async {
    try {
      await _client.from('file_storage').delete().eq('id', fileId);
      debugPrint('StorageService: deleted file $fileId');
    } catch (e) {
      debugPrint('StorageService.deleteFile: $e');
    }
  }

  Future<void> deleteByUrl(String url) async {
    try {
      // Extract file ID from URL pattern: /storage/{id}
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final storageIndex = segments.indexOf('storage');
      if (storageIndex == -1 || storageIndex + 1 >= segments.length) return;

      final fileId = segments[storageIndex + 1];
      await deleteFile(fileId);
    } catch (e) {
      debugPrint('StorageService.deleteByUrl: $e');
    }
  }

  // ── Download / Get File ───────────────────────────────────────────────

  Future<Uint8List?> downloadFile(String fileId) async {
    try {
      final response = await _client
          .from('file_storage')
          .select('data')
          .eq('id', fileId)
          .single();

      final base64Data = response['data'] as String?;
      if (base64Data == null) return null;

      // Decode base64 to bytes
      return base64Decode(base64Data);
    } catch (e) {
      debugPrint('StorageService.downloadFile: $e');
      return null;
    }
  }

  // ── Core upload ───────────────────────────────────────────────────────

  Future<String> _upload({
    required String folder,
    required String fileName,
    required String mimeType,
    File? file,
    Uint8List? bytes,
    required void Function(double) onProgress,
  }) async {
    final storagePath = '$folder/$fileName';

    // Resolve bytes
    final Uint8List data;
    if (kIsWeb || bytes != null) {
      assert(bytes != null, 'bytes required on web');
      data = bytes!;
    } else {
      assert(file != null, 'file required on non-web');
      data = await file!.readAsBytes();
    }

    debugPrint('StorageService: uploading $storagePath '
        '(${data.lengthInBytes} bytes, $mimeType)');
    debugPrint('StorageService: user=${_client.auth.currentUser?.email}');

    onProgress(0.1);

    try {
      // Convert bytes to base64 for database storage (text column)
      final base64Data = base64Encode(data);

      debugPrint(
          'StorageService: base64 encoded, length=${base64Data.length} chars');

      final response = await _client
          .from('file_storage')
          .insert({
            'path': storagePath,
            'mime_type': mimeType,
            'size_bytes': data.lengthInBytes,
            'data': base64Data,
            'uploaded_by': _client.auth.currentUser?.id,
          })
          .select()
          .single();

      onProgress(0.9);

      final fileId = response['id'] as String;

      // Generate a pseudo-URL that identifies this file
      // Format: https://{project}.supabase.co/storage/{fileId}
      final projectUrl = AppConstants.supabaseUrl;
      final publicUrl = '$projectUrl/storage/$fileId';

      onProgress(1.0);

      debugPrint('StorageService: upload success → $publicUrl');
      return publicUrl;
    } on PostgrestException catch (e) {
      debugPrint('StorageService UPLOAD FAILED:');
      debugPrint('  message : ${e.message}');
      debugPrint('  code    : ${e.code}');
      debugPrint('  details : ${e.details}');
      rethrow;
    }
  }
}
