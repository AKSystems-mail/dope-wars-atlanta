class Weapon {
  final String id;
  final String name;
  final double killChance; // 0.0 - 1.0
  final int maxDurability;
  final int price;
  final String emoji;

  const Weapon({
    required this.id,
    required this.name,
    required this.killChance,
    required this.maxDurability,
    required this.price,
    required this.emoji,
  });

  bool get isFists => id == 'fists';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'killChance': killChance,
        'maxDurability': maxDurability,
        'price': price,
        'emoji': emoji,
      };

  factory Weapon.fromJson(Map<String, dynamic> json) => Weapon(
        id: json['id'] as String,
        name: json['name'] as String,
        killChance: (json['killChance'] as num).toDouble(),
        maxDurability: json['maxDurability'] as int,
        price: json['price'] as int,
        emoji: json['emoji'] as String,
      );

  static const List<Weapon> defaults = [
    Weapon(id: 'fists', name: 'Fists', killChance: 0.45, maxDurability: 9999, price: 0, emoji: '✊'),
    Weapon(id: 'blicky', name: 'Blicky', killChance: 0.52, maxDurability: 5, price: 300, emoji: '🔫'),
    Weapon(id: 'strap', name: 'Strap', killChance: 0.63, maxDurability: 5, price: 550, emoji: '🔫'),
    Weapon(id: 'draco', name: 'Draco', killChance: 0.77, maxDurability: 5, price: 3000, emoji: '💥'),
  ];
}

class WeaponSlot {
  Weapon weapon;
  int durability;
  bool equipped;

  WeaponSlot({
    required this.weapon,
    required this.durability,
    this.equipped = false,
  });

  bool get isBroken => weapon.maxDurability <= 5 && durability <= 0;

  Map<String, dynamic> toJson() => {
        'weapon': weapon.toJson(),
        'durability': durability,
        'equipped': equipped,
      };

  factory WeaponSlot.fromJson(Map<String, dynamic> json) => WeaponSlot(
        weapon: Weapon.fromJson(json['weapon'] as Map<String, dynamic>),
        durability: json['durability'] as int,
        equipped: json['equipped'] as bool? ?? false,
      );

  static WeaponSlot fists() => WeaponSlot(
        weapon: Weapon.defaults[0],
        durability: 9999,
        equipped: true,
      );
}
