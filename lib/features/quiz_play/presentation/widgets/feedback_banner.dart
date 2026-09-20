import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/format/app_format.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/quiz_play_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// `.fb` — the verdict banner that slides up over the options.
///
/// It always carries the question's **explanation**, right or wrong. The bible
/// calls that "the single feature that turns a quiz into learning", so the
/// explanation is not optional here and there is no branch that omits it.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    required this.state,
    required this.onNextPressed,
    super.key,
  });

  final QuizPlayInProgress state;
  final VoidCallback onNextPressed;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    final feedback = state.feedback;
    final isGood = feedback is CorrectFeedback;

    final (String emoji, String title, String? trailing) = switch (feedback) {
      CorrectFeedback(:final pointsEarned) => (
        '🎉',
        l10n.feedbackCorrect,
        l10n.feedbackPoints(AppFormat.number(pointsEarned, localeName)),
      ),
      WrongFeedback() => ('💔', l10n.feedbackWrong, l10n.feedbackHeartLost),
      TimeoutFeedback() => ('⏳', l10n.feedbackTimeout, l10n.feedbackHeartLost),
      NoFeedback() => ('', '', null),
    };

    final body = StringBuffer(state.question.explanation);
    switch (feedback) {
      case CorrectFeedback(
        :final speedBonus,
        :final difficultyMultiplier,
        :final streakMultiplier,
      ):
        body
          ..write(' ')
          ..write(
            l10n.feedbackBreakdown(
              speedBonus,
              AppFormat.multiplier(difficultyMultiplier, localeName),
              AppFormat.multiplier(streakMultiplier, localeName),
            ),
          );
      case WrongFeedback(:final brokeStreak, :final heartsRemaining):
        if (brokeStreak) body.write(' ${l10n.feedbackStreakReset}');
        if (heartsRemaining == 1) body.write(' ${l10n.feedbackLastHeart}');
      case TimeoutFeedback(:final brokeStreak, :final heartsRemaining):
        if (brokeStreak) body.write(' ${l10n.feedbackStreakReset}');
        if (heartsRemaining == 1) body.write(' ${l10n.feedbackLastHeart}');
      case NoFeedback():
        break;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 18.h),
      decoration: BoxDecoration(
        color: isGood ? quizoo.ok : quizoo.bad,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
        boxShadow: quizoo.shadowLarge,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(emoji, style: AppTypography.glyph(24.sp)),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.headlineMedium!.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing,
                    style: textTheme.headlineMedium!.copyWith(
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              body.toString(),
              style: textTheme.bodyMedium!.copyWith(
                fontSize: 12.5.sp,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
            SizedBox(height: AppRadius.iconButton.h),
            ChunkyButton.ghost(
              label: state.isLastQuestion
                  ? l10n.feedbackFinish
                  : l10n.feedbackNext,
              onPressed: onNextPressed,
            ),
          ],
        ),
      ),
    ).animate().slideY(
      begin: 1,
      end: 0,
      duration: AppMotion.durationOf(context, AppMotion.sheet),
      curve: AppMotion.curveOf(context, AppMotion.sheetCurve),
    );
  }
}
