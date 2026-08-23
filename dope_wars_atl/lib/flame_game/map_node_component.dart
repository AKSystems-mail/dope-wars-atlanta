import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../utils/location_emoji.dart';
import '../utils/location_coords.dart';
import '../models/location.dart';
/// A location node on the map
/// A location node on the map: colored circle with text label.
///
/// Uses the same coordinate system (1000x1000 world space) and
/// accent colors as the original CustomPainter pixel map.
class MapNodeComponent extends Component {
  final Location location;
  final bool isCurrent;
  final VoidCallback onTap;

  double _time = 0;

  MapNodeComponent({
    required this.location,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  bool containsPoint(Vector2 point) {
    final pos = locationCoords[location.id];
    if (pos == null) return false;
    final dx = point.x - pos.dx;
    final dy = point.y - pos.dy;
    return sqrt(dx * dx + dy * dy) < 28;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final pos = locationCoords[location.id];
    if (pos == null) return;

    final accent = locationAccents[location.id] ?? Colors.white;
    const double circleRadius = 16.0;
    final radius = isCurrent ? circleRadius * 1.3 : circleRadius;
    final pulseValue = (sin(_time * 2) + 1) / 2; // 0..1 oscillator

    // Outer glow (current location)
    if (isCurrent) {
      final glowPaint = Paint()
        ..color = accent.withAlpha(64)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawCircle(pos, radius + 8, glowPaint);
    }

    // Fill circle
    final fillPaint = Paint()
      ..color = accent.withAlpha(90)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, radius, fillPaint);

    // Stroke circle
    final strokePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(pos, radius, strokePaint);

    // Inner dot
    canvas.drawCircle(pos, 4, Paint()..color = accent);

    // Pulsing ring (current location)
    if (isCurrent) {
      final ringPaint = Paint()
        ..color = accent.withAlpha((128 - pulseValue * 77).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(pos, radius + 4 + pulseValue * 6, ringPaint);
    }

    // Text label below circle
    final displayName = _displayName(location.id);
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      fontFamily: 'monospace',
      shadows: const [
        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
        Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 0)),
      ],
    );

    final builder = TextPainter(
      text: TextSpan(text: displayName, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    builder.layout();

    final labelPos = Offset(
      pos.dx - builder.width / 2,
      pos.dy + radius + 6,
    );

    // Semi-transparent background pill
    final bgRect = Rect.fromLTWH(
      labelPos.dx - 5,
      labelPos.dy - 2,
      builder.width + 10,
      builder.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      Paint()..color = Colors.black54,
    );
    builder.paint(canvas, labelPos);
  }

  String _displayName(String id) {
    const names = {
      'west_end': 'West End',
      'midtown': 'Midtown',
      'little_five': 'Little Five',
      'buckhead': 'Buckhead',
      'decatur': 'Decatur',
      'cobb': 'Cobb County',
    };
    return names[id] ?? id;
  }
}
