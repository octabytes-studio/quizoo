import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/subscription/pro_membership.dart';
import 'package:quizoo/core/subscription/pro_plan.dart';
import 'package:quizoo/core/subscription/pro_status_api.dart';
import 'package:quizoo/core/subscription/pro_promo_store.dart';
import 'package:quizoo/core/subscription/purchases_service.dart';
import 'package:quizoo/core/subscription/subscription_repository.dart';

import '../support/fake_purchases.dart';

class _MockProStatusApi extends Mock implements ProStatusApi {}

void main() {
  late FakePurchasesService purchases;
  late _MockProStatusApi proStatus;
  late MemoryPreferences preferences;
  late ProPromoStore promos;
  late StreamController<UserIdentity?> users;

  setUp(() {
    purchases = FakePurchasesService();
    proStatus = _MockProStatusApi();
    when(() => proStatus.sync()).thenAnswer((_) async => true);
    preferences = MemoryPreferences();
    promos = ProPromoStore(preferences);
    users = StreamController<UserIdentity?>.broadcast();
    addTearDown(users.close);
  });

  SubscriptionRepository repository() =>
      SubscriptionRepository(purchases, proStatus, preferences);

  SubscriptionCubit build({
    String? apiKey = 'test-key',
    bool isEnabled = true,
    String? initialUserId = 'user-1',
  }) => SubscriptionCubit(
    repository: repository(),
    promos: promos,
    userIds: users.stream,
    initialUserId: initialUserId,
    apiKey: apiKey,
    isEnabled: isEnabled,
  );

  group('SubscriptionCubit', () {
    test('starts free when the cache is empty', () async {
      final cubit = build();
      addTearDown(cubit.close);
      expect(cubit.state.isPro, isFalse);
    });

    test('starts Pro when the cache says so', () async {
      await preferences.setBool('subscription.isPro', true);
      final cubit = build();
      addTearDown(cubit.close);
      expect(cubit.state.isPro, isTrue);
    });

    blocTest<SubscriptionCubit, SubscriptionState>(
      'initialize succeeds and reports Pro with its membership',
      build: () {
        purchases.emitSnapshot(
          const PurchasesSnapshot(
            isPro: true,
            membership: ProMembership(
              plan: ProPlan.yearly,
              willRenew: true,
              expiresAt: null,
            ),
          ),
        );
        return build();
      },
      act: (cubit) => cubit.initialize(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state.isPro, isTrue);
        expect(cubit.state.perks.fiftyFifty, 2);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'a null API key leaves Pro unavailable and never calls the SDK',
      build: () => build(apiKey: null),
      act: (cubit) => cubit.initialize(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state.isPro, isFalse);
        expect(
          cubit.state,
          isA<SubscriptionFree>().having(
            (state) => state.isAvailable,
            'isAvailable',
            isFalse,
          ),
        );
        expect(purchases.calls, isEmpty);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'pro_enabled = false leaves Pro unavailable',
      build: () => build(isEnabled: false),
      act: (cubit) => cubit.initialize(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(purchases.calls, isEmpty);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'a failing initialize keeps the cached state rather than throwing',
      build: () {
        purchases.errorToThrow = Exception('SDK down');
        return build();
      },
      act: (cubit) => cubit.initialize(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state.isPro, isFalse);
      },
    );

    test(
      'a replayed identity cannot reach the SDK before configure completes',
      () async {
        final gate = Completer<void>();
        purchases.configureGate = gate;
        final cubit = SubscriptionCubit(
          repository: repository(),
          promos: promos,
          // The real auth stream is a replay subject: it delivers the current
          // session the moment it is listened to.
          userIds: Stream.value((id: 'user-1', isAnonymous: true)),
          initialUserId: 'user-1',
          apiKey: 'test-key',
          isEnabled: true,
        );
        addTearDown(cubit.close);

        final initializing = cubit.initialize();
        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(
          purchases.calls.where((call) => call.startsWith('logIn:')),
          isEmpty,
          reason: 'logIn must never race Purchases.configure',
        );

        gate.complete();
        await initializing;
        expect(purchases.calls, contains('configure:user-1'));
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'a changes event flips the state',
      build: () => build(),
      act: (cubit) async {
        await cubit.initialize();
        purchases.emitSnapshot(fakeProSnapshot);
      },
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state.isPro, isTrue);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'a user-id change calls switchUser with the right carryPurchases',
      build: () => build(),
      act: (cubit) async {
        await cubit.initialize();
        purchases.emitSnapshot(fakeProSnapshot);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        // Sign-in (not anonymous) while Pro: the receipt moves across.
        users.add((id: 'user-2', isAnonymous: false));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        // Sign-out (anonymous) while Pro: it does not.
        users.add((id: 'user-3', isAnonymous: true));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      verify: (cubit) {
        expect(purchases.calls, contains('logIn:user-2:true'));
        expect(purchases.calls, contains('logIn:user-3:false'));
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'dismissHomePromo hides the card',
      build: () => build(),
      act: (cubit) => cubit.dismissHomePromo(),
      verify: (cubit) {
        expect(promos.shouldShowHomeCard, isFalse);
        expect(
          cubit.state,
          isA<SubscriptionFree>().having(
            (state) => state.showHomePromo,
            'showHomePromo',
            isFalse,
          ),
        );
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'openManagement reports whether the store page opened',
      build: () => build(),
      act: (cubit) async {
        expect(await cubit.openManagement(), isTrue);
      },
      verify: (cubit) {
        expect(purchases.calls, contains('openManagement'));
      },
      expect: () => <SubscriptionState>[],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'a failing openManagement reports false rather than throwing',
      build: () {
        purchases.errorToThrow = Exception('no store here');
        return build();
      },
      act: (cubit) async {
        expect(await cubit.openManagement(), isFalse);
      },
    );
  });
}
