import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/ladder/ladder_config_repository.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_gradients.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/share_sheet.dart';
import 'package:quizoo/features/topic_mastery/data/topic_mastery_api.dart';
import 'package:quizoo/features/topic_mastery/data/topic_mastery_repository.dart';
import 'package:quizoo/features/topic_mastery/domain/topic_mastery.dart';
import 'package:quizoo/features/topic_mastery/presentation/bloc/topic_mastery_cubit.dart';
import 'package:quizoo/features/topic_mastery/presentation/widgets/mastery_confetti.dart';
import 'package:quizoo/features/topic_mastery/presentation/widgets/mastery_medallion.dart';
import 'package:quizoo/features/topic_mastery/presentation/widgets/mastery_stats_card.dart';
import 'package:quizoo/features/topic_mastery/presentation/widgets/tier_journey_strip.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// The congratulations screen after a topic's final level (plan 020) —
/// reached automatically the first time level 30 is cleared, and again any
/// time from the level map's "🏆 Mastered" pill.
class TopicMasteredScreen extends StatelessWidget {
  const TopicMasteredScreen({
    required this.categoryId,
    required this.subcategoryId,
    super.key,
  });

  final String categoryId;
  final String subcategoryId;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return BlocProvider<TopicMasteryCubit>(
      create: (context) =>
          TopicMasteryCubit(
            TopicMasteryRepository(
              TopicMasteryApi(supabase, context.read<LadderConfigRepository>()),
            ),
          )..load(
            categoryId: categoryId,
            subcategoryId: subcategoryId,
            locale: locale,
          ),
      child: const _TopicMasteredView(),
    );
  }
}

class _TopicMasteredView extends StatelessWidget {
  const _TopicMasteredView();

  void _continue(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _share(BuildContext context, TopicMastery mastery) {
    AppBottomSheet.show<void>(
      context,
      builder: (sheetContext) => ShareSheet(
        title: AppLocalizations.of(sheetContext).masteryShareTitle,
        message: AppLocalizations.of(sheetContext).shareSpoilerFree,
        preview: _SharePreview(mastery: mastery),
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
            gradient: AppGradients.linear(AppGradients.washAngle, const [
              AppColors.masteryWashTop,
              AppColors.masteryWashBottom,
            ]),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                const Positioned.fill(child: MasteryConfetti()),
                BlocBuilder<TopicMasteryCubit, TopicMasteryState>(
                  builder: (context, state) => switch (state) {
                    TopicMasteryLoading() => _TopicMasteryLoading(
                      onClose: () => _continue(context),
                    ),
                    TopicMasteryError() => _TopicMasteryErrorView(
                      onClose: () => _continue(context),
                    ),
                    TopicMasteryLoaded(:final mastery) => _TopicMasteryContent(
                      mastery: mastery,
                      onClose: () => _continue(context),
                      onContinue: () => _continue(context),
                      onShare: () => _share(context, mastery),
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicMasteryLoading extends StatelessWidget {
  const _TopicMasteryLoading({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(AppSpacing.screenMargin.w),
          child: Row(
            children: [_GlyphButton(glyph: '✕', onTap: onClose)],
          ),
        ),
        const Expanded(
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      ],
    );
  }
}

class _TopicMasteryErrorView extends StatelessWidget {
  const _TopicMasteryErrorView({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(AppSpacing.screenMargin.w),
          child: Row(
            children: [_GlyphButton(glyph: '✕', onTap: onClose)],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.contentErrorTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge!.copyWith(color: Colors.white),
                  ),
                  SizedBox(height: AppSpacing.base.h),
                  ChunkyButton.ghost(
                    label: l10n.commonClose,
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopicMasteryContent extends StatelessWidget {
  const _TopicMasteryContent({
    required this.mastery,
    required this.onClose,
    required this.onContinue,
    required this.onShare,
  });

  final TopicMastery mastery;
  final VoidCallback onClose;
  final VoidCallback onContinue;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final quizoo = context.quizoo;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenMargin.w,
            AppSpacing.xs.h,
            AppSpacing.screenMargin.w,
            AppSpacing.md.h,
          ),
          child: Row(
            children: [
              _GlyphButton(glyph: '✕', onTap: onClose),
              const Spacer(),
              _GlyphButton(glyph: '↗', onTap: onShare),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
            child: Column(
              children: [
                Text(
                  l10n.masteryEyebrow,
                  style: textTheme.labelSmall!.copyWith(
                    color: quizoo.gold,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: AppSpacing.lg.h),
                MasteryMedallion(
                  emoji: mastery.emoji,
                  plateColor: mastery.plateColor,
                  levelsCleared: mastery.levelsCleared,
                  levelCount: mastery.levelCount,
                  topicName: mastery.topicName,
                ),
                SizedBox(height: AppSpacing.lg.h),
                Text(
                  l10n.masteryTitle(mastery.topicName),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.displayMedium!.copyWith(
                    fontSize: 28.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  l10n.masterySubtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium!.copyWith(
                    fontSize: 13.5.sp,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: AppSpacing.xl.h),
                TierJourneyStrip(tiers: mastery.tiers),
                SizedBox(height: AppSpacing.xl.h),
                MasteryStatsCard(mastery: mastery),
                SizedBox(height: AppSpacing.base.h),
                Text(
                  mastery.isFlawless
                      ? l10n.masteryFlawless
                      : l10n.masteryMissingStars(mastery.missingStars),
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall!.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                SizedBox(height: AppSpacing.xl.h),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenMargin.w,
            AppSpacing.md.h,
            AppSpacing.screenMargin.w,
            AppSpacing.sm.h + 2.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChunkyButton.gold(
                label: l10n.masteryContinue,
                onPressed: onContinue,
              ),
              SizedBox(height: 9.h),
              ChunkyButton.line(label: l10n.masteryShare, onPressed: onShare),
            ],
          ),
        ),
      ],
    );
  }
}

/// Copied from `core/widgets/result_wash.dart`'s private `_WashGlyphButton`
/// rather than promoted, per plan 020's Phase 3b note — the same 38.w
/// glyph-button look used by S-23 and S-21/S-22's wash.
class _GlyphButton extends StatelessWidget {
  const _GlyphButton({required this.glyph, required this.onTap});

  final String glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        child: SizedBox(
          width: 38.w,
          height: 38.w,
          child: Center(
            child: Text(
              glyph,
              style: AppTypography.glyph(20.sp, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _SharePreview extends StatelessWidget {
  const _SharePreview({required this.mastery});

  final TopicMastery mastery;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

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
                mastery.plateColor,
                mastery.plateColor,
              ),
              borderRadius: BorderRadius.circular(AppRadius.emojiPlate.r),
            ),
            child: Text(mastery.emoji, style: AppTypography.glyph(24.sp)),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Text(
              '${mastery.topicName} Mastered · '
              '⭐ ${mastery.starsEarned}/${mastery.starsAvailable}',
              style: textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
