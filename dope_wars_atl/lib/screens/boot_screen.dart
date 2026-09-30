import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Boot screen. Types its lines out, then waits — the terminal no longer starts
/// the game by itself, because starting a game means choosing a mode first.
class BootScreen extends StatefulWidget {
  /// Called with the chosen mode, or null to continue an existing save.
  final void Function(String? mode) onStart;

  /// Whether there is a run to continue. When there is, the prompt offers it
  /// first so a tap cannot silently wipe progress.
  final bool hasSave;

  const BootScreen({
    super.key,
    required this.onStart,
    this.hasSave = false,
  });

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseCtrl;
  late AnimationController _blinkCtrl;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scanlineAnimation;
  String _bootText = '';
  bool _ready = false;
  bool _typing = true;
  // The canvas line and the button must never read as the same control. The
  // terminal text used to end in PRESS START and the button beneath it was
  // also PRESS START, so a finished boot screen showed the words twice.

  final String _fullText = '''DOPE WARS ATL
LOADING...
v1.0.0

ATLANTA, GA
EST. 2026

INSERT COIN''';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _scanlineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    // Breathe, so the PRESS START button reads as live rather than as chrome.
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat(reverse: true);
    // LOADING cursor blink, only while the typewriter is running.
    _blinkCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _startTypewriter();
  }

  void _startTypewriter() async {
    for (int i = 0; i < _fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;
      setState(() => _bootText = _fullText.substring(0, i + 1));
    }
    _controller.forward();
    if (mounted) {
      setState(() {
        _ready = true;
        _typing = false;
      });
      _blinkCtrl.stop(); // cursor has done its job
    }
  }

  /// Blinking LOADING cursor. Hidden when idle so the finished screen is calm.
  TextStyle _blinkStyle() => AppTheme.jersey10(
        size: 14,
        color: AppTheme.accentGreen.withValues(alpha: _blinkCtrl.value),
      );

  @override
  void dispose() {
    _controller.dispose();
    _pulseCtrl.dispose();
    _blinkCtrl.dispose();
    super.dispose();
  }

  /// The mode choice. Two single-player modes, one engine: Classic races the
  /// calendar, Progressive opens the city as you earn it. No CONTINUE here —
  /// that is its own button on the boot screen, so it shouldn't also be an
  /// option inside the "pick a mode" sheet.
  Future<void> _promptMode() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('CHOOSE YOUR RUN',
                  textAlign: TextAlign.center,
                  style: AppTheme.jersey10(size: 12, color: AppTheme.accentGreen)),
              const SizedBox(height: 16),
              if (widget.hasSave) ...[
                _ModeButton(
                  emoji: '🗑️',
                  title: 'START OVER',
                  subtitle: 'Discard the saved run and choose a fresh mode',
                  onTap: () => Navigator.pop(ctx, 'new'),
                ),
                const SizedBox(height: 10),
              ],
              _ModeButton(
                emoji: '🎯',
                title: 'CLASSIC',
                subtitle: 'The whole city is open. Beat the calendar and bank the most.',
                onTap: () => Navigator.pop(ctx, 'classic'),
              ),
              const SizedBox(height: 10),
              _ModeButton(
                emoji: '🗺️',
                title: 'PROGRESSIVE',
                subtitle: 'Start with two hoods. Earn the rest, then own the city.',
                onTap: () => Navigator.pop(ctx, 'progressive'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('BACK',
                    style: AppTheme.jersey10(size: 10, color: AppTheme.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !mounted) return;
    widget.onStart(choice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Scanline effect
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScanlinePainter(
                  progress: _scanlineAnimation.value,
                  color: AppTheme.accentGreen.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
          // Terminal text. While the typewriter runs, LOADING is a blinking
          // cursor block; the rest of the line is already-spaced text so the
          // animated part doesn't shift the block around as it changes.
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: _bootText),
                    if (_typing)
                      TextSpan(text: '█', style: _blinkStyle()),
                  ]),
                  style: AppTheme.jersey10(size: 14,
                    color: AppTheme.accentGreen,
                    height: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // The buttons. PRESS START is the primary action and pulses; CONTINUE
          // sits directly beneath it so the two never read as one control.
          if (_ready)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        // Gentle scale + glow, not a flicker.
                        final t = Curves.easeInOut.transform(_pulseCtrl.value);
                        return Transform.scale(
                          scale: 1.0 + 0.04 * t,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentGreen
                                      .withValues(alpha: 0.25 + 0.35 * t),
                                  blurRadius: 18 + 14 * t,
                                  spreadRadius: 1 + 2 * t,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 240,
                        child: ElevatedButton(
                          onPressed: _promptMode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            'PRESS START',
                            // Explicit colour: AppTheme.jersey10 defaults to
                            // textPrimary (white), which would win over the
                            // button's own foreground and be unreadable on the
                            // green fill.
                            style: AppTheme.jersey10(
                                size: 12, color: AppTheme.background),
                          ),
                        ),
                      ),
                    ),
                    if (widget.hasSave) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: 240,
                        child: OutlinedButton(
                          // Continues straight into the save — no sheet, since
                          // asking "what mode?" for an existing run is a
                          // question with no answer.
                          onPressed: () => widget.onStart(null),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(
                                color: AppTheme.textSecondary, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            'CONTINUE',
                            style: AppTheme.jersey10(
                                size: 12, color: AppTheme.textPrimary),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One mode option in the prompt: emoji, name, and a line explaining what the
/// run actually is.
class _ModeButton extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeButton({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.pixelCard(accentColor: AppTheme.accentGreen),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTheme.jersey15(
                          size: 20, color: AppTheme.accentGreen)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTheme.jersey15(
                          size: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanlinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    final y = size.height * progress;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => old.progress != progress;
}
