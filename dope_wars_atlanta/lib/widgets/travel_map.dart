import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/game_state.dart';
import '../models/location.dart';

class TravelMap extends StatefulWidget {
  final GameState state;
  final void Function(LocationType destination, TravelMode mode) onTravel;
  final VoidCallback onClose;

  const TravelMap({
    super.key,
    required this.state,
    required this.onTravel,
    required this.onClose,
  });

  @override
  State<TravelMap> createState() => _TravelMapState();
}

class _TravelMapState extends State<TravelMap> {
  bool _showHighwayMap = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  _showHighwayMap ? '🚗 DRIVE / RYDE' : '🚇 MARTA',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 10,
                    color: AppColors.accent,
                  ),
                ),
                const Spacer(),
                // Map toggle
                GestureDetector(
                  onTap: () => setState(() => _showHighwayMap = !_showHighwayMap),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _showHighwayMap ? '🚇 MARTA' : '🛣️ HIGHWAY',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 6,
                        color: AppColors.accent2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onClose,
                  child: const Icon(Icons.close, color: AppColors.gray, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Map content
          if (_showHighwayMap)
            _buildHighwayMap()
          else
            _buildMartaMap(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMartaMap() {
    final locations = LocationType.values
        .where((l) => l != LocationType.cobbCounty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: locations.map((loc) {
          final isCurrent = loc == widget.state.currentLocation;
          final accent = AppColors.accentForLocation(loc.accentColor);

          return Column(
            children: [
              // Location node
              _MapNode(
                location: loc,
                accentColor: accent,
                isCurrent: isCurrent,
                onTap: () {
                  if (!isCurrent) {
                    _showTransportPicker(loc);
                  }
                },
              ),
              // Rail line connector (not after last)
              if (loc != locations.last)
                Container(
                  width: 2,
                  height: 24,
                  color: accent.withValues(alpha: 0.4),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHighwayMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Highway schematic - simplified layout
          _buildHighwaySegment(
            label: 'I-285 (Perimeter)',
            color: AppColors.midtownBlue,
            locations: const [
              LocationType.westEnd,
              LocationType.decatur,
              LocationType.midtown,
            ],
          ),
          const SizedBox(height: 8),
          _buildHighwaySegment(
            label: 'I-75 / I-85 (Downtown Connector)',
            color: AppColors.westEndRed,
            locations: const [
              LocationType.buckhead,
              LocationType.midtown,
            ],
          ),
          const SizedBox(height: 8),
          _buildHighwaySegment(
            label: 'I-75 N (Cobb Extension)',
            color: AppColors.cobbGray,
            locations: const [
              LocationType.midtown,
              LocationType.cobbCounty,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighwaySegment({
    required String label,
    required Color color,
    required List<LocationType> locations,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.pressStart2p(
              fontSize: 7,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: locations.map((loc) {
              final isCurrent = loc == widget.state.currentLocation;
              final canTravel = loc != widget.state.currentLocation;

              return Expanded(
                child: GestureDetector(
                  onTap: canTravel
                      ? () => _showTransportPicker(loc, highway: true)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? color.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCurrent
                            ? color
                            : color.withValues(alpha: 0.2),
                        width: isCurrent ? 1.5 : 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isCurrent
                              ? Icons.location_on
                              : Icons.location_on_outlined,
                          color: isCurrent ? color : AppColors.gray,
                          size: 16,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.displayName,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 6,
                            color: isCurrent ? AppColors.white : AppColors.gray,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showTransportPicker(LocationType destination, {bool highway = false}) {
    List<MapEntry<String, TravelMode>> options;

    if (destination == LocationType.cobbCounty) {
      options = [
        MapEntry('🚗 Ryde (\$25-\$60)', TravelMode.ryde),
        MapEntry('🚙 Drive (\$20)', TravelMode.drive),
      ];
    } else if (highway) {
      options = [
        MapEntry('🚗 Ryde (\$25-\$60)', TravelMode.ryde),
        MapEntry('🚙 Drive (\$20)', TravelMode.drive),
      ];
    } else {
      options = [
        MapEntry('🚇 MARTA (\$5)', TravelMode.marta),
        MapEntry('🚗 Ryde (\$25-\$60)', TravelMode.ryde),
        MapEntry('🚙 Drive (\$20)', TravelMode.drive),
      ];
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Travel to ${destination.displayName}',
              style: GoogleFonts.permanentMarker(
                fontSize: 18,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context); // close travel map
                    widget.onTravel(destination, opt.value);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardLight,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.all(14),
                  ),
                  child: Text(
                    opt.key,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppColors.gray),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapNode extends StatelessWidget {
  final LocationType location;
  final Color accentColor;
  final bool isCurrent;
  final VoidCallback onTap;

  const _MapNode({
    required this.location,
    required this.accentColor,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCurrent ? null : onTap,
      child: Row(
        children: [
          // Station dot
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? accentColor : AppColors.card,
              border: Border.all(
                color: isCurrent ? accentColor : AppColors.darkGray,
                width: 2,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Icon(
                isCurrent ? Icons.train : Icons.train_outlined,
                color: isCurrent ? AppColors.background : AppColors.darkGray,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Location name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? accentColor : AppColors.white,
                  ),
                ),
                if (location.specialFeature != null)
                  Text(
                    location.specialFeature!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.gray,
                    ),
                  ),
              ],
            ),
          ),
          if (!isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'GO',
                style: GoogleFonts.pressStart2p(
                  fontSize: 7,
                  color: accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
