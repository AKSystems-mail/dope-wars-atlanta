import 'package:flutter/material.dart';

/// Geographic coordinates for each location on the 1000x1000 pixel map.
///
/// Extracted from pixel_map_overlay_painter.dart so it can be shared
/// by both the legacy CustomPainter and the new FlameGame components.
const Map<String, Offset> locationCoords = {
  'cobb': Offset(182, 300),
  'buckhead': Offset(534, 170),
  'midtown': Offset(534, 340),
  'five_points': Offset(534, 580),
  'west_end': Offset(288, 530),
  'little_five': Offset(706, 520),
  'decatur': Offset(834, 610),
  'east_point': Offset(375, 710),
  'hapeville': Offset(470, 860),
  'college_park': Offset(342, 810),
  'airport': Offset(524, 910),
};
