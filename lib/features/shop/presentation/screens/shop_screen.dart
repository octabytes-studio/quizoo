import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/models/power_up.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/currency_pill.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/core/widgets/list_row_tile.dart';
import 'package:quizoo/core/widgets/section_header.dart';
import 'package:quizoo/core/widgets/simple_top_bar.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/shop/data/shop_api.dart';
import 'package:quizoo/features/shop/data/shop_repository.dart';
import 'package:quizoo/features/shop/domain/shop_content.dart';
import 'package:quizoo/features/shop/presentation/bloc/shop_cubit.dart';
import 'package:quizoo/features/shop/presentation/widgets/coin_pack_tile.dart';
import 'package:quizoo/features/shop/presentation/widgets/rewarded_ad_dialog.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-36 — the shop, and (via [showRewardedAdOnOpen]) S-37's own reserved path,
/// which opens the shop with the rewarded-ad dialog already presented —
/// exactly like S-09's level-brief sheet opens the level map beneath it.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.showRewardedAdOnOpen = false});

  final bool showRewardedAdOnOpen;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _hasShownRewardedAd = false;

  void _maybeShowRewardedAd(BuildContext context, ShopState state) {
    if (!widget.showRewardedAdOnOpen ||
        _hasShownRewardedAd ||
        state is! ShopLoaded) {
      return;
    }
    _hasShownRewardedAd = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openRewardedAd(context, state.content);
    });
  }

  void _openRewardedAd(BuildContext context, ShopContent content) {
    final cubit = context.read<ShopCubit>();
    final l10n = AppLocalizations.of(context);
    RewardedAdDialog.show(
      context,
      content: content,
      onWatched: (coins) {
        cubit.creditRewardedAd(coins);
        AppSnackbar.show(
          context,
          title: l10n.rewardedAdSuccessTitle(coins),
          intent: SnackbarIntent.success,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShopCubit>(
      create: (_) => ShopCubit(ShopRepository(ShopApi()))..load(),
      child: Builder(
        builder: (context) {
          final quizoo = context.quizoo;
          final l10n = AppLocalizations.of(context);

          return Scaffold(
            backgroundColor: quizoo.s0,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BlocConsumer<ShopCubit, ShopState>(
                    listener: _maybeShowRewardedAd,
                    builder: (context, state) => SimpleTopBar(
                      title: l10n.shopTitle,
                      trailing: state is ShopLoaded
                          ? _WalletPills(content: state.content)
                          : null,
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<ShopCubit, ShopState>(
                      builder: (context, state) => switch (state) {
                        ShopInitial() || ShopLoading() => const _ShopSkeleton(),
                        ShopError(:final error) => _ShopError(
                          error: error.code,
                        ),
                        ShopLoaded() => _ShopLoadedView(
                          state: state,
                          onWatchAd: () =>
                              _openRewardedAd(context, state.content),
                        ),
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WalletPills extends StatelessWidget {
  const _WalletPills({required this.content});

  final ShopContent content;

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CurrencyPill(
          kind: CurrencyKind.coin,
          value: AppFormat.number(content.coins, localeName),
        ),
        SizedBox(width: 7.w),
        CurrencyPill(
          kind: CurrencyKind.gem,
          value: AppFormat.plain(content.gems, localeName),
        ),
      ],
    );
  }
}

class _ShopLoadedView extends StatelessWidget {
  const _ShopLoadedView({required this.state, required this.onWatchAd});

  final ShopLoaded state;
  final VoidCallback onWatchAd;

  void _buyPowerUp(BuildContext context, PowerUp powerUp) {
    final l10n = AppLocalizations.of(context);
    final bought = context.read<ShopCubit>().buyPowerUp(powerUp);
    AppSnackbar.show(
      context,
      title: bought
          ? l10n.shopPurchaseSuccess(_powerUpName(l10n, powerUp))
          : (powerUp.costGems != null
                ? l10n.shopInsufficientGems
                : l10n.shopInsufficientCoins),
      intent: bought ? SnackbarIntent.success : SnackbarIntent.warning,
    );
  }

  void _mockPurchase(BuildContext context) {
    AppSnackbar.show(
      context,
      title: AppLocalizations.of(context).shopMockPayment,
      intent: SnackbarIntent.info,
    );
  }

  static String _powerUpName(AppLocalizations l10n, PowerUp powerUp) =>
      switch (powerUp) {
        PowerUp.fiftyFifty => l10n.quizPowerUpFiftyFifty,
        PowerUp.addTime => l10n.quizPowerUpAddTime,
        PowerUp.skip => l10n.quizPowerUpSkip,
        PowerUp.freeze => l10n.shopPowerUpFreeze,
      };

  static String _powerUpDescription(AppLocalizations l10n, PowerUp powerUp) =>
      switch (powerUp) {
        PowerUp.fiftyFifty => l10n.shopPowerUpFiftyFiftyBody,
        PowerUp.addTime => l10n.shopPowerUpAddTimeBody,
        PowerUp.skip => l10n.shopPowerUpSkipBody,
        PowerUp.freeze => l10n.shopPowerUpFreezeBody,
      };

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final content = state.content;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin.w,
        vertical: AppSpacing.base.h,
      ),
      children: [
        _FreeCoinsCard(content: content, onTap: onWatchAd),
        SizedBox(height: AppSpacing.xl.h),
        SectionHeader(title: l10n.shopPowerUpsHeading),
        SizedBox(height: AppSpacing.md.h),
        for (final powerUp in PowerUp.values)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
            child: ListRowTile(
              title: _powerUpName(l10n, powerUp),
              subtitle: _powerUpDescription(l10n, powerUp),
              leadingEmoji: powerUp.emoji,
              trailingValue: powerUp.costCoins != null
                  ? '🪙 ${powerUp.costCoins}'
                  : '💎 ${powerUp.costGems}',
              trailingLabel: l10n.shopOwned(content.inventory.countOf(powerUp)),
              onTap: () => _buyPowerUp(context, powerUp),
            ),
          ),
        SizedBox(height: AppSpacing.lg.h),
        SectionHeader(title: l10n.shopCoinPacksHeading),
        SizedBox(height: AppSpacing.md.h),
        Row(
          children: [
            for (final pack in content.coinPacks) ...[
              if (pack != content.coinPacks.first)
                SizedBox(width: AppSpacing.sm.w),
              Expanded(
                child: CoinPackTile(
                  pack: pack,
                  onTap: () => _mockPurchase(context),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: AppSpacing.lg.h),
        ListRowTile(
          title: l10n.shopRemoveAdsTitle,
          subtitle: l10n.shopRemoveAdsBody,
          leadingEmoji: '🚫',
          trailing: Text(
            l10n.shopRemoveAdsPrice,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.w800,
              color: quizoo.tx,
            ),
          ),
          onTap: () => _mockPurchase(context),
        ),
        SizedBox(height: AppSpacing.xl.h),
      ],
    );
  }
}

/// A gold/mango gradient card — the bible's "free coins sit above paid coins,
/// deliberately".
class _FreeCoinsCard extends StatelessWidget {
  const _FreeCoinsCard({required this.content, required this.onTap});

  final ShopContent content;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final canWatch = content.hasFreeAdsRemaining;

    return Opacity(
      opacity: canWatch ? 1 : 0.55,
      child: Semantics(
        button: true,
        enabled: canWatch,
        label: l10n.shopFreeCoinsTitle,
        child: GestureDetector(
          onTap: canWatch ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.all(AppSpacing.base.w),
            decoration: BoxDecoration(
              gradient: AppGradients.tile(
                const Color(0xFFFFC61A),
                const Color(0xFFFF8A24),
              ),
              borderRadius: AppRadius.cardAll,
            ),
            child: Row(
              children: [
                Text('📺', style: AppTypography.glyph(34.sp)),
                SizedBox(width: AppSpacing.md.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.shopFreeCoinsTitle,
                        style: textTheme.bodyLarge!.copyWith(
                          fontSize: 15.sp,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        canWatch
                            ? l10n.shopFreeCoinsMeta(
                                content.freeAdsRemainingToday,
                              )
                            : l10n.shopFreeCoinsNoneLeft,
                        style: textTheme.bodyMedium!.copyWith(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    '+${content.freeCoinsReward} 🪙',
                    style: textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopSkeleton extends StatelessWidget {
  const _ShopSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin.w),
      child: Column(
        children: [
          SizedBox(height: AppSpacing.base.h),
          SkeletonBox(height: 96.h),
          SizedBox(height: AppSpacing.xl.h),
          SkeletonBox(height: 64.h),
          SizedBox(height: AppSpacing.sm.h),
          SkeletonBox(height: 64.h),
          SizedBox(height: AppSpacing.sm.h),
          SkeletonBox(height: 64.h),
        ],
      ),
    );
  }
}

class _ShopError extends StatelessWidget {
  const _ShopError({required this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: ErrorStateView(
        title: l10n.contentErrorTitle,
        emoji: '🛰️',
        message: l10n.contentErrorBody,
        errorCode: error,
        action: ChunkyButton(
          label: l10n.commonRetry,
          onPressed: () => context.read<ShopCubit>().load(),
        ),
      ),
    );
  }
}
