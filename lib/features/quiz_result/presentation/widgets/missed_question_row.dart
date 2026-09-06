import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/core/theme/app_radius.dart';
import 'package:quizoo/core/theme/app_typography.dart';
import 'package:quizoo/core/theme/quizoo_colors.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// One row of S-22's "YOU MISSED THESE — TAP TO REVIEW" list.
///
/// It always names the **correct** answer, then what the player said. That
/// ordering is the point: the list is the fastest route back into the level,
/// so it has to teach, not just tally.
class MissedQuestionRow extends StatelessWidget {
  const MissedQuestionRow({
    required this.answer,
    required this.onTap,
    super.key,
  });

  final AnsweredQuestion answer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quizoo = context.quizoo;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final chosen = answer.chosenAnswer;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: quizoo.s1,
          border: Border.all(color: quizoo.ln),
          borderRadius: BorderRadius.circular(AppRadius.snackbar.r),
        ),
        child: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: quizoo.badBg,
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Text(
                '✕',
                style: AppTypography.glyph(15.sp, color: quizoo.bad),
              ),
            ),
            SizedBox(width: 11.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    answer.question.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge!.copyWith(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w800,
                      color: quizoo.tx,
                    ),
                  ),
                  Text(
                    // A timeout has no "you said" to print, so it gets its own
                    // line rather than an empty one.
                    chosen == null
                        ? l10n.failedMissedTimeout(
                            answer.question.correctAnswer,
                          )
                        : l10n.failedMissedAnswer(
                            answer.question.correctAnswer,
                            chosen,
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall!.copyWith(fontSize: 10.5.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
