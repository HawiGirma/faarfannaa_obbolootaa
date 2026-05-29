import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song_model.dart';
import '../core/constants/app_constants.dart';

class SongService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Streams (realtime) ────────────────────────────────────────────────

  /// All songs ordered by newest first — live updates via Supabase Realtime
  Stream<List<SongModel>> getSongsStream() {
    return _client
        .from(AppConstants.songsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(SongModel.fromMap).toList());
  }

  /// Featured songs — live updates
  Stream<List<SongModel>> getFeaturedSongs() {
    return _client
        .from(AppConstants.songsTable)
        .stream(primaryKey: ['id'])
        .eq('featured', true)
        .order('created_at', ascending: false)
        .map((rows) => rows.take(10).map(SongModel.fromMap).toList());
  }

  // ── One-shot queries ──────────────────────────────────────────────────

  Future<List<SongModel>> getRecentSongs({int limit = 10}) async {
    final rows = await _client
        .from(AppConstants.songsTable)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(SongModel.fromMap).toList();
  }

  Future<List<SongModel>> getTrendingSongs({int limit = 10}) async {
    final rows = await _client
        .from(AppConstants.songsTable)
        .select()
        .order('play_count', ascending: false)
        .limit(limit);
    return rows.map(SongModel.fromMap).toList();
  }

  Future<List<SongModel>> getSongsByLanguage(String language) async {
    final rows = await _client
        .from(AppConstants.songsTable)
        .select()
        .eq('language', language)
        .order('created_at', ascending: false);
    return rows.map(SongModel.fromMap).toList();
  }

  Future<List<SongModel>> searchSongs(String query) async {
    if (query.isEmpty) return [];
    // Supabase ilike for case-insensitive partial match
    final rows = await _client
        .from(AppConstants.songsTable)
        .select()
        .or('title.ilike.%$query%,artist.ilike.%$query%,language.ilike.%$query%')
        .order('created_at', ascending: false);
    return rows.map(SongModel.fromMap).toList();
  }

  Future<SongModel?> getSongById(String id) async {
    final row = await _client
        .from(AppConstants.songsTable)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row != null) return SongModel.fromMap(row);
    return null;
  }

  Future<List<SongModel>> getSongsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(AppConstants.songsTable)
        .select()
        .inFilter('id', ids);
    return rows.map(SongModel.fromMap).toList();
  }

  // ── Admin writes ──────────────────────────────────────────────────────

  Future<void> addSong(SongModel song) async {
    await _client.from(AppConstants.songsTable).insert(song.toMap());
  }

  Future<void> updateSong(SongModel song) async {
    final data = song.toMap()..remove('id'); // id is the PK, not updated
    await _client.from(AppConstants.songsTable).update(data).eq('id', song.id);
  }

  Future<void> deleteSong(String id) async {
    await _client.from(AppConstants.songsTable).delete().eq('id', id);
  }

  Future<void> incrementPlayCount(String id) async {
    try {
      // Use Supabase RPC for atomic increment
      await _client.rpc('increment_play_count', params: {'song_id': id});
    } catch (e) {
      debugPrint('SongService.incrementPlayCount: $e');
    }
  }

  Future<void> toggleFeatured(String id, bool featured) async {
    await _client
        .from(AppConstants.songsTable)
        .update({'featured': featured}).eq('id', id);
  }
}
