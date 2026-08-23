import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dope_wars_atl/flame_game/dope_wars_game.dart';
import 'package:dope_wars_atl/services/game_service.dart';

void main() {
  testWidgets('map loads without exception', (tester) async {
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = (d) => errors.add(d);
    final game = GameService();
    final g = DopeWarsGame(gameService: game, currentLocationId: 'midtown');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: GameWidget(game: g))));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    for (final e in errors) {
      print('FLUTTER ERROR: ${e.exception}');
    }
    expect(errors, isEmpty, reason: 'Map game threw during load');
  });
}
