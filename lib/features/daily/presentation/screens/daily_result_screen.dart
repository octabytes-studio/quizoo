import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/ads/ad_placement.dart';
import 'package:quizoo/core/widgets/ad_break.dart';
import 'package:quizoo/core/navigation/badge_celebration.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/distribution_chart.dart';
import 'package:quizoo/core/widgets/native_ad_card.dart';
import 'package:quizoo/core/widgets/result_wash.dart';
import 'package:quizoo/core/widgets/share_sheet.dart';
import 'package:quizoo/features/daily/domain/daily_result.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-28 — the daily challenge's result.
///
/// [result] is real, server-scored data by the time this screen is reached:
/// `DailyPlayScreen` fetches today's real questions, collects the player's
/// actual answers, and submits that genuine pattern before pushing here with
/// the outcome — this screen is now pure display except for the post-frame
/// badge-celebration chain (plan 014), which mirrors `LevelCompleteScreen`'s.
class DailyResultScreen extends StatefulWidget {
  const DailyResultScreen({required this.result, super.key});

  final DailyResult result;

  @override
  State<DailyResultScreen> createState() => _DailyResultScreenState();
}

class _DailyResultScreenState extends State<DailyResultScreen> {
  /// True while the exit is in flight (an interstitial may be up) — a second
  /// tap is ignored. Ephemeral UI state, never rendered.
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runChain());
  }

  Future<void> _runChain() async {
    await celebrateBadges(context, widget.result.newlyEarnedBadgeIds);
  }

  /// The day's run is over, so leaving is a natural break for an
  /// interstitial (plan 022, I3) — never on a day that just earned a badge.
  Future<void> _leave() async {
    if (_isLeaving) return;
    _isLeaving = true;
    await runAdBreak(
      context,
      AdPlacement.dailyResultBreak,
      isCelebration: widget.result.newlyEarnedBadgeIds.isNotEmpty,
    );
    if (!mounted) return;
    _isLeaving = false;
    context.pop();
  }

  @override
  Widget build(BuildContext context) =>
      _DailyResultLoadedView(result: widget.result, onLeave: _leave);
}

class _DailyResultLoadedView extends StatelessWidget {
  const _DailyResultLoadedView({required this.result, required this.onLeave});

  final DailyResult result;

  /// ✕ and "Back to daily".
  final VoidCallback onLeave;

  void _share(BuildContext context) {
    AppBottomSheet.show<void>(
      context,
      builder: (sheetContext) => ShareSheet(
        title: AppLocalizations.of(sheetContext).dailyResultShareTitle,
        message: AppLocalizations.of(sheetContext).shareSpoilerFree,
        preview: _SharePreview(result: result),
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
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return ResultWash(
      accent: quizoo.g,
      onClose: onLeave,
      onShare: () => _share(context),
      actions: [
        ChunkyButton.secondary(
          label: l10n.dailyResultShare,
          onPressed: () => _share(context),
        ),
        SizedBox(height: 9.h),
        ChunkyButton.line(
          label: l10n.dailyResultBackToDaily,
          onPressed: onLeave,
        ),
      ],
      child: Column(
        children: [
          Text('🎯', style: AppTypography.glyph(48.sp)),
          Text(
            l10n.dailyResultScoreLine(result.correctCount, result.totalCount),
            textAlign: TextAlign.center,
            style: textTheme.displayMedium!.copyWith(
              fontSize: 25.sp,
              color: Colors.white,
            ),
          ),
          Text(
            l10n.dailyResultBetterThan(result.betterThanPercent),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium!.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: AppSpacing.base.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.base.w),
            decoration: BoxDecoration(
              color: quizoo.s1,
              borderRadius: BorderRadius.circular(AppRadius.card.r),
              boxShadow: quizoo.shadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.dailyResultDistribution, style: textTheme.labelSmall),
                SizedBox(height: AppSpacing.sm.h),
                DistributionChart(
                  barPercents: result.distributionPercents,
                  labels: const ['0-2', '3-4', '5-6', '7-8', '9-10'],
                  highlightedIndex: result.highlightedBucketIndex,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
                  child: Divider(height: 1, color: quizoo.ln),
                ),
                Row(
                  children: [
                    _ResultStat(
                      value: '🪙 ${result.coinsEarned}',
                      label: l10n.dailyResultEarned,
                      color: quizoo.gold,
                    ),
                    _ResultStat(
                      value: '🔥 ${result.streakNow}',
                      label: l10n.dailyResultStreakNow,
                      color: quizoo.p,
                    ),
                  ],
                ),
              ],
            ),
          ),
          NativeAdCard(
            placement: AdPlacement.dailyResultNative,
            padding: EdgeInsets.only(top: AppSpacing.base.h),
          ),
          SizedBox(height: AppSpacing.xl.h),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.displayMedium!.copyWith(
              fontSize: 19.sp,
              color: color,
            ),
          ),
          Text(label, style: textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// The card shared to the OS's share sheet — the spoiler-free emoji grid.
class _SharePreview extends StatelessWidget {
  const _SharePreview({required this.result});

  final DailyResult result;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: quizoo.s2,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(color: quizoo.ln),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dailyResultScoreLine(result.correctCount, result.totalCount),
            style: textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            result.shareGrid,
            style: AppTypography.glyph(18.sp, height: 1.4),
          ),
        ],
      ),
    );
  }
}
