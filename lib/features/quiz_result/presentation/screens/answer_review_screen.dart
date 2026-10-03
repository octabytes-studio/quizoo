import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/widgets/content_language_scope.dart';
import 'package:quizoo/core/widgets/simple_top_bar.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_result/presentation/widgets/review_question_card.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// Every question of a finished run, with the right answer and the
/// explanation (plan 023, benefit 8).
///
/// Pure presentation of an in-memory [QuizRun] — there is no loading, no
/// error and no business decision to make, so there is deliberately no Cubit
/// here (CLAUDE.md §1: do not introduce a domain layer for trivial reads).
/// The run arrives on the route's `extra`, exactly as it already does for
/// the result screens.
///
/// Question content is wrapped in [ContentLanguageScope] so an Urdu/Arabic
/// topic renders RTL and in the question typeface, as the play surface does.
class AnswerReviewScreen extends StatelessWidget {
  const AnswerReviewScreen({super.key, this.run});

  /// Null only on the debug route, where no run exists — see [run].
  final QuizRun? run;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentRun = run;
    final languageCode = context.read<ContentLanguageCubit>().state.code;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SimpleTopBar(title: l10n.reviewTitle),
            Expanded(
              child: currentRun == null || currentRun.answers.isEmpty
                  ? _Empty(l10n: l10n)
                  : ContentLanguageScope(
                      languageCode: languageCode,
                      child: ListView.builder(
                        padding: EdgeInsets.all(AppSpacing.base.w),
                        itemCount: currentRun.answers.length,
                        itemBuilder: (context, index) => ReviewQuestionCard(
                          answer: currentRun.answers[index],
                          index: index,
                          total: currentRun.answers.length,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg.w),
        child: Text(
          l10n.reviewEmpty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
