import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/theme/app_colors.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/quiz_play/domain/scoring.dart';
import 'package:quizoo/features/quiz_result/domain/level_result.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-21's score card: the total counting up, the breakdown staggering in
/// beneath it, then the coin/XP pair and the XP bar.
///
/// The total is the **sum of the rows**, taken from the same [Scoring.breakdown]
/// call that renders them — which is what makes "the breakdown sums to the
/// total shown" true by construction rather than by two pieces of code
/// happening to agree.
class ScoreBreakdownCard extends StatelessWidget {
  const ScoreBreakdownCard({required this.result, super.key});

  final LevelResult result;

  /// The bible's own stagger between breakdown rows.
  static const Duration rowStagger = Duration(milliseconds: 60);

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    final lines = Scoring.breakdown(result.run);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: quizoo.s1,
        border: Border.all(color: quizoo.ln),
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        boxShadow: quizoo.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.resultFinalScore, style: textTheme.labelSmall),
          // The score rolls up over 900 ms — `count` in the motion tokens.
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: result.finalScore),
            duration: AppMotion.durationOf(context, AppMotion.count),
            curve: AppMotion.countCurve,
            builder: (context, value, _) => Text(
              AppFormat.number(value, localeName),
              style: textTheme.displayLarge!.copyWith(color: quizoo.tx),
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.snackbar.r),
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: quizoo.ln)),
              child: Column(
                children: [
                  for (var index = 0; index < lines.length; index++)
                    _BreakdownRow(
                      label: _labelFor(
                        l10n,
                        lines[index],
                        result.run.questionCount,
                      ),
                      value: AppFormat.number(lines[index].value, localeName),
                      index: index,
                    ),
                  _BreakdownRow(
                    label: l10n.resultBreakdownTotal,
                    value: AppFormat.number(result.finalScore, localeName),
                    index: lines.length,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _PayoutStat(
                value: l10n.resultCoinsValue(
                  AppFormat.number(result.coinsEarned, localeName),
                ),
                label: l10n.resultCoins,
                color: quizoo.gold,
              ),
              SizedBox(width: 9.w),
              _PayoutStat(
                value: l10n.resultXpValue(
                  AppFormat.number(result.xpEarned, localeName),
                ),
                label: l10n.resultExperience,
                color: quizoo.g,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md.h),
          _XpBar(result: result),
        ],
      ),
    );
  }

  static String _labelFor(
    AppLocalizations l10n,
    ScoreLine line,
    int questionCount,
  ) => switch (line.kind) {
    ScoreLineKind.correct => l10n.resultBreakdownCorrect(line.value ~/ 100),
    ScoreLineKind.speed => l10n.resultBreakdownSpeed,
    ScoreLineKind.streak => l10n.resultBreakdownStreak(
      line.value ~/ Scoring.streakBonusPerStep,
    ),
    ScoreLineKind.cleanRun => l10n.resultBreakdownCleanRun,
    ScoreLineKind.flawless => l10n.resultBreakdownFlawless(questionCount),
    ScoreLineKind.hearts => l10n.resultBreakdownHearts(
      line.value ~/ Scoring.heartBonus,
    ),
    ScoreLineKind.boss => l10n.resultBreakdownBoss,
  };
}

/// `.brk div` — one row, staggering in 60 ms after the one above it.
class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.index,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final int index;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isTotal ? quizoo.s2 : quizoo.s1,
            border: Border(
              top: BorderSide(color: quizoo.ln, width: index == 0 ? 0 : 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium!.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: quizoo.tx2,
                  ),
                ),
              ),
              Text(
                value,
                style: textTheme.bodyMedium!.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  fontFeatures: AppTypography.tabular,
                  color: quizoo.tx,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          delay: ScoreBreakdownCard.rowStagger * index,
          duration: AppMotion.durationOf(context, AppMotion.slide),
        )
        .slideY(begin: 0.3, end: 0, curve: AppMotion.slideCurve);
  }
}

/// The coin and XP pair.
class _PayoutStat extends StatelessWidget {
  const _PayoutStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 9.h),
        decoration: BoxDecoration(
          color: quizoo.s2,
          border: Border.all(color: quizoo.ln),
          borderRadius: BorderRadius.circular(AppRadius.card.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: textTheme.displayMedium!.copyWith(
                fontSize: 17.sp,
                color: color,
              ),
            ),
            Text(label, style: textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

/// `.bar` — the grape XP track toward the next player level.
class _XpBar extends StatelessWidget {
  const _XpBar({required this.result});

  final LevelResult result;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.resultPlayerLevel(result.playerLevel),
              style: textTheme.labelSmall!.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              l10n.resultXpProgress(
                AppFormat.number(result.xpIntoLevel, localeName),
                AppFormat.number(result.xpToNextLevel, localeName),
              ),
              style: textTheme.labelSmall!.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill.r),
          child: SizedBox(
            height: 10.h,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: quizoo.s3)),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: result.xpProgress),
                  duration: AppMotion.durationOf(context, AppMotion.count),
                  curve: AppMotion.countCurve,
                  builder: (context, value, _) => FractionallySizedBox(
                    widthFactor: value,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [quizoo.g, AppColors.xpGradientEnd],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.pill.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
