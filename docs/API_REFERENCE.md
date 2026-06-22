# Dope Wars Atlanta — API Reference

> **Internal Services & Data Models Reference**  
> Last Updated: 2026-06-22

---

## 1. Data Models

### 1.1 GameState (`lib/models/game_state.dart`)

The central game state singleton. All game progression data lives here.

```dart
class GameState {
  // ── Constructor ──
  GameState();                              // Default (new game)
  GameState.fromDifficulty(String d);       // 'easy' | 'normal' | 'hard'
  GameState.fromJson(Map<String, dynamic>); // Deserialization

  // ── Player Finances ──
  int cash;              // Current cash on hand
  int bankBalance;       // Money in bank
  int debt;              // Outstanding debt
  int totalEarned;       // Lifetime earnings tracker
  int totalSpent;        // Lifetime spending tracker

  // ── Inventory ──
  Map<String, int> inventory;           // productId -> quantity
  int get inventoryCount;               // sum of all inventory values
  int maxInventory;                     // Backpack capacity
  Weapon equippedWeapon;                // Currently equipped weapon

  // ── Game Progression ──
  String currentLocationId;
  int day;                              // Current day (1-indexed)
  int maxDays;                          // Game ends at maxDays
  int hour;                             // 6-22 (16-hour day cycle)
  String weather;                       // 'clear', 'rain', 'fog', 'storm'
  String difficulty;                    // 'easy', 'normal', 'hard'

  // ── Metadata ──
  bool soundEnabled;
  bool gameStarted;
  DateTime lastSaveTime;
  int totalGamesPlayed;

  // ── Events ──
  double rydeSurgeMultiplier;           // 1.0 - 2.5
  List<String> triggeredEvents;

  // ── Computed Properties ──
  int get netWorth;                     // cash + bankBalance - debt
  String get timeOfDayLabel;            // 'Dawn', 'Morning', 'Afternoon', 'Evening', 'Night'
  Location get currentLocation;         // Lookup from location registry

  // ── Mutators ──
  void advanceTime(int hours);          // Advance hour, increment day if needed
  void applyDailyInterest();            // 2% of debt (configurable)
  void loseInventoryPercent(double pct);// Lose pct of inventory
  void confiscateEquippedWeapon();      // Remove equipped weapon (set to fists)
  bool useDurability();                 // Returns true if weapon breaks
  void addToInventory(String productId, int qty);
  bool removeFromInventory(String productId, int qty);
  void bailoutFromArrest(int fee);      // Councilman bailout
}
```

### 1.2 Location (`lib/models/location.dart`)

```dart
class Location {
  final String id;                      // e.g., 'five_points'
  final String name;                    // e.g., 'Five Points'
  final String description;             // Flavor text
  final Color accentColor;              // UI accent for this location
  final List<String> products;          // productIds available here
  final List<String> martaConnections;  // Location IDs reachable via MARTA
  final List<String> highwayConnections;// Location IDs reachable via Ryde/Drive
  final bool isBank;                    // Has bank service
  final bool isWeaponShop;              // Has weapon shop
  final bool isCouncilman;              // Has councilman
  final bool isBookbagUpgrade;          // Has backpack upgrade
  final Map<String, double> priceMultipliers; // productId -> multiplier

  static List<Location> get all;        // All 11 locations
  static Location? findById(String id); // Lookup helper
}
```

### 1.3 Product (`lib/models/product.dart`)

```dart
class Product {
  final String id;                      // e.g., 'motor_oil'
  final String name;                    // e.g., 'Motor Oil'
  final String emoji;                   // e.g., '🛢️'
  final int basePrice;                  // Base price in dollars
  final double volatility;              // Price fluctuation (0.1 = 10%)
  final String category;                // 'standard', 'premium', 'luxury'

  // ── Pricing ──
  int priceAtLocation(Location loc, {double eventMultiplier = 1.0});
  String get categoryLabel;

  static List<Product> get all;
  static Product? findById(String id);
}
```

### 1.4 Weapon (`lib/models/weapon.dart`)

```dart
class Weapon {
  final String id;                      // e.g., 'glock'
  final String name;                    // e.g., 'Glock 19'
  final String emoji;                   // e.g., '🔫'
  final double killChance;              // 0.0 - 1.0
  final int maxDurability;              // Max uses before break
  final int durability;                 // Current durability
  final int cost;                       // Purchase price

  bool get isBroken => durability <= 0;
  bool use();                           // Decrement durability, return false if broken
  Weapon copyWith({int? durability});

  static Weapon get fists;              // Default weapon (unlimited durability)
  static Weapon glock, bat, tec9, ak47; // Purchasable weapons
  static List<Weapon> get all;
}
```

---

## 2. Services

### 2.1 GameService (`lib/services/game_service.dart`)

**Type**: `ChangeNotifier`  
**Provider**: `ChangeNotifierProvider<GameService>`  
**Consumed by**: All game screens and widgets

```dart
class GameService extends ChangeNotifier {
  // ── State Accessors ──
  GameState? get state;
  bool get loading;
  Location get currentLocation;

  // ── Initialization ──
  Future<void> init();                              // Load save or create new
  Future<void> newGame({String difficulty, int gameDuration});
  Future<void> autoSave();

  // ── Travel ──
  bool canTravelTo(String locationId, {required bool isMarta});
  int getMartaCost();
  int getRydeCost();
  int getDriveCost();
  Future<bool> travelByMarta(String locationId);    // Returns true if encounter
  Future<bool> travelByRyde(String locationId);
  Future<bool> travelByDrive(String locationId);

  // ── Commerce ──
  int getBuyPrice(String productId);                // Price at current location
  int getSellPrice(String productId);
  bool canBuy(String productId, int quantity);
  Future<bool> buyProduct(String productId, int quantity);
  Future<bool> sellProduct(String productId, int quantity);

  // ── Inventory ──
  Map<String, int> get inventory;
  int get inventoryCount;
  int get maxInventory;
  bool hasItem(String productId);

  // ── Weapons ──
  void equipWeapon(Weapon weapon);
  List<Weapon> get purchasableWeapons;              // Weapons at current location
  Weapon get equippedWeapon;

  // ── Banking ──
  bool get hasBank;
  Future<bool> depositCash(int amount);
  Future<bool> withdrawCash(int amount);
  int get bankBalance;

  // ── Encounters (Read) ──
  String get encounterText;
  List<EncounterChoice>? get encounterChoices;
  bool get showEncounter;
  void dismissEncounter();                          // Close encounter overlay
  void refresh();                                   // Force notifyListeners

  // ── Ads ──
  String? get currentAdAsset;
  bool get showAd;
  void dismissAd();

  // ── Game Over ──
  bool get showGameOver;
  String get gameOverMessage;
  void dismissGameOver();
  void applyBankruptcyBailout();

  // ── Settings ──
  Future<void> updateSettings({
    required String difficulty,
    required int maxDays,
    required bool soundEnabled,
  });
}
```

### 2.2 SaveService (`lib/services/save_service.dart`)

```dart
class SaveService {
  static const _saveKey = 'dope_wars_atl_save';

  /// Load saved game state from SharedPreferences.
  /// Returns null if no save exists or deserialization fails.
  Future<GameState?> load();

  /// Persist current game state to SharedPreferences as JSON.
  Future<void> save(GameState state);

  /// Delete saved game data.
  Future<void> delete();
}
```

**Serialization format:**
```json
{
  "cash": 15000,
  "bankBalance": 0,
  "debt": 0,
  "inventory": {"motor_oil": 5, "coolant": 2},
  "equippedWeaponId": "fists",
  "equippedWeaponDurability": -1,
  "currentLocationId": "five_points",
  "day": 1,
  "maxDays": 30,
  "hour": 8,
  "weather": "clear",
  "difficulty": "easy",
  "soundEnabled": true,
  "rydeSurgeMultiplier": 1.0,
  "totalEarned": 0,
  "totalSpent": 0,
  "gameStarted": true,
  "lastSaveTime": "2026-06-22T10:30:00.000Z",
  "totalGamesPlayed": 1,
  "triggeredEvents": []
}
```

### 2.3 SoundService (`lib/services/sound_service.dart`)

```dart
class SoundService {
  void setVolume(double value);     // 0.0 - 1.0
  void playMartaChime();            // assets/sounds/marta_chime.wav
  void playCarHorn();               // assets/sounds/car_horn.wav
  void playCashRegister();          // assets/sounds/cash_register.wav
  void playEncounter();             // assets/sounds/encounter.wav
  void playWeaponFire();            // assets/sounds/weapon_fire.wav
  void stopAll();
  void dispose();
}
```

### 2.4 AdService (`lib/services/ad_service.dart`)

```dart
class AdService {
  _Ad? getRandomAd();                          // Random from 5 ads
  _Ad? getAdForMartaTravel();                  // Trigger ad for MARTA travel
  String? get currentAdAsset;                  // Current ad image path
}

class _Ad {
  final String title;
  final String subtitle;
  final String asset;                          // e.g., 'assets/ads/ryde.png'
}
```

---

## 3. Widget & Screen API

### 3.1 Screens

| Screen | Route/Entry | Props | Description |
|---|---|---|---|
| `BootScreen` | `BootScreen(onComplete)` | `VoidCallback onComplete` | 4s retro intro animation |
| `GameScreen` | `const GameScreen()` | None (uses Provider) | Main game with tabs |
| `MapScreen` | `Navigator.push(MapScreen())` | None (uses Provider) | Full-screen interactive map |

### 3.2 Widgets

| Widget | Purpose | Key Props |
|---|---|---|
| `HudWidget` | Persistant stats bar | None (Provider) |
| `PixelMap` | Interactive map container | None (Provider) |
| `PixelMapOverlayPainter` | Map markers/routes | `currentLocationId`, `travelPathFrom`, `travelPathTo`, `pulseAnimation`, `travelProgress` |
| `PixelHud` | Full HUD (stats + transport) | None (Provider) |
| `EncounterOverlay` | Encounter dialog | `text`, `choices`, `onDismiss` |
| `AdOverlay` | Ad interstitial | `asset`, `onDismiss` |
| `TravelAnimationScreen` | Travel transition | `transportType`, `destination`, `onArrive` |
| `ArrivalPopup` | Arrival dialog | `location`, `game` |
| `LocationCard` | Location list item | `location`, `isCurrent`, `onTap` |
| `NeonWidgets` | Neon-themed buttons/labels | Various |

### 3.3 Encounter System

```dart
class EncounterChoice {
  final String label;           // Button text (e.g., 'RUN', 'BRIBE $200')
  final Color color;            // Button accent color
  final VoidCallback onTap;     // Action on selection
}
```

---

## 4. Theme API

### 4.1 AppTheme (`lib/theme/app_theme.dart`)

```dart
class AppTheme {
  // ── Colors ──
  static const Color background = Color(0xFF0a0a0a);
  static const Color card = Color(0xFF1a1a1a);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF888888);
  static const Color accentGreen = Color(0xFF00ff9d);
  static const Color accentPink = Color(0xFFff4081);
  static const Color gold = Color(0xFFffd740);
  static const Color danger = Color(0xFFe53935);
  static const Color midtown = Color(0xFF26c6da);

  // ── Location Colors ──
  static const Color westEnd = Color(0xFFe53935);
  static const Color fivePoints = Color(0xFF42a5f5);
  static const Color midtownBlue = Color(0xFF1e88e5);
  static const Color littleFive = Color(0xFFab47bc);
  static const Color buckhead = Color(0xFFfdd835);
  static const Color decatur = Color(0xFFfb8c00);

  // ── Typography ──
  static TextStyle jersey10({double? size, Color? color});    // Smaller text
  static TextStyle jersey15({double? size, Color? color});    // Body text
  static TextStyle jersey20({double? size, Color? color});    // Headings

  // ── Decoration Builders ──
  static Decoration pixelButton({Color color, double padding});
  static Decoration pixelCard({Color accentColor, bool isActive});
  static Decoration pixelBorder({Color color, Color fillColor});
  static BoxDecoration glassPanel({double opacity});

  // ── Theme Data ──
  static ThemeData get darkTheme;
}
```

---

## 5. Utility Modules

### 5.1 Sprites (`lib/utils/sprites.dart`)

```dart
class Sprites {
  static String forLocation(String locationId);    // Location emoji
  static const String cash, bag, day, mapEmoji, shop, menu, bank, weapon, councilman;
  static const String marta, ryde, drive, travel;
  static const Map<String, String> products;       // productId -> emoji
  static String timeIcon(int hour);                 // Time-of-day emoji
  static const Map<String, String> encounters;      // encounterType -> emoji
  static const List<String> adAssets;               // Asset paths
  static const Map<String, Map<String, String>> actions;  // Action button configs
  static const Map<String, Map<String, String>> features; // Feature badge configs
}
```

### 5.2 Location Emoji (`lib/utils/location_emoji.dart`)

```dart
const Map<String, String> locationEmojis;     // locationId -> emoji
const Set<String> outsidePerimeterIds;        // Locations outside I-285
const Map<String, Color> locationAccents;     // locationId -> accent color
```

---

## 6. Error Codes & Edge Cases

| Condition | Behavior |
|---|---|
| Insufficient cash for travel | Button disabled / toast "Need \$X" |
| No connection to destination | Button disabled / tooltip "No route" |
| Inventory full | Buy button disabled / "Bag full" |
| No products to sell | Sell button disabled / "Nothing to sell" |
| Bank not at location | Bank button hidden |
| Weapon shop not at location | Weapon tab hidden |
| Debt exceeds cash + bank | Game over check on each tick |
| Save corruption on load | Fall back to new game |
| Missing asset file | Silent fail (debugPrint) |
