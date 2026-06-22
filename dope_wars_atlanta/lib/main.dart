import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'models/game_state.dart';
import 'data/game_data.dart';
import 'services/save_service.dart';
import 'screens/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DopeWarsApp());
}

class DopeWarsApp extends StatelessWidget {
  const DopeWarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dope Wars — Atlanta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const BootScreen(),
    );
  }
}

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  @override
  void initState() {
    super.initState();
    _bootSequence();
  }

  Future<void> _bootSequence() async {
    // Brief boot screen — retro terminal nod
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Check for saved game
    final hasSave = await SaveService.hasSaveData();
    if (!mounted) return;

    if (hasSave) {
      final savedState = await SaveService.loadGame();
      if (!mounted) return;

      if (savedState != null && !savedState.isGameOver) {
        _enterGame(savedState);
        return;
      }
    }

    // No save — show new game menu
    _showNewGame();
  }

  void _showNewGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const NewGameScreen()),
    );
  }

  void _enterGame(GameState state) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameProvider(
          initialState: state,
          child: const GameScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DOPE WARS',
              style: GoogleFonts.pressStart2p(
                fontSize: 20,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ATLANTA',
              style: GoogleFonts.protestRevolution(
                fontSize: 28,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'LOADING...',
              style: GoogleFonts.pressStart2p(
                fontSize: 8,
                color: AppColors.accent.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }
}

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  Difficulty _selectedDifficulty = Difficulty.normal;
  int _selectedDuration = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DOPE WARS',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 18,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ATLANTA',
                  style: GoogleFonts.protestRevolution(
                    fontSize: 26,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 32),

                // Difficulty
                Text(
                  'DIFFICULTY',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 9,
                    color: AppColors.gray,
                  ),
                ),
                const SizedBox(height: 12),
                ...Difficulty.values.map((diff) {
                  final selected = diff == _selectedDifficulty;
                  Color color;
                  switch (diff) {
                    case Difficulty.easy:
                      color = AppColors.success;
                      break;
                    case Difficulty.normal:
                      color = AppColors.warning;
                      break;
                    case Difficulty.hard:
                      color = AppColors.danger;
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDifficulty = diff),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.15)
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? color : AppColors.cardLight,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected ? color : AppColors.darkGray,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    diff.displayName,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  Text(
                                    '\$${diff.startingCash} cash / \$${diff.startingDebt} debt',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.gray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Duration
                Text(
                  'DURATION',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 9,
                    color: AppColors.gray,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [30, 60, 90].map((days) {
                    final selected = days == _selectedDuration;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: days == 30 ? 0 : 4,
                          right: days == 90 ? 0 : 4,
                        ),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDuration = days),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.accent.withValues(alpha: 0.15)
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected ? AppColors.accent : AppColors.cardLight,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$days',
                                  style: GoogleFonts.pressStart2p(
                                    fontSize: 14,
                                    color: selected ? AppColors.accent : AppColors.gray,
                                  ),
                                ),
                                Text(
                                  'days',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: selected ? AppColors.accent : AppColors.darkGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Start button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'START GAME',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 10,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startGame() {
    final state = GameData.createNewGame(
      difficulty: _selectedDifficulty,
      totalDays: _selectedDuration,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameProvider(
          initialState: state,
          child: const GameScreen(),
        ),
      ),
    );
  }
}
