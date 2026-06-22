import 'dart:math';
import 'package:flutter/material.dart';
import '../models/location.dart';
import '../theme/app_theme.dart';

/// Full-screen travel animation overlay shown for ~5 seconds
/// before the player arrives at the destination.
class TravelAnimationScreen extends StatefulWidget {
  final String transportType; // 'marta', 'ryde', 'drive'
  final Location destination;
  final VoidCallback onArrive;

  const TravelAnimationScreen({
    super.key,
    required this.transportType,
    required this.destination,
    required this.onArrive,
  });

  @override
  State<TravelAnimationScreen> createState() => _TravelAnimationScreenState();
}

class _TravelAnimationScreenState extends State<TravelAnimationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  String get _actionLabel {
    switch (widget.transportType) {
      case 'marta':
        return 'ON THE MARTA...';
      case 'ryde':
        return 'RIDING...';
      case 'drive':
        return 'DRIVING I-285...';
      default:
        return 'TRAVELING...';
    }
  }

  String get _emoji {
    switch (widget.transportType) {
      case 'marta':
        return '🚇';
      case 'ryde':
        return '🚗';
      case 'drive':
        return '🏎️';
      default:
        return '📍';
    }
  }

  Color get _accentColor {
    switch (widget.transportType) {
      case 'marta':
        return AppTheme.midtown; // teal
      case 'ryde':
        return AppTheme.accentPink;
      case 'drive':
        return AppTheme.gold;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _progress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onArrive();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                const Spacer(flex: 2),
                // Transport icon with bounce
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final bounce =
                        sin(_progress.value * pi * 4) * 10;
                    return Transform.translate(
                      offset: Offset(0, bounce),
                      child: Text(
                        _emoji,
                        style: TextStyle(
                          fontSize: 72,
                          color: _accentColor,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Action label
                Text(
                  _actionLabel,
                  style: AppTheme.jersey10(size: 14,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                // Destination name
                Text(
                  widget.destination.name,
                  style: AppTheme.jersey15(size: 24,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 24),
                // Progress bar
                Container(
                  width: 200,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progress.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Location subtitle
                Text(
                  widget.destination.description,
                  style: AppTheme.jersey15(size: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(flex: 2),
                // Road / track animation at bottom
                SizedBox(
                  height: 40,
                  child: Stack(
                    children: [
                      // Road line
                      Positioned(
                        top: 18,
                        left: 0,
                        right: 0,
                        child: CustomPaint(
                          painter: _RoadLinePainter(
                            progress: _progress.value,
                            color: _accentColor,
                          ),
                          size: const Size(double.infinity, 4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Paints dashed road lines that scroll left-to-right
class _RoadLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RoadLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2;

    const dashWidth = 20.0;
    const gapWidth = 15.0;
    final totalWidth = dashWidth + gapWidth;
    final offset = (progress * totalWidth * 3) % totalWidth;

    double x = -offset;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + dashWidth, 0),
        paint,
      );
      x += totalWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _RoadLinePainter old) =>
      old.progress != progress;
}
