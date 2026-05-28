import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import '../models/song_model.dart';
import 'download_service.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final DownloadService _downloadService;

  SongModel? _currentSong;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;
  List<SongModel> _queue = [];
  int _currentIndex = 0;

  SongModel? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isLoading => _isLoading;
  List<SongModel> get queue => _queue;
  int get currentIndex => _currentIndex;
  AudioPlayer get player => _player;

  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  AudioPlayerService(this._downloadService) {
    _initListeners();
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
      // Use local cached file if available, otherwise stream from remote
      final url = _downloadService.resolveUrl(song.id, song.audioUrl);
      await _player.setUrl(url);
      await _player.play();

      // After playback starts successfully, cache in background for next time
      if (!_downloadService.isDownloaded(song.id) && song.audioUrl.isNotEmpty) {
        _downloadService.downloadSong(song.id, song.audioUrl);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
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
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
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
    _player.dispose();
    super.dispose();
  }
}
