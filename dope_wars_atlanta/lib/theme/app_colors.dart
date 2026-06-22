import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core palette
  static const Color background = Color(0xFF1a1625);
  static const Color card = Color(0xFF2a2438);
  static const Color cardLight = Color(0xFF352f48);
  static const Color accent = Color(0xFF00ff9d);  // green
  static const Color accent2 = Color(0xFFff00f7);  // pink
  static const Color white = Color(0xFFffffff);
  static const Color gray = Color(0xFF9ca3af);
  static const Color darkGray = Color(0xFF6b7280);

  // Location accent colors
  static const Color midtownBlue = Color(0xFF3b82f6);
  static const Color buckheadGold = Color(0xFFf5c518);
  static const Color cobbGray = Color(0xFF6b7280);
  static const Color l5pPurple = Color(0xFFa855f7);
  static const Color decaturOrange = Color(0xFFf97316);
  static const Color westEndRed = Color(0xFFef4444);

  // Semantic
  static const Color danger = Color(0xFFef4444);
  static const Color success = Color(0xFF00ff9d);
  static const Color warning = Color(0xFFf5c518);

  static Color accentForLocation(String locationAccentName) {
    switch (locationAccentName) {
      case 'blue': return midtownBlue;
      case 'gold': return buckheadGold;
      case 'gray': return cobbGray;
      case 'purple': return l5pPurple;
      case 'orange': return decaturOrange;
      case 'red': return westEndRed;
      default: return accent;
    }
  }
}
