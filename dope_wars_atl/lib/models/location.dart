import 'dart:ui';
import 'product.dart';

class Location {
  final String id;
  final String name;
  final String description;
  final Color accentColor;
  final List<String> martaConnections; // location ids reachable via MARTA
  final List<String> highwayConnections; // location ids reachable via Drive/Ryde
  final bool isBank;
  final bool isWeaponShop;
  final bool isCouncilman;
  final bool isBookbagUpgrade;
  final bool isTravelable; // false = reserved for future multiplayer mode

  /// The ring — see docs/PRICING_SPEC.md §3. What this hood sells cheap, and
  /// what it pays up for. Every product has exactly one cheap source and one
  /// premium market across the six hoods. Cobb is the exception: no cheap
  /// source, and it pays premium on two.
  final String? cheapProductId;
  final List<String> premiumProductIds;

  /// True for the Progressive starting pair. Their shelves always carry BOTH
  /// ring products, so the opening trip — the one that teaches how the ring
  /// works — can never arrive to find nobody buying. Randomness starts after
  /// these two hoods.
  final bool guaranteeWholeRing;

  const Location({
    required this.id,
    required this.name,
    required this.description,
    required this.accentColor,
    this.martaConnections = const [],
    this.highwayConnections = const [],
    this.isBank = false,
    this.isWeaponShop = false,
    this.isCouncilman = false,
    this.isBookbagUpgrade = false,
    this.isTravelable = true,
    this.cheapProductId,
    this.premiumProductIds = const [],
    this.guaranteeWholeRing = false,
  });

  static Product _product(String id) =>
      Product.defaults.firstWhere((p) => p.id == id);

  static String _nameOf(String id) => _product(id).name;

  /// Always on this hood's shelf, whatever the per-visit roll does. Cheap source
  /// so a lap can always be started; both ring products at the starting pair;
  /// and one premium at Cobb so a trip out there is never wasted.
  List<String> get guaranteedProducts {
    if (guaranteeWholeRing) {
      return [
        if (cheapProductId != null) cheapProductId!,
        ...premiumProductIds,
      ];
    }
    if (cheapProductId != null) return [cheapProductId!];
    return premiumProductIds.take(1).toList();
  }

  /// What this hood is known for, for the location card. Shown only once the
  /// player knows the hood (Classic: first visit · Progressive: the informant).
  String get reputationLine {
    final parts = <String>[
      if (cheapProductId != null) 'cheap ${_nameOf(cheapProductId!)}',
      if (premiumProductIds.isNotEmpty)
        'pays for ${premiumProductIds.map(_nameOf).join(' and ')}',
    ];
    return parts.join(' · ');
  }

  /// Connection rule: martaConnections mirrors the road links EXCEPT for Cobb
  /// County, which has no MARTA at all. Cobb is the game's only restricted
  /// location — every other pair works by MARTA, Ryde and Drive, both ways.
  static final List<Location> defaults = [
    // ── TRAVELABLE (6) ──
    Location(
      id: 'west_end',
      name: 'West End',
      description: 'Weapons spot. Keep your head up.',
      accentColor: const Color(0xFFe53935),
      martaConnections: ['midtown', 'decatur'],
      highwayConnections: ['midtown', 'decatur'],
      cheapProductId: 'powda',
      premiumProductIds: const ['oxy'],
      isWeaponShop: true,
    ),
    Location(
      id: 'midtown',
      name: 'Midtown',
      description: 'The Bank. Money moves here.',
      accentColor: const Color(0xFF1e88e5),
      // west_end and buckhead both list Midtown under MARTA but the reverse
      // edges were missing, so the subway only ran one way. MARTA is
      // bidirectional; every other MARTA pair here already is.
      martaConnections: ['little_five', 'west_end', 'buckhead', 'decatur'],
      highwayConnections: ['buckhead', 'decatur', 'west_end'],
      cheapProductId: 'oxy',
      premiumProductIds: const ['shrooms'],
      isBank: true,
    ),
    Location(
      id: 'little_five',
      name: 'Little Five Points',
      description: 'Eclectic. Underground. Bookbag upgrades here.',
      accentColor: const Color(0xFFab47bc),
      martaConnections: ['midtown', 'decatur'],
      highwayConnections: ['decatur'],
      cheapProductId: 'shrooms',
      premiumProductIds: const ['acid'],
      isBookbagUpgrade: true,
    ),
    Location(
      id: 'buckhead',
      name: 'Buckhead',
      description: 'The Councilman holds court here. Money talks.',
      accentColor: const Color(0xFFfdd835),
      martaConnections: ['midtown', 'decatur'],
      highwayConnections: ['midtown', 'decatur', 'cobb'],
      cheapProductId: 'blunts',
      premiumProductIds: const ['powda'],
      guaranteeWholeRing: true,
      isCouncilman: true,
    ),
    Location(
      id: 'decatur',
      name: 'Decatur',
      description: 'College town. Solid middle market.',
      accentColor: const Color(0xFFfb8c00),
      martaConnections: ['little_five', 'west_end', 'midtown', 'buckhead'],
      highwayConnections: ['little_five', 'midtown', 'buckhead', 'cobb', 'west_end'],
      cheapProductId: 'acid',
      premiumProductIds: const ['blunts'],
      guaranteeWholeRing: true,
    ),
    Location(
      id: 'cobb',
      name: 'Cobb County',
      description: 'Out past the perimeter. Different rules out here.',
      accentColor: const Color(0xFF78909c),
      martaConnections: [], // No MARTA access
      highwayConnections: ['buckhead', 'decatur'],
      // No cheap source: Cobb is a cash-out detour, not a ring stop.
      premiumProductIds: const ['oxy', 'shrooms'],
    ),
  ];

  /// Never throws: a save written before the v3 map rework can hold a location
  /// id that no longer exists, and an uncaught StateError here takes down the
  /// whole game screen (release builds show only a gray box for it).
  static Location getById(String id) {
    return defaults.firstWhere((l) => l.id == id, orElse: () => defaults.first);
  }

  /// Returns only the 6 currently travelable locations
  static List<Location> get travelable => defaults.where((l) => l.isTravelable).toList();
}
