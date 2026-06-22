import 'package:flutter/material.dart';
import '../models/location.dart';
import '../theme/app_theme.dart';

class LocationCard extends StatelessWidget {
  final Location location;
  final bool isCurrent;
  final VoidCallback? onTap;

  const LocationCard({
    super.key,
    required this.location,
    this.isCurrent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.pixelCard(
            accentColor: location.accentColor,
            isActive: isCurrent,
          ),
          child: Row(
            children: [
              // Location icon (emoji based on type)
              Text(_locationEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: AppTheme.jersey15(size: 22,
                        color: isCurrent
                            ? location.accentColor
                            : AppTheme.textPrimary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location.description,
                      style: AppTheme.jersey15(size: 13,
                        color: AppTheme.textSecondary,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Product emojis
              if (location.products.isNotEmpty)
                Text(
                  location.products.map((p) => p.emoji).join(' '),
                  style: const TextStyle(fontSize: 18),
                ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: AppTheme.pixelBorder(
                    color: AppTheme.accentGreen,
                    fillColor: AppTheme.accentGreen.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    'HERE',
                    style: AppTheme.jersey10(size: 10,
                      color: AppTheme.accentGreen,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _locationEmoji {
    if (location.isBank) return '🏦';
    if (location.isWeaponShop) return '🔫';
    if (location.isCouncilman) return '🧑‍⚖️';
    if (location.isBookbagUpgrade) return '🎒';
    switch (location.id) {
      case 'airport': return '✈️';
      case 'hapeville': return '🏠';
      case 'cobb': return '🏔️';
      default: return '📍';
    }
  }
}
