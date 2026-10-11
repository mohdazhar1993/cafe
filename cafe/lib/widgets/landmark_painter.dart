import 'package:flutter/material.dart';
import '../services/gesture_service.dart';

class LandmarkPainter extends CustomPainter {
  final List<LandmarkPoint> landmarks;
  final Color pointColor;
  final Color lineColor;

  LandmarkPainter({
    required this.landmarks,
    this.pointColor = const Colors.cyanAccent,
    this.lineColor = Colors.tealAccent,
  });

  // Standard Hand skeleton connectivity pairs
  static const List<List<int>> connections = [
    // Thumb
    [0, 1], [1, 2], [2, 3], [3, 4],
    // Index
    [0, 5], [5, 6], [6, 7], [7, 8],
    // Middle
    [0, 9], [9, 10], [10, 11], [11, 12],
    // Ring
    [0, 13], [13, 14], [14, 15], [15, 16],
    // Pinky
    [0, 17], [17, 18], [18, 19], [19, 20],
    // Palm base
    [5, 9], [9, 13], [13, 17],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;

    // Draw lines
    for (final conn in connections) {
      if (conn[0] < landmarks.length && conn[1] < landmarks.length) {
        final p1 = Offset(landmarks[conn[0]].x * size.width, landmarks[conn[0]].y * size.height);
        final p2 = Offset(landmarks[conn[1]].x * size.width, landmarks[conn[1]].y * size.height);
        canvas.drawLine(p1, p2, linePaint);
      }
    }

    // Draw joints
    for (final p in landmarks) {
      final center = Offset(p.x * size.width, p.y * size.height);
      canvas.drawCircle(center, 5.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LandmarkPainter oldDelegate) => true;
}
