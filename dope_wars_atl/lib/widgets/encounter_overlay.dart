import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EncounterOverlay extends StatefulWidget {
  final String text;
  final List<EncounterChoice>? choices;
  final VoidCallback onDismiss;

  const EncounterOverlay({
    super.key,
    required this.text,
    this.choices,
    required this.onDismiss,
  });

  @override
  State<EncounterOverlay> createState() => _EncounterOverlayState();
}

class _EncounterOverlayState extends State<EncounterOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _scrollController;
  late Animation<double> _scrollAnimation;
  int _visibleLines = 0;
  final List<String> _lines = [];

  @override
  void initState() {
    super.initState();
    _lines.addAll(widget.text.split('\n'));
    _scrollController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scrollAnimation = CurvedAnimation(
      parent: _scrollController,
      curve: Curves.easeInOut,
    );
    _scrollController.forward();
    _startTypewriter();
  }

  void _startTypewriter() async {
    for (int i = 0; i < _lines.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() => _visibleLines = i + 1);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _scrollAnimation,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.background.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentGreen.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Typewriter text lines
              ...List.generate(
                _visibleLines.clamp(0, _lines.length),
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    _lines[i],
                    style: AppTheme.jersey10(size: 10,
                      color: AppTheme.accentGreen,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              if (widget.choices != null && widget.choices!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: widget.choices!.map((choice) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: choice.onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: choice.color ?? AppTheme.accentGreen,
                            foregroundColor: AppTheme.background,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            choice.label,
                            style: AppTheme.jersey10(size: 11,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              // Tap to dismiss
              if (widget.choices == null || widget.choices!.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    onTap: widget.onDismiss,
                    child: Center(
                      child: Text(
                        '[ TAP TO CONTINUE ]',
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
      ),
    );
  }
}

class EncounterChoice {
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const EncounterChoice({
    required this.label,
    this.color,
    required this.onTap,
  });
}
