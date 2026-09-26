import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/game_service.dart';
import '../theme/app_theme.dart';
import 'neon_widgets.dart';

/// Pixel-art styled HUD overlay for the game screen.
///
/// Shows: day count, time of day, cash, debt, bag space, and settings gear.
class PixelHud extends StatelessWidget {
  final GameService game;

  const PixelHud({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final state = game.state!;
    final isLateGame = state.day / state.maxDays > 0.75;
    final timeLabel = _formatTime(state.gameHour);

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
      // Wrap, not Row: at 1.5x this bar no longer fits one line on a phone,
      // and a wrapped second line beats a clipped/overflowing one.
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Day counter
          _HudItem(
            label: 'DAY ${state.day}/${state.maxDays}',
            color: isLateGame ? AppTheme.danger : AppTheme.accentGreen,
          ),
          const SizedBox(width: 12),

          // Heat, Progressive only, and as a state word rather than a number
          // (D9). Classic never shows it — the player should suspect, not audit.
          if (state.isProgressive) ...[
            _HudItem(
              label: 'HEAT ${state.heatLabel.toUpperCase()}',
              color: state.heatLabel == 'Hot'
                  ? AppTheme.danger
                  : (state.heatLabel == 'Warm'
                      ? AppTheme.gold
                      : AppTheme.textSecondary),
            ),
            const SizedBox(width: 12),
          ],

          // Time
          _HudItem(
            label: timeLabel,
            color: AppTheme.gold,
          ),

          // Bank balance (only meaningful once you've used the Bank)
          if (state.bankBalance > 0) ...[
            _HudItem(
              label: 'B\$${state.bankBalance}',
              color: AppTheme.midtown,
            ),
            const SizedBox(width: 12),
          ],

          // Cash
          _HudItem(
            label: '\$${state.cash}',
            color: AppTheme.gold,
          ),

          const SizedBox(width: 12),

          // Debt
          if (state.debt > 0)
            _HudItem(
              label: '\$${state.debt}',
              color: AppTheme.danger,
            ),

          if (state.debt > 0) const SizedBox(width: 12),

          // Bag space
          _HudItem(
            label: '${state.bagUsed}/${state.bagCapacity}',
            color: state.bagUsed >= state.bagCapacity * 0.8
                ? AppTheme.gold
                : AppTheme.textSecondary,
          ),

          const SizedBox(width: 8),

          // Settings gear
          GestureDetector(
            onTap: () => _showMenu(context, game),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: AppTheme.surface,
              ),
              child: const Text('⚙️', style: TextStyle(fontSize: 20)),
            ),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context, GameService game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('MENU',
                style: AppTheme.jersey15(
                    size: 16, color: AppTheme.accentGreen)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Text('⚙️', style: TextStyle(fontSize: 22)),
              title: Text('Settings',
                  style: AppTheme.jersey15(size: 16, color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                // Settings sheet opens from GameScreen via callback
                if (game.state != null) {
                  _showSettings(context, game);
                }
              },
            ),
            ListTile(
              leading: const Text('🔄', style: TextStyle(fontSize: 22)),
              title: Text('New Game',
                  style: AppTheme.jersey15(size: 16, color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    backgroundColor: AppTheme.card,
                    title: Text('Start Over?',
                        style: AppTheme.jersey15(
                            size: 16, color: AppTheme.accentPink)),
                    content: Text(
                        'This will wipe your current save.',
                        style: AppTheme.jersey15(
                            size: 14, color: AppTheme.textSecondary)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx),
                        child: Text('Cancel',
                            style: AppTheme.jersey10(size: 10)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dCtx);
                          game.newGame();
                        },
                        child: Text('Confirm',
                            style: AppTheme.jersey10(
                                size: 10, color: AppTheme.danger)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context, GameService game) {
    String difficulty = game.state?.difficulty ?? 'normal';
    int maxDays = game.state?.maxDays ?? 30;
    bool soundEnabled = game.state?.soundEnabled ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text('SETTINGS',
                    style: AppTheme.jersey15(
                        size: 20, color: AppTheme.accentGreen)),
              ),
              const SizedBox(height: 24),

              // Difficulty
              Text('Difficulty',
                  style: AppTheme.jersey10(
                      size: 10, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: ['easy', 'normal', 'hard'].map((d) {
                  final selected = difficulty == d;
                  final color = d == 'easy'
                      ? AppTheme.accentGreen
                      : d == 'normal'
                          ? AppTheme.gold
                          : AppTheme.danger;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: NeonBorderButton(
                        label: GameState.difficultyDisplayName(d),
                        onPressed: () {
                          setSheetState(() => difficulty = d);
                        },
                        neonColor: color,
                        selected: selected,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Game Duration
              Text('Game Duration',
                  style: AppTheme.jersey10(
                      size: 10, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [30, 60, 90].map((d) {
                  final selected = maxDays == d;
                  final color = AppTheme.accentPink;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: NeonBorderButton(
                        label: '${d}d',
                        onPressed: () {
                          setSheetState(() => maxDays = d);
                        },
                        neonColor: color,
                        selected: selected,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Sound toggle
              Row(
                children: [
                  Text('Sound',
                      style: AppTheme.jersey10(
                          size: 10, color: AppTheme.textSecondary)),
                  const Spacer(),
                  Switch(
                    value: soundEnabled,
                    onChanged: (v) {
                      setSheetState(() => soundEnabled = v);
                    },
                    activeColor: AppTheme.accentGreen,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    game.updateSettings(
                      difficulty: difficulty,
                      maxDays: maxDays,
                      soundEnabled: soundEnabled,
                    );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: AppTheme.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('SAVE',
                      style: AppTheme.jersey10(size: 10)),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel',
                      style: AppTheme.jersey10(
                          size: 10, color: AppTheme.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int hour) {
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour $amPm';
  }
}

class _HudItem extends StatelessWidget {
  final String label;
  final Color color;

  const _HudItem({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTheme.jersey10(
        size: 11,
        color: color,
      ),
    );
  }
}
