class NoteImageModel {
  final String id;
  final String noteId;
  final String userId;
  final String imageUrl;
  final String? thumbnailUrl;
  final String? caption;
  final double? width;
  final double? height;
  final int position;
  final DateTime createdAt;

  NoteImageModel({
    required this.id,
    required this.noteId,
    required this.userId,
    required this.imageUrl,
    this.thumbnailUrl,
    this.caption,
    this.width,
    this.height,
    required this.position,
    required this.createdAt,
  });

  factory NoteImageModel.fromJson(Map<String, dynamic> json) {
    return NoteImageModel(
      id: json['id'] as String,
      noteId: json['note_id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      caption: json['caption'] as String?,
      width: json['width'] as double?,
      height: json['height'] as double?,
      position: json['position'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note_id': noteId,
      'user_id': userId,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'caption': caption,
      'width': width,
      'height': height,
      'position': position,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NoteImageModel copyWith({
    String? id,
    String? noteId,
    String? userId,
    String? imageUrl,
    String? thumbnailUrl,
    String? caption,
    double? width,
    double? height,
    int? position,
    DateTime? createdAt,
  }) {
    return NoteImageModel(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      width: width ?? this.width,
      height: height ?? this.height,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
