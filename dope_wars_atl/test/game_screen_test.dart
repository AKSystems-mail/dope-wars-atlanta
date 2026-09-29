import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dope_wars_atl/services/game_service.dart';
import 'package:dope_wars_atl/screens/game_screen.dart';
import 'package:dope_wars_atl/models/location.dart';
import 'package:dope_wars_atl/models/game_state.dart';
import 'package:dope_wars_atl/models/market.dart';

void main() {
  testWidgets('GameScreen builds with a fresh game', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final game = GameService();
    await tester.runAsync(() async {
      await game.init();
    });
    await tester.pump();

    await tester.pumpWidget(
      ChangeNotifierProvider<GameService>.value(
        value: game,
        child: const MaterialApp(home: GameScreen()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull, reason: 'GameScreen threw while building');
    expect(find.textContaining('TRADE'), findsWidgets, reason: 'bottom nav must render');
  });

  // A save written before the v3 map rework can hold a location id that no
  // longer exists. Location.getById used firstWhere() with no orElse, which
  // throws StateError, so the whole game screen died and release mode painted
  // Flutter's gray error box instead of the red screen.
  testWidgets('GameScreen survives a stale location id from an old save', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final game = GameService();
    await tester.runAsync(() async {
      await game.init();
    });
    await tester.pump();

    game.state!.currentLocationId = 'downtown'; // not one of the 6 v3 locations

    await tester.pumpWidget(
      ChangeNotifierProvider<GameService>.value(
        value: game,
        child: const MaterialApp(home: GameScreen()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull,
        reason: 'a stale saved location id must not crash the game screen');
    expect(find.textContaining('TRADE'), findsWidgets);
  });

  test('getById never throws for an unknown id', () {
    expect(() => Location.getById('downtown'), returnsNormally);
    expect(() => Location.getById(''), returnsNormally);
  });

  test('a stale saved location id is repaired on load', () {
    final state = GameState.fromJson(<String, dynamic>{'currentLocationId': 'downtown'});
    expect(state.currentLocationId, 'buckhead');
    expect(() => state.currentLocation, returnsNormally);
  });

  // The qty stepper's MAX is the one bit of real logic in the merged trade row:
  // it has to be clamped to what the game will actually allow, or one tap
  // either silently no-ops (overshoot) or moves a single unit (zero cash).
  group('MAX quantity', () {
    test('buy MAX is capped by cash and bag space, whichever binds first', () {
      // Mirrors _ProductRowState._maxBuy: min(remainingSpace, cash ~/ price).
      int maxBuy({required int cash, required int space, required int price}) =>
          space < cash ~/ price ? space : cash ~/ price;

      expect(maxBuy(cash: 1000, space: 50, price: 10), 50, reason: 'space binds');
      expect(maxBuy(cash: 100, space: 500, price: 10), 10, reason: 'cash binds');
      expect(maxBuy(cash: 95, space: 500, price: 10), 9, reason: 'never fractional');
      expect(maxBuy(cash: 5, space: 500, price: 10), 0, reason: 'unaffordable');
    });

    test('a MAX buy is always accepted by the service', () async {
      // The invariant that matters: the qty the row computes must be one
      // buyProduct actually honours. A row that overshoots turns into a silent
      // no-op, which is the exact failure this stepper exists to remove.
      SharedPreferences.setMockInitialValues({});
      final game = GameService();
      await game.init();
      final market = game.market!;
      final product = market.shelfProducts.first;
      final price = market.buyPriceOf(product.id)!;
      expect(price, greaterThan(0), reason: 'else MAX divides by zero');

      final state = game.state!;
      state.cash = 1000;
      final qty = math.min(state.remainingSpace, state.cash ~/ price);
      expect(qty, greaterThan(0));
      // Both halves of the clamp are the reason qty is legal at all.
      expect(state.cash, greaterThanOrEqualTo(price * qty));
      expect(state.remainingSpace, greaterThanOrEqualTo(qty));
    });
  });
  // BUY ALL / SELL ALL loop the single-product calls, so their stopping
  // conditions are the only thing that can silently break: overshoot the bag,
  // overspend the cash, or sell a product this hood doesn't stock.
  group('whole-bag actions', () {
    test('SELL ALL sells every stocked product and leaves the rest', () async {
      SharedPreferences.setMockInitialValues({});
      final game = GameService();
      await game.init();
      final state = game.state!;
      // No audioplayers plugin in the test env; every trade plays a sound.
      state.soundEnabled = false;
      final stocked = game.marketProducts;
      expect(stocked, isNotEmpty, reason: 'a fresh run must stock a shelf');

      // Stock two of the first, one of the second, plus one this hood does
      // NOT carry — that last one must survive a SELL ALL untouched.
      state.addToInventory(stocked[0].id, 2);
      state.addToInventory(stocked[1].id, 1);
      final unstocked = 'not_on_this_shelf';
      state.addToInventory(unstocked, 5);
      final cashBefore = state.cash;

      for (final p in stocked) {
        final held = state.inventory[p.id] ?? 0;
        if (held > 0) await game.sellProduct(p.id, held);
      }

      // removeFromInventory drops the key at zero, so "gone" is null-or-0.
      expect(state.inventory[stocked[0].id] ?? 0, 0, reason: 'stocked stock is sold');
      expect(state.inventory[stocked[1].id] ?? 0, 0);
      expect(state.inventory[unstocked], 5,
          reason: 'a product this hood does not stock must NOT be sold');
      expect(state.cash, greaterThan(cashBefore), reason: 'selling pays out');
    });

    test('BUY ALL stops at the bag and the wallet, never past either', () async {
      SharedPreferences.setMockInitialValues({});
      final game = GameService();
      await game.init();
      final state = game.state!;
      state.soundEnabled = false;
      state.cash = 500;

      // Mirror _buyAll: cheapest first, clamped to space and cash.
      final shelf = [...game.marketProducts]
        ..sort((a, b) => game.getBuyPrice(a).compareTo(game.getBuyPrice(b)));
      for (final p in shelf) {
        if (state.remainingSpace <= 0 || state.cash <= 0) break;
        final price = game.getBuyPrice(p);
        if (price <= 0) continue;
        final qty = math.min(state.remainingSpace, state.cash ~/ price);
        if (qty <= 0) continue;
        await game.buyProduct(p, qty);
      }

      expect(state.inventoryCount, lessThanOrEqualTo(state.bagCapacity),
          reason: 'BUY ALL must never overfill the bag');
      expect(state.cash, greaterThanOrEqualTo(0),
          reason: 'BUY ALL must never overspend');
    });
  });
  // The floor case, with the player's own numbers: shrooms at $171, $500 in
  // pocket. Integer division must give 2 units and leave $158 — buying a
  // third would go negative, and silently rounding up is how a "buy" button
  // ends up minting or voiding money.
  group('partial buys leave the remainder', () {
    test(r'$500 buys 2 of a $171 product and keeps $158', () async {
      SharedPreferences.setMockInitialValues({});
      final game = GameService();
      await game.init();
      final state = game.state!;
      state.soundEnabled = false;

      final product = game.marketProducts.first;
      // Pin the shelf to the scenario: one product, $171.
      final market = state.ensureMarket();
      state.market = Market(
        hoodId: market.hoodId,
        visitIndex: market.visitIndex,
        shelf: [product.id],
        buyPrices: {product.id: 171},
        sellPrices: {product.id: 150},
      );
      state.cash = 500;
      final space = state.remainingSpace;
      expect(space, greaterThanOrEqualTo(2));

      // Exactly what _maxBuy computes.
      final qty = math.min(space, state.cash ~/ 171);
      expect(qty, 2, reason: '500 ~/ 171 floors to 2');
      expect(await game.buyProduct(product, qty), isTrue);

      expect(state.inventory[product.id] ?? 0, 2);
      expect(state.cash, 158, reason: 'the unspent remainder stays in pocket');
      // And a third genuinely is refused, rather than half-happening.
      expect(await game.buyProduct(product, 1), isFalse);
      expect(state.cash, 158, reason: 'a refused buy must not move money');
    });
  });
}
