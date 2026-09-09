import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/share_sheet.dart';
import 'package:quizoo/features/achievements/data/achievements_api.dart';
import 'package:quizoo/features/achievements/data/achievements_repository.dart';
import 'package:quizoo/features/achievements/domain/badge_progress.dart';
import 'package:quizoo/features/achievements/presentation/bloc/badge_unlocked_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-23 — the badge-unlocked interstitial.
///
/// Full-screen, not a toast: reached by `context.push` from
/// `QuizResultCubit` when its mock data says a badge was newly earned this
/// run (plan 002, Phase E) — this plan is responsible only for the route and
/// screen existing; it does not know anything about `quiz_result`'s
/// internals.
class BadgeUnlockedScreen extends StatelessWidget {
  const BadgeUnlockedScreen({required this.badgeId, super.key});

  final String badgeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BadgeUnlockedCubit>(
      create: (_) =>
          BadgeUnlockedCubit(AchievementsRepository(AchievementsApi(supabase)))
            ..load(badgeId),
      child: const _BadgeUnlockedView(),
    );
  }
}

class _BadgeUnlockedView extends StatelessWidget {
  const _BadgeUnlockedView();

  void _dismiss(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.you);
    }
  }

  void _share(BuildContext context, BadgeProgress progress) {
    AppBottomSheet.show<void>(
      context,
      builder: (sheetContext) => ShareSheet(
        title: AppLocalizations.of(sheetContext).badgeUnlockedShareTitle,
        message: AppLocalizations.of(sheetContext).shareSpoilerFree,
        preview: _SharePreview(progress: progress),
        targets: [
          ShareTarget(
            emoji: '💬',
            label: 'WhatsApp',
            onTap: () => _confirmShared(sheetContext),
          ),
          ShareTarget(
            emoji: '✖️',
            label: 'X',
            onTap: () => _confirmShared(sheetContext),
          ),
          ShareTarget(
            emoji: '🔗',
            label: 'Copy',
            onTap: () => _confirmShared(sheetContext),
          ),
        ],
      ),
    );
  }

  void _confirmShared(BuildContext context) {
    Navigator.of(context).maybePop();
    AppSnackbar.show(
      context,
      title: AppLocalizations.of(context).commonSharedMock,
      intent: SnackbarIntent.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.linear(178, const [
              Color(0xFF7B4DFF),
              Color(0xFF4B22C4),
            ]),
          ),
          child: SafeArea(
            child: BlocBuilder<BadgeUnlockedCubit, BadgeUnlockedState>(
              builder: (context, state) => switch (state) {
                BadgeUnlockedLoading() => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                BadgeUnlockedError() => _BadgeUnlockedError(
                  onDismiss: () => _dismiss(context),
                ),
                BadgeUnlockedLoaded(:final progress) => _BadgeUnlockedContent(
                  progress: progress,
                  onShare: () => _share(context, progress),
                  onDismiss: () => _dismiss(context),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeUnlockedContent extends StatelessWidget {
  const _BadgeUnlockedContent({
    required this.progress,
    required this.onShare,
    required this.onDismiss,
  });

  final BadgeProgress progress;
  final VoidCallback onShare;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final badge = progress.badge;

    return Column(
      children: [
        const Spacer(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 34.w),
          child: Column(
            children: [
              Text(
                l10n.badgeUnlockedEyebrow,
                style: textTheme.labelSmall!.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                width: 140.w,
                height: 140.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.tileFromHex(
                    badge.gradientFrom,
                    badge.gradientTo,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.card.r + 26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80000000),
                      offset: Offset(0, 18),
                      blurRadius: 44,
                      spreadRadius: -12,
                    ),
                  ],
                ),
                child: Text(badge.emoji, style: AppTypography.glyph(70.sp)),
              ),
              SizedBox(height: 20.h),
              Text(
                badge.name,
                style: textTheme.displayMedium!.copyWith(
                  fontSize: 28.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                l10n.badgeUnlockedDescription(
                  badge.description,
                  badge.rarityPercent,
                ),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium!.copyWith(
                  fontSize: 13.5.sp,
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.5,
                ),
              ),
              if (progress.rewardCoins != null) ...[
                SizedBox(height: AppSpacing.md.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    l10n.badgeDetailReward(progress.rewardCoins!),
                    style: textTheme.labelSmall!.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenMargin.w,
            0,
            AppSpacing.screenMargin.w,
            AppSpacing.sm.h + 2.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChunkyButton.gold(
                label: l10n.badgeUnlockedShare,
                onPressed: onShare,
              ),
              SizedBox(height: 9.h),
              ChunkyButton.line(
                label: l10n.badgeUnlockedNice,
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgeUnlockedError extends StatelessWidget {
  const _BadgeUnlockedError({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.contentErrorTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge!.copyWith(color: Colors.white),
            ),
            SizedBox(height: AppSpacing.base.h),
            ChunkyButton.ghost(label: l10n.commonClose, onPressed: onDismiss),
          ],
        ),
      ),
    );
  }
}

class _SharePreview extends StatelessWidget {
  const _SharePreview({required this.progress});

  final BadgeProgress progress;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;
    final badge = progress.badge;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: quizoo.s2,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: quizoo.ln),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppGradients.tileFromHex(
                badge.gradientFrom,
                badge.gradientTo,
              ),
              borderRadius: BorderRadius.circular(AppRadius.emojiPlate.r),
            ),
            child: Text(badge.emoji, style: AppTypography.glyph(24.sp)),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Text(
              badge.name,
              style: textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
