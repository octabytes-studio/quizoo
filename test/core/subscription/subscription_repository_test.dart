import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/subscription/pro_plan.dart';
import 'package:quizoo/core/subscription/pro_status_api.dart';
import 'package:quizoo/core/subscription/purchases_service.dart';
import 'package:quizoo/core/subscription/subscription_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_purchases.dart';

class _MockProStatusApi extends Mock implements ProStatusApi {}

void main() {
  late FakePurchasesService purchases;
  late _MockProStatusApi proStatus;
  late SubscriptionRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    purchases = FakePurchasesService();
    proStatus = _MockProStatusApi();
  });

  Future<SubscriptionRepository> build() async => SubscriptionRepository(
    purchases,
    proStatus,
    await SharedPreferences.getInstance(),
  );

  group('SubscriptionRepository', () {
    test('caches isPro on every snapshot', () async {
      when(() => proStatus.sync()).thenAnswer((_) async => true);
      repository = await build();
      expect(repository.cachedIsPro, isFalse);

      // The cache write rides the `changes` stream, so something has to be
      // listening — exactly as `SubscriptionCubit` is in the app.
      final seen = <PurchasesSnapshot>[];
      final sub = repository.changes.listen(seen.add);
      addTearDown(sub.cancel);

      purchases.emitSnapshot(fakeProSnapshot);
      await pumpEventQueue();
      expect(seen, hasLength(1));
      expect(repository.cachedIsPro, isTrue);
    });

    test('purchase success triggers a server sync', () async {
      when(() => proStatus.sync()).thenAnswer((_) async => true);
      repository = await build();
      purchases.purchaseOutcome = const PurchasePurchased();

      final outcome = await repository.purchase(fakeOffers().first);
      expect(outcome, isA<PurchasePurchased>());
      await pumpEventQueue();
      verify(() => proStatus.sync()).called(1);
    });

    test('a failing server sync does not fail the purchase', () async {
      when(
        () => proStatus.sync(),
      ).thenThrow(const ApiException('boom', kind: ApiErrorKind.server));
      repository = await build();
      purchases.purchaseOutcome = const PurchasePurchased();

      final outcome = await repository.purchase(fakeOffers().first);
      expect(outcome, isA<PurchasePurchased>());
      await pumpEventQueue();
    });

    test('a cancelled purchase caches nothing and syncs nothing', () async {
      when(() => proStatus.sync()).thenAnswer((_) async => true);
      repository = await build();
      purchases.purchaseOutcome = const PurchaseCancelled();

      final outcome = await repository.purchase(fakeOffers().first);
      expect(outcome, isA<PurchaseCancelled>());
      await pumpEventQueue();
      verifyNever(() => proStatus.sync());
    });

    test('switchUser carries purchases only when asked', () async {
      when(() => proStatus.sync()).thenAnswer((_) async => true);
      repository = await build();

      await repository.switchUser('user-1', carryPurchases: true);
      await repository.switchUser('user-2', carryPurchases: false);

      expect(purchases.calls, contains('logIn:user-1:true'));
      expect(purchases.calls, contains('logIn:user-2:false'));
    });

    test('switchUser with carryPurchases syncs the server', () async {
      when(() => proStatus.sync()).thenAnswer((_) async => true);
      repository = await build();

      await repository.switchUser('user-1', carryPurchases: true);
      await pumpEventQueue();
      verify(() => proStatus.sync()).called(1);
    });

    test('a restore that finds Pro caches it and syncs', () async {
      when(() => proStatus.sync()).thenAnswer((_) async => true);
      purchases.restoreResult = fakeProSnapshot;
      repository = await build();

      final snapshot = await repository.restore();
      expect(snapshot.isPro, isTrue);
      await pumpEventQueue();
      verify(() => proStatus.sync()).called(1);
    });

    test('a restore that finds nothing syncs nothing', () async {
      when(() => proStatus.sync()).thenAnswer((_) async => true);
      purchases.restoreResult = PurchasesSnapshot.free;
      repository = await build();

      final snapshot = await repository.restore();
      expect(snapshot.isPro, isFalse);
      await pumpEventQueue();
      verifyNever(() => proStatus.sync());
    });

    test('openManagement passes the store result through', () async {
      repository = await build();
      purchases.openManagementResult = true;

      expect(await repository.openManagement(), isTrue);
      expect(purchases.calls, contains('openManagement'));
    });

    test('openManagement maps an SDK failure to ApiException', () async {
      repository = await build();
      purchases.errorToThrow = Exception('no store here');

      await expectLater(
        repository.openManagement(),
        throwsA(isA<ApiException>()),
      );
    });

    // Plan 023 fix: the server mirror is what *other* players see, so a
    // device that already knows it is Pro must re-ask the server on every
    // launch. Without this, a failed purchase-time sync was never retried
    // and `profiles.is_pro` stayed false for ever.
    test('start re-syncs the server when the device is already Pro', () async {
      when(() => proStatus.sync()).thenAnswer((_) async => true);
      purchases.emitSnapshot(fakeProSnapshot);
      repository = await build();

      await repository.start('user-1', apiKey: 'key');
      await pumpEventQueue();
      verify(() => proStatus.sync()).called(1);
    });

    test('start does not sync the server for a free player', () async {
      when(() => proStatus.sync()).thenAnswer((_) async => true);
      repository = await build();

      await repository.start('user-1', apiKey: 'key');
      await pumpEventQueue();
      verifyNever(() => proStatus.sync());
    });

    test('an SDK failure surfaces as ApiException', () async {
      when(() => proStatus.sync()).thenAnswer((_) async => true);
      purchases.errorToThrow = Exception('store is down');
      repository = await build();

      await expectLater(repository.offers(), throwsA(isA<ApiException>()));
    });

    test('offers are passed through untouched', () async {
      when(() => proStatus.sync()).thenAnswer((_) async => true);
      purchases.offersResult = fakeOffers();
      repository = await build();

      final offers = await repository.offers();
      expect(offers.map((offer) => offer.plan), [
        ProPlan.yearly,
        ProPlan.monthly,
        ProPlan.lifetime,
      ]);
    });
  });
}
