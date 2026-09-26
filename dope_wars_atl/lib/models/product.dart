class Product {
  final String id;
  final String name;
  final int baseBuyPrice;
  final String emoji;

  const Product({
    required this.id,
    required this.name,
    required this.baseBuyPrice,
    required this.emoji,
  });

  Product copyWith({int? baseBuyPrice}) => Product(
        id: id,
        name: name,
        baseBuyPrice: baseBuyPrice ?? this.baseBuyPrice,
        emoji: emoji,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseBuyPrice': baseBuyPrice,
        'emoji': emoji,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        baseBuyPrice: json['baseBuyPrice'] as int,
        emoji: json['emoji'] as String,
      );

  /// `baseBuyPrice` is the only price a product carries now. Buy and sell at a
  /// hood are both derived from it plus that hood's value multiplier — see
  /// lib/models/market.dart. The old baseSellPrice and highPrice are gone;
  /// fromJson ignores them so older JSON still loads.
  static const List<Product> defaults = [
    Product(id: 'blunts', name: 'Blunts', baseBuyPrice: 60, emoji: '🌿'),
    Product(id: 'oxy', name: 'Oxy', baseBuyPrice: 20, emoji: '💊'),
    Product(id: 'shrooms', name: 'Shrooms', baseBuyPrice: 150, emoji: '🍄'),
    Product(id: 'powda', name: 'Powda', baseBuyPrice: 120, emoji: '❄️'),
    Product(id: 'acid', name: 'Acid', baseBuyPrice: 55, emoji: '💧'),
  ];
}
