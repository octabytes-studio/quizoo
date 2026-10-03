import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'pro_membership.dart';
import 'pro_offer.dart';
import 'pro_plan.dart';
import 'purchases_service.dart';
import 'revenuecat_config.dart';

/// The one `purchases_flutter` implementation of [PurchasesService].
///
/// Every SDK type in the app lives in this file (plan 023): the seam above
/// it is pure Dart, tests use hand-written fakes, and nothing else may
/// construct this class.
class RevenueCatPurchasesService implements PurchasesService {
  RevenueCatPurchasesService();

  final StreamController<PurchasesSnapshot> _changes =
      StreamController<PurchasesSnapshot>.broadcast();
  CustomerInfoUpdateListener? _listener;
  bool _configured = false;

  @override
  Future<void> configure({
    required String apiKey,
    required String userId,
  }) async {
    await Purchases.setLogLevel(LogLevel.warn);
    await Purchases.configure(
      PurchasesConfiguration(apiKey)..appUserID = userId,
    );
    _configured = true;
    _attachListener();
    _emit(await Purchases.getCustomerInfo());
  }

  @override
  Future<PurchasesSnapshot> logIn(
    String userId, {
    required bool carryPurchases,
  }) async {
    await Purchases.logIn(userId);
    // RevenueCat's default "transfer to new App User ID" behaviour moves the
    // entitlement when the store recognises the receipt; syncing asks it to
    // re-attach now rather than at the next purchase. Only on a sign-in —
    // on sign-out Pro stays with the account (plan 023, "Identity").
    if (carryPurchases) await Purchases.syncPurchases();
    final info = await Purchases.getCustomerInfo();
    _emit(info);
    return _toSnapshot(info);
  }

  @override
  Future<PurchasesSnapshot> current() async {
    if (!_configured) return PurchasesSnapshot.free;
    return _toSnapshot(await Purchases.getCustomerInfo());
  }

  @override
  Stream<PurchasesSnapshot> get changes => _changes.stream;

  @override
  Future<List<ProOffer>> offers() async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) return const [];

    return [
      if (current.annual != null) _toOffer(ProPlan.yearly, current.annual!),
      if (current.monthly != null) _toOffer(ProPlan.monthly, current.monthly!),
      if (current.lifetime != null)
        _toOffer(ProPlan.lifetime, current.lifetime!),
    ];
  }

  @override
  Future<PurchaseOutcome> purchase(ProOffer offer) async {
    final package = await _packageFor(offer.packageId);
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _emit(result.customerInfo);
      return const PurchasePurchased();
    } on PlatformException catch (error) {
      return switch (PurchasesErrorHelper.getErrorCode(error)) {
        PurchasesErrorCode.purchaseCancelledError => const PurchaseCancelled(),
        PurchasesErrorCode.paymentPendingError => const PurchasePending(),
        PurchasesErrorCode.purchaseNotAllowedError => const PurchaseFailed(
          'Purchases are not allowed on this account',
        ),
        _ => PurchaseFailed(error.message ?? 'Purchase failed'),
      };
    }
  }

  @override
  Future<PurchasesSnapshot> restore() async {
    final info = await Purchases.restorePurchases();
    _emit(info);
    return _toSnapshot(info);
  }

  @override
  Future<bool> openManagement() async {
    final info = await Purchases.getCustomerInfo();
    // The SDK's own URL is store- and platform-correct (App Store on iOS,
    // Play Store on Android); the fallback covers the Test Store, sandbox
    // and any case where RevenueCat reported none.
    final url =
        info.managementURL ?? _storeManagementUrl(defaultTargetPlatform);
    if (url == null) return false;
    // External, so the store app takes over rather than an in-app web view:
    // both stores' management pages only cancel when opened natively.
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// The store's account-level subscriptions page, used when RevenueCat has
  /// no `managementURL`. Apple's page is fixed; Google lists every
  /// subscription on the device account, which is where Play's own SDK
  /// points when the app cannot be targeted directly.
  static String? _storeManagementUrl(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.iOS ||
        TargetPlatform.macOS => 'https://apps.apple.com/account/subscriptions',
        TargetPlatform.android =>
          'https://play.google.com/store/account/subscriptions',
        _ => null,
      };

  @override
  Future<PurchasesSnapshot> syncPurchases() async {
    await Purchases.syncPurchases();
    final info = await Purchases.getCustomerInfo();
    _emit(info);
    return _toSnapshot(info);
  }

  void _attachListener() {
    if (_listener != null) return;
    _listener = _emit;
    Purchases.addCustomerInfoUpdateListener(_listener!);
  }

  void _emit(CustomerInfo info) {
    if (!_changes.isClosed) _changes.add(_toSnapshot(info));
  }

  Future<Package> _packageFor(String packageId) async {
    final current = (await Purchases.getOfferings()).current;
    if (current == null) {
      throw PlatformException(
        code: PurchasesErrorCode.configurationError.name,
        message: 'No current offering',
      );
    }
    for (final package in current.availablePackages) {
      if (package.identifier == packageId) return package;
    }
    throw PlatformException(
      code: PurchasesErrorCode.productNotAvailableForPurchaseError.name,
      message: 'Package $packageId is not in the current offering',
    );
  }

  /// Everything above this file sees is Quizoo's own model; this is the only
  /// place a RevenueCat [CustomerInfo] becomes a [PurchasesSnapshot].
  static PurchasesSnapshot _toSnapshot(CustomerInfo info) {
    final entitlement = info.entitlements.all[RevenueCatConfig.entitlementId];
    if (entitlement == null || !entitlement.isActive) {
      return PurchasesSnapshot.free;
    }

    return PurchasesSnapshot(
      isPro: true,
      membership: ProMembership(
        plan: planFromProductId(entitlement.productIdentifier),
        expiresAt: DateTime.tryParse(entitlement.expirationDate ?? ''),
        willRenew: entitlement.willRenew,
        isTrial: entitlement.periodType == PeriodType.trial,
        hasBillingIssue: entitlement.billingIssueDetectedAt != null,
        managementUrl: info.managementURL,
      ),
    );
  }

  static ProOffer _toOffer(ProPlan plan, Package package) {
    final product = package.storeProduct;
    return ProOffer(
      plan: plan,
      packageId: package.identifier,
      priceLabel: product.priceString,
      price: product.price,
      currencyCode: product.currencyCode,
      trialDays: _trialDaysOf(product.introductoryPrice),
      // The SDK's own monthly-equivalent string; null on lifetime and when
      // the store cannot compute one.
      perMonthLabel: plan == ProPlan.yearly
          ? product.pricePerMonthString
          : null,
    );
  }

  /// Only a *free* introductory price counts as a trial. A paid intro price
  /// is a discount, not a trial, and the paywall must not say "free".
  static int? _trialDaysOf(IntroductoryPrice? intro) {
    if (intro == null || intro.price > 0) return null;
    return switch (intro.periodUnit) {
      PeriodUnit.day => intro.periodNumberOfUnits,
      PeriodUnit.week => intro.periodNumberOfUnits * 7,
      PeriodUnit.month => intro.periodNumberOfUnits * 30,
      PeriodUnit.year => intro.periodNumberOfUnits * 365,
      PeriodUnit.unknown => null,
    };
  }
}
