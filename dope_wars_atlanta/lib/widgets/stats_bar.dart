import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/game_state.dart';

class StatsBar extends StatelessWidget {
  final GameState state;
  final VoidCallback? onSettingsTap;

  const StatsBar({super.key, required this.state, this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // Cash
          _StatItem(
            label: '\$',
            value: _formatCash(state.cash),
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          // Debt
          if (state.debt > 0)
            _StatItem(
              label: 'DEBT',
              value: '\$${_formatCash(state.debt)}',
              color: AppColors.danger,
            )
          else
            _StatItem(
              label: 'DEBT',
              value: 'PAID',
              color: AppColors.success,
            ),
          const SizedBox(width: 8),
          // Day
          _StatItem(
            label: 'DAY',
            value: '${state.currentDay}/${state.totalDays}',
            color: AppColors.accent2,
          ),
          const SizedBox(width: 8),
          // Bag
          _StatItem(
            label: 'BAG',
            value: '${state.totalInventoryCount}/${state.bagCapacity}',
            color: AppColors.gray,
          ),
          const Spacer(),
          // Settings gear
          if (onSettingsTap != null)
            GestureDetector(
              onTap: onSettingsTap,
              child: const Icon(
                Icons.settings,
                color: AppColors.gray,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  String _formatCash(int amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toString();
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: GoogleFonts.pressStart2p(
            fontSize: 8,
            color: AppColors.darkGray,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.pressStart2p(
            fontSize: 8,
            color: color,
          ),
        ),
      ],
    );
  }
}
