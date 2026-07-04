import 'package:flutter/material.dart';

class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final Color color;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.color,
    required this.isPinned,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Factory: from Supabase JSON ────────────────────────────────────────
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      content: json['content'] as String? ?? '',
      color: _colorFromHex(json['color'] as String? ?? '#FFFFFF'),
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // ── Convert to JSON for Supabase ───────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'color': _colorToHex(color),
      'is_pinned': isPinned,
      'is_archived': isArchived,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ── CopyWith method ────────────────────────────────────────────────────
  NoteModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    Color? color,
    bool? isPinned,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Helper: Convert hex string to Color ────────────────────────────────
  static Color _colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // ── Helper: Convert Color to hex string ────────────────────────────────
  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  // ── Predefined note colors ─────────────────────────────────────────────
  static const List<Color> noteColors = [
    Color(0xFFFFFFFF), // White
    Color(0xFFFFCDD2), // Red
    Color(0xFFF8BBD0), // Pink
    Color(0xFFE1BEE7), // Purple
    Color(0xFFD1C4E9), // Deep Purple
    Color(0xFFC5CAE9), // Indigo
    Color(0xFFBBDEFB), // Blue
    Color(0xFFB3E5FC), // Light Blue
    Color(0xFFB2EBF2), // Cyan
    Color(0xFFB2DFDB), // Teal
    Color(0xFFC8E6C9), // Green
    Color(0xFFDCEDC8), // Light Green
    Color(0xFFF0F4C3), // Lime
    Color(0xFFFFF9C4), // Yellow
    Color(0xFFFFECB3), // Amber
    Color(0xFFFFE0B2), // Orange
  ];

  @override
  String toString() {
    return 'NoteModel(id: $id, title: $title, isPinned: $isPinned, isArchived: $isArchived)';
  }
}
