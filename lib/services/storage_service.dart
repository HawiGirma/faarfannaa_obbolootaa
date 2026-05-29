import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  SupabaseClient get _client => Supabase.instance.client;

  // ── Audio ─────────────────────────────────────────────────────────────

  Future<String> uploadAudioWithProgress(
    String fileName, {
    File? file,
    Uint8List? bytes,
    required void Function(double) onProgress,
  }) {
    return _upload(
      folder: AppConstants.audioFolder,
      fileName: fileName,
      mimeType: 'audio/mpeg',
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

  Future<void> deleteFile(String storagePath) async {
    try {
      await _client.storage
          .from(AppConstants.songsBucket)
          .remove([storagePath]);
    } catch (e) {
      debugPrint('StorageService.deleteFile: $e');
    }
  }

  Future<void> deleteByUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(AppConstants.songsBucket);
      if (bucketIndex == -1) return;
      final storagePath = segments.sublist(bucketIndex + 1).join('/');
      await deleteFile(storagePath);
    } catch (e) {
      debugPrint('StorageService.deleteByUrl: $e');
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
    const String bucket = AppConstants.songsBucket;

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
        '(${data.lengthInBytes} bytes, $mimeType) to bucket "$bucket"');
    debugPrint('StorageService: user=${_client.auth.currentUser?.email}');

    onProgress(0.1);

    try {
      await _client.storage.from(bucket).uploadBinary(
            storagePath,
            data,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );
    } on StorageException catch (e) {
      debugPrint('StorageService UPLOAD FAILED:');
      debugPrint('  message : ${e.message}');
      debugPrint('  status  : ${e.statusCode}');
      debugPrint('  error   : ${e.error}');
      rethrow;
    }

    onProgress(1.0);

    final publicUrl = _client.storage.from(bucket).getPublicUrl(storagePath);

    debugPrint('StorageService: upload success → $publicUrl');
    return publicUrl;
  }
}
