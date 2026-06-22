import 'package:flutter/material.dart';

/// Emoji icons for each game location (used in dialogs and info panels).
const Map<String, String> locationEmojis = {
  'cobb': '🌲',
  'buckhead': '🏰',
  'midtown': '🏢',
  'five_points': '🏛️',
  'west_end': '🔫',
  'little_five': '🎸',
  'decatur': '🎓',
  'east_point': '🏭',
  'hapeville': '🏪',
  'college_park': '🏫',
  'airport': '✈️',
};

/// Locations outside the I-285 perimeter (no highway icons, different rules).
const Set<String> outsidePerimeterIds = {
  'cobb', 'airport', 'college_park',
};

/// Color accent for each location.
const Map<String, Color> locationAccents = {
  'hapeville': Color(0xFF9e9e9e),
  'college_park': Color(0xFF757575),
  'airport': Color(0xFF616161),
  'east_point': Color(0xFF8d6e63),
  'west_end': Color(0xFFe53935),
  'five_points': Color(0xFF42a5f5),
  'midtown': Color(0xFF1e88e5),
  'little_five': Color(0xFFab47bc),
  'buckhead': Color(0xFFfdd835),
  'decatur': Color(0xFFfb8c00),
  'cobb': Color(0xFF78909c),
};
