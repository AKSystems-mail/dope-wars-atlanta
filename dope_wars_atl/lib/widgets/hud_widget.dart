import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/game_service.dart';
import 'package:provider/provider.dart';

class HudWidget extends StatelessWidget {
  const HudWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameService>(
      builder: (context, game, _) {
        final state = game.state;
        if (state == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.background.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.accentGreen.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Cash
              _HudItem(
                label: '\$${_formatNumber(state.cash)}',
                color: AppTheme.accentGreen,
              ),
              // Bank balance (always show)
              if (state.bankBalance > 0)
                _HudItem(
                  label: 'B\$${_formatNumber(state.bankBalance)}',
                  color: AppTheme.midtown,
                ),
              // Debt
              if (state.debt > 0)
                _HudItem(
                  label: 'D\$${_formatNumber(state.debt)}',
                  color: AppTheme.accentPink,
                ),
              // Day
              _HudItem(
                label: 'D${state.day}/${state.maxDays}',
                color: AppTheme.textSecondary,
              ),
              // Time of day
              _HudItem(
                label: state.timeOfDayLabel,
                color: state.rydeSurgeMultiplier > 1.0
                    ? AppTheme.danger
                    : AppTheme.textSecondary,
              ),
              // Bag
              _HudItem(
                label: '📦${state.inventoryCount}',
                color: AppTheme.gold,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    }
    return n.toString();
  }
}

class _HudItem extends StatelessWidget {
  final String label;
  final Color color;

  const _HudItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTheme.jersey10(size: 10,
        color: color,
      ),
    );
  }
}
