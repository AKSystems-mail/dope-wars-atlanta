import 'package:flutter/material.dart';

/// Emoji icons for each game location (used in dialogs and info panels).
const Map<String, String> locationEmojis = {
  'cobb': '🌲',
  'buckhead': '🏰',
  'midtown': '🏢',
  'west_end': '🔫',
  'little_five': '🎸',
  'decatur': '🎓',
};

/// Locations outside the I-285 perimeter (no highway icons, different rules).
const Set<String> outsidePerimeterIds = {
  'cobb',
};

/// Color accent for each location.
const Map<String, Color> locationAccents = {
  'west_end': Color(0xFFe53935),
  'midtown': Color(0xFF1e88e5),
  'little_five': Color(0xFFab47bc),
  'buckhead': Color(0xFFfdd835),
  'decatur': Color(0xFFfb8c00),
  'cobb': Color(0xFF78909c),
};
