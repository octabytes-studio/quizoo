import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/subscription/pro_offer.dart';
import 'package:quizoo/core/subscription/pro_plan.dart';
import 'package:quizoo/core/subscription/purchases_service.dart';
import 'package:quizoo/core/subscription/subscription_repository.dart';

part 'paywall_state.dart';

/// The paywall's decisions (CLAUDE.md §1: business logic lives in the Cubit).
///
/// All of it is here rather than in the screen: which plan is preselected,
/// the yearly savings arithmetic, and which one-shot notice a purchase
/// outcome deserves. A cancelled purchase is deliberately **not** a notice —
/// the player backed out, the paywall simply returns to rest.
///
/// Scoped to the screen it serves (not app-root): the paywall, the Pro
/// Welcome return path and the membership screen's "Restore purchases" each
/// build their own.
class PaywallCubit extends Cubit<PaywallState> {
  PaywallCubit(this._repository) : super(const PaywallLoading());

  final SubscriptionRepository _repository;

  /// Loads the store's offers. Preselects yearly when it exists, otherwise
  /// the first offer — the plan's own ordering is the paywall's ordering.
  Future<void> load() async {
    emit(const PaywallLoading());
    try {
      final offers = await _repository.offers();
      if (isClosed) return;
      if (offers.isEmpty) {
        emit(PaywallUnavailable(const ApiException('No offers available')));
        return;
      }
      emit(
        PaywallReady(
          offers: offers,
          selected: offers.any((offer) => offer.plan == ProPlan.yearly)
              ? ProPlan.yearly
              : offers.first.plan,
        ),
      );
    } on ApiException catch (error) {
      if (!isClosed) emit(PaywallUnavailable(error));
    }
  }

  void select(ProPlan plan) {
    final current = state;
    if (current is! PaywallReady || current.isBusy) return;
    emit(PaywallReady(offers: current.offers, selected: plan));
  }

  /// Runs the store sheet for the selected plan.
  Future<void> purchase() async {
    final current = state;
    if (current is! PaywallReady || current.isBusy) return;
    final offer = current.selectedOffer;
    if (offer == null) return;

    emit(
      PaywallReady(
        offers: current.offers,
        selected: current.selected,
        isBusy: true,
      ),
    );
    final PurchaseOutcome outcome;
    try {
      outcome = await _repository.purchase(offer);
    } on ApiException {
      // The exception is only for logs; the notice is the player-facing
      // message (CLAUDE.md §1: screens show their own copy).
      if (!isClosed) {
        emit(
          PaywallReady(
            offers: current.offers,
            selected: current.selected,
            notice: PaywallNotice.failed,
          ),
        );
      }
      return;
    }

    if (isClosed) return;
    switch (outcome) {
      case PurchasePurchased():
        emit(const PaywallPurchased(wasRestore: false));
      case PurchaseCancelled():
        // Backing out is not a failure: rest, silently.
        emit(PaywallReady(offers: current.offers, selected: current.selected));
      case PurchasePending():
        emit(
          PaywallReady(
            offers: current.offers,
            selected: current.selected,
            notice: PaywallNotice.pending,
          ),
        );
      case PurchaseFailed():
        emit(
          PaywallReady(
            offers: current.offers,
            selected: current.selected,
            notice: PaywallNotice.failed,
          ),
        );
    }
  }

  /// "Restore purchases". A restore that finds nothing is a notice, not an
  /// error state — the plans are still on screen.
  Future<void> restore() async {
    final current = state;
    if (current is PaywallReady && current.isBusy) return;

    final offers = current is PaywallReady
        ? current.offers
        : const <ProOffer>[];
    final selected = current is PaywallReady
        ? current.selected
        : ProPlan.yearly;
    emit(PaywallReady(offers: offers, selected: selected, isBusy: true));

    try {
      final snapshot = await _repository.restore();
      if (isClosed) return;
      if (snapshot.isPro) {
        emit(const PaywallPurchased(wasRestore: true));
      } else {
        emit(
          PaywallReady(
            offers: offers,
            selected: selected,
            notice: PaywallNotice.nothingToRestore,
          ),
        );
      }
    } on ApiException {
      if (!isClosed) {
        emit(PaywallReady(offers: offers, selected: selected));
      }
    }
  }

  /// The screen has shown the notice; drop it so it is not repeated on the
  /// next rebuild.
  void clearNotice() {
    final current = state;
    if (current is! PaywallReady || current.notice == null) return;
    emit(PaywallReady(offers: current.offers, selected: current.selected));
  }
}
