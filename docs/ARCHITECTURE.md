# Dope Wars Atlanta — Architecture Guide

> **Version:** 1.0.0  
> **Last Updated:** 2026-06-22  
> **Tech Stack:** Flutter 3.29.2 + Flame (optional hybrid layer)  
> **Platform Target:** Linux Desktop (Fedora 44), Android  
> **State Management:** Provider (ChangeNotifier)

---

## 1. Project Overview

Dope Wars Atlanta is a drug-trade empire simulation game set in Atlanta, GA. The player travels between 11 Atlanta-area neighborhoods buying and selling products, managing cash/debt, avoiding police encounters, and building their empire within a limited number of in-game days.

### 1.1 Architectural Philosophy

- **Documentation-first**: Every system is specified in markdown before implementation
- **Provider pattern**: Single source of truth via `ChangeNotifier` + `Consumer` widgets
- **Flutter-native UI**: All menus, HUD, and shop screens are pure Flutter widgets
- **CustomPainter map**: Map overlay drawn on canvas (no game engine dependency for current scope)
- **Flame as optional add-on**: Flame `FlameGame` can wrap the game loop for real-time clock ticking and future multiplayer networking via Nakama
- **Desktop-first build**: Developed and tested on Fedora 44 Linux desktop before mobile ports

### 1.2 Engine Decision

| Layer | Technology | Why |
|---|---|---|
| UI (menus, HUD, shop, inventory) | Flutter widgets | Hot reload, rapid iteration, rich theming |
| Map (overlay, markers, routes) | CustomPainter | Full control over pixel-art aesthetic, no engine overhead |
| Game loop (day/hour ticks) | Timer (current) → Flame `GameLoop` (future) | Flame provides precise `dt`-based update cycle |
| Multiplayer (future) | Flame + Nakama | Nakama handles matchmaking, state sync, leaderboards |
| Audio | `audioplayers` package | Offline WAV playback, simple API |

---

## 2. Directory Structure

```
~/DopeWars-Atlanta/
├── README.md                    # Project overview & quick-start
├── SPEC.md                      # Original game specification
├── docs/                        # Comprehensive documentation
│   ├── ARCHITECTURE.md          # This file
│   ├── GAME_DESIGN.md           # Full game design document
│   ├── DEV_ROADMAP.md           # Development roadmap & milestones
│   ├── API_REFERENCE.md         # Internal service/API reference
│   ├── MAP_SYSTEM.md            # Map coordinate & overlay design
│   └── MULTIPLAYER_DESIGN.md    # Future multiplayer architecture
├── dope_wars_atl/               # Main Flutter project
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart            # App entry, Provider setup
│   │   ├── models/
│   │   ├── services/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── utils/
│   │   └── theme/
│   ├── assets/
│   │   ├── ads/                 # PNG ad images
│   │   ├── sounds/              # WAV sound effects
│   │   └── images/              # Map background & sprites
│   └── test/
└── flame_game/                  # Future Flame overlay project
    └── lib/
        └── game_loop.dart
```

---

## 3. Data Flow Architecture

### 3.1 Provider/Consumer Pattern

```
┌─────────────────────────────────────────────────────┐
│                   main.dart                          │
│                                                      │
│  ChangeNotifierProvider<GameService>                  │
│       │                                              │
│       ▼                                              │
│  GameWrapper (StatefulWidget)                        │
│       │                                              │
│       ├── BootScreen ──► onComplete ──►              │
│       │                                              │
│       ▼                                              │
│  Scaffold ─── Stack ────────────────────┐            │
│  │                                      │            │
│  ├── Column                             │            │
│  │   ├── HudWidget (Consumer)           │            │
│  │   └── GameScreen (Consumer)          │            │
│  │                                      │            │
│  ├── EncounterOverlay (conditional)     │            │
│  ├── AdOverlay (conditional)            │            │
│  └── GameOverOverlay (conditional)      │            │
│                                         │            │
└─────────────────────────────────────────┘            │
                                                      │
                      ┌───────────────────┐           │
                      │   GameService      │           │
                      │   (ChangeNotifier) │◄──────────┘
                      │                    │
                      │  ┌─ GameState      │
                      │  └─ Business logic │
                      │                    │
                      │  SaveService ◄─────┤── SharedPreferences
                      │  SoundService      │
                      └───────────────────┘
```

### 3.2 State Mutation Flow

1. **User action** (tap location, buy item, travel) triggers a widget event
2. Widget calls `GameService.someMethod()`
3. `GameService` mutates `GameState` fields
4. `GameService` calls `notifyListeners()`
5. All `Consumer<GameService>` widgets rebuild
6. `GameService` calls `autoSave()` (persist to SharedPreferences)

### 3.3 Travel Flow (Complete Sequence)

```
User taps destination
        │
        ▼
GameService.canTravelTo(locationId, isMarta: true/false)
        │
        ├── false ──► Show error (no connection)
        │
        ▼ true
GameService.travelByMarta(locationId)
  or travelByRyde(locationId)
  or travelByDrive(locationId)
        │
        ├── Charge fare from cash
        ├── Set currentLocationId
        ├── advanceTime(hours)
        ├── applyDailyInterest()
        ├── Play sound effect
        │
        ├── Check encounter (3-6% chance)
        │       ├── True ──► Show EncounterOverlay
        │       └── False ──► Continue
        │
        ├── Check location event (Water Boys, YNs)
        │       ├── True ──► Show EncounterOverlay
        │       └── False ──► Continue
        │
        ├── Check pricing events
        ├── Check game over
        ├── Show ad overlay
        └── autoSave()
```

---

## 4. State Management

### 4.1 GameState (game_state.dart)

The single data class holding all player and world state. **No business logic** — pure data.

```dart
class GameState {
  // Player finances
  int cash;
  int bankBalance;
  int debt;
  int totalEarned;
  int totalSpent;

  // Inventory
  Map<String, int> inventory;      // productId -> quantity
  Weapon equippedWeapon;

  // Game progression
  String currentLocationId;
  int day;
  int maxDays;
  int hour;                        // 6-22 (16 hours per day)
  String weather;                  // 'clear', 'rain', 'fog', 'storm'
  String difficulty;

  // Metadata
  bool soundEnabled;
  bool gameStarted;
  DateTime lastSaveTime;
  int totalGamesPlayed;

  // Events
  double rydeSurgeMultiplier;      // 1.0-2.5
  List<String> triggeredEvents;    // event IDs for repeat prevention
}
```

### 4.2 GameService (game_service.dart)

The **brain** of the application. A `ChangeNotifier` that:

- **Initializes** from saved state or creates new game
- **Manages travel** between locations (3 transport modes)
- **Handles encounters** (police, thieves, GSP, YNs, Water Boys)
- **Runs economy** (pricing engine, supply/demand, events)
- **Controls game flow** (day advancement, interest, game-over checks)
- **Orchestrates audio** via SoundService

Key methods:

| Method | Description |
|---|---|
| `init()` | Load saved game or create default state |
| `newGame({difficulty, gameDuration})` | Reset for new game |
| `travelByMarta(locationId)` | MARTA transit (connections-based) |
| `travelByRyde(locationId)` | Ryde ride-share (road-based) |
| `travelByDrive(locationId)` | Drive own car (road-based, fastest) |
| `buyProduct(productId, quantity)` | Purchase from current location |
| `sellProduct(productId, quantity)` | Sell at current location |
| `equipWeapon(weapon)` | Change equipped weapon |
| `depositCash(amount)` | Bank deposit |
| `withdrawCash(amount)` | Bank withdrawal |
| `applyBankruptcyBailout()` | Emergency loan from Councilman |
| `dismissEncounter()` | Close encounter overlay |
| `dismissAd()` | Close ad overlay |
| `autoSave()` | Persist to disk |

### 4.3 Save Service

```dart
class SaveService {
  static const _saveKey = 'dope_wars_atl_save';

  Future<GameState?> load();     // Deserialize from SharedPreferences
  Future<void> save(GameState);  // Serialize to JSON, persist
  Future<void> delete();         // Clear save data
}
```

---

## 5. Navigation & Routing

The app uses a **lightweight state-machine approach** rather than named routes:

```
main.dart
  │
  └── GameWrapper (StatefulWidget)
       │
       ├── [_showBoot = true]  ──► BootScreen(onComplete)
       │
       └── [_showBoot = false] ──► Scaffold
              │
              ├── HudWidget (persistent stats bar)
              │
              ├── GameScreen
              │     │
              │     ├── [currentScreen = 'shop']  ──► ShopView
              │     ├── [currentScreen = 'map']   ──► MapScreen (push)
              │     ├── [currentScreen = 'bag']   ──► InventoryView
              │     └── [currentScreen = 'menu']  ──► MenuView
              │
              ├── EncounterOverlay (stacked on top)
              ├── AdOverlay (stacked on top)
              └── GameOverOverlay (stacked on top)
```

**BootScreen** → 4-second retro animation with ASCII-style logo → sets `_showBoot = false` → enters game loop.

**MapScreen** uses `Navigator.push` (full Material route) for full-screen map interaction.

**Overlays** are stacked widgets, not routes — they appear on top of the current game screen.

---

## 6. Map System

See [MAP_SYSTEM.md](./MAP_SYSTEM.md) for full details.

**Summary:**
- Custom `PixelMapOverlayPainter` (extends `CustomPainter`)
- 11 Atlanta locations with `(x,y)` coordinates on a 1000×1000 unit grid
- Dashed travel path animation using `AnimationController`
- Player dot with pulsing glow effect
- 5-second travel animation screen for transport transitions

---

## 7. Combat & Encounter System

### 7.1 Weapons

| Weapon | Kill Chance | Durability | Cost |
|---|---|---|---|
| Fists | 0.20 | ∞ (free) | $0 |
| Bat | 0.35 | 10 | $80 |
| Glock | 0.55 | 15 | $350 |
| Tec-9 | 0.65 | 10 | $600 |
| AK-47 | 0.80 | 25 | $1,200 |

### 7.2 Encounter Types

| Encounter | Trigger | Transport | Chance | Resolution |
|---|---|---|---|---|
| MARTA Police | Random | MARTA | 3% | Run / Fight |
| Ryde Cop | Random | Ryde | 3% | Bribe $200 / Run |
| GSP Chase | Random | Drive | 6% | 75% caught (lose 75% inv), 25% escape |
| Water Boys | Location | Midtown | 8% | Lose 30% inventory |
| YNs (armed) | Location | West End | 10% | Pass (if weapon), lose $100-300 (if unarmed) |

---

## 8. Economy Engine

### 8.1 Products

| Product | Base Price | Volatility | Category |
|---|---|---|---|
| Motor Oil | $80 | Low | Standard |
| Antifreeze | $120 | Medium | Standard |
| Brake Fluid | $100 | Medium | Standard |
| Transmission Fluid | $200 | High | Premium |
| Gasoline | $150 | Medium | Standard |
| Diesel | $175 | Medium | Standard |
| Coolant | $650 | Very High | Luxury |

### 8.2 Pricing Model

```
finalPrice = basePrice * locationMultiplier * eventMultiplier + randomWalk

locationMultiplier: 0.5x - 1.5x (based on location's preferred products)
eventMultiplier:    0.5x (market flood) or 2.0x (demand spike)
randomWalk:         ±10-20% daily change (lognormal distribution)
```

---

## 9. Transport System

| Mode | Cost | Time | Connections | Encounter Risk |
|---|---|---|---|---|
| MARTA | $5 | +2 hours | martaConnections only | 3% police |
| Ryde | $25-60 (with surge) | +2 hours | highwayConnections | 3% cop |
| Drive | $20 | +1 hour | highwayConnections | 6% GSP chase |

Each location defines its own `martaConnections[]` and `highwayConnections[]`, creating a directed graph of the Atlanta transit network.

---

## 10. Sound & Media

- **SoundService**: Lazy-loads `AudioPlayer` instances per asset path
- **5 SFX**: `marta_chime.wav`, `car_horn.wav`, `cash_register.wav`, `encounter.wav`, `weapon_fire.wav`
- **AdService**: Holds 5 parody ad definitions (Ryde, Councilman, Get Higher, Certified Whips, The Varsity)
- **Assets directory**: Organized as `assets/ads/`, `assets/sounds/`, `assets/images/`

---

## 11. Future Architecture

### 11.1 Flame Integration

```dart
class DopeWarsGame extends FlameGame {
  late final GameService gameService;
  late final CameraComponent camera;

  @override Future<void> onLoad() async {
    camera = CameraComponent.withFixedResolution(width: 1000, height: 1000);
    // Map nodes as PositionComponent
    // Player as SpriteComponent
    // Game loop for time advancement
  }
}
```

### 11.2 Multiplayer (Nakama)

See [MULTIPLAYER_DESIGN.md](./MULTIPLAYER_DESIGN.md) for full architecture.

### 11.3 CI/CD Pipeline

```
Git push → GitHub Actions → flutter test → flutter build linux → Firebase App Distribution (Android)
```

---

## 12. Build & Run

```bash
# From project root
cd dope_wars_atl

# Get dependencies
flutter pub get

# Run on desktop
flutter run -d linux

# Build for release
flutter build linux --release

# Build Android APK
flutter build apk --release
```

### 12.1 Dependencies

| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.1.2 | State management |
| `google_fonts` | ^6.2.1 | Jersey M54 font for retro UI |
| `shared_preferences` | ^2.3.4 | Save game persistence |
| `path_provider` | ^2.1.5 | File system paths |
| `audioplayers` | ^6.4.0 | WAV sound effect playback |
| `flame` (future) | ^1.x | Game engine loop + multiplayer |

---

## 13. Testing Strategy

- **Unit tests**: GameState serialization, pricing model, encounter probabilities
- **Widget tests**: HUD rendering, shop screen, encounter overlay
- **Integration tests**: Full travel → buy → sell → travel loop
- **Manual testing**: All 3 difficulty modes, 11 locations, 5 weapons, 4 encounter types
