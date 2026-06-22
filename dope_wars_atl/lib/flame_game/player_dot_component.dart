import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../utils/location_coords.dart';

/// Green pulsing player indicator dot on the map.
///
/// Drawn at the player's current location with a pulsing glow ring.
class PlayerDotComponent extends Component {
  final String currentLocationId;
  double _time = 0;

  PlayerDotComponent({required this.currentLocationId});

  void updateLocation(String newId) {
    // For simplicity we store it directly; in a full implementation
    // this would check for changes before re-rendering.
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final pos = locationCoords[currentLocationId];
    if (pos == null) return;

    final pulseScale = 0.8 + (sin(_time * 2) + 1) / 2 * 0.2;
    final radius = 8.0 * pulseScale;

    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00ff9d).withAlpha(77)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(pos, radius + 8, glowPaint);

    // Main green dot
    canvas.drawCircle(pos, radius, Paint()..color = const Color(0xFF00ff9d));

    // Inner bright dot
    canvas.drawCircle(
      pos,
      radius * 0.4,
      Paint()..color = const Color(0xFFccffdd),
    );

    // Pulsing ring
    final pulseValue = (sin(_time * 2) + 1) / 2;
    final ringPaint = Paint()
      ..color = const Color(0xFF00ff9d)
          .withAlpha((153 - pulseValue * 102).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      pos,
      radius + 4 + pulseValue * 4,
      ringPaint,
    );
  }
}
