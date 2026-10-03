import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/app/ads_cubit.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/subscription/paywall_source.dart';
import 'package:quizoo/core/subscription/pro_promo_store.dart';
import 'package:quizoo/core/widgets/pro_upsell_sheet.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The one interstitial break point (plan 023, Step 5.6).
///
/// Wraps [AdsCubit.showInterstitialIfDue] so the ad layer and the Pro upsell
/// stay in one place: every result screen calls this instead of the Cubit,
/// and the "one sheet after the third interstitial" offer lives here rather
/// than being re-implemented at each call site.
///
/// A member sees no interstitial at all (the Cubit returns false), so the
/// counter never moves and the offer can never appear to them. The sheet is
/// shown **once ever** per device, and only when Pro is actually available —
/// an unsupported platform or `pro_enabled = false` stays offer-free.
Future<void> runAdBreak(
  BuildContext context,
  AdPlacement placement, {
  bool isCelebration = false,
}) async {
  final ads = context.read<AdsCubit>();
  final shown = await ads.showInterstitialIfDue(
    placement,
    isCelebration: isCelebration,
  );
  if (!shown || !context.mounted) return;

  final promos = context.read<ProPromoStore>();
  promos.noteInterstitialSeen();
  if (promos.interstitialsSeen < 3 || promos.adFreeOfferShown) return;

  final subscription = context.read<SubscriptionCubit>();
  final state = subscription.state;
  // Only a free player who could actually buy is worth interrupting.
  if (state.isPro) return;
  final free = state;
  if (free is SubscriptionFree && !free.isAvailable) return;

  if (!context.mounted) return;
  promos.markAdFreeOfferShown();
  await ProUpsellSheet.show(
    context,
    emoji: '🚫',
    title: AppLocalizations.of(context).proUpsellAdFreeTitle,
    message: AppLocalizations.of(context).proUpsellAdFreeBody,
    source: PaywallSource.adBreak,
  );
}
