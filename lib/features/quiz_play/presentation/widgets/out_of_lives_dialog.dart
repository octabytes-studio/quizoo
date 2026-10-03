import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/app/ads_cubit.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/subscription/paywall_source.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_dialog.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/heart_ad_cubit.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/quiz_play_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// S-19 — out of lives.
///
/// **Never a hard wall.** The free option is listed first and is visually the
/// loudest; leaving is always available. Hearts simply reset to 3 the next
/// time this level is started — the copy makes no claim about a refill timer.
///
/// Plan 023 layers two things on top, both from the entitlement and both
/// rebuilt automatically when it changes — so a player who taps through to
/// the paywall and buys comes back to a dialog that now offers the revive:
///
/// * A member with the level's free revive still in hand gets it as the
///   first (gold) action, with the rewarded ad demoted to a secondary
///   button. The free revive is once per level; a second visit shows the
///   ad again.
/// * A free player on a device where Pro is purchasable gets one quiet
///   centred text link under the buttons. It is a link, never a button
///   (plan 023, Assumption 4 — this is not a loss screen, but it is close
///   enough to keep it quiet).
class OutOfLivesDialog extends StatelessWidget {
  const OutOfLivesDialog({
    required this.state,
    required this.onBackToMap,
    super.key,
  });

  final QuizPlayOutOfLives state;
  final VoidCallback onBackToMap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<HeartAdCubit, HeartAdState>(
      listener: (context, adState) {
        if (adState is HeartAdFailed) {
          AppSnackbar.show(
            context,
            title: l10n.outOfLivesAdFailedTitle,
            message: l10n.commonRetry,
            intent: SnackbarIntent.error,
          );
        }
        if (adState is HeartAdPlaying) {
          // A rewarded ad is a full-screen ad too: tell the pacer, so no
          // interstitial follows it moments later (plan 022).
          context.read<AdsCubit>().noteFullScreenAdShown();
        }
        if (adState is HeartAdSucceeded) {
          context.read<QuizPlayCubit>().grantHeartFromAd();
        }
      },
      builder: (context, adState) {
        final watch = context.read<HeartAdCubit>().watch;
        final (String label, VoidCallback? onPressed) = switch (adState) {
          HeartAdReady() => (l10n.outOfLivesWatchAd, watch),
          HeartAdLoading() => (l10n.outOfLivesAdLoading, null),
          HeartAdPlaying() => (l10n.outOfLivesAdPlaying, null),
          HeartAdSucceeded() => (l10n.outOfLivesAdPlaying, null),
          HeartAdFailed() => (l10n.outOfLivesWatchAd, watch),
        };

        // Read live, not captured: the dialog must offer the revive the
        // moment the player comes back from the paywall (plan 023).
        final subscription = context.watch<SubscriptionCubit>().state;
        final canRevive =
            subscription.isPro && !state.underlying.run.freeReviveUsed;
        final canOfferPro =
            subscription is SubscriptionFree && subscription.isAvailable;

        final actions = <Widget>[
          if (canRevive) ...[
            ChunkyButton.gold(
              label: l10n.proUseFreeRevive,
              onPressed: () =>
                  context.read<QuizPlayCubit>().useFreeRevive(isPro: true),
            ),
            SizedBox(height: 9.h),
            ChunkyButton.secondary(label: label, onPressed: onPressed),
          ] else
            ChunkyButton.gold(label: label, onPressed: onPressed),
          SizedBox(height: 9.h),
          ChunkyButton.line(
            label: l10n.outOfLivesBackToMap,
            onPressed: onBackToMap,
          ),
        ];

        return AppDialog(
          emoji: '💔',
          iconPlateColor: quizoo.badBg,
          title: l10n.outOfLivesTitle,
          message: l10n.outOfLivesBody,
          actions: [
            ...actions,
            if (canOfferPro) ...[
              SizedBox(height: 9.h),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  context.push(
                    AppRoutes.paywall,
                    extra: PaywallSource.outOfLives,
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  child: Text(
                    l10n.proOutOfLivesLink,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: context.quizoo.g,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
