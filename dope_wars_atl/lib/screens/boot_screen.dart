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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scanlineAnimation;
  String _bootText = '';
  bool _ready = false;

  final String _fullText = '''DOPE WARS ATL
LOADING...
v1.0.0

ATLANTA, GA
EST. 2026

PRESS START''';

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
    _startTypewriter();
  }

  void _startTypewriter() async {
    for (int i = 0; i < _fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;
      setState(() => _bootText = _fullText.substring(0, i + 1));
    }
    _controller.forward();
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The mode choice. Two single-player modes, one engine: Classic races the
  /// calendar, Progressive opens the city as you earn it.
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
                  emoji: '▶️',
                  title: 'CONTINUE',
                  subtitle: 'Pick up the run you already have',
                  onTap: () => Navigator.pop(ctx, 'continue'),
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
    widget.onStart(choice == 'continue' ? null : choice);
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
          // Terminal text
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  _bootText,
                  style: AppTheme.jersey10(size: 14,
                    color: AppTheme.accentGreen,
                    height: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // The button. It only appears once the typing finishes, so it is a
          // deliberate press rather than an accidental one.
          if (_ready)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: SizedBox(
                    width: 240,
                    child: ElevatedButton(
                      onPressed: _promptMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: AppTheme.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        widget.hasSave ? 'CONTINUE' : 'PRESS START',
                        style: AppTheme.jersey10(size: 12),
                      ),
                    ),
                  ),
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
