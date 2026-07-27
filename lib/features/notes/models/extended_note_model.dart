import 'package:flutter/material.dart';
import '../../../models/note_model.dart';
import 'rich_text_content.dart';

/// Extended note model with additional features
class ExtendedNoteModel extends NoteModel {
  final RichTextContent? richContent;
  final bool hasDrawing;
  final bool hasImages;
  final bool hasAttachments;
  final bool hasChecklist;
  final List<String> topics;
  final List<String> tags;
  final int viewCount;
  final bool isFavorite;
  final DateTime? lastViewedAt;
  final String? fontFamily;
  final double? fontSize;

  ExtendedNoteModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.content,
    required super.color,
    required super.isPinned,
    required super.isArchived,
    required super.createdAt,
    required super.updatedAt,
    this.richContent,
    this.hasDrawing = false,
    this.hasImages = false,
    this.hasAttachments = false,
    this.hasChecklist = false,
    this.topics = const [],
    this.tags = const [],
    this.viewCount = 0,
    this.isFavorite = false,
    this.lastViewedAt,
    this.fontFamily,
    this.fontSize,
  });

  /// Create from base NoteModel
  factory ExtendedNoteModel.fromNoteModel(NoteModel note) {
    return ExtendedNoteModel(
      id: note.id,
      userId: note.userId,
      title: note.title,
      content: note.content,
      color: note.color,
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );
  }

  /// Create from JSON with extended fields
  factory ExtendedNoteModel.fromJson(Map<String, dynamic> json) {
    return ExtendedNoteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      content: json['content'] as String? ?? '',
      color: _colorFromHex(json['color'] as String? ?? '#FFFFFF'),
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      richContent: json['rich_content'] != null
          ? RichTextContent.fromJson(
              json['rich_content'] as Map<String, dynamic>)
          : null,
      hasDrawing: json['has_drawing'] as bool? ?? false,
      hasImages: json['has_images'] as bool? ?? false,
      hasAttachments: json['has_attachments'] as bool? ?? false,
      hasChecklist: json['has_checklist'] as bool? ?? false,
      topics: json['topics'] != null
          ? List<String>.from(json['topics'] as List)
          : [],
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
      viewCount: json['view_count'] as int? ?? 0,
      isFavorite: json['is_favorite'] as bool? ?? false,
      lastViewedAt: json['last_viewed_at'] != null
          ? DateTime.parse(json['last_viewed_at'] as String)
          : null,
      fontFamily: json['font_family'] as String?,
      fontSize: json['font_size'] as double?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({
      'rich_content': richContent?.toJson(),
      'has_drawing': hasDrawing,
      'has_images': hasImages,
      'has_attachments': hasAttachments,
      'has_checklist': hasChecklist,
      'topics': topics,
      'tags': tags,
      'view_count': viewCount,
      'is_favorite': isFavorite,
      'last_viewed_at': lastViewedAt?.toIso8601String(),
      'font_family': fontFamily,
      'font_size': fontSize,
    });
    return baseJson;
  }

  ExtendedNoteModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    Color? color,
    bool? isPinned,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    RichTextContent? richContent,
    bool? hasDrawing,
    bool? hasImages,
    bool? hasAttachments,
    bool? hasChecklist,
    List<String>? topics,
    List<String>? tags,
    int? viewCount,
    bool? isFavorite,
    DateTime? lastViewedAt,
    String? fontFamily,
    double? fontSize,
  }) {
    return ExtendedNoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      richContent: richContent ?? this.richContent,
      hasDrawing: hasDrawing ?? this.hasDrawing,
      hasImages: hasImages ?? this.hasImages,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      hasChecklist: hasChecklist ?? this.hasChecklist,
      topics: topics ?? this.topics,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      isFavorite: isFavorite ?? this.isFavorite,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  static Color _colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Check if note has any media
  bool get hasMedia => hasImages || hasDrawing || hasAttachments;

  /// Get all content indicators
  List<String> get contentIndicators {
    final indicators = <String>[];
    if (hasImages) indicators.add('images');
    if (hasDrawing) indicators.add('drawing');
    if (hasAttachments) indicators.add('attachments');
    if (hasChecklist) indicators.add('checklist');
    return indicators;
  }
}
