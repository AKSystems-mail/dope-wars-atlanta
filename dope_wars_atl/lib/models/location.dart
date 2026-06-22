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

    // ── FUTURE MULTIPLAYER LOCATIONS (kept in code, not travelable) ──
    Location(
      id: 'hapeville',
      name: 'Hapeville',
      description: 'Where it all starts. The bottom rung.',
      accentColor: const Color(0xFF9e9e9e),
      isTravelable: false,
      products: [
        Product.defaults[0],
        Product.defaults[1],
      ],
    ),
    Location(
      id: 'college_park',
      name: 'College Park',
      description: 'Quiet suburb. Decent prices.',
      accentColor: const Color(0xFF757575),
      isTravelable: false,
      products: [
        Product.defaults[0],
        Product.defaults[1],
        Product.defaults[4],
      ],
    ),
    Location(
      id: 'airport',
      name: 'Airport',
      description: 'Heavy traffic, heavy heat. Cops everywhere.',
      accentColor: const Color(0xFF616161),
      isTravelable: false,
      products: [
        Product.defaults[0],
        Product.defaults[1],
        Product.defaults[2],
        Product.defaults[3],
        Product.defaults[4],
      ],
    ),
    Location(
      id: 'east_point',
      name: 'East Point',
      description: 'Gritty. Real. The product moves here.',
      accentColor: const Color(0xFF8d6e63),
      isTravelable: false,
      products: [
        Product.defaults[0],
        Product.defaults[1],
        Product.defaults[3],
      ],
    ),
    Location(
      id: 'five_points',
      name: 'Five Points',
      description: 'The hub. MARTA central. Watch your back.',
      accentColor: const Color(0xFF42a5f5),
      isTravelable: false,
      products: [
        Product.defaults[0],
        Product.defaults[2],
        Product.defaults[4],
      ],
    ),
  ];

  static Location getById(String id) {
    return defaults.firstWhere((l) => l.id == id);
  }

  /// Returns only the 6 currently travelable locations
  static List<Location> get travelable => defaults.where((l) => l.isTravelable).toList();
}
