import 'package:flutter/material.dart';

/// Geographic coordinates for each location on the map background.
///
/// v3: measured directly on `assets/images/map_background_v3.jpg`
/// (606x1280 source image, real Atlanta highway layout).
/// Values are in the source-image pixel space; the map renderer
/// scales them to display space.
const Map<String, Offset> locationCoords = {
  'cobb': Offset(148, 300),
  'buckhead': Offset(330, 500),
  'midtown': Offset(312, 618),
  'little_five': Offset(395, 627),
  'decatur': Offset(478, 636),
  'west_end': Offset(255, 690),
};
