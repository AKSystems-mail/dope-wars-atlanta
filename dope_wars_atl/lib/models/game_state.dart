import 'dart:math';
import 'weapon.dart';
import 'location.dart';
import 'market.dart';

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

  /// 'classic' — every hood open, race the calendar for net worth.
  /// 'progressive' — the city unlocks as you earn it, and owning it is the win.
  /// A configuration of this same state, not a second engine.
  /// See docs/PROGRESSIVE_SPEC.md.
  String mode;

  /// Hoods open for travel. Ignored in Classic, where all six always are.
  Set<String> unlockedHoods;

  /// Internal 0-100. Never rendered as a number: Classic hides it entirely,
  /// Progressive shows only a state word (docs/DESIGN_DECISIONS.md D9).
  int heat;

  /// Items found rather than bought. The MARTA card is the first instance of a
  /// general mechanism (`SPEC.md` §6), so this is a map, not a flag.
  Map<String, bool> items;

  /// The informant, Progressive's gate. Armed by a cash threshold; once armed
  /// he turns up on a roll bounded by [informantSightingsBound] so an unlucky
  /// run cannot lose to a coin flip (D13).
  bool informantArmed;
  int informantArrivals;

  /// The market for wherever we are right now. Resolved once per arrival and
  /// held until the next one — see [ensureMarket] and lib/models/market.dart.
  Market? market;

  /// Hoods whose reputation the player has learned. Classic fills this by
  /// visiting; Progressive fills it when the informant tells them.
  Set<String> knownHoods;

  /// Progressive's unlock sequence, walking the ring: each new hood extends an
  /// arc the player can already run (docs/PROGRESSIVE_SPEC.md §3).
  static const List<String> unlockOrder = ['little_five', 'midtown', 'west_end', 'cobb'];

  /// Where Progressive starts. Buckhead is the cheap blunts source and Decatur
  /// pays for blunts, so the opening trip is the first leg of the ring.
  static const List<String> startingHoods = ['buckhead', 'decatur'];

  static const String martaCard = 'marta_card';
  static const int heatMax = 100;
  static const int heatPerTrip = 1;
  static const int heatPostWinPerTrip = 3;
  static const int layLowHeatDrop = 10;
  static const int informantSightingsBound = 3;
  static const int informantAppearPercent = 45;

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

  static int startingCashFor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 6000;
      case 'hard':
        return 2000;
      default:
        return 4000;
    }
  }

  static int startingDebtFor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 5000;
      case 'hard':
        return 15000;
      default:
        return 10000;
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
    this.mode = 'classic',
    Set<String>? unlockedHoods,
    this.heat = 0,
    Map<String, bool>? items,
    this.informantArmed = false,
    this.informantArrivals = 0,
    this.market,
    Set<String>? knownHoods,
  })  : inventory = inventory ?? {},
        weaponSlots = weaponSlots ?? [WeaponSlot.fists()],
        unlockedHoods = unlockedHoods ??
            (mode == 'progressive' ? startingHoods.toSet() : <String>{}),
        items = items ?? {},
        knownHoods = knownHoods ?? <String>{};

  factory GameState.fromDifficulty(String difficulty, {String mode = 'classic'}) {
    return GameState(
      cash: startingCashFor(difficulty),
      debt: startingDebtFor(difficulty),
      difficulty: difficulty,
      mode: mode,
    );
  }

  Location get currentLocation => Location.getById(currentLocationId);

  int get netWorth => cash + bankBalance - debt;

  int get inventoryCount =>
      inventory.values.fold(0, (sum, qty) => sum + qty);

  bool get canCarryMore => inventoryCount < bagCapacity;

  int get remainingSpace => bagCapacity - inventoryCount;

  // ---- MODE ----

  bool get isProgressive => mode == 'progressive';

  bool isUnlocked(String hoodId) =>
      !isProgressive || unlockedHoods.contains(hoodId);

  bool get hasMartaCard => items[martaCard] ?? false;

  /// The next hood the informant will open, or null when the city is yours.
  String? get nextUnlockHood {
    for (final id in unlockOrder) {
      if (!unlockedHoods.contains(id)) return id;
    }
    return null;
  }

  int get unlocksDone => unlockOrder.where(unlockedHoods.contains).length;

  /// Progressive's win: every hood open and the Councilman square.
  bool get ownsTheCity => isProgressive && nextUnlockHood == null && debt <= 0;

  /// The cash mark that arms the informant. Scales with progress so the ask
  /// keeps pace. These are tuning numbers, not design (D13).
  int get informantThreshold =>
      (startingCashFor(difficulty) * 1.5 * (unlocksDone + 1)).round();

  /// A run can only be bailed out while it is still being played for something.
  /// Post-win Progressive has no safety net (D18).
  bool get bailoutAvailable => !(isProgressive && won);

  // ---- HEAT ----

  /// Encounter odds scale with this: 1.0 at zero heat, 2.0 at boiling.
  double get heatFactor {
    final factor = 1.0 + heat / heatMax;
    // Twice the odds at boiling is plenty, and the clamp means a future tuning
    // change to accrual cannot quietly turn every trip into an encounter.
    return factor > 2.0 ? 2.0 : factor;
  }

  String get heatLabel {
    if (heat < 30) return 'Cool';
    if (heat < 70) return 'Warm';
    return 'Hot';
  }

  void raiseHeat(int amount) {
    if (amount <= 0) return;
    heat = (heat + amount).clamp(0, heatMax);
  }

  /// Lay low for a day: the **only** way heat comes down (D5). Time passes,
  /// which is what gives patience a price in a capped run. Post-win there is no
  /// cooling at all — the squeeze only tightens.
  void layLow() {
    if (!won) {
      heat = (heat - layLowHeatDrop).clamp(0, heatMax);
    }
    final dayBefore = day;
    // Same step as travel, so a lay-low day costs the same as a travel day.
    advanceTime(2);
    if (day == dayBefore) advanceDay();
    applyDailyInterest();
  }

  // ---- MARKET ----

  bool knowsHood(String hoodId) => knownHoods.contains(hoodId);

  /// The market here, resolved on arrival and then held.
  ///
  /// Safe to call from anywhere: it re-rolls only when the hood has changed, so
  /// the old save-with-no-market resolves exactly once and every arrival gets a
  /// fresh shelf without any caller having to remember to ask for one.
  ///
  /// Arriving also teaches you the hood, which is Classic's reputation rule. The
  /// informant adds to the same set for Progressive.
  Market ensureMarket({Random? rng}) {
    final existing = market;
    if (existing != null && existing.hoodId == currentLocationId) {
      knownHoods.add(currentLocationId);
      return existing;
    }
    final resolved = Market.resolve(
      currentLocation,
      visitIndex: (existing?.visitIndex ?? 0) + 1,
      rng: rng,
    );
    market = resolved;
    knownHoods.add(currentLocationId);
    return resolved;
  }

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
  ///
  /// Classic: win means surviving the cap with the debt cleared. Progressive:
  /// owning the city is the win, and it does **not** end the run — the overlay
  /// celebrates it, dismissing it puts you back in the same game, and from then
  /// on there is no cooling and no bailout until you are out of product or
  /// money (D12, D16, D18).
  String? checkGameOver() {
    if (gameOver) return null;

    if (isProgressive && !won && ownsTheCity) {
      won = true;
      gameOver = true;
      return 'YOU OWN THE CITY\n'
          'Every hood is open and the Councilman is square.\n'
          'Nothing left to prove here — but the heat is still rising.';
    }

    // Empty pockets and an empty bag ends any run.
    if (cash <= 0 && inventoryCount <= 0) {
      gameOver = true;
      return isProgressive
          ? 'GAME OVER\nEmpty pockets and an empty bag.\nOut here that is the end of the road.'
          : 'GAME OVER\nYou\'re broke with nothing to sell.\nThe Councilman might help... for a price.';
    }

    if (day > maxDays) {
      if (isProgressive) {
        gameOver = true;
        return 'TIME UP\nThe city is not yours yet.\nBut you are still standing.';
      }
      if (debt <= 0) {
        won = true;
        gameOver = true;
        return 'YOU WIN!\nSurvived $totalDaysPassed days.\nNet worth: \$${netWorth}';
      }
      gameOver = true;
      return 'GAME OVER\nYou ran out of time with debt remaining.';
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
    // Charge only what's actually owed — an over-typed amount must not burn the excess.
    final payment = amount > debt ? debt : amount;
    if (cash < payment) return false;
    cash -= payment;
    debt -= payment;
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
  //
  // Price variation lives in Market.pricesFor. Buy and sell are derived from one
  // local level, so a same-hood round trip loses by construction and no rebuild
  // can change a quoted price. See docs/PRICING_SPEC.md.

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
        'mode': mode,
        'unlockedHoods': unlockedHoods.toList(),
        'heat': heat,
        'items': items,
        'informantArmed': informantArmed,
        'informantArrivals': informantArrivals,
        'market': market?.toJson(),
        'knownHoods': knownHoods.toList(),
      };

  /// A save written before the v3 map rework may hold a location id that no
  /// longer exists - snap it to the default so the state stays navigable.
  static String _knownLocationId(Object? id) =>
      id is String && Location.defaults.any((l) => l.id == id) ? id : 'buckhead';

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        currentLocationId: _knownLocationId(json['currentLocationId']),
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
        // Everything below is absent on a save written before Progressive
        // existed. The defaults put such a save in Classic with every hood
        // open, which is exactly what it was.
        mode: json['mode'] as String? ?? 'classic',
        unlockedHoods: json['unlockedHoods'] == null
            ? null
            : (json['unlockedHoods'] as List).cast<String>().toSet(),
        heat: json['heat'] as int? ?? 0,
        items: (json['items'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as bool)),
        informantArmed: json['informantArmed'] as bool? ?? false,
        informantArrivals: json['informantArrivals'] as int? ?? 0,
        // Absent on any save written before the pricing rework; ensureMarket
        // resolves one on first use rather than a migration.
        market: json['market'] == null
            ? null
            : Market.fromJson((json['market'] as Map).cast<String, dynamic>()),
        knownHoods: ((json['knownHoods'] as List?) ?? const [])
            .cast<String>()
            .toSet(),
      );
}
