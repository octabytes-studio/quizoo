import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// One question in the answer review (plan 023, benefit 8).
///
/// Every option is shown, with the correct one marked ✓ on mint and the one
/// the player picked marked ✕ on raspberry — colour **and** glyph, so the
/// difference survives colour-blindness (design bible §04). A timeout shows
/// "You didn't answer" instead of a wrong-pick marker. The explanation is
/// always shown; the bible calls it the thing that turns a quiz into
/// learning.
class ReviewQuestionCard extends StatelessWidget {
  const ReviewQuestionCard({
    required this.answer,
    required this.index,
    required this.total,
    super.key,
  });

  /// The answered question, with what the player did.
  final AnsweredQuestion answer;

  /// 0-based position in the run — rendered as "Question 1 of 20".
  final int index;

  /// How many questions the run had, for the same caption.
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final quizoo = context.quizoo;
    final question = answer.question;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.base.h),
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: quizoo.s1,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(color: quizoo.ln),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.reviewQuestionNumber(index + 1, total),
            style: textTheme.labelSmall!.copyWith(color: quizoo.tx3),
          ),
          SizedBox(height: AppSpacing.xs.h),
          Text(question.text, style: textTheme.titleSmall),
          SizedBox(height: AppSpacing.base.h),
          for (var i = 0; i < question.options.length; i++)
            _OptionRow(
              label: question.options[i],
              isCorrect: i == question.correctIndex,
              isChosen: i == answer.chosenIndex,
              l10n: l10n,
            ),
          if (answer.chosenIndex == null) ...[
            SizedBox(height: AppSpacing.sm.h),
            Text(
              l10n.reviewTimedOut,
              style: textTheme.labelSmall!.copyWith(color: quizoo.tx2),
            ),
          ],
          SizedBox(height: AppSpacing.base.h),
          Text(
            l10n.reviewExplanation,
            style: textTheme.labelSmall!.copyWith(
              color: quizoo.tx3,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.xs.h),
          Text(
            question.explanation,
            style: textTheme.bodySmall!.copyWith(color: quizoo.tx2),
          ),
        ],
      ),
    );
  }
}

/// One option line, with its verdict marker if any.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.isCorrect,
    required this.isChosen,
    required this.l10n,
  });

  final String label;
  final bool isCorrect;
  final bool isChosen;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final quizoo = context.quizoo;

    final Color color;
    final String marker;
    if (isCorrect) {
      color = quizoo.ok;
      marker = '✓';
    } else if (isChosen) {
      color = quizoo.bad;
      marker = '✕';
    } else {
      color = quizoo.tx3;
      marker = '•';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            marker,
            style: textTheme.titleSmall!.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium!.copyWith(color: quizoo.tx),
            ),
          ),
          if (isCorrect || isChosen)
            Text(
              isCorrect ? l10n.reviewCorrect : l10n.reviewYourAnswer,
              style: textTheme.labelSmall!.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
