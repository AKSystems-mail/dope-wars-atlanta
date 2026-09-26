// The ring, and the invariants that keep it from being exploited.
//
// These are the four checks promised in docs/PRICING_SPEC.md §7. The first one
// matters most: the price model's whole job is that you cannot buy and sell in
// one hood for a profit, so this file is the guard on the money path.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:dope_wars_atl/models/game_state.dart';
import 'package:dope_wars_atl/models/location.dart';
import 'package:dope_wars_atl/models/market.dart';
import 'package:dope_wars_atl/models/product.dart';

void main() {
  group('same_hood_loses', () {
    // The guard against money-printing. Buy and sell are derived from one
    // level, so this holds no matter what the multipliers, events, or jitter
    // do — if it ever fails, the game can be farmed by standing still.
    test('every product on every hood shelf costs more than it fetches', () {
      for (final hood in Location.defaults) {
        for (var seed = 0; seed < 200; seed++) {
          final market = Market.resolve(hood, visitIndex: seed, rng: Random(seed));
          for (final id in market.shelf) {
            final buy = market.buyPriceOf(id)!;
            final sell = market.sellPriceOf(id)!;
            expect(sell, lessThan(buy),
                reason: '${hood.name} / $id: buy $buy, sell $sell — '
                    'a round trip here would profit');
          }
        }
      }
    });

    test('no multiplier, event or jitter combination can invert the spread', () {
      const valueMults = [Market.cheapValueMult, 1.0, Market.premiumValueMult];
      const eventMults = [Market.floodEventMult, 1.0, Market.spikeEventMult];
      for (final vm in valueMults) {
        for (final em in eventMults) {
          for (var i = 0; i <= 30; i++) {
            final jitter = Market.jitterLow +
                (Market.jitterHigh - Market.jitterLow) * (i / 30);
            final p = Market.pricesFor(
              base: 100,
              valueMult: vm,
              eventMult: em,
              jitter: jitter,
            );
            expect(p.sell, lessThan(p.buy),
                reason: 'vm=$vm em=$em jitter=$jitter → ${p.buy}/${p.sell}');
          }
        }
      }
    });
  });

  group('ring_profits', () {
    // Priced through the model rather than the shelf, because a premium market
    // only rolls its product some visits (D10, fully random). This asserts the
    // economics of the ring table itself.
    test('every product is worth more at its market than at its source', () {
      for (final product in Product.defaults) {
        final source =
            Location.defaults.firstWhere((l) => l.cheapProductId == product.id);
        final market = Location.defaults
            .firstWhere((l) => l.premiumProductIds.contains(product.id));

        final buy = Market.pricesFor(
          base: product.baseBuyPrice,
          valueMult: Market.valueMultFor(source, product.id),
          eventMult: 1.0,
          jitter: 1.0,
        ).buy;
        final sell = Market.pricesFor(
          base: product.baseBuyPrice,
          valueMult: Market.valueMultFor(market, product.id),
          eventMult: 1.0,
          jitter: 1.0,
        ).sell;

        expect(sell, greaterThan(buy),
            reason: '${product.name}: buy \$$buy in ${source.name}, '
                'sell \$$sell in ${market.name}');
        expect(sell / buy, greaterThan(1.5),
            reason: '${product.name}: spread too thin to be worth the trip');
      }
    });

    test('the starting pair is the first leg of the ring', () {
      // Buckhead sells blunts cheap; Decatur pays for them. The opening trip
      // has to teach the mechanic, so this pairing is load-bearing.
      final buckhead = Location.getById('buckhead');
      final decatur = Location.getById('decatur');
      expect(buckhead.cheapProductId, 'blunts');
      expect(decatur.premiumProductIds, contains('blunts'));
    });
  });

  group('market_is_stable', () {
    test('the same seed resolves the same market', () {
      for (final hood in Location.defaults) {
        final a = Market.resolve(hood, visitIndex: 3, rng: Random(42));
        final b = Market.resolve(hood, visitIndex: 3, rng: Random(42));
        expect(b.shelf, a.shelf);
        expect(b.buyPrices, a.buyPrices);
        expect(b.sellPrices, a.sellPrices);
      }
    });

    test('asking twice in one visit does not reroll the shelf or the prices', () {
      final state = GameState();
      final first = state.ensureMarket(rng: Random(7));
      final buyBefore = Map<String, int>.from(first.buyPrices);
      final shelfBefore = List<String>.from(first.shelf);

      final second = state.ensureMarket(rng: Random(7));
      expect(identical(first, second), isTrue,
          reason: 'a rebuild must not hand out a fresh market');
      expect(second.buyPrices, buyBefore);
      expect(second.shelf, shelfBefore);
    });

    test('moving hood resolves a new market with a new visit index', () {
      final state = GameState();
      final atBuckhead = state.ensureMarket(rng: Random(1));
      state.currentLocationId = 'decatur';
      final atDecatur = state.ensureMarket(rng: Random(1));
      expect(atDecatur.hoodId, 'decatur');
      expect(atDecatur.visitIndex, atBuckhead.visitIndex + 1);
    });
  });

  group('shelf_guarantee', () {
    test('the guaranteed products are always on the shelf', () {
      for (final hood in Location.defaults) {
        final guaranteed = hood.guaranteedProducts;
        expect(guaranteed, isNotEmpty,
            reason: '${hood.name} guarantees nothing, so a trip there can '
                'arrive with nothing it wants');
        for (var seed = 0; seed < 200; seed++) {
          final market = Market.resolve(hood, visitIndex: seed, rng: Random(seed));
          for (final id in guaranteed) {
            expect(market.shelf, contains(id),
                reason: '${hood.name} lost its guaranteed $id on seed $seed');
          }
        }
      }
    });

    test('a shelf is never smaller than three products', () {
      for (final hood in Location.defaults) {
        for (var seed = 0; seed < 200; seed++) {
          final market = Market.resolve(hood, visitIndex: seed, rng: Random(seed));
          expect(market.shelf.length, inInclusiveRange(3, Product.defaults.length),
              reason: '${hood.name} rolled ${market.shelf.length} products');
          // No duplicates.
          expect(market.shelf.toSet().length, market.shelf.length);
        }
      }
    });

    test('Cobb, which has no cheap source, still guarantees a market', () {
      final cobb = Location.getById('cobb');
      expect(cobb.cheapProductId, isNull);
      expect(cobb.guaranteedProducts, isNotEmpty);
    });
  });

  group('market save round trip', () {
    test('a market survives toJson/fromJson', () {
      final market = Market.resolve(Location.getById('decatur'),
          visitIndex: 5, rng: Random(11));
      final restored = Market.fromJson(market.toJson());
      expect(restored.hoodId, market.hoodId);
      expect(restored.shelf, market.shelf);
      expect(restored.buyPrices, market.buyPrices);
      expect(restored.sellPrices, market.sellPrices);
      expect(restored.spikeProduct, market.spikeProduct);
    });

    test('a save with no market still loads (pre-rework saves)', () {
      final state = GameState.fromJson({'cash': 1234});
      expect(state.cash, 1234);
      expect(state.market, isNull);
      // and resolves one on demand rather than crashing
      expect(state.ensureMarket(rng: Random(1)).shelf, isNotEmpty);
    });
  });
}
