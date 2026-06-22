import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Draws a dashed connection line between two locations on the map.
///
/// Used for MARTA (blue) and highway (orange) connections.
class ConnectionLineComponent extends Component {
  final Offset from;
  final Offset to;
  final Color color;
  final double dashLength;
  final double gapLength;

  ConnectionLineComponent({
    required this.from,
    required this.to,
    required this.color,
    this.dashLength = 8,
    this.gapLength = 6,
  });

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()..moveTo(from.dx, from.dy)..lineTo(to.dx, to.dy);
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = min(distance + dashLength, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += dashLength + gapLength;
      }
    }
  }
}
