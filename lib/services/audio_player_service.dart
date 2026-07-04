import 'dart:async';
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song_model.dart';
import 'download_service.dart';
import 'background_audio_service.dart';

enum AudioRepeatMode {
  off, // No repeat
  all, // Repeat all tracks in queue
  one, // Repeat current track
}

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final DownloadService _downloadService;
  BackgroundAudioHandler? _audioHandler;

  SongModel? _currentSong;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;
  List<SongModel> _queue = [];
  int _currentIndex = 0;
  AudioRepeatMode _repeatMode = AudioRepeatMode.off;

  // Sleep timer
  Timer? _sleepTimer;
  DateTime? _sleepEndTime;

  SongModel? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isLoading => _isLoading;
  List<SongModel> get queue => _queue;
  int get currentIndex => _currentIndex;
  AudioPlayer get player => _player;
  AudioRepeatMode get repeatMode => _repeatMode;
  DateTime? get sleepEndTime => _sleepEndTime;
  bool get hasSleepTimer => _sleepTimer != null && _sleepTimer!.isActive;

  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  AudioPlayerService(this._downloadService) {
    _initListeners();
  }

  /// Set the background audio handler for notifications
  void setAudioHandler(BackgroundAudioHandler handler) {
    _audioHandler = handler;
  }

  void _initListeners() {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      if (state.processingState == ProcessingState.completed) {
        _playNext();
      }
      notifyListeners();
    });

    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });
  }

  Future<void> playSong(SongModel song, {List<SongModel>? queue}) async {
    if (queue != null) {
      _queue = queue;
      _currentIndex = queue.indexWhere((s) => s.id == song.id);
      if (_currentIndex < 0) _currentIndex = 0;
    } else if (_queue.isEmpty) {
      _queue = [song];
      _currentIndex = 0;
    }

    _currentSong = song;
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('AudioPlayer: Attempting to play song: ${song.title}');
      debugPrint('AudioPlayer: Audio URL: ${song.audioUrl}');

      // Check if audio URL is empty
      if (song.audioUrl.isEmpty) {
        throw Exception('Audio URL is empty for song: ${song.title}');
      }

      // Check if this is a database storage URL
      if (_isDatabaseStorageUrl(song.audioUrl)) {
        debugPrint('AudioPlayer: Loading from database storage');
        await _playFromDatabase(song.audioUrl);
      } else {
        debugPrint('AudioPlayer: Loading from URL: ${song.audioUrl}');
        // Use local cached file if available, otherwise stream from remote
        final url = _downloadService.resolveUrl(song.id, song.audioUrl);
        await _player.setUrl(url);
      }

      await _player.play();

      // After playback starts successfully, cache in background for next time
      if (!_downloadService.isDownloaded(song.id) &&
          song.audioUrl.isNotEmpty &&
          !_isDatabaseStorageUrl(song.audioUrl)) {
        _downloadService.downloadSong(song.id, song.audioUrl);
      }
    } catch (e, stackTrace) {
      debugPrint('AudioPlayer ERROR: $e');
      debugPrint('AudioPlayer STACK TRACE: $stackTrace');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Check if URL is a database storage URL (format: https://.../storage/{fileId})
  bool _isDatabaseStorageUrl(String url) {
    return url.contains('/storage/') && url.split('/storage/').length > 1;
  }

  /// Fetch audio file from database and play from bytes
  Future<void> _playFromDatabase(String url) async {
    try {
      // Extract file ID from URL: https://xyz.supabase.co/storage/{fileId}
      final fileId = url.split('/storage/').last;
      debugPrint('AudioPlayer: Fetching file ID: $fileId from database');

      // Fetch base64 data from database
      final client = Supabase.instance.client;
      final response = await client
          .from('file_storage')
          .select('data, mime_type')
          .eq('id', fileId)
          .single();

      final base64Data = response['data'] as String?;
      if (base64Data == null || base64Data.isEmpty) {
        throw Exception('No audio data found in database for file ID: $fileId');
      }

      debugPrint(
          'AudioPlayer: Received base64 data, length=${base64Data.length}');

      // Decode base64 to bytes
      final bytes = base64Decode(base64Data);
      debugPrint('AudioPlayer: Decoded to ${bytes.length} bytes');

      if (bytes.isEmpty) {
        throw Exception('Decoded audio bytes are empty');
      }

      final mimeType = response['mime_type'] as String? ?? 'audio/mpeg';
      debugPrint('AudioPlayer: Using MIME type: $mimeType');

      // Play from bytes
      await _player.setAudioSource(
        _BytesAudioSource(bytes, mimeType: mimeType),
      );
      debugPrint('AudioPlayer: Audio source set successfully');
    } catch (e, stackTrace) {
      debugPrint('AudioPlayer: Database fetch failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekToProgress(double progress) async {
    final position = Duration(
      milliseconds: (_duration.inMilliseconds * progress).round(),
    );
    await seekTo(position);
  }

  Future<void> _playNext() async {
    if (_repeatMode == AudioRepeatMode.one) {
      // Repeat current track
      await seekTo(Duration.zero);
      await _player.play();
    } else if (_currentIndex < _queue.length - 1) {
      // Move to next track
      _currentIndex++;
      await playSong(_queue[_currentIndex]);
    } else if (_repeatMode == AudioRepeatMode.all && _queue.isNotEmpty) {
      // Repeat all: go back to first track
      _currentIndex = 0;
      await playSong(_queue[_currentIndex]);
    }
  }

  Future<void> playNext() async {
    await _playNext();
  }

  Future<void> playPrevious() async {
    if (_position.inSeconds > 3) {
      await seekTo(Duration.zero);
    } else if (_currentIndex > 0) {
      _currentIndex--;
      await playSong(_queue[_currentIndex]);
    }
  }

  /// Toggle repeat mode: off -> all -> one -> off
  void toggleRepeatMode() {
    switch (_repeatMode) {
      case AudioRepeatMode.off:
        _repeatMode = AudioRepeatMode.all;
        break;
      case AudioRepeatMode.all:
        _repeatMode = AudioRepeatMode.one;
        break;
      case AudioRepeatMode.one:
        _repeatMode = AudioRepeatMode.off;
        break;
    }
    notifyListeners();
  }

  /// Jump to a specific song in the queue
  Future<void> playQueueItem(int index) async {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      await playSong(_queue[_currentIndex]);
    }
  }

  /// Set sleep timer to stop playback after specified duration
  void setSleepTimer(Duration duration) {
    cancelSleepTimer();
    _sleepEndTime = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () async {
      debugPrint('Sleep timer: Stopping playback');
      await stop();
      _sleepEndTime = null;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Cancel active sleep timer
  void cancelSleepTimer() {
    if (_sleepTimer != null) {
      _sleepTimer!.cancel();
      _sleepTimer = null;
      _sleepEndTime = null;
      notifyListeners();
    }
  }

  /// Get remaining time on sleep timer
  Duration? getRemainingTime() {
    if (_sleepEndTime != null) {
      final remaining = _sleepEndTime!.difference(DateTime.now());
      return remaining.isNegative ? Duration.zero : remaining;
    }
    return null;
  }

  Future<void> stop() async {
    await _player.stop();
    _currentSong = null;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}

/// Custom audio source for playing from bytes (database storage)
class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;
  final String? mimeType;

  _BytesAudioSource(this._bytes, {this.mimeType});

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;

    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      contentType: mimeType ?? 'audio/mpeg',
      stream: Stream.value(_bytes.sublist(start, end)),
    );
  }
}
