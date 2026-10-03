import 'dart:async';

import 'package:quizoo/core/subscription/pro_membership.dart';
import 'package:quizoo/core/subscription/pro_offer.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/subscription/pro_plan.dart';
import 'package:quizoo/core/subscription/pro_promo_store.dart';
import 'package:quizoo/core/subscription/pro_status_api.dart';
import 'package:quizoo/core/subscription/subscription_repository.dart';
import 'package:quizoo/core/subscription/purchases_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A hand-written, completer-backed fake of the purchase SDK seam (plan 023).
///
/// Matches the `core/ads` convention: fakes, not mocktail, for SDK seams —
/// every method completes immediately unless a test drives it, so nothing
/// hangs `pumpAndSettle`. **No test may construct
/// `RevenueCatPurchasesService`.**
class FakePurchasesService implements PurchasesService {
  FakePurchasesService({PurchasesSnapshot? initial})
    : _snapshot = initial ?? PurchasesSnapshot.free;

  /// The canned answer for [offers]. Empty by default, which the paywall
  /// renders as its unavailable state.
  List<ProOffer> offersResult = const [];

  /// What [purchase] returns. Defaults to a success.
  PurchaseOutcome purchaseOutcome = const PurchasePurchased();

  /// What [restore] reports.
  PurchasesSnapshot restoreResult = PurchasesSnapshot.free;

  /// What [openManagement] reports: whether the store's page opened.
  bool openManagementResult = true;

  /// Set to make the next SDK call throw, so the repository's `ApiException`
  /// mapping can be exercised.
  Object? errorToThrow;

  /// When set, [configure] waits on it, so a test can hold the SDK
  /// "unconfigured" while events fire and assert none reaches the SDK early.
  Completer<void>? configureGate;

  /// Records what each call was asked to do.
  final List<String> calls = [];

  PurchasesSnapshot _snapshot;
  final StreamController<PurchasesSnapshot> _changes =
      StreamController<PurchasesSnapshot>.broadcast();

  /// Publishes a new snapshot on [changes], as a purchase made elsewhere
  /// would.
  void emitSnapshot(PurchasesSnapshot snapshot) {
    _snapshot = snapshot;
    _changes.add(snapshot);
  }

  void _throwIfAsked() {
    final error = errorToThrow;
    if (error != null) throw error;
  }

  @override
  Future<void> configure({
    required String apiKey,
    required String userId,
  }) async {
    calls.add('configure:$userId');
    _throwIfAsked();
    final gate = configureGate;
    if (gate != null) await gate.future;
  }

  @override
  Future<PurchasesSnapshot> logIn(
    String userId, {
    required bool carryPurchases,
  }) async {
    calls.add('logIn:$userId:$carryPurchases');
    _throwIfAsked();
    return _snapshot;
  }

  @override
  Future<PurchasesSnapshot> current() async {
    calls.add('current');
    _throwIfAsked();
    return _snapshot;
  }

  @override
  Stream<PurchasesSnapshot> get changes => _changes.stream;

  @override
  Future<List<ProOffer>> offers() async {
    calls.add('offers');
    _throwIfAsked();
    return offersResult;
  }

  @override
  Future<PurchaseOutcome> purchase(ProOffer offer) async {
    calls.add('purchase:${offer.packageId}');
    _throwIfAsked();
    return purchaseOutcome;
  }

  @override
  Future<PurchasesSnapshot> restore() async {
    calls.add('restore');
    _throwIfAsked();
    return restoreResult;
  }

  @override
  Future<bool> openManagement() async {
    calls.add('openManagement');
    _throwIfAsked();
    return openManagementResult;
  }

  @override
  Future<PurchasesSnapshot> syncPurchases() async {
    calls.add('syncPurchases');
    _throwIfAsked();
    return _snapshot;
  }
}

/// Three canned offers, one per plan, at store-shaped prices — enough for the
/// paywall's ordering, preselection and savings maths to be tested against
/// something realistic.
List<ProOffer> fakeOffers({
  double monthlyPrice = 4.99,
  double yearlyPrice = 39.99,
  double lifetimePrice = 99.99,
  int? yearlyTrialDays,
}) => [
  ProOffer(
    plan: ProPlan.yearly,
    packageId: '\$rc_annual',
    priceLabel: '\$$yearlyPrice',
    price: yearlyPrice,
    currencyCode: 'USD',
    trialDays: yearlyTrialDays,
    perMonthLabel: 'USD 3.33',
  ),
  ProOffer(
    plan: ProPlan.monthly,
    packageId: '\$rc_monthly',
    priceLabel: '\$$monthlyPrice',
    price: monthlyPrice,
    currencyCode: 'USD',
  ),
  ProOffer(
    plan: ProPlan.lifetime,
    packageId: '\$rc_lifetime',
    priceLabel: '\$$lifetimePrice',
    price: lifetimePrice,
    currencyCode: 'USD',
  ),
];

/// A [SubscriptionCubit] that is neither Pro nor able to buy Pro — the
/// state every screen rendered before plan 023. Handy for tests that use
/// `pumpApp` rather than `pumpScreen` and so have no app-root providers.
SubscriptionCubit freeSubscriptionCubit() => SubscriptionCubit(
  repository: SubscriptionRepository(
    FakePurchasesService(),
    FakeProStatusApi(),
    MemoryPreferences(),
  ),
  promos: ProPromoStore(MemoryPreferences()),
  userIds: const Stream.empty(),
  initialUserId: null,
  apiKey: null,
  isEnabled: false,
);

/// A [SubscriptionCubit] holding Pro on this device.
SubscriptionCubit proSubscriptionCubit() {
  final preferences = MemoryPreferences();
  unawaited(preferences.setBool('subscription.isPro', true));
  return SubscriptionCubit(
    repository: SubscriptionRepository(
      FakePurchasesService(initial: fakeProSnapshot),
      FakeProStatusApi(),
      preferences,
    ),
    promos: ProPromoStore(preferences),
    userIds: const Stream.empty(),
    initialUserId: null,
    apiKey: 'test',
    isEnabled: true,
  );
}

class FakeProStatusApi implements ProStatusApi {
  @override
  Future<bool> sync() async => true;
}

/// In-memory `SharedPreferences` for the promo store's dismissal clock and
/// the repository's `isPro` cache. A mocktail `Mock` with an in-memory map
/// behind it, so `SharedPreferences`'s many members need no stubbing.
class MemoryPreferences extends Mock implements SharedPreferences {
  MemoryPreferences() {
    final values = <String, Object>{};
    when(() => getBool(any())).thenAnswer(
      (invocation) => values[invocation.positionalArguments.first] as bool?,
    );
    when(() => getInt(any())).thenAnswer(
      (invocation) => values[invocation.positionalArguments.first] as int?,
    );
    when(() => getString(any())).thenAnswer(
      (invocation) => values[invocation.positionalArguments.first] as String?,
    );
    when(() => setBool(any(), any())).thenAnswer((invocation) async {
      values[invocation.positionalArguments.first] =
          invocation.positionalArguments[1];
      return true;
    });
    when(() => setInt(any(), any())).thenAnswer((invocation) async {
      values[invocation.positionalArguments.first] =
          invocation.positionalArguments[1];
      return true;
    });
    when(() => setString(any(), any())).thenAnswer((invocation) async {
      values[invocation.positionalArguments.first] =
          invocation.positionalArguments[1];
      return true;
    });
  }
}

/// A [SubscriptionRepository] over [FakePurchasesService] and
/// [FakeProStatusApi] — what `pumpScreen` provides when a test supplies
/// nothing of its own.
SubscriptionRepository fakeSubscriptionRepository() => SubscriptionRepository(
  FakePurchasesService(),
  FakeProStatusApi(),
  MemoryPreferences(),
);

/// A [SubscriptionCubit] holding Pro with an exact membership detail — for
/// tests that care which date line the UI shows.
SubscriptionCubit proSubscriptionCubitWith(ProMembership membership) {
  final preferences = MemoryPreferences();
  unawaited(preferences.setBool('subscription.isPro', true));
  return SubscriptionCubit(
    repository: SubscriptionRepository(
      FakePurchasesService(
        initial: PurchasesSnapshot(isPro: true, membership: membership),
      ),
      FakeProStatusApi(),
      preferences,
    ),
    promos: ProPromoStore(preferences),
    userIds: const Stream.empty(),
    initialUserId: null,
    apiKey: 'test',
    isEnabled: true,
  );
}

/// A member's snapshot, for tests that need Pro on.
const PurchasesSnapshot fakeProSnapshot = PurchasesSnapshot(
  isPro: true,
  membership: ProMembership(plan: ProPlan.yearly, willRenew: true),
);
