# Dope Wars Atlanta — Map System Design

> **Version:** 1.0.0  
> **Last Updated:** 2026-06-22  
> **Coordinate System:** 1000×1000 pixel virtual grid  
> **Rendering:** CustomPainter overlay on pixel art background

---

## 1. Overview

The map is the central navigation interface of Dope Wars Atlanta. Players see a pixel-art style map of Atlanta with 11 location markers, connection lines, and a pulsing player indicator. The map uses a `CustomPainter` overlay drawn on top of a static background image.

---

## 2. Coordinate System

### 2.1 Virtual Grid

All positions are defined on a 1000×1000 virtual coordinate space. The `PixelMapOverlayPainter` applies a uniform scale transform to map these coordinates to the actual widget size:

```dart
static const double mapSize = 1000.0;

void paint(Canvas canvas, Size size) {
  final scale = size.width / mapSize;
  canvas.save();
  canvas.scale(scale, scale);
  // ... draw in 1000x1000 space
  canvas.restore();
}
```

### 2.2 Location Coordinates

Coordinates are stored in `locationCoords` map in `pixel_map_overlay_painter.dart`:

| Location ID | X | Y | Quadrant | Notes |
|---|---|---|---|---|
| `cobb` | 182 | 300 | NW | Outside I-285 at I-75/I-285 interchange |
| `buckhead` | 534 | 170 | North center | GA 400 near I-285 top loop |
| `midtown` | 534 | 340 | Central | Along connector |
| `five_points` | 534 | 580 | Downtown | Below connector, I-20 crossing |
| `west_end` | 288 | 530 | West | Above I-20 |
| `little_five` | 706 | 520 | East | Below connector |
| `decatur` | 834 | 610 | East | Outside I-285 |
| `east_point` | 375 | 710 | SW | Inside I-285 |
| `hapeville` | 470 | 860 | South | Between I-75 and I-85 |
| `college_park` | 342 | 810 | SW | Near I-85 |
| `airport` | 524 | 910 | Far south | I-85/I-285 |

### 2.3 Map Background

The pixel art map is a 936×1000 image (`assets/images/map_background.png`) that gets scaled to fill the 1000×1000 virtual grid. The background is rendered as:

```dart
// In pixel_map.dart
Image.asset(
  'assets/images/map_background.png',
  fit: BoxFit.contain,  // Preserve aspect ratio within the container
)
```

---

## 3. Overlay Layers

The `PixelMapOverlayPainter` draws in this order (bottom to top):

```
Layer 0: Map background image (static)
Layer 1: Travel path (dashed yellow line + animated dot) [conditional]
Layer 2: Location circles + labels (all 11)
Layer 3: Player dot (green pulsing indicator)
Layer 4: Pulsing ring on current location
```

### 3.1 Layer 1 — Travel Path

When the player is traveling, a dashed yellow line connects the origin to destination:

```dart
void _drawTravelPath(Canvas canvas) {
  // Dashed line from -> to
  // Animated green dot moving along path (drive progress 0.0 → 1.0)
  // Glow ring on animated dot
}
```

Properties:
- Line color: `Color(0x66FFEB3B)` (yellow, 40% opacity)
- Line width: 3px
- Dash pattern: 8px dash, 6px gap
- Animated dot: green (`Color(0x9900ff9d)`), radius 8
- Glow: `Color(0xFF00ff9d)` at 30%, blur 6

### 3.2 Layer 2 — Location Markers

Each location is drawn as:

```dart
void _drawLocationMarker(Canvas canvas, String id, Offset pos, bool isCurrent) {
  // 1. Outer glow ring (current location only) — blur 14, accent 25%
  // 2. Fill circle — accent 35%, radius 16 (current: 20.8)
  // 3. Stroke circle — accent 100%, 3px width
  // 4. Inner dot — accent 100%, radius 4
  // 5. Pulsing ring (current location only) — expanding circle animation
  // 6. Text label (white, monospace, 11px bold, black shadow)
  // 7. Label background pill (black semi-transparent, rounded corners)
}
```

**Current location** gets enhanced visuals:
- 30% larger circle radius (20.8 vs 16)
- Outer glow ring
- Pulsing expansion ring (animation-driven)
- Accent-colored name text

**Pulsing ring animation:**
```dart
// In PixelMap widget
late AnimationController _pulseController;
late Animation<double> _pulseAnimation;

_pulseController = AnimationController(
  vsync: this,
  duration: Duration(milliseconds: 2000),
)..repeat(reverse: true);
```

### 3.3 Layer 3 — Player Dot

The player's current position is shown as a green pulsing dot:

```dart
void _drawPlayerDot(Canvas canvas) {
  final pos = locationCoords[currentLocationId];
  // 1. Outer glow — green, 30%, blur 12, radius + 8
  // 2. Main dot — green (#00ff9d), radius 8 (scales 0.8-1.0 with pulse)
  // 3. Inner bright dot — lighter green, radius 40% of main
  // 4. Pulsing ring — expanding with pulse
}
```

---

## 4. Travel Animation

### 4.1 TravelAnimationScreen

When the player selects a destination and transport mode, a full-screen travel animation plays:

```
┌──────────────────────────────────┐
│                                  │
│         🚇 (bouncing icon)       │
│                                  │
│       ON THE MARTA...            │
│       Five Points                │
│                                  │
│   ████████░░░░░░░░░░ (progress)  │
│                                  │
│   Downtown Atlanta hub           │
│                                  │
│   ── ── ── ── ── (road lines)   │
│                                  │
└──────────────────────────────────┘
```

- Duration: 5 seconds (easeInOut curve)
- Icon bounce: `sin(progress * π * 4) * 10` (4 bounces per trip)
- Progress bar: animated width
- Road lines: scrolling dashed line at bottom

### 4.2 ArrivalPopup

After travel animation completes (or if no encounter):

```dart
AlertDialog showing:
  - Location emoji (boxed with accent border)
  - "ARRIVED AT" label
  - Location name (uppercase, accent color)
  - Description text
  - Feature badges (Bank, Weapons, Councilman, Upgrades)
  - Current cash display
  - "LET'S GO!" button
```

---

## 5. Interaction

### 5.1 Gesture Handling (pixel_map.dart)

```dart
GestureDetector(
  onTapUp: (details) {
    // Convert tap position to map coordinates
    // Find nearest location within 50px radius
    // If found and connected, show transport dialog
  },
  child: Stack([
    // Map background image
    // CustomPaint overlay
  ]),
)
```

### 5.2 Transport Selection Dialog

Tapping a connected location shows:

```
┌────────────────────────┐
│  Travel to [Location]   │
│                         │
│  [🚇 MARTA $5]         │
│  [🚗 Ryde $25-60]      │
│  [🏎️ Drive $20]        │
│                         │
│  [CANCEL]               │
└────────────────────────┘
```

- **MARTA**: Only available if location is in `martaConnections`
- **Ryde/Drive**: Only available if location is in `highwayConnections`
- Disabled buttons have grayed-out text and a tooltip "No route available"

---

## 6. Future Map Improvements

### 6.1 Pinch-to-Zoom

```dart
InteractiveViewer(
  minScale: 0.5,
  maxScale: 3.0,
  boundaryMargin: EdgeInsets.all(100),
  child: CustomPaint(
    painter: PixelMapOverlayPainter(...),
    child: Image.asset('assets/images/map_background.png'),
  ),
)
```

### 6.2 Distance-Based Travel

```dart
double distanceBetween(String fromId, String toId) {
  final from = locationCoords[fromId];
  final to = locationCoords[toId];
  return sqrt(pow(to.dx - from.dx, 2) + pow(to.dy - from.dy, 2));
}

int travelTime(String fromId, String toId, {required bool isMarta}) {
  final dist = distanceBetween(fromId, toId);
  final time = (dist / 200).round();  // 200 units = 1 hour
  return isMarta ? time + 1 : time;   // MARTA is slower
}
```

### 6.3 Undiscovered Locations

New locations appear as "???" until first visit:

```dart
final isDiscovered = visitedLocations.contains(locationId);
final displayName = isDiscovered ? actualName : '???';
final circleColor = isDiscovered ? accent : Colors.grey;
```

### 6.4 Curved Travel Paths

Replace straight dashed lines with bezier curves that follow road geometry:

```dart
final path = Path()
  ..moveTo(from.dx, from.dy)
  ..cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, to.dx, to.dy);
```

Control points would be defined per connection pair to approximate I-285, I-75, and I-20 geometry.

---

## 7. Map Data Structure

```dart
// Connection graph (defined in location models)
final Map<String, Set<String>> martaNetwork = {
  'cobb': {'buckhead'},
  'buckhead': {'cobb', 'midtown'},
  'midtown': {'buckhead', 'five_points'},
  'five_points': {'midtown', 'west_end', 'east_point'},
  'west_end': {'five_points'},
  'little_five': {'five_points', 'decatur'},
  'east_point': {'five_points', 'college_park'},
  'college_park': {'east_point', 'hapeville'},
  'hapeville': {'college_park', 'airport'},
  'airport': {'hapeville'},
  'decatur': {'little_five'},
};

final Map<String, Set<String>> highwayNetwork = {
  'buckhead': {'midtown'},
  'midtown': {'buckhead', 'five_points'},
  'five_points': {'midtown', 'west_end', 'little_five'},
  'west_end': {'five_points'},
  'little_five': {'five_points'},
  // I-285 belt
  'cobb': {'buckhead', 'decatur'},
  'buckhead': {'cobb', 'decatur'},
  'decatur': {'buckhead', 'cobb', 'east_point'},
  'east_point': {'decatur', 'college_park'},
  'college_park': {'east_point'},
};
```
