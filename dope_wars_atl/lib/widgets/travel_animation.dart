import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/location.dart';
import '../theme/app_theme.dart';

/// Full-screen travel animation overlay showing the actual transport sprite.
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

  Color get _accentColor {
    switch (widget.transportType) {
      case 'marta':
        return AppTheme.midtown; 
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
    // 1.5s travel duration as per spec
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
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
        child: Stack(
          children: [
            // 1. The actual Sprite Animation (Center-screen)
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return _buildSpriteWidget();
                },
              ),
            ),
            // 2. The UI Overlay
            IgnorePointer(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Text(
                    _actionLabel,
                    style: AppTheme.jersey10(size: 14, color: _accentColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.destination.name,
                    style: AppTheme.jersey15(size: 24, color: _accentColor),
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
                  Text(
                    widget.destination.description,
                    style: AppTheme.jersey15(size: 12, color: AppTheme.textSecondary),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpriteWidget() {
    if (widget.transportType == 'drive') {
      return _DriveSprite(
        controller: _controller,
        assetPath: 'assets/images/travel/drive_sheet.png',
      );
    }
    // Placeholder for MARTA/Ryde
    return Text(widget.transportType.toUpperCase(), 
      style: TextStyle(color: _accentColor, fontSize: 24));
  }
}

class _DriveSprite extends StatefulWidget {
  final AnimationController controller;
  final String assetPath;

  const _DriveSprite({
    required this.controller,
    required this.assetPath,
  });

  @override
  State<_DriveSprite> createState() => _DriveSpriteState();
}

class _DriveSpriteState extends State<_DriveSprite> {
  ui.Image? _spriteSheet;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSheet();
  }

  Future<void> _loadSheet() async {
    try {
      final ImageProvider provider = AssetImage(widget.assetPath);
      final ImageStream stream = provider.resolve(ImageConfiguration.empty);
      final Completer<ui.Image> completer = Completer();

      stream.addListener(ImageStreamListener((ImageInfo info, bool _) {
        if (!_loaded) {
          setState(() {
            _spriteSheet = info.image;
            _loaded = true;
          });
          completer.complete(info.image);
        }
      }));
      await completer.future;
    } catch (e) {
      debugPrint('Failed to load drive sprite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _spriteSheet == null) {
      return const SizedBox(width: 128, height: 128);
    }

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        int frameIdx = (widget.controller.value * 8).floor().clamp(0, 7);
        
        return CustomPaint(
          size: const Size(256, 256),
          painter: _SheetPainter(
            image: _spriteSheet!,
            frameIdx: frameIdx,
            frameWidth: 64,
            frameHeight: 64,
          ),
        );
      },
    );
  }
}

class _SheetPainter extends CustomPainter {
  final ui.Image image;
  final int frameIdx;
  final double frameWidth;
  final double frameHeight;

  _SheetPainter({
    required this.image,
    required this.frameIdx,
    required this.frameWidth,
    required this.frameHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = 4.0;
    final Rect src = Rect.fromLTWH(frameIdx * frameWidth, 0, frameWidth, frameHeight);
    final Rect dst = Rect.fromLTWH(
      (size.width - (frameWidth * scale)) / 2,
      (size.height - (frameHeight * scale)) / 2,
      frameWidth * scale,
      frameHeight * scale,
    );

    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.none);
  }

  @override
  bool shouldRepaint(covariant _SheetPainter old) => old.frameIdx != frameIdx;
}
