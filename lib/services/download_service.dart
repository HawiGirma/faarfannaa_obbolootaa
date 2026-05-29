import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages local caching of audio files.
///
/// Flow:
///   1. First play  → stream from Supabase Storage URL (online)
///   2. After first successful retrieval → download & save to local storage
///   3. Subsequent plays → serve from local file (offline-capable)
class DownloadService extends ChangeNotifier {
  static const String _downloadedKey = 'downloaded_songs';

  // songId → local file path
  final Map<String, String> _localPaths = {};
  // songId → download-in-progress flag
  final Map<String, bool> _downloading = {};

  bool isDownloaded(String songId) => _localPaths.containsKey(songId);
  bool isDownloading(String songId) => _downloading[songId] == true;

  /// Returns the local file path if cached, otherwise null.
  String? localPath(String songId) => _localPaths[songId];

  /// Returns the best URL to use for playback:
  ///   - local file URI if already cached
  ///   - remote URL otherwise
  String resolveUrl(String songId, String remoteUrl) {
    final local = _localPaths[songId];
    if (local != null && File(local).existsSync()) {
      return Uri.file(local).toString();
    }
    return remoteUrl;
  }

  /// Load persisted download paths from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_downloadedKey) ?? [];
    for (final entry in stored) {
      final parts = entry.split('|');
      if (parts.length == 2) {
        final id = parts[0];
        final path = parts[1];
        if (File(path).existsSync()) {
          _localPaths[id] = path;
        }
      }
    }
    notifyListeners();
  }

  /// Download [remoteUrl] and cache it locally under [songId].
  /// Safe to call multiple times — skips if already cached or in progress.
  Future<void> downloadSong(String songId, String remoteUrl) async {
    if (isDownloaded(songId) || isDownloading(songId)) return;

    _downloading[songId] = true;
    notifyListeners();

    try {
      final dir = await _getDownloadsDir();
      final filePath = '${dir.path}/$songId.mp3';
      final file = File(filePath);

      // Stream download to avoid loading the whole file into memory
      final response = await http.get(Uri.parse(remoteUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        _localPaths[songId] = filePath;
        await _persist();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DownloadService: failed to cache $songId — $e');
    } finally {
      _downloading.remove(songId);
      notifyListeners();
    }
  }

  /// Delete the local cached file for [songId].
  Future<void> removeDownload(String songId) async {
    final path = _localPaths.remove(songId);
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      await _persist();
      notifyListeners();
    }
  }

  /// Returns the app-specific downloads directory.
  Future<Directory> _getDownloadsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/downloads');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Persist the id→path map to SharedPreferences.
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final entries =
        _localPaths.entries.map((e) => '${e.key}|${e.value}').toList();
    await prefs.setStringList(_downloadedKey, entries);
  }
}
