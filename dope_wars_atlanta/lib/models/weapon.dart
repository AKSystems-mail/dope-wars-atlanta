enum WeaponType {
  fists,
  blicky,
  strap,
  draco;

  String get displayName {
    switch (this) {
      case WeaponType.fists: return 'Fists';
      case WeaponType.blicky: return 'Blicky';
      case WeaponType.strap: return 'Strap';
      case WeaponType.draco: return 'Draco';
    }
  }

  String get emoji {
    switch (this) {
      case WeaponType.fists: return '👊';
      case WeaponType.blicky: return '🔫';
      case WeaponType.strap: return '🔫';
      case WeaponType.draco: return '🔫';
    }
  }

  int get cost {
    switch (this) {
      case WeaponType.fists: return 0;
      case WeaponType.blicky: return 300;
      case WeaponType.strap: return 550;
      case WeaponType.draco: return 3000;
    }
  }

  int get winPercent {
    switch (this) {
      case WeaponType.fists: return 45;
      case WeaponType.blicky: return 52;
      case WeaponType.strap: return 63;
      case WeaponType.draco: return 77;
    }
  }

  int get maxUses {
    switch (this) {
      case WeaponType.fists: return -1; // infinite
      case WeaponType.blicky: return 5;
      case WeaponType.strap: return 5;
      case WeaponType.draco: return 5;
    }
  }
}

class Weapon {
  final WeaponType type;
  int usesRemaining;

  Weapon({required this.type, int? usesRemaining})
      : usesRemaining = usesRemaining ?? type.maxUses;

  bool get isBroken => type.maxUses > 0 && usesRemaining <= 0;

  bool get isInfinite => type.maxUses == -1;

  void use() {
    if (!isInfinite && usesRemaining > 0) {
      usesRemaining--;
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'usesRemaining': usesRemaining,
  };

  factory Weapon.fromJson(Map<String, dynamic> json) => Weapon(
    type: WeaponType.values.byName(json['type'] as String),
    usesRemaining: json['usesRemaining'] as int,
  );
}
