import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AdOverlay extends StatefulWidget {
  final String asset;
  final VoidCallback onDismiss;

  const AdOverlay({
    super.key,
    required this.asset,
    required this.onDismiss,
  });

  @override
  State<AdOverlay> createState() => _AdOverlayState();
}

class _AdOverlayState extends State<AdOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black87,
        child: Stack(
          children: [
            // Ad image
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Image.asset(
                  widget.asset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300,
                      color: AppTheme.card,
                      child: Center(
                        child: Text(
                          'Ad Placeholder',
                          style: AppTheme.jersey10(size: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Skip button
            Positioned(
              bottom: 40,
              right: 24,
              child: TextButton(
                onPressed: widget.onDismiss,
                child: Text(
                  'SKIP >',
                  style: AppTheme.jersey10(size: 10,
                    color: AppTheme.textSecondary,
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
