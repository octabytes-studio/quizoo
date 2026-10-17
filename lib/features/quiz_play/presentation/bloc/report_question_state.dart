part of 'report_question_cubit.dart';

/// S-51's submission states (CLAUDE.md §3).
sealed class ReportQuestionState extends Equatable {
  const ReportQuestionState();

  @override
  List<Object?> get props => const [];
}

/// Nothing sent yet — the sheet is open and waiting for a reason.
final class ReportQuestionIdle extends ReportQuestionState {
  const ReportQuestionIdle();
}

/// The insert is on the wire; the submit button shows its progress and
/// ignores further taps.
final class ReportQuestionSending extends ReportQuestionState {
  const ReportQuestionSending();
}

/// The row is stored — the screen closes and confirms.
final class ReportQuestionSent extends ReportQuestionState {
  const ReportQuestionSent();
}

/// The insert failed; the sheet stays open with an error and the player can
/// retry without re-picking the reason.
final class ReportQuestionFailed extends ReportQuestionState {
  const ReportQuestionFailed(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
