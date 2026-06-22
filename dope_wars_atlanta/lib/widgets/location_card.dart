import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/location.dart';

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
    final accentColor = AppColors.accentForLocation(location.type.accentColor);
    final isVisited = location.isVisited;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.cardLight
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? accentColor : AppColors.cardLight,
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Location accent bar
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          location.type.displayName,
                          style: GoogleFonts.permanentMarker(
                            fontSize: 16,
                            color: isCurrent ? accentColor : AppColors.white,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'HERE',
                              style: GoogleFonts.pressStart2p(
                                fontSize: 6,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (location.type.specialFeature != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        location.type.specialFeature!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Product count
              if (isVisited)
                Text(
                  '${location.availableProducts.length} items',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 7,
                    color: AppColors.darkGray,
                  ),
                )
              else
                Text(
                  '???',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 10,
                    color: AppColors.darkGray,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppColors.darkGray,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
