import 'dart:math';
import '../models/game_state.dart';
import '../models/product.dart';
import '../models/location.dart';

class GameData {
  /// Create a fresh game state with randomized product prices
  static GameState createNewGame({
    Difficulty difficulty = Difficulty.normal,
    int totalDays = 30,
  }) {
    final rng = Random();
    final allTypes = ProductType.values.toList();

    final locations = LocationType.values.map((locType) {
      // Randomly pick 3-5 products for this location (not all products everywhere)
      final shuffled = List<ProductType>.from(allTypes)..shuffle(rng);
      final count = 3 + rng.nextInt(3); // 3 to 5
      final selectedTypes = shuffled.take(count).toList();

      // Check for demand spike or market flood at this location
      final hasDemand = rng.nextDouble() < 0.15;
      final hasFlood = !hasDemand && rng.nextDouble() < 0.10;

      // Assign demand/flood to a random product
      ProductType? demandProduct;
      ProductType? floodProduct;
      if (hasDemand) {
        demandProduct = selectedTypes[rng.nextInt(selectedTypes.length)];
      } else if (hasFlood) {
        floodProduct = selectedTypes[rng.nextInt(selectedTypes.length)];
      }

      final products = selectedTypes.map((type) {
        return Product(
          type: type,
          currentPrice: Product.generatePrice(
            type,
            demandSpike: type == demandProduct,
            marketFlood: type == floodProduct,
          ),
        );
      }).toList();

      return Location(type: locType, availableProducts: products);
    }).toList();

    return GameState(
      difficulty: difficulty,
      totalDays: totalDays,
      locations: locations,
    );
  }
}
