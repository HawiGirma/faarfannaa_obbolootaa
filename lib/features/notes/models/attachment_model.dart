/// Model representing a note attachment (PDF, Word, Excel, Audio, Video, Links)
class AttachmentModel {
  final String id;
  final String noteId;
  final String userId;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String fileUrl;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttachmentModel({
    required this.id,
    required this.noteId,
    required this.userId,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.fileUrl,
    this.thumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] as String,
      noteId: json['note_id'] as String,
      userId: json['user_id'] as String,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int,
      fileUrl: json['file_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note_id': noteId,
      'user_id': userId,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'file_url': fileUrl,
      'thumbnail_url': thumbnailUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get file extension
  String get extension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Check if file is an image
  bool get isImage {
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  /// Check if file is a document
  bool get isDocument {
    return ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt']
        .contains(extension);
  }

  /// Check if file is audio
  bool get isAudio {
    return ['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg'].contains(extension);
  }

  /// Check if file is video
  bool get isVideo {
    return ['mp4', 'avi', 'mov', 'mkv', 'webm', 'flv'].contains(extension);
  }

  /// Format file size
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  AttachmentModel copyWith({
    String? id,
    String? noteId,
    String? userId,
    String? fileName,
    String? fileType,
    int? fileSize,
    String? fileUrl,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttachmentModel(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      fileUrl: fileUrl ?? this.fileUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
