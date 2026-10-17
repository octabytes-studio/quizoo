import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/widgets/app_bottom_sheet.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/report_question_sheet.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/features/quiz_play/domain/report_question_args.dart';
import 'package:quizoo/features/quiz_play/domain/report_reason.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/report_question_cubit.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-51 — the real report-a-question flow (plan 025).
///
/// Presented as a route (the router's `_sheetPage`), so both entry points —
/// the play HUD's "⋯" and the failed-result review list — push one payload
/// instead of each duplicating sheet logic. Submitting inserts into
/// `question_reports` through [ReportQuestionCubit]; the screen only closes
/// once the server stored the row.
class ReportQuestionScreen extends StatelessWidget {
  const ReportQuestionScreen({required this.args, super.key});

  /// Null only when the route is reached without a payload (a stale deep
  /// link). A release build shows a clean unavailable sheet rather than a
  /// fixture question; debug builds keep the old design-review demo
  /// (see `router.dart`).
  final ReportQuestionArgs? args;

  @override
  Widget build(BuildContext context) {
    final resolved = args;
    if (resolved == null) return const _ReportQuestionUnavailable();

    return BlocProvider<ReportQuestionCubit>(
      create: (context) => ReportQuestionCubit(
        context.read<QuizPlayRepository>(),
        args: resolved,
      ),
      child: BlocConsumer<ReportQuestionCubit, ReportQuestionState>(
        listenWhen: (previous, current) =>
            current is ReportQuestionSent || current is ReportQuestionFailed,
        listener: (context, state) {
          final l10n = AppLocalizations.of(context);
          switch (state) {
            // Confirmed stored: confirm first (on the root messenger, so it
            // survives the pop), then close the sheet.
            case ReportQuestionSent():
              AppSnackbar.show(
                context,
                title: l10n.reportQuestionSent,
                intent: SnackbarIntent.success,
              );
              Navigator.of(context).pop();
            // The sheet stays open with the reason still selected so a retry
            // is one tap.
            case ReportQuestionFailed():
              AppSnackbar.show(
                context,
                title: l10n.reportQuestionError,
                intent: SnackbarIntent.error,
              );
            case ReportQuestionIdle() || ReportQuestionSending():
              break;
          }
        },
        builder: (context, state) => _ReportQuestionSheetView(args: resolved),
      ),
    );
  }
}

/// The S-51 sheet itself, wired to the Cubit — building the localized reason
/// list from [ReportReason.values] so the wire codes and the displayed
/// options can never drift apart.
class _ReportQuestionSheetView extends StatelessWidget {
  const _ReportQuestionSheetView({required this.args});

  final ReportQuestionArgs args;

  static String _label(AppLocalizations l10n, ReportReason reason) =>
      switch (reason) {
        ReportReason.wrong => l10n.reportReasonWrong,
        ReportReason.unclear => l10n.reportReasonUnclear,
        ReportReason.translation => l10n.reportReasonTranslation,
        ReportReason.offensive => l10n.reportReasonOffensive,
        ReportReason.image => l10n.reportReasonImage,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ReportQuestionCubit>();

    return ReportQuestionSheet(
      title: l10n.reportQuestionTitle,
      message:
          '${args.topicLabel} — ${l10n.reportQuestionMeta(args.questionText)}',
      reasons: [for (final reason in ReportReason.values) _label(l10n, reason)],
      submitLabel: l10n.reportQuestionSubmit,
      // The Cubit itself ignores a re-submit while one is in flight, so a
      // double tap cannot insert twice.
      onSubmit: (index) => cubit.submit(ReportReason.values[index]),
    );
  }
}

/// The release-safe state for a report route with no payload.
class _ReportQuestionUnavailable extends StatelessWidget {
  const _ReportQuestionUnavailable();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppBottomSheet(
      title: l10n.reportQuestionTitle,
      message: l10n.reportQuestionUnavailableBody,
      child: ChunkyButton.ghost(
        label: l10n.commonClose,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
