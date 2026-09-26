import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flame/game.dart' hide Matrix4;
import '../models/location.dart';
import '../services/game_service.dart';
import '../theme/app_theme.dart';
import '../flame_game/dope_wars_game.dart';
import '../utils/location_coords.dart';

/// Flutter widget that wraps the Flame [DopeWarsGame] with pan/zoom
/// (via InteractiveViewer) and location-tap detection.
///
/// This is the direct replacement for [PixelMap] — same coordinate
/// system, same interaction pattern, but backed by Flame's game loop.
class FlameGameMap extends StatefulWidget {
  final GameService game;
  final String currentLocationId;
  final void Function(String locationId) onLocationTap;

  const FlameGameMap({
    super.key,
    required this.game,
    required this.currentLocationId,
    required this.onLocationTap,
  });

  @override
  State<FlameGameMap> createState() => _FlameGameMapState();
}

class _FlameGameMapState extends State<FlameGameMap> {
  /// v3 map source dimensions (606x1280).
  static const double _mapW = 606;
  static const double _mapH = 1280;

  /// How close a tap must land to a location's source-pixel coordinate.
  static const double _tapRadius = 36;

  final TransformationController _transformCtrl = TransformationController();
  late DopeWarsGame _flameGame;

  /// The actual viewport the map is painted into — the Scaffold body, which is
  /// NOT MediaQuery.size (that includes the app bar, so centring against it
  /// threw the map ~half an app bar off and left dead space up top).
  Size _viewport = Size.zero;

  @override
  void initState() {
    super.initState();
    _flameGame = DopeWarsGame(
      gameService: widget.game,
      currentLocationId: widget.currentLocationId,
    );
    // Runs after the first build, so _viewport is already measured.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerOnLocation(widget.currentLocationId);
    });
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  /// Cover-scale: fill the viewport edge to edge so the map can never float in
  /// dead space. Fit-scale would letterbox on any aspect mismatch.
  double _coverScale(Size v) => math.max(v.width / _mapW, v.height / _mapH);

  void _centerOnLocation(String locationId) {
    final coords = locationCoords[locationId];
    if (coords == null || _viewport == Size.zero) return;

    final scale = _coverScale(_viewport);

    // Aim the current location at the middle, then clamp so the scaled map
    // still covers the viewport: centred where it can be, never a gap.
    final minX = _viewport.width - _mapW * scale;
    final minY = _viewport.height - _mapH * scale;
    final dx = (_viewport.width / 2 - coords.dx * scale).clamp(minX, 0.0).toDouble();
    final dy = (_viewport.height / 2 - coords.dy * scale).clamp(minY, 0.0).toDouble();

    _transformCtrl.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  void _onTapUp(TapUpDetails details) {
    // details.localPosition is ALREADY in map/source-pixel space: this
    // GestureDetector is the InteractiveViewer's child, so hit-testing has
    // already undone the pan/zoom transform on the way in. Applying the
    // inverse transform here (as this used to) double-counted it, so the
    // computed point landed nowhere near any location and every tap missed.
    final mapPos = details.localPosition;

    for (final loc in Location.defaults) {
      final coord = locationCoords[loc.id];
      if (coord == null) continue;
      if ((mapPos - coord).distance < _tapRadius) {
        widget.onLocationTap(loc.id);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measured here (not in initState) because we need the real body size.
        _viewport = Size(constraints.maxWidth, constraints.maxHeight);
        return InteractiveViewer(
          transformationController: _transformCtrl,
          minScale: 0.5,
          maxScale: 3.0,
          constrained: false,
          // No slack beyond the map's own bounds, so panning can't expose
          // empty space around the image.
          boundaryMargin: EdgeInsets.zero,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: _onTapUp,
            child: SizedBox(
              width: _mapW,
              height: _mapH,
              child: GameWidget(
                game: _flameGame,
                loadingBuilder: (_) => const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentGreen),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
