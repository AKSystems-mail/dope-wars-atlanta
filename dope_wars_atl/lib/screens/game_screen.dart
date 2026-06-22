import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/neon_widgets.dart';
import '../models/location.dart';
import '../models/weapon.dart';
import '../models/game_state.dart';
import '../services/game_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_hud.dart';
import 'map_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameService>(
      builder: (context, game, _) {
        final state = game.state;
        if (state == null) return const SizedBox.shrink();

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                // Pixel HUD
                PixelHud(game: game),
                // Location header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        state.currentLocation.accentColor
                            .withValues(alpha: 0.2),
                        AppTheme.background,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        state.currentLocation.name,
                        style: AppTheme.jersey15(
    size: 28, color: state.currentLocation.accentColor,
  ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.currentLocation.description,
                        style: AppTheme.jersey15(size: 12, color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Location list for nearby spots
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      // Current location special features
                      if (state.currentLocation.isBank)
                        _SpecialFeatureCard(
                          emoji: '🏦',
                          title: 'Bank of Midtown',
                          subtitle:
                              'Deposit savings • Withdraw cash • 1% daily interest',
                          color: AppTheme.midtown,
                          onTap: () => _showBank(context, game),
                        ),
                      if (state.currentLocation.isWeaponShop)
                        _SpecialFeatureCard(
                          emoji: '🔫',
                          title: 'West End Arms',
                          subtitle: 'Upgrade your piece',
                          color: AppTheme.westEnd,
                          onTap: () => _showWeaponShop(context, game),
                        ),
                      if (state.currentLocation.isCouncilman)
                        _SpecialFeatureCard(
                          emoji: '🧑‍⚖️',
                          title: 'The Councilman',
                          subtitle: 'Borrow cash • 2% daily interest',
                          color: AppTheme.buckhead,
                          onTap: () => _showCouncilman(context, game),
                        ),
                      if (state.currentLocation.isBookbagUpgrade)
                        _SpecialFeatureCard(
                          emoji: '🎒',
                          title: 'Bookbag Upgrades',
                          subtitle: 'Carry more product',
                          color: AppTheme.littleFive,
                          onTap: () => _showBookbagShop(context, game),
                        ),
                    ],
                  ),
                ),
                // Bottom navigation bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.accentGreen.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: NeonActionButton(
                          label: 'BUY',
                          onPressed: () => _showShop(context, game),
                          neonColor: AppTheme.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: NeonActionButton(
                          label: 'MAP',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MapScreen()),
                          ),
                          neonColor: AppTheme.accentPink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: NeonActionButton(
                          label: 'INVENTORY',
                          onPressed: () => _showInventory(context, game),
                          neonColor: AppTheme.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showShop(BuildContext context, GameService game) {
    final location = game.currentLocation;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ShopSheet(location: location, game: game),
    );
  }

  void _showInventory(BuildContext context, GameService game) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _InventorySheet(game: game),
    );
  }

  void _showBank(BuildContext context, GameService game) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _BankSheet(game: game),
    );
  }

  void _showWeaponShop(BuildContext context, GameService game) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _WeaponSheet(game: game),
    );
  }

  void _showCouncilman(BuildContext context, GameService game) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _CouncilmanSheet(game: game),
    );
  }

  void _showBookbagShop(BuildContext context, GameService game) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _BookbagSheet(game: game),
    );
  }
}

class _SpecialFeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SpecialFeatureCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.pixelCard(accentColor: color, isActive: false),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTheme.jersey15(size: 18, color: color)),
                    const SizedBox(height: 2),
                    Text(subtitle,
style: AppTheme.jersey15(size: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Text('➡️', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopSheet extends StatefulWidget {
  final Location location;
  final GameService game;

  const _ShopSheet({required this.location, required this.game});

  @override
  State<_ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends State<_ShopSheet> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '${widget.location.name} — SHOP',
              style: AppTheme.jersey15(size: 20, color: AppTheme.accentGreen)),
          ),
          const SizedBox(height: 16),
          ...widget.location.products.map((product) {
            final buyPrice = widget.game.getBuyPrice(product);
            final sellPrice = widget.game.getSellPrice(product);
            final priceNote = widget.game.getPriceNote(product);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(product.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name,
style: AppTheme.jersey15(size: 16, color: AppTheme.textPrimary)),
                              Text(
                                  'Buy: \$${buyPrice} | Sell: \$${sellPrice}',
                                  style: AppTheme.jersey10(size: 10, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        _QtyButton(
                          label: 'BUY',
                          color: AppTheme.accentGreen,
                          onTap: () {
                            widget.game.buyProduct(product, 1);
                          },
                        ),
                        const SizedBox(width: 4),
                        _QtyButton(
                          label: 'SELL',
                          color: AppTheme.accentPink,
                          onTap: () {
                            widget.game.sellProduct(product.id, 1);
                          },
                        ),
                      ],
                    ),
                    if (priceNote != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(priceNote,
                            style: AppTheme.jersey10(size: 11, color: AppTheme.accentPink),
                      )),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Cash: \$${widget.game.state!.cash} | Bag: ${widget.game.state!.inventoryCount}/${widget.game.state!.bagCapacity}',
              style: AppTheme.jersey10(size: 10, color: AppTheme.accentGreen)),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QtyButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style:
              AppTheme.jersey10(size: 10, color: color),
        ),
      ),
    );
  }
}

class _InventorySheet extends StatelessWidget {
  final GameService game;

  const _InventorySheet({required this.game});

  @override
  Widget build(BuildContext context) {
    final inv = game.state!.inventory;
    final state = game.state!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'BOOKBAG (${state.inventoryCount}/${state.bagCapacity})',
              style: AppTheme.jersey15(size: 20, color: AppTheme.gold)),
          ),
          const SizedBox(height: 16),
          // ---- WEAPON INVENTORY ----
          Text(
            'WEAPONS',
            style: AppTheme.jersey10(size: 11, color: AppTheme.accentPink)),
          const SizedBox(height: 8),
          ...List.generate(state.weaponSlots.length, (i) {
            final slot = state.weaponSlots[i];
            final equipped = slot.equipped;
            final isBroken = slot.isBroken;
            final isFists = slot.weapon.isFists;
            final duraText = isFists
                ? '∞'
                : '${slot.durability}/${slot.weapon.maxDurability}';
            return GestureDetector(
              onTap: isBroken || equipped
                  ? null
                  : () => game.equipWeapon(i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: equipped
                      ? AppTheme.accentGreen.withValues(alpha: 0.15)
                      : AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: equipped
                        ? AppTheme.accentGreen
                        : isBroken
                            ? AppTheme.danger.withValues(alpha: 0.3)
                            : AppTheme.card,
                    width: equipped ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(slot.weapon.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(slot.weapon.name,
                                  style: AppTheme.jersey15(size: 14, color: equipped
                                          ? AppTheme.accentGreen
                                          : isBroken
                                              ? AppTheme.danger
                                              : AppTheme.textPrimary)),
                              if (equipped)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Text('[EQUIPPED]',
                                      style: AppTheme.jersey10(size: 10, color: AppTheme.accentGreen)),
                              ),
                              if (isBroken && !isFists)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Text('[BROKEN]',
                                      style: AppTheme.jersey10(size: 10, color: AppTheme.danger)),
                              ),
                            ],
                          ),
                          Text('${(slot.weapon.killChance * 100).round()}% • $duraText',
style: AppTheme.jersey10(size: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    if (slot.weapon.isFists && !slot.equipped)
                      Text('ALWAYS',
style: AppTheme.jersey10(size: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            );
          }),
          Text(
            'Bank: \$${state.bankBalance}', 
            style: AppTheme.jersey10(size: 10, color: AppTheme.midtown)),
          const SizedBox(height: 16),
          if (inv.isEmpty)
            Center(
              child: Text(
                'Empty bag. Time to re-up.',
                style: AppTheme.jersey15(size: 14, color: AppTheme.textSecondary)),
            ),
          ...inv.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text('${entry.value}x', style: AppTheme.jersey10(size: 12, color: AppTheme.accentGreen)),
                  const SizedBox(width: 8),
                  Text(entry.key, style: AppTheme.jersey15(size: 16, color: AppTheme.textPrimary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BankSheet extends StatelessWidget {
  final GameService game;

  const _BankSheet({required this.game});

  @override
  Widget build(BuildContext context) {
    final state = game.state!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              'BANK OF MIDTOWN',
              style: AppTheme.jersey15(size: 20, color: AppTheme.midtown)),
          ),
          const SizedBox(height: 8),
          Text(
            'Cash: \$${state.cash} | Bank: \$${state.bankBalance}',
            style: AppTheme.jersey10(size: 11, color: AppTheme.textSecondary)),
          Text(
            '1% daily interest on savings',
            style: AppTheme.jersey10(size: 11, color: AppTheme.accentGreen)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NeonBorderButton(
                  label: 'DEPOSIT',
                  onPressed: () => _showDepositDialog(context, game),
                  neonColor: AppTheme.accentGreen,
                  width: double.infinity,
                  height: 44,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeonBorderButton(
                  label: 'WITHDRAW',
                  onPressed: () => _showWithdrawDialog(context, game),
                  neonColor: AppTheme.accentPink,
                  width: double.infinity,
                  height: 44,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDepositDialog(BuildContext context, GameService game) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('Deposit to Bank',
            style: AppTheme.jersey15(size: 16, color: AppTheme.accentGreen)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cash on hand: \$${game.state!.cash}',
                style: AppTheme.jersey15(size: 14, color: AppTheme.textSecondary)),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: AppTheme.jersey10(size: 12, color: AppTheme.accentGreen),
              decoration: InputDecoration(
                hintText: 'Amount',
                hintStyle: AppTheme.jersey10(size: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTheme.jersey10(size: 10)),
          ),
          TextButton(
            onPressed: () {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0) game.deposit(amount);
              Navigator.pop(ctx);
            },
            child: Text('Deposit', style: AppTheme.jersey10(size: 10, color: AppTheme.accentGreen)),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, GameService game) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('Withdraw from Bank',
            style: AppTheme.jersey15(size: 16, color: AppTheme.accentPink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bank balance: \$${game.state!.bankBalance}',
                style: AppTheme.jersey15(size: 14, color: AppTheme.textSecondary)),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: AppTheme.jersey10(size: 12, color: AppTheme.accentPink),
              decoration: InputDecoration(
                hintText: 'Amount',
                hintStyle: AppTheme.jersey10(size: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTheme.jersey10(size: 10)),
          ),
          TextButton(
            onPressed: () {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0) game.withdraw(amount);
              Navigator.pop(ctx);
            },
            child: Text('Withdraw', style: AppTheme.jersey10(size: 10, color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }
}

class _WeaponSheet extends StatelessWidget {
  final GameService game;

  const _WeaponSheet({required this.game});

  /// Check if the player already owns a working version of this weapon
  bool _ownsWorking(Weapon weapon, GameState state) {
    for (final slot in state.weaponSlots) {
      if (slot.weapon.id == weapon.id && !slot.isBroken) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = game.state!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'WEST END ARMS',
              style: AppTheme.jersey15(size: 20, color: AppTheme.westEnd)),
          ),
          const SizedBox(height: 8),
          // ---- CURRENT INVENTORY ----
          if (state.weaponSlots.isNotEmpty) ...[
            Text(
              'INVENTORY (${state.weaponSlotCount}/${GameState.maxWeaponSlots})',
              style: AppTheme.jersey10(size: 10, color: AppTheme.accentPink)),
            const SizedBox(height: 8),
            ...List.generate(state.weaponSlots.length, (i) {
              final slot = state.weaponSlots[i];
              final equipped = slot.equipped;
              final isBroken = slot.isBroken;
              final isFists = slot.weapon.isFists;
              final duraText = isFists
                  ? '∞'
                  : '${slot.durability}/${slot.weapon.maxDurability}';
              return GestureDetector(
                onTap: isBroken || equipped || isFists
                    ? null
                    : () => game.equipWeapon(i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: equipped
                        ? AppTheme.accentGreen.withValues(alpha: 0.15)
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: equipped
                          ? AppTheme.accentGreen
                          : isBroken
                              ? AppTheme.danger.withValues(alpha: 0.3)
                              : AppTheme.card,
                      width: equipped ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(slot.weapon.emoji,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(slot.weapon.name,
                                    style: AppTheme.jersey15(size: 14, color: equipped
                                            ? AppTheme.accentGreen
                                            : isBroken
                                                ? AppTheme.danger
                                                : AppTheme.textPrimary)),
                                if (equipped)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Text('[EQ]',
                                        style: AppTheme.jersey10(size: 10, color: AppTheme.accentGreen)),
                                  ),
                                if (isBroken && !isFists)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Text('[BROKEN]',
                                        style: AppTheme.jersey10(size: 10, color: AppTheme.danger)),
                                  ),
                              ],
                            ),
                            Text(
                                '${(slot.weapon.killChance * 100).round()}% • $duraText',
                                style: AppTheme.jersey10(size: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      if (!equipped && !isBroken && !isFists)
                        Text('TAP TO EQUIP',
style: AppTheme.jersey10(size: 10, color: AppTheme.accentGreen)),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Divider(color: AppTheme.card, thickness: 1),
            const SizedBox(height: 8),
          ],
          // ---- SHOP ----
          Text(
            'SHOP',
            style: AppTheme.jersey10(size: 11, color: AppTheme.gold)),
          const SizedBox(height: 8),
          ...Weapon.defaults.where((w) => w.id != 'fists').toList().map((weapon) {
            final ownsWorking = _ownsWorking(weapon, state);
            final canAfford = state.cash >= weapon.price;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: ownsWorking
                      ? Border.all(
                          color: AppTheme.accentGreen.withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    Text(weapon.emoji,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(weapon.name,
style: AppTheme.jersey15(size: 16, color: AppTheme.textPrimary)),
                              if (ownsWorking)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Text('[OWNED]',
                                      style: AppTheme.jersey10(size: 10, color: AppTheme.accentGreen)),
                                ),
                            ],
                          ),
                          Text(
                              '${(weapon.killChance * 100).round()}% | ${weapon.maxDurability} uses | \$${weapon.price}',
                              style: AppTheme.jersey10(size: 10, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    NeonBorderButton(
                      label: '${ownsWorking ? 'OWNED' : !canAfford ? '\$${weapon.price}' : 'BUY'}',
                      onPressed: ownsWorking || !canAfford
                          ? null
                          : () => game.buyWeapon(weapon),
                      neonColor: ownsWorking
                          ? AppTheme.textSecondary
                          : AppTheme.westEnd,
                      width: 100,
                      height: 36,
                      fontSize: 10,
                    ),
                  ],
                ),
              ),
            );
          }),
          if (state.weaponSlotCount >= GameState.maxWeaponSlots)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  '⚠️ Slots full — buying a new weapon replaces your lowest-value unequipped weapon',
                  style: AppTheme.jersey10(size: 11, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CouncilmanSheet extends StatelessWidget {
  final GameService game;

  const _CouncilmanSheet({required this.game});

  @override
  Widget build(BuildContext context) {
    final state = game.state!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              'THE COUNCILMAN',
              style: AppTheme.jersey15(size: 20, color: AppTheme.buckhead)),
          ),
          const SizedBox(height: 8),
          Text(
            '"I can make things happen... for a price."',
            style: AppTheme.jersey15(size: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text(
            'Debt: \$${state.debt} (2% daily interest)',
            style: AppTheme.jersey10(size: 10, color: AppTheme.accentPink)),
          Text(
            'Net worth: \$${state.netWorth}',
            style: AppTheme.jersey10(size: 10, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NeonBorderButton(
                  label: 'BORROW',
                  onPressed: () => _borrowDialog(context, game),
                  neonColor: AppTheme.buckhead,
                  width: double.infinity,
                  height: 44,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeonBorderButton(
                  label: 'PAY DEBT',
                  onPressed: () => _payDialog(context, game),
                  neonColor: AppTheme.accentGreen,
                  width: double.infinity,
                  height: 44,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _borrowDialog(BuildContext context, GameService game) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('Borrow from Councilman',
            style: AppTheme.jersey15(size: 16, color: AppTheme.buckhead)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current debt: \$${game.state!.debt}',
                style: AppTheme.jersey15(size: 14, color: AppTheme.textSecondary)),
            Text('2% daily interest applies!',
                style: AppTheme.jersey10(size: 10, color: AppTheme.danger)),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: AppTheme.jersey10(size: 12, color: AppTheme.buckhead),
              decoration: InputDecoration(hintText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTheme.jersey10(size: 10)),
          ),
          TextButton(
            onPressed: () {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0) game.borrowFromCouncilman(amount);
              Navigator.pop(ctx);
            },
            child: Text('Borrow', style: AppTheme.jersey10(size: 10, color: AppTheme.buckhead)),
          ),
        ],
      ),
    );
  }

  void _payDialog(BuildContext context, GameService game) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('Pay Down Debt',
            style: AppTheme.jersey15(size: 16, color: AppTheme.accentGreen)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cash: \$${game.state!.cash} | Debt: \$${game.state!.debt}',
                style: AppTheme.jersey15(size: 14, color: AppTheme.textSecondary)),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: AppTheme.jersey10(size: 12, color: AppTheme.accentGreen),
              decoration: InputDecoration(
                hintText: 'Amount',
                hintStyle: AppTheme.jersey10(size: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTheme.jersey10(size: 10)),
          ),
          TextButton(
            onPressed: () {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0) game.payDebt(amount);
              Navigator.pop(ctx);
            },
            child: Text('Pay', style: AppTheme.jersey10(size: 10, color: AppTheme.accentGreen)),
          ),
        ],
      ),
    );
  }
}

class _BookbagSheet extends StatelessWidget {
  final GameService game;

  const _BookbagSheet({required this.game});

  @override
  Widget build(BuildContext context) {
    final upgrades = [
      (capacity: 250, cost: 400),
      (capacity: 600, cost: 1000),
      (capacity: 1000, cost: 3000),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'BOOKBAG UPGRADES',
              style: AppTheme.jersey15(size: 20, color: AppTheme.littleFive)),
          ),
          const SizedBox(height: 8),
          Text(
            'Current: ${game.state!.bagCapacity} capacity',
            style: AppTheme.jersey10(size: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ...upgrades.map((u) {
            final canAfford = game.state!.cash >= u.cost;
            final isBetter = u.capacity > game.state!.bagCapacity;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${u.capacity} capacity — \$${u.cost}',
                        style: AppTheme.jersey15(size: 14, color: isBetter ? AppTheme.textPrimary : AppTheme.textSecondary)),
                      ),
                    NeonBorderButton(
                      label: 'BUY',
                      onPressed:
                          isBetter && canAfford ? () => game.upgradeBookbag(u.cost, u.capacity) : null,
                      neonColor: AppTheme.littleFive,
                      width: 80,
                      height: 36,
                      fontSize: 10,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
