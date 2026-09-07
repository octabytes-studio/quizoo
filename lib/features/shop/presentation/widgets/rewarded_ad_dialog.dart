import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_dialog.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/shop/domain/shop_content.dart';
import 'package:quizoo/features/shop/presentation/bloc/rewarded_ad_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-37 — the rewarded-ad prompt.
///
/// A failed "ad load" shows a toast and drops straight back to a tappable
/// "Watch now" — the bible's own rule that this button must never go dead
/// (plan 004, Edge cases) — rather than leaving the dialog stuck.
class RewardedAdDialog extends StatelessWidget {
  const RewardedAdDialog({required this.onWatched, super.key});

  /// Fired once the mocked ad succeeds, with the coins to credit. The caller
  /// owns the wallet ([ShopCubit]) and the success snackbar.
  final ValueChanged<int> onWatched;

  /// Presents the dialog over [content]'s numbers.
  static Future<void> show(
    BuildContext context, {
    required ShopContent content,
    required ValueChanged<int> onWatched,
  }) {
    return AppDialog.show<void>(
      context,
      builder: (_) => BlocProvider<RewardedAdCubit>(
        create: (_) => RewardedAdCubit(
          coinsBefore: content.coins,
          rewardCoins: content.freeCoinsReward,
          freeAdsLeft: content.freeAdsRemainingToday,
          freeAdsPerDay: content.freeAdsPerDay,
        ),
        child: RewardedAdDialog(onWatched: onWatched),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<RewardedAdCubit, RewardedAdState>(
      listener: (context, state) {
        switch (state) {
          case RewardedAdFailed():
            AppSnackbar.show(
              context,
              title: l10n.rewardedAdFailedTitle,
              message: l10n.rewardedAdFailedBody,
              intent: SnackbarIntent.error,
            );
            context.read<RewardedAdCubit>().retry();
          case RewardedAdSucceeded(:final rewardCoins):
            onWatched(rewardCoins);
            Navigator.of(context).pop();
          case RewardedAdReady() || RewardedAdPlaying():
            break;
        }
      },
      builder: (context, state) {
        final isReady = state is RewardedAdReady;
        return AppDialog(
          emoji: '📺',
          iconPlateColor: context.quizoo.gold.withValues(alpha: 0.2),
          title: l10n.rewardedAdTitle,
          message: l10n.rewardedAdBody(
            state.rewardCoins,
            state.freeAdsLeft,
            state.freeAdsPerDay,
          ),
          content: _BalanceRow(
            before: state.coinsBefore,
            after: state.coinsAfter,
          ),
          actions: [
            ChunkyButton.gold(
              label: state is RewardedAdPlaying
                  ? l10n.rewardedAdWatching
                  : l10n.rewardedAdWatch,
              onPressed: isReady
                  ? () => context.read<RewardedAdCubit>().watch()
                  : null,
            ),
            ChunkyButton.line(
              label: l10n.rewardedAdNoThanks,
              onPressed: isReady ? () => Navigator.of(context).pop() : null,
            ),
          ],
        );
      },
    );
  }
}

/// The before→after coin chip pair, connected by an arrow — the projected
/// balance outlined in mint.
class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.before, required this.after});

  final int before;
  final int after;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CoinChip(value: before),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
          child: Text(
            '→',
            style: AppTypography.glyph(16.sp, color: quizoo.tx3),
          ),
        ),
        _CoinChip(value: after, isProjected: true),
      ],
    );
  }
}

class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.value, this.isProjected = false});

  final int value;
  final bool isProjected;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: quizoo.s3,
        borderRadius: AppRadius.pillAll,
        border: isProjected ? Border.all(color: quizoo.ok, width: 2) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🪙', style: AppTypography.glyph(13.sp)),
          SizedBox(width: 5.w),
          Text(
            '$value',
            style: textTheme.bodyLarge!.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: isProjected ? quizoo.ok : quizoo.tx,
            ),
          ),
        ],
      ),
    );
  }
}
