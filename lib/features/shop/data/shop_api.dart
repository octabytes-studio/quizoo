import 'package:quizoo/core/mock/mock_api.dart';
import 'package:quizoo/core/mock/mock_player.dart';
import 'package:quizoo/core/models/power_up.dart';
import 'package:quizoo/features/shop/domain/coin_pack.dart';
import 'package:quizoo/features/shop/domain/shop_content.dart';

/// The mocked shop endpoint.
class ShopApi extends MockApi {
  ShopApi({
    super.minLatency,
    super.maxLatency,
    super.failureRate,
    super.random,
  });

  static ShopContent get _shop => ShopContent(
    coins: MockPlayer.currency.coins,
    gems: MockPlayer.currency.gems,
    // "1 of 3" — the bible's own worked example for the free-coins card.
    freeAdsWatchedToday: 1,
    freeAdsPerDay: 3,
    freeCoinsReward: 50,
    inventory: const PowerUpInventory(
      fiftyFifty: MockPlayer.fiftyFiftyCount,
      addTime: MockPlayer.addTimeCount,
      skip: MockPlayer.skipCount,
    ),
    coinPacks: const [
      CoinPack(id: 'pack_small', coins: 500, priceLabel: '\$0.99'),
      CoinPack(
        id: 'pack_medium',
        coins: 2800,
        priceLabel: '\$4.99',
        bonusPercent: 20,
        isHighlighted: true,
      ),
      CoinPack(
        id: 'pack_large',
        coins: 6500,
        priceLabel: '\$9.99',
        bonusPercent: 50,
      ),
    ],
  );

  Future<ShopContent> fetchShop() => respond(() => _shop);
}
