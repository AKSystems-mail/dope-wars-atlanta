// Money-path invariants for GameState: pricing invariants, bank conservation,
// debt floor, affordability rejections. Pure model logic — no widgets.
import 'package:flutter_test/flutter_test.dart';
import 'package:dope_wars_atl/models/game_state.dart';
import 'package:dope_wars_atl/models/market.dart';
import 'package:dope_wars_atl/models/weapon.dart';

void main() {
  group('pricing', () {
    // The old per-call roller lived in GameState.getPrice. Market replaced it:
    // buy and sell sit either side of one local level, so the spread is a
    // property of the model rather than something a caller has to respect.
    test('buy and sell sit either side of the level', () {
      final p = Market.pricesFor(
          base: 1000, valueMult: 1.0, eventMult: 1.0, jitter: 1.0);
      expect(p.buy, 1063); // 1000 × 1.0625
      expect(p.sell, 938); // 1000 × 0.9375
    });

    test('a higher level moves both prices, never the spread', () {
      final flat = Market.pricesFor(
          base: 1000, valueMult: 1.0, eventMult: 1.0, jitter: 1.0);
      final spiked = Market.pricesFor(
          base: 1000, valueMult: 1.0, eventMult: Market.spikeEventMult, jitter: 1.0);
      expect(spiked.buy, greaterThan(flat.buy));
      expect(spiked.sell, greaterThan(flat.sell));
      expect(spiked.sell / spiked.buy, closeTo(flat.sell / flat.buy, 0.01));
    });
  });

  group('bank', () {
    test('deposit moves cash to bank and rejects when short (state unchanged)', () {
      final s = GameState(cash: 5000);
      expect(s.deposit(2000), isTrue);
      expect(s.cash, 3000);
      expect(s.bankBalance, 2000);

      expect(s.deposit(999999), isFalse);
      expect(s.cash, 3000, reason: 'failed deposit must not touch cash');
      expect(s.bankBalance, 2000, reason: 'failed deposit must not touch bank');
    });

    test('withdraw is the inverse of deposit and rejects when empty', () {
      final s = GameState(cash: 5000);
      s.deposit(2000);
      expect(s.withdraw(2000), isTrue);
      expect(s.cash, 5000);
      expect(s.bankBalance, 0);

      expect(s.withdraw(1), isFalse);
      expect(s.cash, 5000);
    });

    test('money is conserved across a deposit/withdraw round trip', () {
      final s = GameState(cash: 4000, debt: 10000);
      final before = s.netWorth;
      s.deposit(1500);
      s.withdraw(1500);
      expect(s.netWorth, before);
    });

    test('netWorth == cash + bank - debt', () {
      final s = GameState(cash: 1234, debt: 4321)..bankBalance = 999;
      expect(s.netWorth, 1234 + 999 - 4321);
    });

    test('applyDailyInterest compounds debt 2% and bank 1%, no-ops at zero', () {
      final s = GameState(cash: 0, debt: 10000)..bankBalance = 1000;
      s.applyDailyInterest();
      expect(s.debt, 10200); // 10000 + 2%
      expect(s.bankBalance, 1010); // 1000 + 1%

      final clean = GameState(cash: 0, debt: 0)..bankBalance = 0;
      clean.applyDailyInterest();
      expect(clean.debt, 0);
      expect(clean.bankBalance, 0);
    });
  });

  group('debt', () {
    test('payDebt pays down and never lets debt go negative', () {
      final s = GameState(cash: 1000, debt: 400);
      expect(s.payDebt(400), isTrue);
      expect(s.cash, 600);
      expect(s.debt, 0);
    });

    test('payDebt charges only what is owed when over-typed', () {
      final s = GameState(cash: 10000, debt: 500);
      final before = s.netWorth;
      expect(s.payDebt(10000), isTrue);
      expect(s.debt, 0);
      expect(s.cash, 9500, reason: 'the excess 9500 must not be burned');
      expect(s.netWorth, before,
          reason: 'paying debt converts cash 1:1, so net worth is unchanged');
    });

    test('payDebt rejects when cash is short (state unchanged)', () {
      final s = GameState(cash: 100, debt: 400);
      expect(s.payDebt(400), isFalse);
      expect(s.cash, 100);
      expect(s.debt, 400);
    });

    test('borrowFromCouncilman raises cash and debt by the same amount', () {
      final s = GameState(cash: 1000, debt: 10000);
      expect(s.borrowFromCouncilman(500), isTrue);
      expect(s.cash, 1500);
      expect(s.debt, 10500);
    });

    test('bankruptcyBailout grants walking money and adds 2000 debt', () {
      final s = GameState(cash: 0, debt: 1000)..gameOver = true;
      s.bankruptcyBailout();
      expect(s.cash, 500);
      expect(s.debt, 3000);
      expect(s.gameOver, isFalse);
    });
  });

  group('purchases', () {
    test('buyWeapon rejects an unaffordable weapon (state unchanged)', () {
      final s = GameState(cash: 100);
      final draco = Weapon.defaults.firstWhere((w) => w.id == 'draco');
      expect(s.buyWeapon(draco), isFalse);
      expect(s.cash, 100);
      expect(s.equippedWeapon.isFists, isTrue);
    });

    test('buyWeapon deducts exactly the price and equips it', () {
      final s = GameState(cash: 1000);
      final blicky = Weapon.defaults.firstWhere((w) => w.id == 'blicky');
      expect(s.buyWeapon(blicky), isTrue);
      expect(s.cash, 1000 - blicky.price);
      expect(s.equippedWeapon.id, 'blicky');
    });

    test('upgradeBag rejects when short, applies capacity when affordable', () {
      final poor = GameState(cash: 100);
      expect(poor.upgradeBag(500, 150), isFalse);
      expect(poor.cash, 100);
      expect(poor.bagCapacity, 100);

      final ok = GameState(cash: 1000);
      expect(ok.upgradeBag(500, 150), isTrue);
      expect(ok.cash, 500);
      expect(ok.bagCapacity, 150);
    });
  });

  group('inventory accounting', () {
    test('add/remove keeps bagUsed in sync and never goes negative', () {
      final s = GameState(bagCapacity: 100);
      s.addToInventory('weed', 10);
      expect(s.inventoryCount, 10);
      expect(s.bagUsed, 10);

      s.removeFromInventory('weed', 4);
      expect(s.inventory['weed'], 6);
      expect(s.bagUsed, 6);

      // Removing more than held drops the key entirely (no negative count)
      s.removeFromInventory('weed', 999);
      expect(s.inventory.containsKey('weed'), isFalse);
      expect(s.inventoryCount, 0);
      expect(s.bagUsed, 0);
    });

    test('loseInventoryPercent is a no-op on an empty bag', () {
      final s = GameState();
      s.loseInventoryPercent(0.5); // must not throw
      expect(s.inventoryCount, 0);
    });
  });
}
