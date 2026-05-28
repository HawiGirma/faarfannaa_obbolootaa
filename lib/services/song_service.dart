import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song_model.dart';
import '../core/constants/app_constants.dart';

class SongService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _songsRef =>
      _firestore.collection(AppConstants.songsCollection);

  /// Get all songs stream
  Stream<List<SongModel>> getSongsStream() {
    return _songsRef.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => SongModel.fromFirestore(d)).toList(),
        );
  }

  /// Get featured songs
  Stream<List<SongModel>> getFeaturedSongs() {
    return _songsRef
        .where('featured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => SongModel.fromFirestore(d)).toList(),
        );
  }

  /// Get recently added songs
  Future<List<SongModel>> getRecentSongs({int limit = 10}) async {
    final snap = await _songsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => SongModel.fromFirestore(d)).toList();
  }

  /// Get songs by language
  Stream<List<SongModel>> getSongsByLanguage(String language) {
    return _songsRef
        .where('language', isEqualTo: language)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => SongModel.fromFirestore(d)).toList(),
        );
  }

  /// Get trending songs (by play count)
  Future<List<SongModel>> getTrendingSongs({int limit = 10}) async {
    final snap = await _songsRef
        .orderBy('playCount', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => SongModel.fromFirestore(d)).toList();
  }

  /// Search songs
  Future<List<SongModel>> searchSongs(String query) async {
    if (query.isEmpty) return [];
    final queryLower = query.toLowerCase();
    final snap = await _songsRef.get();
    return snap.docs
        .map((d) => SongModel.fromFirestore(d))
        .where(
          (s) =>
              s.title.toLowerCase().contains(queryLower) ||
              s.artist.toLowerCase().contains(queryLower) ||
              s.language.toLowerCase().contains(queryLower),
        )
        .toList();
  }

  /// Get song by ID
  Future<SongModel?> getSongById(String id) async {
    final doc = await _songsRef.doc(id).get();
    if (doc.exists) return SongModel.fromFirestore(doc);
    return null;
  }

  /// Get songs by IDs (for favorites)
  Future<List<SongModel>> getSongsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final futures = ids.map((id) => getSongById(id));
    final results = await Future.wait(futures);
    return results.whereType<SongModel>().toList();
  }

  /// Add song (admin only) — uses the song's existing id as the document ID
  Future<void> addSong(SongModel song) async {
    await _songsRef.doc(song.id).set(song.toFirestore());
  }

  /// Update song (admin only)
  Future<void> updateSong(SongModel song) async {
    await _songsRef.doc(song.id).update(song.toFirestore());
  }

  /// Delete song (admin only)
  Future<void> deleteSong(String id) async {
    await _songsRef.doc(id).delete();
  }

  /// Increment play count
  Future<void> incrementPlayCount(String id) async {
    await _songsRef.doc(id).update({'playCount': FieldValue.increment(1)});
  }

  /// Toggle featured
  Future<void> toggleFeatured(String id, bool featured) async {
    await _songsRef.doc(id).update({'featured': featured});
  }
}
