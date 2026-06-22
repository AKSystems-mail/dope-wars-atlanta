import 'product.dart';

enum LocationType {
  midtown,
  buckhead,
  cobbCounty,
  littleFivePoints,
  decatur,
  westEnd;

  String get displayName {
    switch (this) {
      case LocationType.midtown: return 'Midtown';
      case LocationType.buckhead: return 'Buckhead';
      case LocationType.cobbCounty: return 'Cobb County';
      case LocationType.littleFivePoints: return 'Little Five Points';
      case LocationType.decatur: return 'Decatur';
      case LocationType.westEnd: return 'West End';
    }
  }

  String get accentColor {
    // Each neighborhood gets a distinct accent
    switch (this) {
      case LocationType.midtown: return 'blue';
      case LocationType.buckhead: return 'gold';
      case LocationType.cobbCounty: return 'gray';
      case LocationType.littleFivePoints: return 'purple';
      case LocationType.decatur: return 'orange';
      case LocationType.westEnd: return 'red';
    }
  }

  String? get specialFeature {
    switch (this) {
      case LocationType.midtown: return '🏦 Bank';
      case LocationType.buckhead: return '👔 Councilman';
      case LocationType.cobbCounty: return '🚫 Ryde/Drive only';
      case LocationType.littleFivePoints: return '🎒 Bookbag upgrades';
      case LocationType.decatur: return null;
      case LocationType.westEnd: return '🔫 Weapon shop';
    }
  }

  bool get requiresRydeOrDrive => this == LocationType.cobbCounty;
}

class Location {
  final LocationType type;
  List<Product> availableProducts;
  bool isVisited;

  Location({
    required this.type,
    List<Product>? availableProducts,
    this.isVisited = false,
  }) : availableProducts = availableProducts ?? [];

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'availableProducts': availableProducts.map((p) => p.toJson()).toList(),
    'isVisited': isVisited,
  };

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    type: LocationType.values.byName(json['type'] as String),
    availableProducts: (json['availableProducts'] as List)
        .map((p) => Product.fromJson(p as Map<String, dynamic>))
        .toList(),
    isVisited: json['isVisited'] as bool? ?? false,
  );
}
