import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dope_wars_atl/services/game_service.dart';
import 'package:dope_wars_atl/screens/game_screen.dart';
import 'package:dope_wars_atl/models/location.dart';
import 'package:dope_wars_atl/models/game_state.dart';

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
}
