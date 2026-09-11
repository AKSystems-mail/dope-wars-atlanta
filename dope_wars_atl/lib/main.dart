import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/game_service.dart';
import 'screens/boot_screen.dart';
import 'screens/game_screen.dart';
import 'widgets/hud_widget.dart';
import 'widgets/encounter_overlay.dart';
import 'widgets/ad_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Crash reporting to Firebase (project dw-atl). Deliberately best-effort: if
  // Firebase cannot start - offline first launch, or web where there is no
  // google-services config - the game must still run.
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (_) {
    // Best effort only. The ErrorWidget below still surfaces errors on screen.
  }

  // Release builds otherwise paint a featureless gray box for any build/paint
  // exception, which makes a device-only bug nearly impossible to diagnose.
  // Show the actual message instead. Debug keeps Flutter's richer red screen.
  // Deliberately built from raw widgets only: ErrorWidget must not depend on
  // AppTheme or fonts, which could themselves be what is failing.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            color: const Color(0xFF1a1625),
            padding: const EdgeInsets.all(12),
            alignment: Alignment.topLeft,
            child: SingleChildScrollView(
              child: Text(
                '${details.exceptionAsString()}\n\n${details.stack ?? ''}',
                style: const TextStyle(
                  color: Color(0xFFff4081),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        );
  }

  runApp(const DopeWarsApp());
}

class DopeWarsApp extends StatelessWidget {
  const DopeWarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameService()..init(),
      child: MaterialApp(
        title: 'Dope Wars ATL',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const GameWrapper(),
      ),
    );
  }
}

class GameWrapper extends StatelessWidget {
  const GameWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameService>(
      builder: (context, game, _) {
        if (game.loading) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentGreen,
              ),
            ),
          );
        }

        return _GameRoot(game: game);
      },
    );
  }
}

class _GameRoot extends StatefulWidget {
  final GameService game;

  const _GameRoot({required this.game});

  @override
  State<_GameRoot> createState() => _GameRootState();
}

class _GameRootState extends State<_GameRoot> {
  bool _showBoot = true;

  @override
  Widget build(BuildContext context) {
    if (_showBoot) {
      return BootScreen(
        onComplete: () => setState(() => _showBoot = false),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Persistent HUD
                const HudWidget(),
                // Main game screen
                const Expanded(
                  child: GameScreen(),
                ),
              ],
            ),
            // Game over dialog
            if (widget.game.showGameOver) _GameOverOverlay(game: widget.game),
            // Encounter overlay (shown on top of everything)
            if (widget.game.showEncounter)
              EncounterOverlay(
                text: widget.game.encounterText,
                choices: widget.game.encounterChoices,
                onDismiss: widget.game.dismissEncounter,
              ),
            // Ad overlay (shown on top of everything)
            if (widget.game.showAd)
              AdOverlay(
                asset: widget.game.currentAdAsset!,
                onDismiss: widget.game.dismissAd,
              ),
          ],
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatefulWidget {
  final GameService game;

  const _GameOverOverlay({required this.game});

  @override
  State<_GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<_GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.game.gameOverMessage;
    final isWin = message.contains('🏆');
    final state = widget.game.state;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: AppTheme.background.withValues(alpha: 0.92),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isWin ? 'YOU WIN!' : 'GAME OVER',
                  style: AppTheme.jersey15(size: 36,
                    color: isWin ? AppTheme.accentGreen : AppTheme.danger,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  message.replaceAll('🏆 ', '').replaceAll('💀 ', ''),
                  style: AppTheme.jersey15(size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (state != null) ...[
                  Text(
                    'Final Cash: \$${state.cash}',
                    style: AppTheme.jersey10(size: 10,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                  Text(
                    'Net Worth: \$${state.netWorth}',
                    style: AppTheme.jersey10(size: 10,
                      color: AppTheme.gold,
                    ),
                  ),
                  if (state.debt > 0)
                    Text(
                      'Debt: \$${state.debt}',
                      style: AppTheme.jersey10(size: 10,
                        color: AppTheme.accentPink,
                      ),
                    ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.game.dismissGameOver();
                      widget.game.newGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: AppTheme.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'NEW GAME',
                      style: AppTheme.jersey10(size: 12),
                    ),
                  ),
                ),
                if (!isWin && state != null && state.cash <= 0) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        widget.game.applyBankruptcyBailout();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentPink,
                        side: const BorderSide(color: AppTheme.accentPink),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'BAILOUT (to \$500)',
                        style: AppTheme.jersey10(size: 11),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
