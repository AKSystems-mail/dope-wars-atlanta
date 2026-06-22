import 'dart:math';

enum ProductType {
  blunts,
  oxy,
  shrooms,
  powda,
  acid;

  String get displayName {
    switch (this) {
      case ProductType.blunts: return 'Blunts';
      case ProductType.oxy: return 'Oxy';
      case ProductType.shrooms: return 'Shrooms';
      case ProductType.powda: return 'Powda';
      case ProductType.acid: return 'Acid';
    }
  }

  String get emoji {
    switch (this) {
      case ProductType.blunts: return '🚬';
      case ProductType.oxy: return '💊';
      case ProductType.shrooms: return '🍄';
      case ProductType.powda: return '❄️';
      case ProductType.acid: return '🎨';
    }
  }

  int get basePrice {
    switch (this) {
      case ProductType.blunts: return 60;
      case ProductType.oxy: return 20;
      case ProductType.shrooms: return 150;
      case ProductType.powda: return 120;
      case ProductType.acid: return 55;
    }
  }

  int get minPrice {
    switch (this) {
      case ProductType.blunts: return 40;
      case ProductType.oxy: return 5;
      case ProductType.shrooms: return 70;
      case ProductType.powda: return 60;
      case ProductType.acid: return 10;
    }
  }

  int get maxPrice {
    switch (this) {
      case ProductType.blunts: return 120;
      case ProductType.oxy: return 80;
      case ProductType.shrooms: return 350;
      case ProductType.powda: return 325;
      case ProductType.acid: return 130;
    }
  }
}

class Product {
  final ProductType type;
  int currentPrice;
  int quantity;

  Product({
    required this.type,
    required this.currentPrice,
    this.quantity = 0,
  });

  /// Calculate price for a location, with optional demand spike/flood
  static int generatePrice(ProductType type, {bool demandSpike = false, bool marketFlood = false}) {
    final rng = Random();
    double multiplier;

    if (demandSpike) {
      multiplier = 0.9 + rng.nextDouble() * 0.1; // 0.9-1.0 → near max
    } else if (marketFlood) {
      multiplier = 0.1 + rng.nextDouble() * 0.1; // 0.1-0.2 → near min
    } else {
      multiplier = 0.7 + rng.nextDouble() * 0.6; // 0.7-1.3
    }

    final price = (type.basePrice * multiplier).round();
    return price.clamp(type.minPrice, type.maxPrice);
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'currentPrice': currentPrice,
    'quantity': quantity,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    type: ProductType.values.byName(json['type'] as String),
    currentPrice: json['currentPrice'] as int,
    quantity: json['quantity'] as int? ?? 0,
  );
}
