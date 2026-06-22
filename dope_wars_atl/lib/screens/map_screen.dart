import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../theme/app_theme.dart';
import '../models/location.dart';
import '../widgets/ad_overlay.dart';
import '../widgets/flame_game_map.dart';
import '../widgets/travel_animation.dart';
import '../widgets/arrival_popup.dart';

/// Full-screen pixel map of Atlanta rendered via Flame Engine.
///
/// Uses [FlameGameMap] (backed by Flame's game loop + camera system)
/// instead of the older InteractiveViewer + CustomPainter approach.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameService>(
      builder: (context, game, _) {
        if (game.showAd) {
          return AdOverlay(
            asset: game.currentAdAsset!,
            onDismiss: game.dismissAd,
          );
        }

        final state = game.state!;
        final currentId = state.currentLocationId;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            elevation: 0,
            title: Text(
              'ATLANTA',
              style: AppTheme.jersey15(size: 12, color: AppTheme.accentGreen),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textSecondary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: FlameGameMap(
            game: game,
            currentLocationId: currentId,
            onLocationTap: (locationId) =>
                _onLocationTap(context, game, locationId),
          ),
        );
      },
    );
  }

  void _onLocationTap(BuildContext context, GameService game, String locationId) {
    final state = game.state;
    if (state == null) return;
    if (locationId == state.currentLocationId) {
      _showLocationInfo(context, locationId);
      return;
    }

    final currentLoc = Location.getById(state.currentLocationId);
    final destLoc = Location.getById(locationId);
    final isConnected =
        currentLoc.martaConnections.contains(locationId) ||
        currentLoc.highwayConnections.contains(locationId);

    if (!isConnected) {
      _showNotReachable(context, destLoc.name);
      return;
    }

    _showTravelOptions(context, game, destLoc);
  }

  void _showLocationInfo(BuildContext context, String locationId) {
    final loc = Location.getById(locationId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.name,
                style: AppTheme.jersey15(size: 22, color: loc.accentColor)),
            const SizedBox(height: 4),
            Text(loc.description,
                style: AppTheme.jersey15(size: 13, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK',
                style: AppTheme.jersey10(size: 10, color: AppTheme.accentGreen)),
          ),
        ],
      ),
    );
  }

  void _showNotReachable(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('🚫 No Route',
            style: AppTheme.jersey10(size: 12, color: AppTheme.danger)),
        content: Text(
          "Can't reach $name from here.\nTry a different location first.",
          style: AppTheme.jersey15(size: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK',
                style: AppTheme.jersey10(size: 10, color: AppTheme.accentGreen)),
          ),
        ],
      ),
    );
  }

  void _showTravelOptions(BuildContext context, GameService game, Location dest) {
    final state = game.state!;
    final currentLoc = Location.getById(state.currentLocationId);
    final rydeCost = game.getRydeCost();
    final driveCost = game.getDriveCost();
    final hasRyde = state.cash >= rydeCost;
    final hasDrive = state.cash >= driveCost;
    final hasMarta = currentLoc.martaConnections.contains(dest.id) &&
        state.cash >= 5;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(dest.name,
                style: AppTheme.jersey15(size: 20, color: dest.accentColor)),
            const SizedBox(height: 4),
            const Text('🏙️', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 16),
            Text('HOW TO GET THERE?',
                style: AppTheme.jersey10(size: 10, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            if (hasMarta)
              _TravelOption(
                emoji: '🚇', label: 'MARTA', cost: '\$5',
                color: AppTheme.midtown,
                onTap: () {
                  Navigator.pop(ctx);
                  _startTravel(context, game, dest, 'marta', 5);
                },
              ),
            if (hasRyde)
              _TravelOption(
                emoji: '🚗', label: 'Ryde', cost: '\$$rydeCost',
                color: AppTheme.accentPink,
                onTap: () {
                  Navigator.pop(ctx);
                  _startTravel(context, game, dest, 'ryde', rydeCost);
                },
              ),
            if (hasDrive)
              _TravelOption(
                emoji: '🏎️', label: 'Drive', cost: '\$$driveCost',
                color: AppTheme.gold,
                onTap: () {
                  Navigator.pop(ctx);
                  _startTravel(context, game, dest, 'drive', driveCost);
                },
              ),
            if (!hasMarta && !hasRyde && !hasDrive)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Not enough cash for any transport!',
                    style: TextStyle(color: AppTheme.danger)),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CANCEL',
                  style: AppTheme.jersey10(size: 10, color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  void _startTravel(BuildContext context, GameService game, Location dest,
      String mode, int cost) {
    // Play travel animation via existing overlay
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TravelAnimationScreen(
          transportType: mode,
          destination: dest,
          onArrive: () => Navigator.pop(context),
        ),
      ),
    ).then((_) async {
      if (!context.mounted) return;
      late bool encounter;
      switch (mode) {
        case 'marta':
          encounter = await game.travelByMarta(dest.id);
          break;
        case 'ryde':
          encounter = await game.travelByRyde(dest.id);
          break;
        case 'drive':
          encounter = await game.travelByDrive(dest.id);
          break;
        default:
          encounter = false;
      }
      if (context.mounted && !encounter) {
        // Show arrival popup
        _showArrivalPopup(context, game, dest);
      }
    });
  }

  void _showArrivalPopup(BuildContext context, GameService game, Location dest) {
    showDialog(
      context: context,
      builder: (ctx) => ArrivalPopup(location: dest, game: game),
    );
  }
}

// ---- Travel Option Tile ----

class _TravelOption extends StatelessWidget {
  final String emoji;
  final String label;
  final String cost;
  final Color color;
  final VoidCallback onTap;

  const _TravelOption({
    required this.emoji,
    required this.label,
    required this.cost,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: AppTheme.jersey15(size: 18, color: color)),
            ),
            Text(cost,
                style: AppTheme.jersey10(size: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
