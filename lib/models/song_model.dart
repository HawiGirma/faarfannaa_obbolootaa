class SongModel {
  final String id;
  final String title;
  final String artist;
  final String language;
  final String lyrics;
  final String audioUrl;
  final String imageUrl;
  final DateTime createdAt;
  final bool featured;
  final int playCount;
  final String? albumName;
  final Duration? duration;
  final String? uploadedBy;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.language,
    required this.lyrics,
    required this.audioUrl,
    required this.imageUrl,
    required this.createdAt,
    this.featured = false,
    this.playCount = 0,
    this.albumName,
    this.duration,
    this.uploadedBy,
  });

  /// Construct from a Supabase row (Map<String, dynamic>)
  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      artist: map['artist'] as String? ?? '',
      language: map['language'] as String? ?? '',
      lyrics: map['lyrics'] as String? ?? '',
      audioUrl: map['audio_url'] as String? ?? '',
      imageUrl: map['cover_url'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      featured: map['featured'] as bool? ?? false,
      playCount: map['play_count'] as int? ?? 0,
      albumName: map['album_name'] as String?,
      duration: map['duration_seconds'] != null
          ? Duration(seconds: map['duration_seconds'] as int)
          : null,
      uploadedBy: map['uploaded_by'] as String?,
    );
  }

  /// Convert to a map for Supabase insert / update
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'language': language,
      'lyrics': lyrics,
      'audio_url': audioUrl,
      'cover_url': imageUrl,
      'featured': featured,
      'play_count': playCount,
      'album_name': albumName,
      'duration_seconds': duration?.inSeconds,
      'uploaded_by': uploadedBy,
      // created_at is set by Supabase default (now())
    };
  }

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? language,
    String? lyrics,
    String? audioUrl,
    String? imageUrl,
    DateTime? createdAt,
    bool? featured,
    int? playCount,
    String? albumName,
    Duration? duration,
    String? uploadedBy,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      language: language ?? this.language,
      lyrics: lyrics ?? this.lyrics,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      featured: featured ?? this.featured,
      playCount: playCount ?? this.playCount,
      albumName: albumName ?? this.albumName,
      duration: duration ?? this.duration,
      uploadedBy: uploadedBy ?? this.uploadedBy,
    );
  }
}
