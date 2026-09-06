import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/quiz_result/presentation/bloc/quiz_result_cubit.dart';
import 'package:quizoo/features/quiz_result/presentation/widgets/missed_question_row.dart';
import 'package:quizoo/features/quiz_result/presentation/widgets/result_wash.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-22 — level failed, reframed as nearly-there.
///
/// Three of the bible's rules for this screen are structural, not stylistic,
/// and are worth naming because each is easy to undo by accident:
///
/// * **No stars.** There is nothing to grey out, so the row is simply absent.
/// * **No ad and no offer, of any kind.** This screen never sells anything.
/// * **No save-progress sheet.** It is offered after a success and never after
///   a failure — which is why this screen has no chain to run at all, unlike
///   S-21.
class LevelFailedScreen extends StatelessWidget {
  const LevelFailedScreen({required this.state, super.key});

  final QuizResultFailed state;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final run = state.result.run;

    // A `pop`, not a `go` — the play screen reached this one via
    // `pushReplacement`, so the level map is already directly beneath it on
    // the stack. `go` would rebuild the stack from this location alone,
    // dropping the category/level-map history and leaving nothing for a
    // later back press to pop.
    void backToMap() => context.pop();

    return ResultWash(
      accent: quizoo.bad,
      onClose: backToMap,
      actions: [
        ChunkyButton(
          label: l10n.failedTryAgain,
          subLabel: l10n.failedTryAgainCost,
          onPressed: () =>
              context.pushReplacement(AppRoutes.countdownPath(run.levelId)),
        ),
        SizedBox(height: 9.h),
        ChunkyButton.line(label: l10n.resultBackToMap, onPressed: backToMap),
      ],
      child: Column(
        children: [
          Text('😤', style: AppTypography.glyph(54.sp)),
          Text(
            l10n.failedTitle,
            textAlign: TextAlign.center,
            style: textTheme.displayMedium!.copyWith(
              fontSize: 26.sp,
              color: Colors.white,
            ),
          ),
          Text(
            // A quit must never claim the player ran out of hearts.
            state.ranOutOfHearts
                ? l10n.failedRanOutOfHearts(run.answers.length)
                : l10n.failedQuitEarly(run.answers.length),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium!.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: 18.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.base.w),
            decoration: BoxDecoration(
              color: quizoo.s1,
              border: Border.all(color: quizoo.ln),
              borderRadius: BorderRadius.circular(AppRadius.card.r),
              boxShadow: quizoo.shadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _FailedStat(
                      value: '${run.correctCount}',
                      label: l10n.failedCorrect,
                    ),
                    _FailedStat(
                      value: AppFormat.number(run.score, localeName),
                      label: l10n.failedPoints,
                    ),
                    _FailedStat(
                      value: l10n.failedAccuracyValue(run.accuracyPercent),
                      label: l10n.failedAccuracy,
                    ),
                  ],
                ),
                if (run.missed.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    child: Divider(color: quizoo.ln, height: 1, thickness: 1),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l10n.failedMissedHeading,
                      style: textTheme.labelSmall,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  for (final answer in run.missed)
                    Padding(
                      padding: EdgeInsets.only(bottom: 7.h),
                      child: MissedQuestionRow(
                        answer: answer,
                        // Reviewing a question is plan 004's report/review
                        // surface; here the row's job is to name the miss.
                        onTap: () => context.push(AppRoutes.reportQuestion),
                      ),
                    ),
                ],
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xl.h),
        ],
      ),
    );
  }
}

class _FailedStat extends StatelessWidget {
  const _FailedStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.displayMedium!.copyWith(fontSize: 23.sp),
          ),
          Text(label, style: textTheme.labelSmall),
        ],
      ),
    );
  }
}
