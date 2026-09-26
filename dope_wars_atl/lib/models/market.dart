import 'dart:math';
import 'location.dart';
import 'product.dart';

/// What a hood is offering on the current visit: the shelf, the prices, and
/// which product this visit's event is touching.
///
/// Resolved ONCE per arrival and then held. Both halves of that matter, because
/// the old code did neither:
///
///   * prices re-rolled on every rebuild, so the shop showed one number and
///     charged another;
///   * availability re-rolled too, so closing and reopening the app at the same
///     hood handed out a fresh shelf for free, indefinitely.
///
/// Buy and sell both derive from a single local [level], which makes "a round
/// trip in one hood loses money" structural rather than a rule to remember.
/// See docs/PRICING_SPEC.md.
class Market {
  final String hoodId;
  final int visitIndex;
  final List<String> shelf;
  final Map<String, int> buyPrices;
  final Map<String, int> sellPrices;

  /// The visit's event products, for the shop's price note and popups.
  final String? spikeProduct;
  final String? floodProduct;

  const Market({
    required this.hoodId,
    required this.visitIndex,
    required this.shelf,
    required this.buyPrices,
    required this.sellPrices,
    this.spikeProduct,
    this.floodProduct,
  });

  // Tuning knobs, all in one place.
  static const double cheapValueMult = 0.70;
  static const double premiumValueMult = 1.50;
  static const double spikeEventMult = 1.50;
  static const double floodEventMult = 0.30;
  static const double buySide = 1.0625;
  static const double sellSide = 0.9375;
  static const double jitterLow = 0.85;
  static const double jitterHigh = 1.15;
  static const int spikeChance = 15;
  static const int floodChance = 10;
  static const int extraProductsMin = 2;
  static const int extraProductsMax = 3;

  bool has(String productId) => shelf.contains(productId);
  int? buyPriceOf(String productId) => buyPrices[productId];
  int? sellPriceOf(String productId) => sellPrices[productId];

  /// The shelf as products, for the shop UI.
  List<Product> get shelfProducts => [
        for (final id in shelf)
          Product.defaults.firstWhere((p) => p.id == id),
      ];

  /// The price maths, exposed so tests can drive it directly.
  ///
  /// [buySide] and [sellSide] sit either side of the level, so `sell < buy`
  /// holds by construction — no multiplier or event can flip it. The explicit
  /// clamp is belt-and-braces for small integers and for future tuning.
  static ({int buy, int sell}) pricesFor({
    required int base,
    required double valueMult,
    required double eventMult,
    required double jitter,
  }) {
    final level = base * valueMult * eventMult * jitter;
    final buy = (level * buySide).round().clamp(1, 1 << 30);
    final rawSell = (level * sellSide).round();
    final sell = rawSell < buy ? rawSell.clamp(1, 1 << 30) : buy - 1;
    return (buy: buy, sell: sell);
  }

  static double valueMultFor(Location hood, String productId) {
    if (hood.cheapProductId == productId) return cheapValueMult;
    if (hood.premiumProductIds.contains(productId)) return premiumValueMult;
    return 1.0;
  }

  /// Resolve the market for [hood]. Pass [rng] for a deterministic result.
  static Market resolve(Location hood, {required int visitIndex, Random? rng}) {
    final r = rng ?? Random();

    final guaranteed = hood.guaranteedProducts;
    final pool = Product.defaults
        .map((p) => p.id)
        .where((id) => !guaranteed.contains(id))
        .toList()
      ..shuffle(r);
    final extras = pool
        .take(extraProductsMin + r.nextInt(extraProductsMax - extraProductsMin + 1))
        .toList();
    final shelf = [...guaranteed, ...extras].take(Product.defaults.length).toList();

    String? spike;
    String? flood;
    if (shelf.isNotEmpty) {
      if (r.nextInt(100) < spikeChance) spike = shelf[r.nextInt(shelf.length)];
      if (r.nextInt(100) < floodChance) {
        final candidate = shelf[r.nextInt(shelf.length)];
        if (candidate != spike) flood = candidate;
      }
    }

    final buy = <String, int>{};
    final sell = <String, int>{};
    for (final id in shelf) {
      final eventMult = id == spike
          ? spikeEventMult
          : id == flood
              ? floodEventMult
              : 1.0;
      // One jitter per product per visit, applied to the level — so it moves
      // both sides together and can never open a spread.
      final jitter = jitterLow + r.nextDouble() * (jitterHigh - jitterLow);
      final p = pricesFor(
        base: Product.defaults.firstWhere((x) => x.id == id).baseBuyPrice,
        valueMult: valueMultFor(hood, id),
        eventMult: eventMult,
        jitter: jitter,
      );
      buy[id] = p.buy;
      sell[id] = p.sell;
    }

    return Market(
      hoodId: hood.id,
      visitIndex: visitIndex,
      shelf: shelf,
      buyPrices: buy,
      sellPrices: sell,
      spikeProduct: spike,
      floodProduct: flood,
    );
  }

  Map<String, dynamic> toJson() => {
        'hoodId': hoodId,
        'visitIndex': visitIndex,
        'shelf': shelf,
        'buyPrices': buyPrices,
        'sellPrices': sellPrices,
        'spikeProduct': spikeProduct,
        'floodProduct': floodProduct,
      };

  factory Market.fromJson(Map<String, dynamic> json) => Market(
        hoodId: json['hoodId'] as String,
        visitIndex: json['visitIndex'] as int? ?? 0,
        shelf: (json['shelf'] as List?)?.cast<String>() ?? const <String>[],
        buyPrices: ((json['buyPrices'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k as String, v as int)),
        sellPrices: ((json['sellPrices'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k as String, v as int)),
        spikeProduct: json['spikeProduct'] as String?,
        floodProduct: json['floodProduct'] as String?,
      );
}
