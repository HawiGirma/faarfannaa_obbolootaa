import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song_model.dart';

/// Background audio handler that enables:
/// - Background playback
/// - Media notifications
/// - Lockscreen controls
/// - Bluetooth/headphone controls
class BackgroundAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  BackgroundAudioHandler() {
    _init();
  }

  void _init() {
    // Listen to player state and update notification
    _player.playerStateStream.listen((state) {
      playbackState.add(playbackState.value.copyWith(
        playing: state.playing,
        controls: [
          MediaControl.skipToPrevious,
          if (state.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[state.processingState]!,
      ));
    });

    // Listen to position updates
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    // Listen to duration
    _player.durationStream.listen((duration) {
      mediaItem.add(mediaItem.value?.copyWith(duration: duration));
    });

    // Auto-play next song when current completes
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  /// Play a song from the database
  Future<void> playSongFromDatabase(SongModel song) async {
    try {
      debugPrint('BackgroundAudioHandler: Playing ${song.title}');

      // Update media item for notification
      mediaItem.add(MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.albumName,
        duration: song.duration,
        artUri: song.imageUrl.isNotEmpty ? Uri.parse(song.imageUrl) : null,
      ));

      // Check if URL is database storage
      if (song.audioUrl.contains('/storage/')) {
        await _playFromDatabase(song.audioUrl);
      } else {
        await _player.setUrl(song.audioUrl);
      }

      play();
    } catch (e) {
      debugPrint('BackgroundAudioHandler: Error playing song: $e');
      rethrow;
    }
  }

  /// Fetch and play audio from database
  Future<void> _playFromDatabase(String url) async {
    final fileId = url.split('/storage/').last;
    debugPrint('BackgroundAudioHandler: Fetching file ID: $fileId');

    final client = Supabase.instance.client;
    final response = await client
        .from('file_storage')
        .select('data, mime_type')
        .eq('id', fileId)
        .single();

    final base64Data = response['data'] as String?;
    if (base64Data == null || base64Data.isEmpty) {
      throw Exception('No audio data found');
    }

    final bytes = base64Decode(base64Data);
    final mimeType = response['mime_type'] as String? ?? 'audio/mpeg';

    await _player.setAudioSource(
      _BytesAudioSource(bytes, mimeType: mimeType),
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    // Implement queue navigation
    debugPrint('Skip to next');
  }

  @override
  Future<void> skipToPrevious() async {
    // Implement queue navigation
    debugPrint('Skip to previous');
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

/// Custom audio source for playing from bytes
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
