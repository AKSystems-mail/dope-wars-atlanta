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
  final TransformationController _transformCtrl = TransformationController();
  late DopeWarsGame _flameGame;

  @override
  void initState() {
    super.initState();
    _flameGame = DopeWarsGame(
      gameService: widget.game,
      currentLocationId: widget.currentLocationId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerOnLocation(widget.currentLocationId);
    });
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  void _centerOnLocation(String locationId) {
    final coords = locationCoords[locationId];
    if (coords == null) return;
    final screenSize = MediaQuery.of(context).size;
    final scale = screenSize.width / 606.0; // v3 map source width
    final dx = screenSize.width / 2 - coords.dx * scale;
    final dy = screenSize.height / 2 - coords.dy * scale;
    _transformCtrl.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  void _onTapUp(TapUpDetails details) {
    // Convert screen coordinates to world (map) coordinates
    final matrix = _transformCtrl.value;
    final inverse = Matrix4.inverted(matrix);
    final mapPos = MatrixUtils.transformPoint(inverse, details.localPosition);

    for (final loc in Location.defaults) {
      final coord = locationCoords[loc.id];
      if (coord == null) continue;
      final dist = (mapPos - coord).distance;
      if (dist < 28) {
        widget.onLocationTap(loc.id);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformCtrl,
      minScale: 0.5,
      maxScale: 3.0,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(100),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: _onTapUp,
        child: SizedBox(
          width: 606, // v3 map source dimensions (606x1280)
          height: 1280,
          child: GameWidget(
            game: _flameGame,
            loadingBuilder: (_) => const Center(
              child: CircularProgressIndicator(color: AppTheme.accentGreen),
            ),
          ),
        ),
      ),
    );
  }
}
