import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/game_state.dart';
import '../models/location.dart';
import '../models/market.dart';
import '../models/product.dart';
import '../models/weapon.dart';
import '../services/save_service.dart';
import '../widgets/encounter_overlay.dart';
import '../theme/app_theme.dart';
import 'sound_service.dart';

class GameService extends ChangeNotifier {
  GameState? _state;
  final SaveService _saveService = SaveService();
  final SoundService sound = SoundService();
  bool _loading = true;

  // Encounter state
  String _encounterText = '';
  List<EncounterChoice>? _encounterChoices;
  bool _showEncounter = false;

  // Ad state
  String? _currentAdAsset;
  bool _showAd = false;

  // Pricing events now live on the resolved Market, not as loose fields.

  // Game-over dialog state
  String _gameOverMessage = '';
  bool _showGameOver = false;

  GameState? get state => _state;
  bool get loading => _loading;
  String get encounterText => _encounterText;
  List<EncounterChoice>? get encounterChoices => _encounterChoices;
  bool get showEncounter => _showEncounter;
  String? get currentAdAsset => _currentAdAsset;
  bool get showAd => _showAd;
  /// The market here — resolved on arrival, held for the whole visit. Asking for
  /// it is always safe: it re-rolls only when the hood has changed.
  Market? get market => _state == null ? null : _state!.ensureMarket();

  /// The shelf here: what can be bought or sold this visit. You can only trade
  /// what a hood stocks — see docs/DESIGN_DECISIONS.md D8.
  List<Product> get marketProducts => market?.shelfProducts ?? const [];
  String get gameOverMessage => _gameOverMessage;
  bool get showGameOver => _showGameOver;

  bool get hasSave => _state != null;
  Location get currentLocation => _state!.currentLocation;

  // ---- INIT / SAVE / NEW GAME ----

  Future<void> init() async {
    _loading = true;
    notifyListeners();

    final saved = await _saveService.load();
    if (saved != null) {
      _state = saved;
    } else {
      _state = GameState();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> autoSave() async {
    if (_state != null) {
      await _saveService.save(_state!);
    }
  }

  Future<void> newGame({String difficulty = 'normal', int gameDuration = 30}) async {
    _state = GameState.fromDifficulty(difficulty);
    _state!.maxDays = gameDuration;
    await _saveService.delete();
    _showGameOver = false;
    _gameOverMessage = '';
    notifyListeners();
  }

  Future<void> updateSettings({
    required String difficulty,
    required int maxDays,
    required bool soundEnabled,
  }) async {
    if (_state == null) return;
    _state!.difficulty = difficulty;
    _state!.maxDays = maxDays;
    _state!.soundEnabled = soundEnabled;
    if (!soundEnabled) sound.stopAll();
    notifyListeners();
    await autoSave();
  }

  // ---- LOCATION / TRAVEL ----

  bool canTravelTo(String locationId, {required bool isMarta}) {
    final loc = currentLocation;
    if (isMarta) {
      return loc.martaConnections.contains(locationId);
    } else {
      return loc.highwayConnections.contains(locationId);
    }
  }

  int getMartaCost() => 5;
  int getRydeCost() {
    final base = Random().nextInt(36) + 25;
    final surge = _state?.rydeSurgeMultiplier ?? 1.0;
    return (base * surge).round();
  }

  /// Ryde surge multiplier label for UI display
  double get rydeSurge => _state?.rydeSurgeMultiplier ?? 1.0;

  /// Current time-of-day label
  String get timeOfDay => _state?.timeOfDayLabel ?? 'Morning';
  int getDriveCost() => 20;

  /// Returns true if an encounter was triggered (UI should show encounter overlay)
  Future<bool> travelByMarta(String locationId) async {
    if (!canTravelTo(locationId, isMarta: true)) return false;
    if (_state!.cash < getMartaCost()) return false;

    _state!.cash -= getMartaCost();
    _state!.currentLocationId = locationId;
    // A trip always costs one day. advanceTime() only rolls the day over when
    // the clock crosses midnight, so assert the day here instead of leaning on
    // it — otherwise it takes a dozen hops to age the game by a single day.
    final dayBefore = _state!.day;
    _state!.advanceTime(2);
    if (_state!.day == dayBefore) _state!.advanceDay();
    _state!.applyDailyInterest();

    // Play MARTA chime
    if (_state!.soundEnabled) sound.playMartaChime();

    // Arrival: resolve this visit's shelf and prices, and learn the hood. Done
    // before the encounter checks so an early return cannot leave the previous
    // hood's market in place.
    _state!.ensureMarket();

    _encounterText = '';
    _encounterChoices = null;
    _showEncounter = false;
    _showAd = false;

    // Check for encounters on MARTA
    if (_checkMartaEncounter()) {
      notifyListeners();
      await autoSave();
      return true;
    }

    // Check location events
    if (_checkLocationEvents('marta')) {
      notifyListeners();
      await autoSave();
      return true;
    }

    // Check game over
    _checkGameOver();

    // Trigger ad
    _currentAdAsset = _getRandomAdAsset();
    _showAd = true;

    notifyListeners();
    await autoSave();
    return false;
  }

  Future<bool> travelByRyde(String locationId) async {
    if (!canTravelTo(locationId, isMarta: false)) return false;
    final cost = getRydeCost();
    if (_state!.cash < cost) return false;

    _state!.cash -= cost;
    _state!.currentLocationId = locationId;
    // A trip always costs one day. advanceTime() only rolls the day over when
    // the clock crosses midnight, so assert the day here instead of leaning on
    // it — otherwise it takes a dozen hops to age the game by a single day.
    final dayBefore = _state!.day;
    _state!.advanceTime(2);
    if (_state!.day == dayBefore) _state!.advanceDay();
    _state!.applyDailyInterest();

    // Play car horn for Ryde
    if (_state!.soundEnabled) sound.playCarHorn();

    // Arrival: resolve this visit's shelf and prices (see travelByMarta).
    _state!.ensureMarket();

    _encounterText = '';
    _encounterChoices = null;
    _showEncounter = false;
    if (_checkRydeEncounter()) {
      notifyListeners();
      await autoSave();
      return true;
    }

    if (_checkLocationEvents('ryde')) {
      notifyListeners();
      await autoSave();
      return true;
    }

    if (locationId == 'midtown' && _checkWaterBoys()) {
      notifyListeners();
      await autoSave();
      return true;
    }

    if (locationId == 'west_end' && _checkYns()) {
      notifyListeners();
      await autoSave();
      return true;
    }

    _checkGameOver();

    notifyListeners();
    await autoSave();
    return false;
  }

  Future<bool> travelByDrive(String locationId) async {
    if (!canTravelTo(locationId, isMarta: false)) return false;
    if (_state!.cash < getDriveCost()) return false;

    _state!.cash -= getDriveCost();
    _state!.currentLocationId = locationId;
    // A trip always costs one day. advanceTime() only rolls the day over when
    // the clock crosses midnight, so assert the day here instead of leaning on
    // it — otherwise it takes a dozen hops to age the game by a single day.
    final dayBefore = _state!.day;
    _state!.advanceTime(1);
    if (_state!.day == dayBefore) _state!.advanceDay();
    _state!.applyDailyInterest();

    // Play car horn for Drive
    if (_state!.soundEnabled) sound.playCarHorn();

    // Arrival: resolve this visit's shelf and prices (see travelByMarta).
    _state!.ensureMarket();

    _encounterText = '';
    _encounterChoices = null;
    _showEncounter = false;
    if (_checkDriveEncounter()) {
      notifyListeners();
      await autoSave();
      return true;
    }

    if (_checkLocationEvents('drive')) {
      notifyListeners();
      await autoSave();
      return true;
    }

    if (locationId == 'midtown' && _checkWaterBoys()) {
      notifyListeners();
      await autoSave();
      return true;
    }

    if (locationId == 'west_end' && _checkYns()) {
      notifyListeners();
      await autoSave();
      return true;
    }

    _checkGameOver();

    notifyListeners();
    await autoSave();
    return false;
  }

  // ---- TRAVEL: CHECK ENCOUNTERS ----

  bool _checkMartaEncounter() {
    if (Random().nextInt(100) >= 3) return false; // 3% chance
    _setPoliceEncounter('MARTA POLICE');
    return true;
  }

  bool _checkRydeEncounter() {
    if (Random().nextInt(100) >= 3) return false; // 3% chance
    _setCopEncounter();
    return true;
  }

  bool _checkDriveEncounter() {
    if (Random().nextInt(100) >= 6) return false; // 6% chance
    // GSP chase
    if (Random().nextInt(100) < 75) {
      // Caught — arrested
      _setArrestedEncounter(
        '🚔 GSP CHASE\nBlue lights flash. You pull over.\nYou\'re arrested for trafficking.\n\nLose 75% of your inventory!\nWeapon confiscated!',
        applyConsequence: () {
          _state!.loseInventoryPercent(0.75);
          _state!.confiscateEquippedWeapon();
        },
      );
    } else {
      // Outran them
      _setEncounterBlock(
        '🚗💨 GSP CHASE\nYou outran the state patrol!\n\nYour heart is pounding but you\'re free.',
      );
    }
    return true;
  }

  bool _checkWaterBoys() {
    if (Random().nextInt(100) >= 8) return false; // 8% chance heading to Midtown
    if (_state!.inventoryCount <= 0) return false; // Nothing to take

    final lost = (_state!.inventoryCount * 0.3).round().clamp(1, _state!.inventoryCount);
    _setEncounterBlock(
      '💧 WATER BOYS\n\"Say, you got any water?\"\n\nThey swarm your ride and jack $lost units of product!\n\n\"Thanks, player.\"',
      onDismiss: () {
        _state!.loseInventoryPercent(0.3);
        _dissolveEncounter();
        refresh();
      },
    );
    return true;
  }

  bool _checkYns() {
    if (Random().nextInt(100) >= 10) return false; // 10% chance heading to West End
    // Weapon check
    if (_state!.equippedWeapon.id != 'fists') {
      _setEncounterBlock(
        '🫡 YNs\n\"Yo, what hood you claim?\"\n\nThey eye your ${_state!.equippedWeapon.emoji} and nod.\n\"Cool, cool. Stay safe out here.\"\n\nThey let you pass.',
      );
    } else {
      final loss = Random().nextInt(201) + 100; // $100-$300
      final actualLoss = loss > _state!.cash ? _state!.cash : loss;
      _setEncounterBlock(
        '🫡 YNs\n\"Yo, what hood you claim?\"\n\nYou ain\'t strapped. They take $actualLoss.\n\"Next time come correct.\"',
        onDismiss: () {
          _state!.cash -= actualLoss;
          if (_state!.cash < 0) _state!.cash = 0;
          _dissolveEncounter();
          refresh();
        },
      );
    }
    return true;
  }

  bool _checkLocationEvents(String travelMode) {
    return false; // Placeholder for future location-specific events
  }

  // ---- ENCOUNTER: POLICE / COP / ARREST ----

  void _setPoliceEncounter(String title) {
    _setEncounterWithChoices(
      '👮 $title\n\"Hold it right there!\"\n\nWhat do you do?',
      [
        EncounterChoice(
          label: 'RUN',
          color: AppTheme.westEnd,
          onTap: _runFromPolice,
        ),
        EncounterChoice(
          label: 'FIGHT',
          color: AppTheme.accentPink,
          onTap: _fightPolice,
        ),
      ],
    );
  }

  void _setCopEncounter() {
    _setEncounterWithChoices(
      '👮‍♂️ RYDE COP\n\"License and registration.\"\n\nHe smells something...',
      [
        EncounterChoice(
          label: 'BRIBE \$200',
          color: AppTheme.gold,
          onTap: _bribeCop,
        ),
        EncounterChoice(
          label: 'RUN',
          color: AppTheme.westEnd,
          onTap: _runFromPolice,
        ),
      ],
    );
  }

  void _runFromPolice() {
    // Run chance based on weapon
    final runChance = _state!.equippedWeapon.killChance * 0.6;
    if (Random().nextDouble() <= runChance) {
      _setEncounterBlock(
        '🏃‍♂️ You bolted!\n\nYou disappeared into the Atlanta night.\n\nClose one.',
        onDismiss: () {
          _dissolveEncounter();
          refresh();
        },
      );
    } else {
      _state!.useDurability();
      _setArrestedEncounter(
        '🚔 You got tackled!\n\nYou\'re cuffed and arrested.',
        applyConsequence: () {
          _state!.loseInventoryPercent(0.5);
        },
      );
    }
  }

  void _fightPolice() {
    final killChance = _state!.equippedWeapon.killChance;
    final broke = _state!.useDurability(); // consumes durability

    if (Random().nextDouble() <= killChance) {
      _setEncounterBlock(
        '💥 You won the fight!\n\n${_state!.equippedWeapon.name} did the job.\nOfficer down. You slip away.\n\n${broke ? 'Your weapon broke in the struggle!' : ''}',
        onDismiss: () {
          _dissolveEncounter();
          refresh();
        },
      );
    } else {
      _setArrestedEncounter(
        '😵 You got clobbered!\n\nWoke up in cuffs.\nLose 50% of inventory.',
        applyConsequence: () {
          _state!.loseInventoryPercent(0.5);
        },
      );
    }
  }

  void _bribeCop() {
    if (_state!.cash < 200) {
      _setArrestedEncounter(
        '😬 You don\'t have \$200!\n\nCop gets out.\nYou\'re arrested.',
      );
      return;
    }

    if (Random().nextInt(100) < 70) {
      _state!.cash -= 200;
      _setEncounterBlock(
        '💵 \"Have a safe night.\"\n\nCop pockets the bribe and walks away.\n-\$200',
        onDismiss: () {
          _dissolveEncounter();
          refresh();
        },
      );
    } else {
      _state!.cash -= 200;
      _setArrestedEncounter(
        '🙅 \"Step out of the vehicle.\"\n\nHe took your \$200 AND arrested you.',
      );
    }
  }

  void _setArrestedEncounter(String customText, {VoidCallback? applyConsequence}) {
    applyConsequence?.call();
    
    final fine = (_state!.cash * 0.5).round().clamp(100, 5000);
    _setEncounterWithChoices(
      customText,
      [
        EncounterChoice(
          label: 'PAY \$$fine',
          color: AppTheme.gold,
          onTap: () {
            _state!.cash -= fine > _state!.cash ? _state!.cash : fine;
            if (_state!.cash < 0) _state!.cash = 0;
            _dissolveEncounter();
            _checkGameOver();
            refresh();
          },
        ),
        EncounterChoice(
          label: 'CALL COUNCILMAN',
          color: AppTheme.accentPink,
          onTap: () {
            _state!.bailoutFromArrest(500);
            _dissolveEncounter();
            refresh();
          },
        ),
      ],
    );
  }

  // ---- ENCOUNTER: HELPERS ----

  void _setEncounterBlock(String text, {VoidCallback? onDismiss}) {
    _encounterText = text;
    _encounterChoices = null;
    _showEncounter = true;
    _onEncounterDismiss = onDismiss;
    if (_state?.soundEnabled ?? true) sound.playEncounter();
    notifyListeners();
  }

  VoidCallback? _onEncounterDismiss;

  void _setEncounterWithChoices(String text, List<EncounterChoice> choices) {
    _encounterText = text;
    _encounterChoices = choices;
    _showEncounter = true;
    _onEncounterDismiss = null;
    if (_state?.soundEnabled ?? true) sound.playEncounter();
    notifyListeners();
  }

  void _dissolveEncounter() {
    _encounterText = '';
    _encounterChoices = null;
    _showEncounter = false;
    _onEncounterDismiss = null;
  }

  /// Callback used by EncounterOverlay for informational-only encounters
  void dismissEncounter() {
    if (_onEncounterDismiss != null) {
      _onEncounterDismiss!();
    } else {
      _dissolveEncounter();
      refresh();
    }
  }

  /// Public method for UI to use when encounter was handled by choices
  void clearEncounter() {
    _dissolveEncounter();
    refresh();
  }

  // ---- AD ----

  void dismissAd() {
    _showAd = false;
    _currentAdAsset = null;
    notifyListeners();
  }

  String _getRandomAdAsset() {
    final ads = [
      'assets/ads/ryde.png',
      'assets/ads/councilman.png',
      'assets/ads/get_higher.png',
      'assets/ads/certified_whips.png',
      'assets/ads/the_varsity.png',
    ];
    return ads[Random().nextInt(ads.length)];
  }

  // ---- SHOPPING ----

  /// This visit's buy price, straight from the resolved market. Held, so the
  /// number the shop shows is the number the shop charges.
  int getBuyPrice(Product product) => market?.buyPriceOf(product.id) ?? 0;

  int getSellPrice(Product product) => market?.sellPriceOf(product.id) ?? 0;

  /// The note shown when this visit's event is touching a product.
  String? getPriceNote(Product product) {
    final m = market;
    if (m == null) return null;
    if (m.spikeProduct == product.id) return '🔥 DEMAND SPIKE';
    if (m.floodProduct == product.id) return '🌊 MARKET FLOOD';
    return null;
  }

  Future<bool> buyProduct(Product product, int quantity) async {
    if (_state == null) return false;
    final m = _state!.ensureMarket();
    // Stock-limited: you can only buy what this hood trades (D8).
    if (!m.has(product.id)) return false;
    final price = m.buyPriceOf(product.id) ?? 0;
    // A zero price would be a free purchase. Never let that through.
    if (price <= 0) return false;
    final total = price * quantity;
    if (_state!.cash < total) return false;
    if (_state!.remainingSpace < quantity) return false;

    _state!.cash -= total;
    _state!.addToInventory(product.id, quantity);
    if (_state!.soundEnabled) sound.playCashRegister();
    notifyListeners();
    await autoSave();
    return true;
  }

  Future<bool> sellProduct(String productId, int quantity) async {
    if (_state == null) return false;
    if (!_state!.inventory.containsKey(productId)) return false;
    final invQty = _state!.inventory[productId]!;
    final qty = quantity > invQty ? invQty : quantity;

    // Stock-limited: you can only sell what this hood trades (D8).
    final m = _state!.ensureMarket();
    if (!m.has(productId)) return false;
    final price = m.sellPriceOf(productId) ?? 0;
    if (price <= 0) return false;
    _state!.cash += price * qty;
    _state!.removeFromInventory(productId, qty);
    if (_state!.soundEnabled) sound.playCashRegister();
    notifyListeners();
    await autoSave();
    return true;
  }

  // ---- BANK ----

  Future<bool> deposit(int amount) async {
    if (_state == null || _state!.cash < amount) return false;
    _state!.deposit(amount);
    notifyListeners();
    await autoSave();
    return true;
  }

  Future<bool> withdraw(int amount) async {
    if (_state == null) return false;
    final result = _state!.withdraw(amount);
    if (result) {
      notifyListeners();
      await autoSave();
    }
    return result;
  }

  // ---- COUNCILMAN ----

  Future<bool> payDebt(int amount) async {
    if (_state == null) return false;
    final result = _state!.payDebt(amount);
    if (result) {
      notifyListeners();
      await autoSave();
    }
    _checkGameOver();
    return result;
  }

  Future<bool> borrowFromCouncilman(int amount) async {
    if (_state == null) return false;
    _state!.borrowFromCouncilman(amount);
    notifyListeners();
    await autoSave();
    return true;
  }

  // ---- BOOKBAG ----

  Future<bool> upgradeBookbag(int cost, int newCapacity) async {
    if (_state == null) return false;
    final result = _state!.upgradeBag(cost, newCapacity);
    if (result) {
      notifyListeners();
      await autoSave();
    }
    return result;
  }

  // ---- WEAPONS ----

  Future<bool> buyWeapon(Weapon weapon) async {
    if (_state == null) return false;
    final result = _state!.buyWeapon(weapon);
    if (result) {
      notifyListeners();
      await autoSave();
    }
    return result;
  }

  Future<void> equipWeapon(int index) async {
    if (_state == null) return;
    _state!.equipWeapon(index);
    notifyListeners();
    await autoSave();
  }

  // ---- PRICING EVENTS ----
  //
  // Both events are rolled when the market resolves on arrival and live on the
  // Market itself, so they move the local level and cannot open a buy-back
  // spread. See lib/models/market.dart.

  // ---- GAME OVER / WIN ----

  void _checkGameOver() {
    if (_state == null) return;
    final message = _state!.checkGameOver();
    if (message != null) {
      _gameOverMessage = message;
      _showGameOver = true;
      if (_state!.won) {
        _gameOverMessage = '🏆 $message';
      } else {
        _gameOverMessage = '💀 $message';
      }
      notifyListeners();
    }
  }

  void dismissGameOver() {
    _showGameOver = false;
    _gameOverMessage = '';
    notifyListeners();
  }

  /// Triggered when the player is broke and gets the bankruptcy bailout
  void applyBankruptcyBailout() {
    if (_state == null) return;
    _state!.bankruptcyBailout();
    _showGameOver = false;
    _gameOverMessage = '';
    notifyListeners();
    autoSave();
  }

  // ---- ENCOUNTER EXPOSURE FOR UI ----

  /// UI should call this when encounter overlay's onTap is triggered
  /// Used when the encounter is informational-only (no choices)
  void handleEncounterDismiss() {
    dismissEncounter();
  }

  /// Refresh listeners (used after encounter callbacks that don't auto-refresh)
  void refresh() {
    notifyListeners();
  }
}
