import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/game_state.dart';
import '../models/location.dart';
import '../models/product.dart';
import '../services/save_service.dart';
import '../widgets/stats_bar.dart';
import '../widgets/location_card.dart';
import '../widgets/travel_map.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // All modals use showModalBottomSheet directly

  @override
  void initState() {
    super.initState();
    // Auto-save when entering this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<_GameModel>();
      state.autoSave();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<_GameModel>(
      builder: (context, model, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Persistent HUD
                StatsBar(
                  state: model.gameState,
                  onSettingsTap: () => _showSettings(context),
                ),
                // Main content
                Expanded(
                  child: _buildMainContent(context, model),
                ),
                // Bottom action bar
                _buildActionBar(context, model),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context, _GameModel model) {
    final currentLoc = model.gameState.getCurrentLocation();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current location header
        Text(
          currentLoc?.type.displayName ?? 'Unknown',
          style: GoogleFonts.permanentMarker(
            fontSize: 24,
            color: AppColors.accentForLocation(
              currentLoc?.type.accentColor ?? 'green',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currentLoc?.type.specialFeature ?? '',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.gray),
        ),
        const SizedBox(height: 16),

        // Market prices (if visited)
        if (currentLoc != null && currentLoc.isVisited) ...[
          _buildMarketSection(currentLoc),
          const SizedBox(height: 16),
        ],

        // Location list
        Text(
          'LOCATIONS',
          style: GoogleFonts.pressStart2p(
            fontSize: 8,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        ...model.gameState.locations.map((loc) => LocationCard(
          location: loc,
          isCurrent: loc.type == model.gameState.currentLocation,
          onTap: () {
            if (loc.type != model.gameState.currentLocation) {
              _showTravel(context, model);
            } else {
              _visitLocation(context, model, loc);
            }
          },
        )),

        if (model.gameState.currentDay > model.gameState.totalDays) ...[
          const SizedBox(height: 24),
          _buildGameOver(context, model),
        ],
      ],
    );
  }

  Widget _buildMarketSection(Location location) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRICES TODAY',
            style: GoogleFonts.pressStart2p(
              fontSize: 8,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          ...location.availableProducts.map((product) {
            final inv = context.read<_GameModel>().gameState.inventory
                .where((p) => p.type == product.type)
                .firstOrNull;
            final owned = inv?.quantity ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(
                    '${product.type.emoji} ${product.type.displayName}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${product.currentPrice}',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 9,
                      color: AppColors.accent,
                    ),
                  ),
                  if (owned > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent2.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '$owned',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 6,
                          color: AppColors.accent2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, _GameModel model) {
    final currentLoc = model.gameState.getCurrentLocation();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.cardLight),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Travel button
            Expanded(
              child: _ActionButton(
                icon: Icons.map,
                label: 'TRAVEL',
                onTap: () => _showTravel(context, model),
              ),
            ),
            const SizedBox(width: 8),
            // Shop (only when at a visited location)
            Expanded(
              child: _ActionButton(
                icon: Icons.shopping_bag,
                label: 'SHOP',
                isActive: currentLoc?.isVisited == true,
                onTap: currentLoc?.isVisited == true
                    ? () => _showShopSheet(context, model)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            // Inventory
            Expanded(
              child: _ActionButton(
                icon: Icons.backpack,
                label: 'BAG',
                isActive: model.gameState.inventory.isNotEmpty ||
                    model.gameState.equippedWeapons.length > 1,
                onTap: () => _showInventorySheet(context, model),
              ),
            ),
            const SizedBox(width: 8),
            // Day advance
            Expanded(
              child: _ActionButton(
                icon: Icons.skip_next,
                label: 'NEXT DAY',
                color: AppColors.accent2,
                onTap: () => _advanceDay(context, model),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Actions ----

  void _showTravel(BuildContext context, _GameModel model) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TravelMap(
        state: model.gameState,
        onTravel: (destination, mode) {
          model.travelTo(destination, mode);
        },
        onClose: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showShopSheet(BuildContext context, _GameModel model) {
    final loc = model.gameState.getCurrentLocation();
    if (loc == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ShopSheet(location: loc, model: model),
    );
  }

  void _showInventorySheet(BuildContext context, _GameModel model) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _InventorySheet(model: model),
    );
  }

  void _visitLocation(BuildContext context, _GameModel model, Location loc) {
    model.visitLocation();
  }

  void _advanceDay(BuildContext context, _GameModel model) {
    model.advanceDay();
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Settings', style: GoogleFonts.permanentMarker(fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sound: On / Off (coming soon)'),
            const SizedBox(height: 8),
            Text('Duration: ${context.read<_GameModel>().gameState.totalDays} days'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOver(BuildContext context, _GameModel model) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.westEndRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.westEndRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('🏁', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            'GAME OVER',
            style: GoogleFonts.pressStart2p(
              fontSize: 14,
              color: AppColors.westEndRed,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Net Worth: \$${model.gameState.netWorth}',
            style: GoogleFonts.inter(
              fontSize: 18,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Action Button ----

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isActive = true,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AppColors.accent;
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: (isActive ? btnColor : AppColors.darkGray).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? btnColor : AppColors.darkGray,
              size: 18,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.pressStart2p(
                fontSize: 6,
                color: isActive ? btnColor : AppColors.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Shop Sheet ----

class _ShopSheet extends StatelessWidget {
  final Location location;
  final _GameModel model;

  const _ShopSheet({required this.location, required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${location.type.displayName} MARKET',
            style: GoogleFonts.permanentMarker(
              fontSize: 20,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cash: \$${model.gameState.cash}  |  Bag: ${model.gameState.totalInventoryCount}/${model.gameState.bagCapacity}',
            style: GoogleFonts.pressStart2p(
              fontSize: 7,
              color: AppColors.gray,
            ),
          ),
          const SizedBox(height: 12),
          ...location.availableProducts.map((product) => _ShopItem(
            product: product,
            canAfford: model.gameState.cash >= product.currentPrice,
            hasSpace: model.gameState.availableBagSpace > 0,
            onBuy: (qty) {
              model.buyProduct(product.type, qty);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppColors.gray),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItem extends StatelessWidget {
  final Product product;
  final bool canAfford;
  final bool hasSpace;
  final void Function(int quantity) onBuy;

  const _ShopItem({
    required this.product,
    required this.canAfford,
    required this.hasSpace,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product.type.emoji} ${product.type.displayName}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  '\$${product.currentPrice}',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 10,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          // Quick buy buttons
          if (canAfford && hasSpace) ...[
            _QtyButton(label: '1', onTap: () => onBuy(1)),
            const SizedBox(width: 4),
            _QtyButton(label: '5', onTap: () => onBuy(5)),
            const SizedBox(width: 4),
            _QtyButton(label: '10', onTap: () => onBuy(10)),
          ] else
            Text(
              canAfford ? 'BAG FULL' : 'BROKE',
              style: GoogleFonts.pressStart2p(
                fontSize: 7,
                color: AppColors.danger,
              ),
            ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QtyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: GoogleFonts.pressStart2p(
            fontSize: 8,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}

// ---- Inventory Sheet ----

class _InventorySheet extends StatelessWidget {
  final _GameModel model;

  const _InventorySheet({required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '🎒 INVENTORY',
            style: GoogleFonts.permanentMarker(
              fontSize: 20,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${model.gameState.totalInventoryCount}/${model.gameState.bagCapacity} used',
            style: GoogleFonts.pressStart2p(
              fontSize: 7,
              color: AppColors.gray,
            ),
          ),
          const SizedBox(height: 12),

          // Products
          if (model.gameState.inventory.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Bag is empty',
                  style: GoogleFonts.inter(color: AppColors.gray),
                ),
              ),
            )
          else
            ...model.gameState.inventory
                .where((p) => p.quantity > 0)
                .map((product) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${product.type.emoji} ${product.type.displayName}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'x${product.quantity}',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 9,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          model.sellProduct(product.type);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent2.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SELL',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 6,
                              color: AppColors.accent2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

          // Weapons
          if (model.gameState.equippedWeapons.length > 1) ...[
            const SizedBox(height: 12),
            Text(
              '🔫 WEAPONS',
              style: GoogleFonts.pressStart2p(
                fontSize: 8,
                color: AppColors.accent2,
              ),
            ),
            const SizedBox(height: 8),
            ...model.gameState.equippedWeapons.map((weapon) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Text(
                    '${weapon.type.emoji} ${weapon.type.displayName}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    weapon.isInfinite
                        ? '∞'
                        : '${weapon.usesRemaining}/${weapon.type.maxUses}',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 7,
                      color: weapon.isBroken ? AppColors.danger : AppColors.gray,
                    ),
                  ),
                ],
              ),
            )),
          ],

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.inter(color: AppColors.gray),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Game Model (Provider) ----

class _GameModel extends ChangeNotifier {
  GameState gameState;

  _GameModel(this.gameState);

  void travelTo(LocationType destination, TravelMode mode) {
    gameState.lastTravelMode = mode;
    gameState.currentLocation = destination;

    // Mark visited
    final loc = gameState.locations
        .where((l) => l.type == destination)
        .firstOrNull;
    if (loc != null) {
      loc.isVisited = true;
    }

    gameState.advanceDay();
    autoSave();
    notifyListeners();
  }

  void visitLocation() {
    final loc = gameState.getCurrentLocation();
    if (loc != null) {
      loc.isVisited = true;
    }
    notifyListeners();
  }

  void advanceDay() {
    gameState.advanceDay();
    autoSave();
    notifyListeners();
  }

  void buyProduct(ProductType type, int quantity) {
    gameState.buyProduct(type, quantity);
    autoSave();
    notifyListeners();
  }

  void sellProduct(ProductType type) {
    gameState.sellProduct(type);
    autoSave();
    notifyListeners();
  }

  Future<void> autoSave() async {
    await SaveService.saveGame(gameState);
  }
}

// ---- Provider Wrapper ----

class GameProvider extends StatelessWidget {
  final GameState initialState;
  final Widget child;

  const GameProvider({
    super.key,
    required this.initialState,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<_GameModel>(
      create: (_) => _GameModel(initialState),
      child: child,
    );
  }
}
