import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/models/power_up.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/shop/data/shop_repository.dart';
import 'package:quizoo/features/shop/domain/shop_content.dart';
import 'package:quizoo/features/shop/presentation/bloc/shop_cubit.dart';

class _MockShopRepository extends Mock implements ShopRepository {}

void main() {
  late _MockShopRepository repository;

  const content = ShopContent(
    coins: 100,
    gems: 4,
    freeAdsWatchedToday: 1,
    freeAdsPerDay: 3,
    freeCoinsReward: 50,
    inventory: PowerUpInventory(),
    coinPacks: [],
  );

  setUp(() {
    repository = _MockShopRepository();
  });

  group('ShopCubit', () {
    blocTest<ShopCubit, ShopState>(
      'success path: loads the shop content',
      setUp: () =>
          when(() => repository.fetchShop()).thenAnswer((_) async => content),
      build: () => ShopCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ShopLoading>(),
        isA<ShopLoaded>().having((state) => state.content, 'content', content),
      ],
    );

    blocTest<ShopCubit, ShopState>(
      'failure path: a failed fetch ends in ShopError',
      setUp: () => when(
        () => repository.fetchShop(),
      ).thenThrow(const ApiException.network()),
      build: () => ShopCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [isA<ShopLoading>(), isA<ShopError>()],
    );

    blocTest<ShopCubit, ShopState>(
      'buying an affordable coin-priced power-up deducts coins and grants it',
      seed: () => const ShopLoaded(content: content),
      build: () => ShopCubit(repository),
      act: (cubit) => cubit.buyPowerUp(PowerUp.fiftyFifty),
      expect: () => [
        isA<ShopLoaded>()
            .having(
              (state) => state.content.coins,
              'coins',
              100 - PowerUp.fiftyFifty.costCoins!,
            )
            .having(
              (state) => state.content.inventory.fiftyFifty,
              'fiftyFifty',
              1,
            ),
      ],
    );

    test('buying a power-up the wallet cannot afford returns false and '
        'changes nothing', () async {
      when(
        () => repository.fetchShop(),
      ).thenAnswer((_) async => content.copyWith(coins: 0));
      final cubit = ShopCubit(repository);
      await cubit.load();

      final bought = cubit.buyPowerUp(PowerUp.fiftyFifty);

      expect(bought, isFalse);
      expect((cubit.state as ShopLoaded).content.coins, 0);
      expect((cubit.state as ShopLoaded).content.inventory.fiftyFifty, 0);
    });

    blocTest<ShopCubit, ShopState>(
      'crediting a rewarded ad adds coins and counts the watch',
      seed: () => const ShopLoaded(content: content),
      build: () => ShopCubit(repository),
      act: (cubit) => cubit.creditRewardedAd(50),
      expect: () => [
        isA<ShopLoaded>()
            .having((state) => state.content.coins, 'coins', 150)
            .having(
              (state) => state.content.freeAdsWatchedToday,
              'freeAdsWatchedToday',
              2,
            ),
      ],
    );
  });
}
