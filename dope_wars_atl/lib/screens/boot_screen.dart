import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BootScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const BootScreen({super.key, required this.onComplete});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scanlineAnimation;
  String _bootText = '';

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
      if (mounted) {
        setState(() => _bootText = _fullText.substring(0, i + 1));
      }
    }
    _controller.forward();
    // Auto-advance after typing completes
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: GestureDetector(
        onTap: widget.onComplete,
        child: Stack(
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
            // Tap hint
            if (_bootText.length >= _fullText.length)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Text(
                      '[ TAP TO START ]',
                      style: AppTheme.jersey10(size: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
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
