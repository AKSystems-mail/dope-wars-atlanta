import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Blocky neon-bordered button with press-shift effect.
///
/// Unpressed: dark panel with thin neon border.
/// Pressed: border brightens, content shifts 2px down+right.
/// No Material pill shapes — pure retro block.
class NeonBorderButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final Color neonColor;
  final double width;
  final double height;
  final double fontSize;
  final bool selected;

  const NeonBorderButton({
    super.key,
    required this.label,
    this.onPressed,
    this.neonColor = AppTheme.accentGreen,
    this.width = double.infinity,
    this.height = 44,
    this.fontSize = 12,
    this.selected = false,
  });

  @override
  State<NeonBorderButton> createState() => _NeonBorderButtonState();
}

class _NeonBorderButtonState extends State<NeonBorderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final color = widget.neonColor;
    final dimColor = color.withValues(alpha: 0.4);
    final bgColor = widget.selected
        ? color.withValues(alpha: 0.15)
        : AppTheme.surface;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: isDisabled ? null : (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.width,
        height: widget.height,
        transform: _pressed
            ? (Matrix4.identity()..translate(2.0, 2.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: _pressed ? color : dimColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4), // Hard min radius
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label.toUpperCase(),
          style: AppTheme.jersey10(
            size: widget.fontSize,
            color: isDisabled
                ? AppTheme.textSecondary.withValues(alpha: 0.4)
                : color,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Dark panel card with neon border for shop/inventory items.
class NeonItemCard extends StatelessWidget {
  final Widget child;
  final Color neonColor;
  final EdgeInsetsGeometry padding;
  final double borderWidth;

  const NeonItemCard({
    super.key,
    required this.child,
    this.neonColor = AppTheme.accentGreen,
    this.padding = const EdgeInsets.all(12),
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border.all(
          color: neonColor.withValues(alpha: 0.3),
          width: borderWidth,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}

/// Neon-styled label for section headers.
class NeonLabel extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;

  const NeonLabel({
    super.key,
    required this.text,
    this.color = AppTheme.accentGreen,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTheme.jersey15(
        size: fontSize,
        color: color,
      ),
    );
  }
}

/// Blocky icon/text action button with press-shift (for bottom nav: BUY / MAP / INVENTORY).
class NeonActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final Color neonColor;

  const NeonActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.neonColor = AppTheme.accentPink,
  });

  @override
  State<NeonActionButton> createState() => _NeonActionButtonState();
}

class _NeonActionButtonState extends State<NeonActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.neonColor;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        transform: _pressed
            ? (Matrix4.identity()..translate(2.0, 2.0))
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(
            color: _pressed ? color : color.withValues(alpha: 0.4),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          widget.label.toUpperCase(),
          style: AppTheme.jersey10(
            size: 14,
            color: color,
          ),
        ),
      ),
    );
  }
}
