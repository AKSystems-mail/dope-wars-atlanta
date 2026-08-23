import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../models/location.dart';
import '../services/game_service.dart';
import '../theme/app_theme.dart';
import '../utils/location_coords.dart';
import 'map_node_component.dart';
import 'connection_line_component.dart';
import 'player_dot_component.dart';

/// The FlameGame that renders the interactive Atlanta map.
///
/// Draws location nodes, connection lines (MARTA / highway), and
/// a green player indicator dot.  Uses the same 1000x1000 world
/// coordinate system as the original CustomPainter-based map.
///
/// Tap detection and pan/zoom are handled by the parent Flutter
/// widget ([FlameGameMap]) — this game only concerns itself with
/// rendering and the update loop (pulse animations).
class DopeWarsGame extends FlameGame {
  final GameService gameService;
  final String currentLocationId;

  DopeWarsGame({
    required this.gameService,
    required this.currentLocationId,
  });

  @override
  Color backgroundColor() => AppTheme.background;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // v3: real Atlanta highway map as the base layer
    final bg = await images.load('map_background_v3.jpg'); // images/ prefix is implicit
    add(SpriteComponent(sprite: Sprite(bg), size: Vector2(606, 1280)));

    // ── Build set of travelable connections (undirected) ──
    final travelableIds = Location.travelable.map((l) => l.id).toSet();

    // Collect unique undirected edges from both connection types
    _addConnections(
      routeType: 'marta',
      color: AppTheme.midtown.withAlpha(100),
    );
    _addConnections(
      routeType: 'highway',
      color: AppTheme.gold.withAlpha(80),
    );

    // ── Location nodes ──
    for (final loc in Location.travelable) {
      add(MapNodeComponent(
        location: loc,
        isCurrent: loc.id == currentLocationId,
        onTap: () {}, // handled by parent widget
      ));
    }
    // Also render non-travelable nodes (greyed out)
    for (final loc in Location.defaults) {
      if (!travelableIds.contains(loc.id)) {
        add(MapNodeComponent(
          location: loc,
          isCurrent: loc.id == currentLocationId,
          onTap: () {},
        ));
      }
    }

    // ── Player dot ──
    add(PlayerDotComponent(currentLocationId: currentLocationId));
  }

  void _addConnections({required String routeType, required Color color}) {
    if (routeType == 'marta') return; // v3: MARTA lines removed from map
    final drawn = <String>{};
    for (final loc in Location.defaults) {
      final connections = routeType == 'marta'
          ? loc.martaConnections
          : loc.highwayConnections;

      final fromPos = locationCoords[loc.id];
      if (fromPos == null) continue;

      for (final destId in connections) {
        final edgeKey = [loc.id, destId]..sort();
        final edgeStr = edgeKey.join('->');
        if (drawn.contains(edgeStr)) continue;
        drawn.add(edgeStr);

        final toPos = locationCoords[destId];
        if (toPos == null) continue;

        add(ConnectionLineComponent(
          from: fromPos,
          to: toPos,
          color: color,
        ));
      }
    }
  }
}
