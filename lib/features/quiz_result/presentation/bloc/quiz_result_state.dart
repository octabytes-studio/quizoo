part of 'quiz_result_cubit.dart';

/// S-21 / S-22's states (CLAUDE.md §3).
sealed class QuizResultState extends Equatable {
  const QuizResultState();

  @override
  List<Object?> get props => const [];
}

/// Submitting the run. Brief, because nothing is fetched.
final class QuizResultLoading extends QuizResultState {
  const QuizResultLoading();
}

/// S-21 — the level was completed.
final class QuizResultCompleted extends QuizResultState {
  const QuizResultCompleted(this.result);

  final LevelResult result;

  @override
  List<Object?> get props => [result];
}

/// S-22 — the run ended early, whether the hearts ran out or the player left.
///
/// **No stars, and no offer of any kind.** Both are bible rules for this
/// screen, not style preferences: there is nothing to grey out, and this is
/// the one screen that never shows an ad or a purchase.
final class QuizResultFailed extends QuizResultState {
  const QuizResultFailed(this.result);

  final LevelResult result;

  /// True when hearts ran out, false when the player chose to leave. The two
  /// get different copy — a quit must never claim they ran out of hearts.
  bool get ranOutOfHearts => result.run.ending == RunEnding.outOfHearts;

  @override
  List<Object?> get props => [result];
}

final class QuizResultError extends QuizResultState {
  const QuizResultError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
