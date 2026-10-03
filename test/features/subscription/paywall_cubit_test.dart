import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/subscription/pro_plan.dart';
import 'package:quizoo/core/subscription/pro_status_api.dart';
import 'package:quizoo/core/subscription/purchases_service.dart';
import 'package:quizoo/core/subscription/subscription_repository.dart';
import 'package:quizoo/features/subscription/presentation/bloc/paywall_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_purchases.dart';

class _MockProStatusApi extends Mock implements ProStatusApi {}

void main() {
  late FakePurchasesService purchases;
  late SubscriptionRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    purchases = FakePurchasesService();
    // `FakePurchasesService` is a hand-written fake, not a mocktail `Mock`,
    // so its fields drive the answers directly — no `when` needed. The
    // server sync *is* a mocktail mock, so it needs a stub.
    final proStatus = _MockProStatusApi();
    when(() => proStatus.sync()).thenAnswer((_) async => true);
    repository = SubscriptionRepository(
      purchases,
      proStatus,
      await SharedPreferences.getInstance(),
    );
  });

  group('PaywallCubit', () {
    test('starts loading', () {
      final cubit = PaywallCubit(repository);
      addTearDown(cubit.close);
      expect(cubit.state, isA<PaywallLoading>());
    });

    blocTest<PaywallCubit, PaywallState>(
      'load preselects yearly and computes the savings percent',
      build: () {
        purchases.offersResult = fakeOffers();
        return PaywallCubit(repository);
      },
      act: (cubit) => cubit.load(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        final state = cubit.state as PaywallReady;
        expect(state.selected, ProPlan.yearly);
        // 12 × 4.99 = 59.88 vs 39.99 → 33% off.
        expect(state.yearlySavingsPercent, 33);
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'the savings percent is null when a price is missing',
      build: () {
        purchases.offersResult = [
          fakeOffers().firstWhere((offer) => offer.plan == ProPlan.yearly),
        ];
        return PaywallCubit(repository);
      },
      act: (cubit) => cubit.load(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect((cubit.state as PaywallReady).yearlySavingsPercent, isNull);
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'load falls back to the first offer when yearly is absent',
      build: () {
        purchases.offersResult = [
          fakeOffers().firstWhere((offer) => offer.plan == ProPlan.monthly),
        ];
        return PaywallCubit(repository);
      },
      act: (cubit) => cubit.load(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect((cubit.state as PaywallReady).selected, ProPlan.monthly);
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'a load failure is PaywallUnavailable',
      build: () {
        purchases.errorToThrow = const ApiException(
          'offline',
          kind: ApiErrorKind.network,
        );
        return PaywallCubit(repository);
      },
      act: (cubit) => cubit.load(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state, isA<PaywallUnavailable>());
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'an empty offering is PaywallUnavailable, not an empty ready state',
      build: () {
        purchases.offersResult = const [];
        return PaywallCubit(repository);
      },
      act: (cubit) => cubit.load(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state, isA<PaywallUnavailable>());
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'purchase success goes to PaywallPurchased',
      build: () {
        purchases.offersResult = fakeOffers();
        purchases.purchaseOutcome = const PurchasePurchased();
        return PaywallCubit(repository);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.purchase();
      },
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(
          cubit.state,
          isA<PaywallPurchased>().having(
            (s) => s.wasRestore,
            'wasRestore',
            isFalse,
          ),
        );
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'a cancelled purchase returns to ready with no notice',
      build: () {
        purchases.offersResult = fakeOffers();
        purchases.purchaseOutcome = const PurchaseCancelled();
        return PaywallCubit(repository);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.purchase();
      },
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        final state = cubit.state as PaywallReady;
        expect(state.isBusy, isFalse);
        expect(state.notice, isNull);
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'a pending purchase raises the pending notice',
      build: () {
        purchases.offersResult = fakeOffers();
        purchases.purchaseOutcome = const PurchasePending();
        return PaywallCubit(repository);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.purchase();
      },
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect((cubit.state as PaywallReady).notice, PaywallNotice.pending);
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'a failed purchase raises the failed notice',
      build: () {
        purchases.offersResult = fakeOffers();
        purchases.purchaseOutcome = const PurchaseFailed('card declined');
        return PaywallCubit(repository);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.purchase();
      },
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect((cubit.state as PaywallReady).notice, PaywallNotice.failed);
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'a restore that finds Pro is a purchase',
      build: () {
        purchases.restoreResult = fakeProSnapshot;
        return PaywallCubit(repository);
      },
      act: (cubit) => cubit.restore(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(
          cubit.state,
          isA<PaywallPurchased>().having(
            (s) => s.wasRestore,
            'wasRestore',
            isTrue,
          ),
        );
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'a restore that finds nothing raises a notice and stays ready',
      build: () {
        purchases.restoreResult = PurchasesSnapshot.free;
        return PaywallCubit(repository);
      },
      act: (cubit) => cubit.restore(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(
          (cubit.state as PaywallReady).notice,
          PaywallNotice.nothingToRestore,
        );
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'clearNotice drops the one-shot notice',
      build: () {
        purchases.offersResult = fakeOffers();
        purchases.purchaseOutcome = const PurchaseFailed('x');
        return PaywallCubit(repository);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.purchase();
        cubit.clearNotice();
      },
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect((cubit.state as PaywallReady).notice, isNull);
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'select changes the plan, but not while busy',
      build: () {
        purchases.offersResult = fakeOffers();
        return PaywallCubit(repository);
      },
      act: (cubit) async {
        await cubit.load();
        cubit.select(ProPlan.lifetime);
      },
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect((cubit.state as PaywallReady).selected, ProPlan.lifetime);
      },
    );
  });
}
