import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/models/power_up.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/shop/data/shop_api.dart';
import 'package:quizoo/features/shop/data/shop_repository.dart';
import 'package:quizoo/features/shop/domain/shop_content.dart';

class _MockShopApi extends Mock implements ShopApi {}

void main() {
  late _MockShopApi api;
  late ShopRepository repository;

  const content = ShopContent(
    coins: 1240,
    gems: 18,
    freeAdsWatchedToday: 1,
    freeAdsPerDay: 3,
    freeCoinsReward: 50,
    inventory: PowerUpInventory(),
    coinPacks: [],
  );

  setUp(() {
    api = _MockShopApi();
    repository = ShopRepository(api);
  });

  group('ShopRepository', () {
    test('success path: hands back the shop content unchanged', () async {
      when(() => api.fetchShop()).thenAnswer((_) async => content);

      final result = await repository.fetchShop();

      expect(result, content);
    });

    test('failure path: the API\'s ApiException reaches the caller', () async {
      when(() => api.fetchShop()).thenThrow(const ApiException.network());

      expect(repository.fetchShop, throwsA(isA<ApiException>()));
    });
  });
}
