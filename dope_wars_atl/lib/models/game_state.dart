import 'dart:math';
import 'weapon.dart';
import 'location.dart';

class GameState {
  String currentLocationId;
  int cash;
  int debt;
  int bankBalance;
  int day;
  int maxDays;
  int gameHour; // 0-23, current time of day
  Map<String, int> inventory;
  List<WeaponSlot> weaponSlots;
  int bagCapacity;
  int bagUsed;
  bool gameOver;
  bool won;
  int totalDaysPassed;
  String difficulty; // 'easy', 'normal', 'hard'
  bool soundEnabled;

  /// Display name for the difficulty setting
  /// 'easy' → 'Mount Paran', 'normal' → 'East Atlanta', 'hard' → 'Hapeville'
  static String difficultyDisplayName(String d) {
    switch (d) {
      case 'easy':
        return 'Mount Paran';
      case 'hard':
        return 'Hapeville';
      default:
        return 'East Atlanta';
    }
  }

  GameState({
    this.currentLocationId = 'buckhead',
    this.cash = 4000,
    this.debt = 10000,
    this.bankBalance = 0,
    this.day = 1,
    this.maxDays = 30,
    this.gameHour = 8, // Start at 8 AM
    Map<String, int>? inventory,
    List<WeaponSlot>? weaponSlots,
    this.bagCapacity = 100,
    this.bagUsed = 0,
    this.gameOver = false,
    this.won = false,
    this.totalDaysPassed = 0,
    this.difficulty = 'normal',
    this.soundEnabled = true,
  })  : inventory = inventory ?? {},
        weaponSlots = weaponSlots ?? [WeaponSlot.fists()];

  factory GameState.fromDifficulty(String difficulty) {
    int cash, debt;
    switch (difficulty) {
      case 'easy':
        cash = 6000;
        debt = 5000;
        break;
      case 'hard':
        cash = 2000;
        debt = 15000;
        break;
      default:
        cash = 4000;
        debt = 10000;
        break;
    }
    return GameState(
      cash: cash,
      debt: debt,
      difficulty: difficulty,
    );
  }

  Location get currentLocation => Location.getById(currentLocationId);

  int get netWorth => cash + bankBalance - debt;

  int get inventoryCount =>
      inventory.values.fold(0, (sum, qty) => sum + qty);

  bool get canCarryMore => inventoryCount < bagCapacity;

  int get remainingSpace => bagCapacity - inventoryCount;

  // ---- WEAPON SLOTS ----

  /// The currently equipped weapon (first slot marked equipped, or fists)
  Weapon get equippedWeapon {
    for (final slot in weaponSlots) {
      if (slot.equipped) return slot.weapon;
    }
    // Fallback — ensure at least fists are equipped
    if (weaponSlots.isEmpty) {
      weaponSlots.add(WeaponSlot.fists());
    }
    weaponSlots.first.equipped = true;
    return weaponSlots.first.weapon;
  }

  int get equippedDurability {
    for (final slot in weaponSlots) {
      if (slot.equipped) return slot.durability;
    }
    return 9999;
  }

  int get weaponSlotCount => weaponSlots.length;
  static const int maxWeaponSlots = 3;

  /// Buy a new weapon. If slots full, replaces the lowest-value non-fists weapon.
  /// Returns true if purchased, false if can't afford.
  bool buyWeapon(Weapon weapon) {
    if (cash < weapon.price) return false;
    cash -= weapon.price;

    // Check if we already own this weapon — recharge it instead
    for (final slot in weaponSlots) {
      if (slot.weapon.id == weapon.id && !slot.isBroken) {
        slot.durability = weapon.maxDurability;
        slot.equipped = true;
        // Unequip others
        for (final other in weaponSlots) {
          if (other != slot) other.equipped = false;
        }
        return true;
      }
    }

    // Has space? Add new slot
    if (weaponSlots.length < maxWeaponSlots) {
      weaponSlots.add(WeaponSlot(weapon: weapon, durability: weapon.maxDurability, equipped: true));
      // Unequip others
      for (final other in weaponSlots) {
        if (other.weapon.id != weapon.id) other.equipped = false;
      }
      return true;
    }

    // Slots full — replace lowest-value non-fists non-equipped weapon
    WeaponSlot? replace;
    for (final slot in weaponSlots) {
      if (slot.weapon.isFists) continue;
      if (slot.equipped) continue;
      if (replace == null || slot.weapon.price < replace.weapon.price) {
        replace = slot;
      }
    }

    if (replace != null) {
      weaponSlots.remove(replace);
      weaponSlots.add(WeaponSlot(weapon: weapon, durability: weapon.maxDurability, equipped: true));
      // Unequip others
      for (final other in weaponSlots) {
        if (other.weapon.id != weapon.id) other.equipped = false;
      }
      return true;
    }

    // All non-fists slots are equipped — refund (can't replace equipped)
    cash += weapon.price;
    return false;
  }

  /// Equip a weapon by slot index
  void equipWeapon(int index) {
    if (index < 0 || index >= weaponSlots.length) return;
    for (int i = 0; i < weaponSlots.length; i++) {
      weaponSlots[i].equipped = i == index;
    }
  }

  /// Use one durability point on the equipped weapon.
  /// Returns true if the weapon broke (auto-switch to next).
  bool useDurability() {
    for (int i = 0; i < weaponSlots.length; i++) {
      if (weaponSlots[i].equipped) {
        weaponSlots[i].durability--;
        if (weaponSlots[i].isBroken) {
          weaponSlots[i].equipped = false;
          // Auto-switch to next available non-broken weapon
          _autoSwitchWeapon();
          return true; // weapon broke
        }
        return false;
      }
    }
    return false;
  }

  /// Confiscate the equipped weapon (when arrested)
  void confiscateEquippedWeapon() {
    for (int i = 0; i < weaponSlots.length; i++) {
      if (weaponSlots[i].equipped && !weaponSlots[i].weapon.isFists) {
        weaponSlots.removeAt(i);
        break;
      }
    }
    _autoSwitchWeapon();
  }

  /// Auto-switch to best available weapon
  void _autoSwitchWeapon() {
    if (weaponSlots.isEmpty) {
      weaponSlots.add(WeaponSlot.fists());
      return;
    }
    // First try to equip any non-broken non-fists weapon
    for (final slot in weaponSlots) {
      if (!slot.weapon.isFists && !slot.isBroken) {
        slot.equipped = true;
        return;
      }
    }
    // Fall back to fists
    for (final slot in weaponSlots) {
      if (slot.weapon.isFists) {
        slot.equipped = true;
        slot.durability = 9999; // Fists never stay broken
        return;
      }
    }
    // No fists found — add them
    weaponSlots.add(WeaponSlot.fists());
  }

  void advanceDay() {
    day++;
    totalDaysPassed++;
  }

  /// Advance game time by [hours] (1-6), wrapping at 24.
  /// Automatically advances the day counter when crossing midnight.
  /// Returns the new hour.
  int advanceTime(int hours) {
    final oldHour = gameHour;
    gameHour = (gameHour + hours) % 24;
    // If old hour was after new hour, we crossed midnight
    if (oldHour + hours >= 24) {
      advanceDay();
    }
    return gameHour;
  }

  /// Time-of-day label for UI display
  String get timeOfDayLabel {
    if (gameHour < 6) return 'Late Night';
    if (gameHour < 12) return 'Morning';
    if (gameHour < 17) return 'Afternoon';
    if (gameHour < 21) return 'Evening';
    return 'Night';
  }

  /// Ryde surge multiplier based on current game hour
  double get rydeSurgeMultiplier {
    // Rush hour: 7-9 AM (morning commute), 4-7 PM (evening commute)
    if ((gameHour >= 7 && gameHour <= 9) || (gameHour >= 16 && gameHour <= 19)) {
      return 1.5 + (gameHour.isEven ? 0.3 : 0.0); // 1.5x-1.8x during rush
    }
    // Late night: 11 PM - 4 AM
    if (gameHour >= 23 || gameHour <= 4) {
      return 1.3;
    }
    return 1.0;
  }

  /// Apply 2% daily interest on debt at the start of each day
  void applyDailyInterest() {
    if (debt > 0) {
      final interest = (debt * 0.02).round();
      if (interest > 0) debt += interest;
    }
    // Bank interest: 1% on balance
    if (bankBalance > 0) {
      final bankInterest = (bankBalance * 0.01).round();
      if (bankInterest > 0) bankBalance += bankInterest;
    }
  }

  /// Check and update game over/win state. Returns a message if game is over.
  String? checkGameOver() {
    if (won || gameOver) return null;

    // Win: survived all days and debt is paid off
    if (day > maxDays) {
      if (debt <= 0) {
        won = true;
        gameOver = true;
        return 'YOU WIN!\nSurvived $totalDaysPassed days.\nNet worth: \$${netWorth}';
      } else {
        gameOver = true;
        return 'GAME OVER\nYou ran out of time with debt remaining.';
      }
    }

    // Cash = 0 and inventory = 0 → game over (bailout available)
    if (cash <= 0 && inventoryCount <= 0) {
      gameOver = true;
      return 'GAME OVER\nYou\'re broke with nothing to sell.\nThe Councilman might help... for a price.';
    }

    return null;
  }

  /// Apply Councilman bankruptcy bailout
  void bankruptcyBailout() {
    debt += 2000; // Heavy debt added
    cash = 500; // Walking around money
    gameOver = false; // Continue playing
  }

  // ---- INVENTORY ----

  void addToInventory(String productId, int quantity) {
    inventory.update(productId, (existing) => existing + quantity,
        ifAbsent: () => quantity);
    bagUsed = inventoryCount;
  }

  void removeFromInventory(String productId, int quantity) {
    if (!inventory.containsKey(productId)) return;
    final current = inventory[productId]!;
    if (current <= quantity) {
      inventory.remove(productId);
    } else {
      inventory[productId] = current - quantity;
    }
    bagUsed = inventoryCount;
  }

  /// Lose a percentage of inventory (for encounters)
  void loseInventoryPercent(double percent) {
    final total = inventoryCount;
    if (total == 0) return;
    final toLose = (total * percent).round().clamp(1, total);
    int remaining = toLose;
    final keys = inventory.keys.toList()..shuffle();
    for (final key in keys) {
      if (remaining <= 0) break;
      final qty = inventory[key]!;
      if (qty <= remaining) {
        inventory.remove(key);
        remaining -= qty;
      } else {
        inventory[key] = qty - remaining;
        remaining = 0;
      }
    }
    bagUsed = inventoryCount;
  }

  /// Lose a percentage of cash (for encounters)
  void loseCashPercent(double percent) {
    final loss = (cash * percent).round().clamp(1, cash);
    cash -= loss;
  }

  bool upgradeBag(int cost, int newCapacity) {
    if (cash < cost) return false;
    cash -= cost;
    bagCapacity = newCapacity;
    bagUsed = inventoryCount;
    return true;
  }

  // ---- BANK ----

  bool deposit(int amount) {
    if (cash < amount) return false;
    cash -= amount;
    bankBalance += amount;
    return true;
  }

  bool withdraw(int amount) {
    if (bankBalance < amount) return false;
    bankBalance -= amount;
    cash += amount;
    return true;
  }

  // ---- COUNCILMAN ----

  bool payDebt(int amount) {
    if (cash < amount) return false;
    cash -= amount;
    debt -= amount;
    if (debt < 0) debt = 0;
    return true;
  }

  bool borrowFromCouncilman(int amount) {
    debt += amount;
    cash += amount;
    return true;
  }

  /// Councilman bailout after arrest — added to debt
  void bailoutFromArrest(int bailAmount) {
    debt += bailAmount;
    // Don't touch cash — the Councilman fronts it
  }

  // ---- PRICING ----

  /// Random price variation for a product at a location
  /// variance: normal variation range (default 0.3 = ±30%)
  static int getPrice(int basePrice, {double variance = 0.3}) {
    final rng = Random();
    final variation = (basePrice * variance).round();
    return basePrice + rng.nextInt(variation * 2 + 1) - variation;
  }

  Map<String, dynamic> toJson() => {
        'currentLocationId': currentLocationId,
        'cash': cash,
        'debt': debt,
        'bankBalance': bankBalance,
        'day': day,
        'maxDays': maxDays,
        'inventory': inventory,
        'weaponSlots': weaponSlots.map((s) => s.toJson()).toList(),
        'bagCapacity': bagCapacity,
        'bagUsed': bagUsed,
        'gameOver': gameOver,
        'won': won,
        'totalDaysPassed': totalDaysPassed,
        'difficulty': difficulty,
        'soundEnabled': soundEnabled,
        'gameHour': gameHour,
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        currentLocationId: json['currentLocationId'] as String? ?? 'buckhead',
        cash: json['cash'] as int? ?? 4000,
        debt: json['debt'] as int? ?? 10000,
        bankBalance: json['bankBalance'] as int? ?? 0,
        day: json['day'] as int? ?? 1,
        maxDays: json['maxDays'] as int? ?? 30,
        inventory: (json['inventory'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
        weaponSlots: json['weaponSlots'] != null
            ? (json['weaponSlots'] as List)
                .map((s) => WeaponSlot.fromJson(s as Map<String, dynamic>))
                .toList()
            : [WeaponSlot.fists()],
        bagCapacity: json['bagCapacity'] as int? ?? 100,
        bagUsed: json['bagUsed'] as int? ?? 0,
        gameOver: json['gameOver'] as bool? ?? false,
        won: json['won'] as bool? ?? false,
        totalDaysPassed: json['totalDaysPassed'] as int? ?? 0,
        difficulty: json['difficulty'] as String? ?? 'normal',
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        gameHour: json['gameHour'] as int? ?? 8,
      );
}
