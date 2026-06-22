import '../utils/location_emoji.dart'; // for locationEmojis map

/// Central sprite and emoji definitions for the Dope Wars game.
///
/// Provides consistent iconography for locations, items, UI actions,
/// and transport modes across all screens.
class Sprites {
  Sprites._();

  // ── Location Emojis ──
  static String forLocation(String locationId) =>
      locationEmojis[locationId] ?? '📍';

  // ── Item Emojis ──
  static const String cash = '💰';
  static const String bag = '🎒';
  static const String day = '📅';
  static const String mapEmoji = '🗺️';
  static const String shop = '🛒';
  static const String menu = '⚙️';
  static const String bank = '🏦';
  static const String weapon = '🔫';
  static const String councilman = '🧑‍⚖️';

  // ── Transport Emojis ──
  static const String marta = '🚇';
  static const String ryde = '🚗';
  static const String drive = '🏎️';
  static const String travel = '📍';

  // ── Product emojis ──
  static const Map<String, String> products = {
    'motor_oil': '🛢️',
    'antifreeze': '🧊',
    'brake_fluid': '💧',
    'transmission': '⚙️',
    'gasoline': '⛽',
    'diesel': '🛢️',
    'coolant': '💎',
  };

  // ── Weather / Time ──
  static String timeIcon(int hour) {
    if (hour < 6) return '🌙';
    if (hour < 12) return '🌅';
    if (hour < 18) return '☀️';
    return '🌆';
  }

  // ── Encounter type ──
  static const Map<String, String> encounters = {
    'cop': '👮',
    'thief': '🥷',
    'dealer': '🧑‍💼',
    'hobo': '🧔',
    'femme': '💃',
    'mission': '📋',
  };

  // ── Ad images (file paths) ──
  static const List<String> adAssets = [
    'assets/ads/ryde.png',
    'assets/ads/councilman.png',
    'assets/ads/get_higher.png',
    'assets/ads/certified_whips.png',
    'assets/ads/the_varsity.png',
  ];

  // ── Action buttons ──
  static const Map<String, Map<String, String>> actions = {
    'shop': {'emoji': '🛒', 'label': 'SHOP'},
    'map': {'emoji': '🗺️', 'label': 'MAP'},
    'bag': {'emoji': '🎒', 'label': 'BAG'},
    'menu': {'emoji': '⚙️', 'label': 'MENU'},
  };

  // ── Feature badges ──
  static const Map<String, Map<String, String>> features = {
    'bank': {'emoji': '🏦', 'label': 'Bank'},
    'weapon': {'emoji': '🔫', 'label': 'Weapons'},
    'councilman': {'emoji': '🧑‍⚖️', 'label': 'Councilman'},
    'bookbag': {'emoji': '🎒', 'label': 'Upgrades'},
  };
}
