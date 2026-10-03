import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/subscription/pro_membership.dart';
import 'package:quizoo/core/subscription/pro_perks.dart';
import 'package:quizoo/core/subscription/pro_promo_store.dart';
import 'package:quizoo/core/subscription/purchases_service.dart';
import 'package:quizoo/core/subscription/subscription_repository.dart';

part 'subscription_state.dart';

/// A change of identity, so the Cubit can move the purchase SDK onto the new
/// user (plan 023, "Identity"). Built in `app.dart` from the auth stream.
typedef UserIdentity = ({String id, bool isAnonymous});

/// This device's Quizoo Pro entitlement (plan 023).
///
/// App-root like [AdsCubit] — see [SubscriptionState]. The initial state
/// comes from [SubscriptionRepository.cachedIsPro], so a returning member
/// never sees an ad flash at launch while the SDK warms up.
class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit({
    required SubscriptionRepository repository,
    required ProPromoStore promos,
    required this.userIds,
    required this.initialUserId,
    required this.apiKey,
    required bool isEnabled,
  }) : _repository = repository,
       _promos = promos,
       _isEnabled = isEnabled,
       super(
         repository.cachedIsPro
             ? const SubscriptionPro()
             : SubscriptionFree(
                 isAvailable: apiKey != null && isEnabled,
                 showHomePromo: promos.shouldShowHomeCard,
               ),
       );

  final SubscriptionRepository _repository;
  final ProPromoStore _promos;

  /// Identity changes from the auth stream, as `app.dart` shapes them.
  final Stream<UserIdentity?> userIds;

  /// The uid already signed in at construction, if any.
  final String? initialUserId;

  /// The RevenueCat SDK key for this platform, or null where Pro is
  /// unavailable (plan 023, Assumption 8).
  final String? apiKey;
  final bool _isEnabled;

  StreamSubscription<PurchasesSnapshot>? _changesSub;
  StreamSubscription<UserIdentity?>? _usersSub;
  bool _started = false;

  /// Starts the purchase SDK and begins following identity changes.
  ///
  /// Never throws: a null [apiKey], [_isEnabled] false, a null [initialUserId] or
  /// any failure simply leaves the cached state in place (and marks Pro
  /// unavailable while free), so a broken store SDK can never block the app.
  Future<void> initialize() async {
    if (_started) return;
    _started = true;

    final key = apiKey;
    if (!_isEnabled || key == null) {
      _emitUnavailableIfFree();
      return;
    }

    final userId = initialUserId;
    if (userId == null) {
      _emitUnavailableIfFree();
      return;
    }

    // Configure the SDK before any listener can reach it. The auth stream
    // replays the current session the moment it is listened to, so
    // subscribing first would let that replay call `logIn` while
    // `Purchases.configure` is still in flight — a fatal error on iOS.
    try {
      _onSnapshot(await _repository.start(userId, apiKey: key));
    } on Exception {
      _emitUnavailableIfFree();
      return;
    }

    _changesSub = _repository.changes.listen(_onSnapshot);
    _usersSub = userIds.listen(_onUserChanged);
  }

  /// Re-reads the SDK's view — after a store sheet returns, or when the app
  /// comes back to the foreground. Silent: never raises an OS prompt, which
  /// is what `restore()` is for.
  Future<void> refresh() async {
    if (!_isEnabled || apiKey == null) return;
    try {
      _onSnapshot(await _repository.current());
    } on Exception {
      // Keep whatever state we already had.
    }
  }

  /// The player dismissed the Home promo card for the next seven days.
  void dismissHomePromo() {
    _promos.dismissHomeCard();
    _emitFree(showHomePromo: false);
  }

  /// Opens the store's subscription-management page, where the player can
  /// cancel or change their plan. Cancellation only ever happens on the
  /// store's surface. Returns false when it could not be opened, so the
  /// screen can say so.
  Future<bool> openManagement() async {
    try {
      return await _repository.openManagement();
    } on ApiException {
      return false;
    }
  }

  void _onSnapshot(PurchasesSnapshot snapshot) {
    if (isClosed) return;
    if (snapshot.isPro) {
      emit(SubscriptionPro(membership: snapshot.membership));
    } else {
      _emitFree();
    }
  }

  void _onUserChanged(UserIdentity? identity) {
    if (identity == null || !_isEnabled || apiKey == null) return;
    // Carry the receipt only on a sign-in — Pro stays with the account on
    // sign-out (plan 023, "Identity").
    final carry = state.isPro && !identity.isAnonymous;
    unawaited(
      _repository
          .switchUser(identity.id, carryPurchases: carry)
          .then(_onSnapshot)
          .catchError((_) {}),
    );
  }

  void _emitFree({bool? showHomePromo}) {
    if (isClosed || state is SubscriptionFree) {
      if (state is SubscriptionFree && showHomePromo != null) {
        final current = state as SubscriptionFree;
        emit(
          SubscriptionFree(
            isAvailable: current.isAvailable,
            showHomePromo: showHomePromo,
          ),
        );
      }
      return;
    }
    emit(
      SubscriptionFree(
        isAvailable: _isEnabled && apiKey != null,
        showHomePromo: showHomePromo ?? _promos.shouldShowHomeCard,
      ),
    );
  }

  void _emitUnavailableIfFree() {
    if (state.isPro) return;
    _emitFree();
  }

  @override
  Future<void> close() {
    unawaited(_changesSub?.cancel());
    unawaited(_usersSub?.cancel());
    return super.close();
  }
}
