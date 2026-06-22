import 'package:flutter/material.dart';
import '../models/location.dart';
import '../theme/app_theme.dart';
import '../utils/location_emoji.dart';

/// Retro arrival popup shown when the player reaches a new location.
///
/// Displays the location name, emoji, description, and quick stats
/// (available features: bank, weapon shop, councilman, bookbag upgrade).
class ArrivalPopup extends StatelessWidget {
  final Location location;
  final dynamic game;

  const ArrivalPopup({
    super.key,
    required this.location,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final features = <Widget>[];
    if (location.isBank) {
      features.add(_FeatureBadge(emoji: '🏦', label: 'Bank'));
    }
    if (location.isWeaponShop) {
      features.add(_FeatureBadge(emoji: '🔫', label: 'Weapons'));
    }
    if (location.isCouncilman) {
      features.add(_FeatureBadge(emoji: '🧑‍⚖️', label: 'Councilman'));
    }
    if (location.isBookbagUpgrade) {
      features.add(_FeatureBadge(emoji: '🎒', label: 'Upgrades'));
    }

    return AlertDialog(
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Location emoji
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: location.accentColor.withValues(alpha: 0.15),
              border: Border.all(color: location.accentColor, width: 1),
            ),
            child: Text(
              locationEmojis[location.id] ?? '📍',
              style: const TextStyle(fontSize: 48),
            ),
          ),
          const SizedBox(height: 12),

          // Arrival text
          Text(
            'ARRIVED AT',
            style: AppTheme.jersey10(size: 9,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),

          // Location name
          Text(
            location.name.toUpperCase(),
            style: AppTheme.jersey10(size: 14,
              color: location.accentColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            location.description,
            style: AppTheme.jersey15(size: 13,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Available features
          if (features.isNotEmpty) ...[
            Text(
              'FEATURES',
              style: AppTheme.jersey10(size: 8,
                color: AppTheme.accentGreen,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: features,
            ),
            const SizedBox(height: 8),
          ],

          // Cash display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.background,
              border: Border.all(
                color: AppTheme.accentGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💰', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  '\$${game.state?.cash ?? 0}',
                  style: AppTheme.jersey10(size: 11,
                    color: AppTheme.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: AppTheme.pixelButton(color: AppTheme.accentGreen),
            child: Text(
              'LET\'S GO!',
              style: AppTheme.jersey10(size: 10,
                color: AppTheme.background,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final String emoji;
  final String label;

  const _FeatureBadge({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.jersey10(size: 8,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
