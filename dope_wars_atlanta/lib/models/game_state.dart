import 'dart:math';
import 'product.dart';
import 'location.dart';
import 'weapon.dart';

enum Difficulty {
  easy,    // Mount Paran
  normal,  // East Atlanta
  hard;    // Hapeville

  String get displayName {
    switch (this) {
      case Difficulty.easy: return 'Mount Paran';
      case Difficulty.normal: return 'East Atlanta';
      case Difficulty.hard: return 'Hapeville';
    }
  }

  int get startingCash {
    switch (this) {
      case Difficulty.easy: return 6000;
      case Difficulty.normal: return 4000;
      case Difficulty.hard: return 2000;
    }
  }

  int get startingDebt {
    switch (this) {
      case Difficulty.easy: return 5000;
      case Difficulty.normal: return 10000;
      case Difficulty.hard: return 15000;
    }
  }
}

class GameState {
  // Core
  Difficulty difficulty;
  int totalDays;
  int currentDay;
  bool isGameOver;

  // Finances
  int cash;
  int debt;
  int bankBalance;

  // Inventory
  int bagCapacity;
  int bagUpgradeLevel; // 0-3
  List<Product> inventory;

  // Weapons
  List<Weapon> equippedWeapons;

  // Location
  LocationType currentLocation;
  List<Location> locations;

  // State flags
  bool hasPaidOffDebt; // unlocks reduced encounter rates
  int fistsCooldownUntil; // day when fists are ready again

  // Travel
  TravelMode? lastTravelMode;

  GameState({
    required this.difficulty,
    this.totalDays = 30,
    this.currentDay = 1,
    this.isGameOver = false,
    int? cash,
    int? debt,
    this.bankBalance = 0,
    this.bagCapacity = 100,
    this.bagUpgradeLevel = 0,
    List<Product>? inventory,
    List<Weapon>? equippedWeapons,
    this.currentLocation = LocationType.buckhead,
    List<Location>? locations,
    this.hasPaidOffDebt = false,
    this.fistsCooldownUntil = 0,
    this.lastTravelMode,
  })  : cash = cash ?? difficulty.startingCash,
        debt = debt ?? difficulty.startingDebt,
        inventory = inventory ?? [],
        equippedWeapons = equippedWeapons ?? [Weapon(type: WeaponType.fists)],
        locations = locations ?? [];

  // ---- Computed Properties ----

  int get availableBagSpace => bagCapacity - totalInventoryCount;

  int get totalInventoryCount =>
      inventory.fold(0, (sum, p) => sum + p.quantity);

  int get weaponSlotCount => 3; // max weapon slots

  int get equippedWeaponCount => equippedWeapons.length;

  bool get isFistsReady => currentDay >= fistsCooldownUntil;

  double get debtInterestRate => 0.02; // 2% per day

  double get bankInterestRate => 0.005; // 0.5% per day

  // ---- Actions ----

  void advanceDay() {
    currentDay++;
    // Apply debt interest
    debt = (debt * (1 + debtInterestRate)).round();
    // Apply bank interest
    bankBalance = (bankBalance * (1 + bankInterestRate)).round();

    if (currentDay > totalDays) {
      isGameOver = true;
    }
  }

  /// Buy a product at the current location
  bool buyProduct(ProductType type, int quantity) {
    final loc = getCurrentLocation();
    if (loc == null) return false;

    final product = loc.availableProducts.firstWhere(
      (p) => p.type == type,
    );

    final totalCost = product.currentPrice * quantity;
    if (totalCost > cash) return false;
    if (quantity > availableBagSpace) return false;

    cash -= totalCost;

    // Add to inventory
    final existing = inventory.where((p) => p.type == type).firstOrNull;
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      inventory.add(Product(
        type: type,
        currentPrice: product.currentPrice,
        quantity: quantity,
      ));
    }

    return true;
  }

  /// Sell a product
  void sellProduct(ProductType type, {int? quantity}) {
    final existing = inventory.where((p) => p.type == type).firstOrNull;
    if (existing == null || existing.quantity <= 0) return;

    final sellQty = quantity ?? existing.quantity;
    final actualQty = min(sellQty, existing.quantity);

    final loc = getCurrentLocation();
    final buyPrice = loc?.availableProducts
        .where((p) => p.type == type)
        .firstOrNull
        ?.currentPrice;

    if (buyPrice != null) {
      cash += buyPrice * actualQty;
    }

    existing.quantity -= actualQty;
  }

  /// Upgrade bookbag (L5P only)
  bool upgradeBag() {
    const costs = [400, 1000, 3000];
    const capacities = [250, 600, 1000];

    if (bagUpgradeLevel >= 3) return false;
    if (currentLocation != LocationType.littleFivePoints) return false;

    final cost = costs[bagUpgradeLevel];
    if (cash < cost) return false;

    cash -= cost;
    bagUpgradeLevel++;
    bagCapacity = capacities[bagUpgradeLevel - 1];
    return true;
  }

  /// Buy a weapon (West End only)
  bool buyWeapon(WeaponType type) {
    if (currentLocation != LocationType.westEnd) return false;
    if (type == WeaponType.fists) return false; // already have them
    if (equippedWeaponCount >= weaponSlotCount) return false;

    final cost = type.cost;
    if (cash < cost) return false;

    cash -= cost;
    equippedWeapons.add(Weapon(type: type));
    return true;
  }

  /// Get the best available weapon for a fight
  Weapon getBestWeapon() {
    final usable = equippedWeapons
        .where((w) => !w.isBroken)
        .toList();

    if (usable.isEmpty) {
      // Shouldn't happen since fists are infinite, but just in case
      return Weapon(type: WeaponType.fists);
    }

    usable.sort((a, b) => b.type.winPercent.compareTo(a.type.winPercent));
    return usable.first;
  }

  /// Pay off debt
  void payDebt(int amount) {
    final actual = min(amount, debt);
    cash -= actual;
    debt -= actual;
    if (debt <= 0) {
      debt = 0;
      hasPaidOffDebt = true;
    }
  }

  /// Borrow money from Councilman
  void borrowMoney(int amount) {
    cash += amount;
    debt += amount;
  }

  /// Deposit to bank
  void deposit(int amount) {
    final actual = min(amount, cash);
    cash -= actual;
    bankBalance += actual;
  }

  /// Withdraw from bank
  void withdraw(int amount) {
    final actual = min(amount, bankBalance);
    bankBalance -= actual;
    cash += actual;
  }

  /// Get the current location object
  Location? getCurrentLocation() {
    return locations.where((l) => l.type == currentLocation).firstOrNull;
  }

  /// Calculate net worth for final score
  int get netWorth {
    int inventoryValue = 0;
    for (final item in inventory) {
      inventoryValue += item.currentPrice * item.quantity;
    }
    return cash + bankBalance + inventoryValue - debt;
  }

  // ---- Serialization ----

  Map<String, dynamic> toJson() => {
    'difficulty': difficulty.name,
    'totalDays': totalDays,
    'currentDay': currentDay,
    'isGameOver': isGameOver,
    'cash': cash,
    'debt': debt,
    'bankBalance': bankBalance,
    'bagCapacity': bagCapacity,
    'bagUpgradeLevel': bagUpgradeLevel,
    'inventory': inventory.map((p) => p.toJson()).toList(),
    'equippedWeapons': equippedWeapons.map((w) => w.toJson()).toList(),
    'currentLocation': currentLocation.name,
    'locations': locations.map((l) => l.toJson()).toList(),
    'hasPaidOffDebt': hasPaidOffDebt,
    'fistsCooldownUntil': fistsCooldownUntil,
  };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    difficulty: Difficulty.values.byName(json['difficulty'] as String),
    totalDays: json['totalDays'] as int,
    currentDay: json['currentDay'] as int,
    isGameOver: json['isGameOver'] as bool? ?? false,
    cash: json['cash'] as int?,
    debt: json['debt'] as int?,
    bankBalance: json['bankBalance'] as int? ?? 0,
    bagCapacity: json['bagCapacity'] as int? ?? 100,
    bagUpgradeLevel: json['bagUpgradeLevel'] as int? ?? 0,
    inventory: (json['inventory'] as List?)
        ?.map((p) => Product.fromJson(p as Map<String, dynamic>))
        .toList() ?? [],
    equippedWeapons: (json['equippedWeapons'] as List?)
        ?.map((w) => Weapon.fromJson(w as Map<String, dynamic>))
        .toList() ?? [Weapon(type: WeaponType.fists)],
    currentLocation: LocationType.values.byName(json['currentLocation'] as String),
    locations: (json['locations'] as List?)
        ?.map((l) => Location.fromJson(l as Map<String, dynamic>))
        .toList() ?? [],
    hasPaidOffDebt: json['hasPaidOffDebt'] as bool? ?? false,
    fistsCooldownUntil: json['fistsCooldownUntil'] as int? ?? 0,
  );
}

enum TravelMode { marta, ryde, drive }
