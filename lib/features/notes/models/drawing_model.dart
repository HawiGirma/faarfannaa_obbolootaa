import 'dart:convert';
import 'package:flutter/material.dart';

/// Model representing a drawing in a note
class DrawingModel {
  final String id;
  final String noteId;
  final String userId;
  final DrawingData drawingData;
  final String? thumbnailUrl;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  DrawingModel({
    required this.id,
    required this.noteId,
    required this.userId,
    required this.drawingData,
    this.thumbnailUrl,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DrawingModel.fromJson(Map<String, dynamic> json) {
    return DrawingModel(
      id: json['id'] as String,
      noteId: json['note_id'] as String,
      userId: json['user_id'] as String,
      drawingData:
          DrawingData.fromJson(json['drawing_data'] as Map<String, dynamic>),
      thumbnailUrl: json['thumbnail_url'] as String?,
      position: json['position'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note_id': noteId,
      'user_id': userId,
      'drawing_data': drawingData.toJson(),
      'thumbnail_url': thumbnailUrl,
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DrawingModel copyWith({
    String? id,
    String? noteId,
    String? userId,
    DrawingData? drawingData,
    String? thumbnailUrl,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DrawingModel(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      userId: userId ?? this.userId,
      drawingData: drawingData ?? this.drawingData,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Drawing data containing strokes
class DrawingData {
  final List<DrawingStroke> strokes;
  final double canvasWidth;
  final double canvasHeight;

  DrawingData({
    required this.strokes,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  factory DrawingData.fromJson(Map<String, dynamic> json) {
    return DrawingData(
      strokes: (json['strokes'] as List)
          .map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
          .toList(),
      canvasWidth: json['canvas_width'] as double,
      canvasHeight: json['canvas_height'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'canvas_width': canvasWidth,
      'canvas_height': canvasHeight,
    };
  }
}

/// Individual stroke in a drawing
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double thickness;
  final double opacity;
  final PenType penType;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.thickness,
    required this.opacity,
    required this.penType,
  });

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      points: (json['points'] as List)
          .map((p) => Offset(p['x'] as double, p['y'] as double))
          .toList(),
      color: Color(json['color'] as int),
      thickness: json['thickness'] as double,
      opacity: json['opacity'] as double,
      penType: PenType.values.firstWhere(
        (e) => e.toString() == json['pen_type'],
        orElse: () => PenType.ballpoint,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
      'thickness': thickness,
      'opacity': opacity,
      'pen_type': penType.toString(),
    };
  }
}

/// Pen types for drawing
enum PenType {
  pencil,
  ballpoint,
  marker,
  calligraphy,
  highlighter,
}

/// Pen settings for drawing
class PenSettings {
  final PenType type;
  final Color color;
  final double thickness;
  final double opacity;

  PenSettings({
    required this.type,
    required this.color,
    required this.thickness,
    required this.opacity,
  });

  PenSettings copyWith({
    PenType? type,
    Color? color,
    double? thickness,
    double? opacity,
  }) {
    return PenSettings(
      type: type ?? this.type,
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      opacity: opacity ?? this.opacity,
    );
  }

  static PenSettings get defaultSettings => PenSettings(
        type: PenType.ballpoint,
        color: Colors.black,
        thickness: 2.0,
        opacity: 1.0,
      );
}

/// Eraser settings
class EraserSettings {
  final EraserSize size;
  final EraserMode mode;

  EraserSettings({
    required this.size,
    required this.mode,
  });

  double get thickness {
    switch (size) {
      case EraserSize.small:
        return 10.0;
      case EraserSize.medium:
        return 20.0;
      case EraserSize.large:
        return 40.0;
    }
  }
}

enum EraserSize {
  small,
  medium,
  large,
}

enum EraserMode {
  stroke, // Erase entire stroke
  partial, // Erase part of stroke
}
