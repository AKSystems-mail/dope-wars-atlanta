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
    expect(find.textContaining('BUY'), findsWidgets, reason: 'bottom nav must render');
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
    expect(find.textContaining('BUY'), findsWidgets);
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
}
