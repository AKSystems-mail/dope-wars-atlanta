import 'dart:ui';
import 'product.dart';

class Location {
  final String id;
  final String name;
  final String description;
  final Color accentColor;
  final List<String> martaConnections; // location ids reachable via MARTA
  final List<String> highwayConnections; // location ids reachable via Drive/Ryde
  final List<Product> products; // products available at this location
  final bool isBank;
  final bool isWeaponShop;
  final bool isCouncilman;
  final bool isBookbagUpgrade;
  final bool isTravelable; // false = reserved for future multiplayer mode

  const Location({
    required this.id,
    required this.name,
    required this.description,
    required this.accentColor,
    this.martaConnections = const [],
    this.highwayConnections = const [],
    this.products = const [],
    this.isBank = false,
    this.isWeaponShop = false,
    this.isCouncilman = false,
    this.isBookbagUpgrade = false,
    this.isTravelable = true,
  });

  Product? getProductById(String productId) {
    try {
      return products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  static final List<Location> defaults = [
    // ── TRAVELABLE (6) ──
    Location(
      id: 'west_end',
      name: 'West End',
      description: 'Weapons spot. Keep your head up.',
      accentColor: const Color(0xFFe53935),
      martaConnections: ['midtown'],
      highwayConnections: ['midtown', 'decatur'],
      products: [
        Product.defaults[0],
        Product.defaults[3],
      ],
      isWeaponShop: true,
    ),
    Location(
      id: 'midtown',
      name: 'Midtown',
      description: 'The Bank. Money moves here.',
      accentColor: const Color(0xFF1e88e5),
      martaConnections: ['little_five'],
      highwayConnections: ['buckhead', 'decatur', 'west_end'],
      products: [
        Product.defaults[0],
        Product.defaults[2],
      ],
      isBank: true,
    ),
    Location(
      id: 'little_five',
      name: 'Little Five Points',
      description: 'Eclectic. Underground. Bookbag upgrades here.',
      accentColor: const Color(0xFFab47bc),
      martaConnections: ['midtown', 'decatur'],
      highwayConnections: ['decatur'],
      products: [
        Product.defaults[2],
        Product.defaults[4],
      ],
      isBookbagUpgrade: true,
    ),
    Location(
      id: 'buckhead',
      name: 'Buckhead',
      description: 'The Councilman holds court here. Money talks.',
      accentColor: const Color(0xFFfdd835),
      martaConnections: ['midtown'],
      highwayConnections: ['midtown', 'decatur', 'cobb'],
      products: [
        Product.defaults[0],
        Product.defaults[2],
        Product.defaults[3],
      ],
      isCouncilman: true,
    ),
    Location(
      id: 'decatur',
      name: 'Decatur',
      description: 'College town. Solid middle market.',
      accentColor: const Color(0xFFfb8c00),
      martaConnections: ['little_five'],
      highwayConnections: ['little_five', 'midtown', 'buckhead', 'cobb', 'west_end'],
      products: [
        Product.defaults[0],
        Product.defaults[1],
        Product.defaults[2],
        Product.defaults[4],
      ],
    ),
    Location(
      id: 'cobb',
      name: 'Cobb County',
      description: 'Out past the perimeter. Different rules out here.',
      accentColor: const Color(0xFF78909c),
      martaConnections: [], // No MARTA access
      highwayConnections: ['buckhead', 'decatur'],
      products: [
        Product.defaults[0],
        Product.defaults[1],
      ],
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
