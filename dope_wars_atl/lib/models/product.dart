class Product {
  final String id;
  final String name;
  final int baseBuyPrice;
  final int baseSellPrice;
  final int highPrice;
  final String emoji;

  const Product({
    required this.id,
    required this.name,
    required this.baseBuyPrice,
    required this.baseSellPrice,
    required this.highPrice,
    required this.emoji,
  });

  Product copyWith({
    int? baseBuyPrice,
    int? baseSellPrice,
    int? highPrice,
  }) {
    return Product(
      id: id,
      name: name,
      baseBuyPrice: baseBuyPrice ?? this.baseBuyPrice,
      baseSellPrice: baseSellPrice ?? this.baseSellPrice,
      highPrice: highPrice ?? this.highPrice,
      emoji: emoji,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseBuyPrice': baseBuyPrice,
        'baseSellPrice': baseSellPrice,
        'highPrice': highPrice,
        'emoji': emoji,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        baseBuyPrice: json['baseBuyPrice'] as int,
        baseSellPrice: json['baseSellPrice'] as int,
        highPrice: json['highPrice'] as int,
        emoji: json['emoji'] as String,
      );

  static const List<Product> defaults = [
    Product(id: 'blunts', name: 'Blunts', baseBuyPrice: 60, baseSellPrice: 40, highPrice: 120, emoji: '🌿'),
    Product(id: 'oxy', name: 'Oxy', baseBuyPrice: 20, baseSellPrice: 5, highPrice: 80, emoji: '💊'),
    Product(id: 'shrooms', name: 'Shrooms', baseBuyPrice: 150, baseSellPrice: 70, highPrice: 350, emoji: '🍄'),
    Product(id: 'powda', name: 'Powda', baseBuyPrice: 120, baseSellPrice: 60, highPrice: 325, emoji: '❄️'),
    Product(id: 'acid', name: 'Acid', baseBuyPrice: 55, baseSellPrice: 10, highPrice: 130, emoji: '💧'),
  ];
}
