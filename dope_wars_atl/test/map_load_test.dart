import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dope_wars_atl/flame_game/dope_wars_game.dart';
import 'package:dope_wars_atl/services/game_service.dart';

void main() {
  testWidgets('map loads its background sprite and nodes', (tester) async {
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = (d) => errors.add(d);

    final g = DopeWarsGame(gameService: GameService(), currentLocationId: 'midtown');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: GameWidget(game: g))));

    // runAsync is REQUIRED. onLoad awaits real image decoding, which does not
    // complete inside the fake-async test zone. Without this the assertions
    // below pass vacuously and the map can be blank in the app while the suite
    // stays green - which is exactly what happened before.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump();

    expect(errors, isEmpty, reason: 'map threw during load');
    expect(g.isLoaded, isTrue, reason: 'onLoad never completed');
    expect(
      g.children.whereType<SpriteComponent>(),
      isNotEmpty,
      reason: 'map background sprite was never added',
    );
    expect(
      g.children.whereType<SpriteComponent>().first.size,
      Vector2(606, 1280),
      reason: 'background sprite must match the v3 map dimensions',
    );
    expect(
      g.children.length,
      greaterThan(10),
      reason: 'connection lines + nodes + player dot should be present',
    );
  });
}
