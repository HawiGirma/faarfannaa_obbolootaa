class NoteDrawingModel {
  final String id;
  final String noteId;
  final String userId;
  final DrawingData drawingData;
  final String? thumbnailUrl;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteDrawingModel({
    required this.id,
    required this.noteId,
    required this.userId,
    required this.drawingData,
    this.thumbnailUrl,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteDrawingModel.fromJson(Map<String, dynamic> json) {
    return NoteDrawingModel(
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
}

class DrawingData {
  final List<DrawingStroke> strokes;
  final double canvasWidth;
  final double canvasHeight;

  DrawingData({
    required this.strokes,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  Map<String, dynamic> toJson() {
    return {
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
    };
  }

  factory DrawingData.fromJson(Map<String, dynamic> json) {
    return DrawingData(
      strokes: (json['strokes'] as List)
          .map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
          .toList(),
      canvasWidth: (json['canvasWidth'] as num).toDouble(),
      canvasHeight: (json['canvasHeight'] as num).toDouble(),
    );
  }
}

class DrawingStroke {
  final List<DrawingPoint> points;
  final String color; // Hex color
  final double strokeWidth;
  final String tool; // 'pen', 'pencil', 'marker', 'eraser'

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.tool,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => p.toJson()).toList(),
      'color': color,
      'strokeWidth': strokeWidth,
      'tool': tool,
    };
  }

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      points: (json['points'] as List)
          .map((p) => DrawingPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      color: json['color'] as String,
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      tool: json['tool'] as String,
    );
  }
}

class DrawingPoint {
  final double x;
  final double y;

  DrawingPoint({required this.x, required this.y});

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y};
  }

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }
}
