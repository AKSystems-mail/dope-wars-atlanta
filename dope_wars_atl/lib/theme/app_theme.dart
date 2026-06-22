import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central theme for Dope Wars – Atlanta.
///
/// Dark retro arcade aesthetic. Neon borders, blocky buttons, no pill shapes.
/// Jersey 10 for small labels/buttons, Jersey 15 for headings/location names.
class AppTheme {
  // ── Core palette ──
  static const Color background = Color(0xFF1a1625);
  static const Color card = Color(0xFF2a2438);
  static const Color surface = Color(0xFF221e30);

  // ── Neon accent palette ──
  static const Color accentGreen = Color(0xFF00ff9d);
  static const Color accentPink = Color(0xFFff00f7);
  static const Color gold = Color(0xFFffd700);
  static const Color danger = Color(0xFFff3355);

  // ── Text ──
  static const Color textPrimary = Color(0xFFe8e4f0);
  static const Color textSecondary = Color(0xFF9e94ad);

  // ── Location accent colors (kept for compatibility) ──
  static const Color buckhead = Color(0xFFfdd835);
  static const Color midtown = Color(0xFF1e88e5);
  static const Color littleFive = Color(0xFFab47bc);
  static const Color westEnd = Color(0xFFe53935);
  static const Color decatur = Color(0xFFfb8c00);
  static const Color cobb = Color(0xFF78909c);

  // ── Font helpers ──

  /// Jersey 10 — small labels, buttons, stats, map labels, HUD items
  static TextStyle jersey10({
    double size = 10,
    Color color = textPrimary,
    double? height,
  }) =>
      GoogleFonts.jersey10(
        fontSize: size,
        color: color,
        height: height,
      );

  /// Jersey 15 — headings, item names, location names, section titles
  static TextStyle jersey15({
    double size = 16,
    Color color = textPrimary,
    double? height,
  }) =>
      GoogleFonts.jersey15(
        fontSize: size,
        color: color,
        height: height,
      );

  // ── Convenience shorthands ──

  /// Button label style (Jersey 10, all caps)
  static TextStyle buttonLabel({
    double size = 12,
    Color color = textPrimary,
  }) =>
      jersey10(size: size, color: color);

  // ── Material theme ──

  /// Material dark theme for the app.
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      surface: card,
      primary: accentGreen,
      secondary: accentPink,
    ),
  );

  // ── Decoration helpers (kept for compatibility) ──

  /// Returns a card-style BoxDecoration with the old pixel-art aesthetic.
  static BoxDecoration pixelCard({Color? accentColor, bool isActive = false}) {
    return BoxDecoration(
      color: card,
      border: Border.all(
        color: accentColor ?? accentGreen,
        width: isActive ? 2.0 : 1.0,
      ),
      borderRadius: BorderRadius.circular(4),
    );
  }

  /// Returns a button-style BoxDecoration.
  static BoxDecoration pixelButton({Color? color}) {
    return BoxDecoration(
      color: color ?? accentGreen,
      borderRadius: BorderRadius.circular(4),
    );
  }

  /// Returns a simple bordered BoxDecoration.
  static BoxDecoration pixelBorder({Color? color, Color? fillColor}) {
    return BoxDecoration(
      color: fillColor ?? Colors.transparent,
      border: Border.all(color: color ?? accentGreen, width: 1.0),
      borderRadius: BorderRadius.circular(4),
    );
  }

  /// Section heading style (Jersey 15)
  static TextStyle heading({
    double size = 18,
    Color color = textPrimary,
  }) =>
      jersey15(size: size, color: color);

  /// Body/label text (Jersey 10)
  static TextStyle label({
    double size = 10,
    Color color = textSecondary,
  }) =>
      jersey10(size: size, color: color);
}
