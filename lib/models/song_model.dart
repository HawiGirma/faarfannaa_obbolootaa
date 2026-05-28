import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory SongModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SongModel(
      id: doc.id,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      language: data['language'] ?? '',
      lyrics: data['lyrics'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      featured: data['featured'] ?? false,
      playCount: data['playCount'] ?? 0,
      albumName: data['albumName'],
      duration: data['durationSeconds'] != null
          ? Duration(seconds: data['durationSeconds'])
          : null,
      uploadedBy: data['uploadedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'artist': artist,
      'language': language,
      'lyrics': lyrics,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'featured': featured,
      'playCount': playCount,
      'albumName': albumName,
      'durationSeconds': duration?.inSeconds,
      'uploadedBy': uploadedBy,
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
