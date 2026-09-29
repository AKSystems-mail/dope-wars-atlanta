// Progressive mode invariants. Model-level: mode config, the unlock sequence,
// heat, the win/continue rules, and save compatibility. The informant's roll
// itself lives in GameService, which needs device IO, so what is asserted here
// is the state it drives.
import 'package:flutter_test/flutter_test.dart';
import 'package:dope_wars_atl/models/game_state.dart';
import 'package:dope_wars_atl/models/location.dart';

void main() {
  group('mode config', () {
    test('progressive starts with two hoods; classic with all of them', () {
      final prog = GameState.fromDifficulty('normal', mode: 'progressive');
      expect(prog.isProgressive, isTrue);
      expect(prog.unlockedHoods, {'buckhead', 'decatur'});
      expect(prog.isUnlocked('buckhead'), isTrue);
      expect(prog.isUnlocked('midtown'), isFalse);

      final classic = GameState.fromDifficulty('normal');
      expect(classic.isProgressive, isFalse);
      for (final loc in Location.defaults) {
        expect(classic.isUnlocked(loc.id), isTrue,
            reason: 'Classic must never gate a hood');
      }
    });

    test('difficulty is unchanged in both modes', () {
      for (final d in ['easy', 'normal', 'hard']) {
        final c = GameState.fromDifficulty(d);
        final p = GameState.fromDifficulty(d, mode: 'progressive');
        expect(p.cash, c.cash);
        expect(p.debt, c.debt);
        expect(p.maxDays, c.maxDays);
      }
    });

    test('the unlock sequence walks the ring and ends at Cobb', () {
      expect(GameState.unlockOrder, ['little_five', 'midtown', 'west_end', 'cobb']);
      final s = GameState.fromDifficulty('normal', mode: 'progressive');
      expect(s.nextUnlockHood, 'little_five');
      expect(s.unlocksDone, 0);
      for (final id in GameState.unlockOrder) {
        s.unlockedHoods.add(id);
      }
      expect(s.nextUnlockHood, isNull);
      expect(s.unlocksDone, GameState.unlockOrder.length);
    });
  });

  group('owning the city', () {
    test('needs every hood open AND the debt cleared', () {
      final s = GameState.fromDifficulty('normal', mode: 'progressive');
      expect(s.ownsTheCity, isFalse);

      for (final id in GameState.unlockOrder) {
        s.unlockedHoods.add(id);
      }
      expect(s.ownsTheCity, isFalse,
          reason: 'hoods alone are not the win — the Councilman has to be square');

      s.debt = 0;
      expect(s.ownsTheCity, isTrue);
    });

    test('the win does not end the run: won is set, and play continues', () {
      final s = GameState(cash: 5000, debt: 0, mode: 'progressive');
      for (final id in GameState.unlockOrder) {
        s.unlockedHoods.add(id);
      }
      final msg = s.checkGameOver();
      expect(msg, isNotNull);
      expect(msg, contains('OWN THE CITY'));
      expect(s.won, isTrue);
      expect(s.gameOver, isTrue, reason: 'the overlay needs to fire once');

      // Dismissing the overlay puts the player back in the same game.
      s.gameOver = false;
      expect(s.checkGameOver(), isNull,
          reason: 'a won run must not re-trigger the win every check');
    });

    test('post-win there is no bailout', () {
      final s = GameState(mode: 'progressive');
      expect(s.bailoutAvailable, isTrue);
      s.won = true;
      expect(s.bailoutAvailable, isFalse);

      final classic = GameState()..won = true;
      expect(classic.bailoutAvailable, isTrue,
          reason: 'Classic keeps its safety net');
    });

    test('running out of days unfinished is a loss, not a win', () {
      final s = GameState(day: 31, maxDays: 30, mode: 'progressive');
      final msg = s.checkGameOver();
      expect(msg, contains('TIME UP'));
      expect(s.won, isFalse);
      expect(s.gameOver, isTrue);
    });
  });

  group('heat', () {
    test('clamps at both ends and reports a state word, never a number', () {
      final s = GameState();
      expect(s.heatLabel, 'Cool');
      s.raiseHeat(1000);
      expect(s.heat, GameState.heatMax);
      expect(s.heatLabel, 'Hot');
      expect(s.heatFactor, 2.0);
      s.heat = 45;
      expect(s.heatLabel, 'Warm');
      expect(s.heatFactor, closeTo(1.45, 0.001));
    });

    test('lay low costs a day and only ever lowers heat', () {
      final s = GameState(heat: 40, day: 5, cash: 4000, debt: 10000);
      final debtBefore = s.debt;
      s.layLow();
      expect(s.heat, 40 - GameState.layLowHeatDrop);
      expect(s.day, 6, reason: 'patience has to cost time in a capped run');
      expect(s.debt, greaterThan(debtBefore), reason: 'interest keeps running');
    });

    test('post-win, heat only climbs — laying low does nothing', () {
      final s = GameState(heat: 40, won: true);
      s.layLow();
      expect(s.heat, 40, reason: 'no cooling after the win (D16)');
    });
  });

  group('informant thresholds', () {
    test('scale with progress and with difficulty', () {
      final s = GameState.fromDifficulty('normal', mode: 'progressive');
      final first = s.informantThreshold;
      expect(first, (4000 * 1.5 * 1).round());

      s.unlockedHoods.add('little_five');
      expect(s.informantThreshold, greaterThan(first),
          reason: 'the ask should keep pace with progress');
    });
  });

  group('save compatibility', () {
    test('progressive state survives a round trip', () {
      final s = GameState.fromDifficulty('normal', mode: 'progressive')
        ..heat = 55
        ..informantArmed = true
        ..informantArrivals = 2;
      s.unlockedHoods.add('little_five');
      s.items[GameState.martaCard] = true;
      s.knownHoods.add('decatur');

      final back = GameState.fromJson(s.toJson());
      expect(back.mode, 'progressive');
      expect(back.unlockedHoods, contains('little_five'));
      expect(back.heat, 55);
      expect(back.hasMartaCard, isTrue);
      expect(back.informantArmed, isTrue);
      expect(back.informantArrivals, 2);
      expect(back.knownHoods, contains('decatur'));
      expect(back.isUnlocked('midtown'), isFalse);
    });

    test('a pre-Progressive save loads as Classic with everything open', () {
      // Exactly the shape of the old format: no mode, no unlockedHoods.
      final old = GameState.fromJson({
        'currentLocationId': 'decatur',
        'cash': 2500,
        'debt': 8000,
        'day': 4,
      });
      expect(old.mode, 'classic');
      expect(old.isProgressive, isFalse);
      expect(old.heat, 0);
      expect(old.informantArmed, isFalse);
      for (final loc in Location.defaults) {
        expect(old.isUnlocked(loc.id), isTrue,
            reason: 'an old save was a Classic run with the whole city open');
      }
      expect(old.currentLocationId, 'decatur');
      expect(old.cash, 2500);
    });
  });

  // Heat has four coolers, all funnelled through coolHeat so one rule holds:
  // heat is raised by movement, so cooling costs the thing that moved. Post-win
  // none of them fire — the Progressive endgame is a one-way ratchet.
  group('cooling actions', () {
    GameState hot() =>
        GameState.fromDifficulty('normal', mode: 'progressive')..heat = 60;

    test('lay low drops its flat amount, capped at zero', () {
      final s = hot();
      s.layLow();
      expect(s.heat, 60 - GameState.layLowHeatDrop);

      final low = hot()..heat = 3;
      low.layLow();
      expect(low.heat, 0, reason: 'heat must never go negative');
    });

    test('deposit cools a little and moves the money', () {
      final s = hot();
      final cash = s.cash;
      expect(s.deposit(1000), isTrue);
      expect(s.heat, 60 - GameState.depositHeatDrop);
      expect(s.cash, cash - 1000);
      expect(s.bankBalance, 1000);
    });

    test('paying debt scales with the amount actually paid', () {
      final s = hot();
      expect(s.payDebt(3000), isTrue);
      expect(s.heat, 60 - 3 * GameState.debtPayHeatPerThousand);
      expect(s.debt, 10000 - 3000);

      // Below $1K cools nothing, and an over-typed payment can't buy heat it
      // didn't spend: only the amount actually applied counts.
      final small = hot()..cash = 5000;
      small.payDebt(500);
      expect(small.heat, 60, reason: 'no full thousand, no cool');
    });

    test('dumping mirrors selling and destroys the goods', () {
      final s = hot()..addToInventory('shrooms', 50);
      final cooled = s.dumpProduct('shrooms', 25);
      expect(cooled, 25 ~/ 25, reason: 'dump takes back what sell would add');
      expect(s.heat, 60 - 1);
      expect(s.inventory['shrooms'], 25, reason: 'the goods are gone for good');
    });

    test('a dump under the minimum is refused outright', () {
      final s = hot()..addToInventory('shrooms', 4);
      expect(s.dumpProduct('shrooms', 4), 0);
      expect(s.inventory['shrooms'], 4, reason: 'a refused dump keeps the stock');
      expect(s.heat, 60, reason: 'and cools nothing');

      // The floor is the anti-exploit: without it, dumping 1 unit would shave
      // heat at 1-for-1 and beat lay low per day.
      expect(s.dumpProduct('shrooms', 1), 0);
    });

    test('dumping more than you hold is refused', () {
      final s = hot()..addToInventory('shrooms', 10);
      expect(s.dumpProduct('shrooms', 25), 0);
      expect(s.inventory['shrooms'], 10);
      expect(s.heat, 60);
    });

    test('after winning, nothing cools', () {
      final s = hot()
        ..addToInventory('shrooms', 50)
        ..won = true;

      expect(s.coolHeat(50), isFalse, reason: 'the gate is the helper itself');
      s.layLow();
      s.deposit(1000);
      s.payDebt(1000);
      s.dumpProduct('shrooms', 25);

      expect(s.heat, 60, reason: 'post-win heat is final');
      expect(s.inventory['shrooms'], 50,
          reason: 'and a refused dump must not destroy stock either');
    });

    test('lay low still costs a day even when it cannot cool', () {
      final s = hot()..won = true;
      final day = s.day;
      s.layLow();
      expect(s.heat, 60);
      expect(s.day, greaterThan(day), reason: 'time passes either way');
    });
  });
}
