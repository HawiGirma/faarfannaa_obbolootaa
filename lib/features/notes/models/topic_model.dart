import 'package:flutter/material.dart';

/// Model representing a note topic/category
class TopicModel {
  final String id;
  final String userId;
  final String name;
  final Color? color;
  final IconData? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  TopicModel({
    required this.id,
    required this.userId,
    required this.name,
    this.color,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      color: json['color'] != null ? _colorFromHex(json['color']) : null,
      icon: json['icon'] != null ? _iconFromString(json['icon']) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color != null ? _colorToHex(color!) : null,
      'icon': icon != null ? _iconToString(icon!) : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TopicModel copyWith({
    String? id,
    String? userId,
    String? name,
    Color? color,
    IconData? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TopicModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Color _colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  static IconData _iconFromString(String iconString) {
    final codePoint = int.tryParse(iconString, radix: 16);
    return codePoint != null
        ? IconData(codePoint, fontFamily: 'MaterialIcons')
        : Icons.folder;
  }

  static String _iconToString(IconData icon) {
    return icon.codePoint.toRadixString(16);
  }

  /// Predefined topics
  static List<Map<String, dynamic>> get defaultTopics => [
        {
          'name': 'Work',
          'icon': Icons.work_rounded,
          'color': const Color(0xFF2196F3)
        },
        {
          'name': 'Personal',
          'icon': Icons.person_rounded,
          'color': const Color(0xFF4CAF50)
        },
        {
          'name': 'Ideas',
          'icon': Icons.lightbulb_rounded,
          'color': const Color(0xFFFF9800)
        },
        {
          'name': 'Study',
          'icon': Icons.school_rounded,
          'color': const Color(0xFF9C27B0)
        },
        {
          'name': 'Meeting',
          'icon': Icons.groups_rounded,
          'color': const Color(0xFF00BCD4)
        },
        {
          'name': 'Shopping',
          'icon': Icons.shopping_cart_rounded,
          'color': const Color(0xFFE91E63)
        },
        {
          'name': 'Finance',
          'icon': Icons.attach_money_rounded,
          'color': const Color(0xFF4CAF50)
        },
        {
          'name': 'Travel',
          'icon': Icons.flight_rounded,
          'color': const Color(0xFF3F51B5)
        },
      ];
}
