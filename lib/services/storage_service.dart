import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../core/constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─── Cross-platform upload helpers ───────────────────────────────────

  /// Uploads audio and returns the public download URL.
  /// Pass [bytes] on web, [file] on mobile/desktop.
  Future<String> uploadAudio(
    String fileName, {
    File? file,
    Uint8List? bytes,
  }) async {
    final url = await _upload(
      path: '${AppConstants.audioStoragePath}$fileName',
      contentType: 'audio/mpeg',
      file: file,
      bytes: bytes,
      onProgress: null,
    );
    return url;
  }

  /// Uploads an image and returns the public download URL.
  /// Pass [bytes] on web, [file] on mobile/desktop.
  Future<String> uploadImage(
    String fileName, {
    File? file,
    Uint8List? bytes,
  }) async {
    final url = await _upload(
      path: '${AppConstants.imageStoragePath}$fileName',
      contentType: 'image/jpeg',
      file: file,
      bytes: bytes,
      onProgress: null,
    );
    return url;
  }

  /// Uploads audio with a progress callback (0.0 → 1.0).
  /// Pass [bytes] on web, [file] on mobile/desktop.
  Future<String> uploadAudioWithProgress(
    String fileName, {
    File? file,
    Uint8List? bytes,
    required void Function(double) onProgress,
  }) {
    return _upload(
      path: '${AppConstants.audioStoragePath}$fileName',
      contentType: 'audio/mpeg',
      file: file,
      bytes: bytes,
      onProgress: onProgress,
    );
  }

  /// Uploads an image with a progress callback (0.0 → 1.0).
  /// Pass [bytes] on web, [file] on mobile/desktop.
  Future<String> uploadImageWithProgress(
    String fileName, {
    File? file,
    Uint8List? bytes,
    required void Function(double) onProgress,
  }) {
    return _upload(
      path: '${AppConstants.imageStoragePath}$fileName',
      contentType: 'image/jpeg',
      file: file,
      bytes: bytes,
      onProgress: onProgress,
    );
  }

  // ─── Core upload implementation ───────────────────────────────────────

  Future<String> _upload({
    required String path,
    required String contentType,
    File? file,
    Uint8List? bytes,
    void Function(double)? onProgress,
  }) async {
    final ref = _storage.ref().child(path);
    final meta = SettableMetadata(contentType: contentType);

    // Choose the right upload method for the platform
    final UploadTask task;
    if (kIsWeb || bytes != null) {
      assert(bytes != null, 'bytes must be provided on web');
      task = ref.putData(bytes!, meta);
    } else {
      assert(file != null, 'file must be provided on non-web');
      task = ref.putFile(file!, meta);
    }

    // Listen to progress events
    if (onProgress != null) {
      task.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });
    }

    // Wait for the task to complete by listening to state changes
    await task.whenComplete(() {});

    final snapshot = await task;
    if (snapshot.state != TaskState.success) {
      throw Exception('Upload failed with state: ${snapshot.state}');
    }

    return await snapshot.ref.getDownloadURL();
  }

  // ─── Delete ───────────────────────────────────────────────────────────

  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('StorageService.deleteByUrl failed: $e');
    }
  }
}
