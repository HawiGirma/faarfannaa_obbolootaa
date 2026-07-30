import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/note_drawing_model.dart' as model;
import '../../../services/note_drawing_service.dart';

enum DrawingTool {
  pen,
  pencil,
  marker,
  eraser,
}

class DrawingCanvas extends StatefulWidget {
  final DrawingTool tool;
  final Color color;
  final double strokeWidth;
  final Color backgroundColor;
  final String? noteId; // For persistence
  final model.DrawingData? initialDrawing; // Load existing drawing

  const DrawingCanvas({
    super.key,
    required this.tool,
    required this.color,
    required this.strokeWidth,
    required this.backgroundColor,
    this.noteId,
    this.initialDrawing,
  });

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  final List<DrawingPoint?> _points = [];
  final List<List<DrawingPoint?>> _undoStack = [];
  final _drawingService = NoteDrawingService();
  Timer? _saveTimer;
  String? _drawingId;
  Size? _canvasSize;

  @override
  void initState() {
    super.initState();
    _loadInitialDrawing();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  /// Public method to trigger save (called by parent)
  Future<void> saveDrawing() async {
    await _saveDrawingToDatabase();
  }

  /// Check if canvas has any drawing
  bool get hasDrawing => _points.isNotEmpty;

  // Load existing drawing if provided
  void _loadInitialDrawing() {
    if (widget.initialDrawing != null) {
      final drawing = widget.initialDrawing!;
      _canvasSize = Size(drawing.canvasWidth, drawing.canvasHeight);

      // Convert model strokes to drawing points
      for (var stroke in drawing.strokes) {
        for (var point in stroke.points) {
          final paint = Paint()
            ..color = Color(int.parse('ff${stroke.color}', radix: 16))
            ..strokeWidth = stroke.strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke;

          _points.add(DrawingPoint(
            offset: Offset(point.x, point.y),
            paint: paint,
          ));
        }
        _points.add(null); // End of stroke marker
      }
      setState(() {});
    }
  }

  // Save drawing with debounce
  void _scheduleAutoSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveDrawingToDatabase();
    });
  }

  // Save to database
  Future<void> _saveDrawingToDatabase() async {
    if (widget.noteId == null || _points.isEmpty) return;
    if (_canvasSize == null) return;

    try {
      // Convert drawing points to model format
      final strokes = <model.DrawingStroke>[];
      final currentStroke = <model.DrawingPoint>[];
      String? currentColor;
      double? currentWidth;
      String? currentTool;

      for (var point in _points) {
        if (point == null) {
          // End of stroke
          if (currentStroke.isNotEmpty && currentColor != null) {
            strokes.add(model.DrawingStroke(
              points: List.from(currentStroke),
              color: currentColor,
              strokeWidth: currentWidth ?? 3.0,
              tool: currentTool ?? 'pen',
            ));
            currentStroke.clear();
          }
        } else {
          // Add point to current stroke
          currentStroke.add(model.DrawingPoint(
            x: point.offset.dx,
            y: point.offset.dy,
          ));
          currentColor =
              point.paint.color.toARGB32().toRadixString(16).substring(2);
          currentWidth = point.paint.strokeWidth;
          // Determine tool based on stroke width ratio
          if (point.paint.strokeWidth > widget.strokeWidth * 1.5) {
            currentTool = 'marker';
          } else if (point.paint.strokeWidth < widget.strokeWidth * 0.8) {
            currentTool = 'pencil';
          } else {
            currentTool = 'pen';
          }
        }
      }

      final drawingData = model.DrawingData(
        strokes: strokes,
        canvasWidth: _canvasSize!.width,
        canvasHeight: _canvasSize!.height,
      );

      if (_drawingId == null) {
        // Create new drawing
        final result = await _drawingService.saveDrawing(
          noteId: widget.noteId!,
          drawingData: drawingData,
          position: 0,
        );
        _drawingId = result.id;
      } else {
        // Update existing drawing
        await _drawingService.updateDrawing(
          drawingId: _drawingId!,
          drawingData: drawingData,
        );
      }
    } catch (e) {
      debugPrint('Error saving drawing: $e');
    }
  }

  void undo() {
    if (_points.isEmpty) return;

    setState(() {
      // Find the last complete path (ending with null)
      int lastNullIndex = -1;
      for (int i = _points.length - 1; i >= 0; i--) {
        if (_points[i] == null) {
          lastNullIndex = i;
          break;
        }
      }

      if (lastNullIndex >= 0) {
        final removed = _points.sublist(lastNullIndex);
        _undoStack.add(removed);
        _points.removeRange(lastNullIndex, _points.length);
      } else if (_points.isNotEmpty) {
        final removed = List<DrawingPoint?>.from(_points);
        _undoStack.add(removed);
        _points.clear();
      }

      _scheduleAutoSave(); // Save after undo
    });
  }

  void redo() {
    if (_undoStack.isEmpty) return;

    setState(() {
      final restored = _undoStack.removeLast();
      _points.addAll(restored);
      _scheduleAutoSave(); // Save after redo
    });
  }

  void clear() {
    setState(() {
      _undoStack.clear();
      _points.clear();
      _scheduleAutoSave(); // Save after clear
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _undoStack.clear(); // Clear undo stack when starting new drawing
          _points.add(
            DrawingPoint(
              offset: details.localPosition,
              paint: Paint()
                ..color = widget.tool == DrawingTool.eraser
                    ? widget.backgroundColor
                    : widget.color
                ..strokeWidth = _getStrokeWidth()
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..style = PaintingStyle.stroke
                ..blendMode = widget.tool == DrawingTool.eraser
                    ? BlendMode.clear
                    : BlendMode.srcOver,
            ),
          );
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _points.add(
            DrawingPoint(
              offset: details.localPosition,
              paint: Paint()
                ..color = widget.tool == DrawingTool.eraser
                    ? widget.backgroundColor
                    : widget.color
                ..strokeWidth = _getStrokeWidth()
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..style = PaintingStyle.stroke
                ..blendMode = widget.tool == DrawingTool.eraser
                    ? BlendMode.clear
                    : BlendMode.srcOver,
            ),
          );
        });
      },
      onPanEnd: (details) {
        setState(() {
          _points.add(null); // Mark end of path
          _scheduleAutoSave(); // Save after stroke complete
        });

        // Capture canvas size for saving
        if (_canvasSize == null) {
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            _canvasSize = renderBox.size;
          }
        }
      },
      child: CustomPaint(
        painter: DrawingPainter(points: _points),
        size: Size.infinite,
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  double _getStrokeWidth() {
    switch (widget.tool) {
      case DrawingTool.pen:
        return widget.strokeWidth;
      case DrawingTool.pencil:
        return widget.strokeWidth * 0.7;
      case DrawingTool.marker:
        return widget.strokeWidth * 2;
      case DrawingTool.eraser:
        return widget.strokeWidth * 3;
    }
  }
}

class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          points[i]!.offset,
          points[i + 1]!.offset,
          points[i]!.paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
