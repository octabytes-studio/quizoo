import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';

part 'quiz_run.freezed.dart';
part 'quiz_run.g.dart';

/// How a question was resolved.
///
/// [timedOut] is deliberately distinct from [wrong]: §19 is explicit that "a
/// timeout costs the question but not a heart, so a cautious player can
/// survive on knowledge alone". Collapsing the two is the single easiest bug
/// to write in this feature.
enum AnswerOutcome { correct, wrong, timedOut, skipped }

/// How a run ended.
enum RunEnding {
  /// Still being played.
  inProgress,

  /// All twenty questions answered with a heart still in hand.
  finished,

  /// Hearts hit zero.
  outOfHearts,

  /// The player chose to leave (S-18 / S-19's third action). Deliberately
  /// distinct from [outOfHearts] so the result screen's copy can differ —
  /// a quit must never claim the player "ran out of hearts".
  quit,
}

/// One answered question inside a run.
@freezed
abstract class AnsweredQuestion with _$AnsweredQuestion {
  const factory AnsweredQuestion({
    required Question question,
    required AnswerOutcome outcome,

    /// What the player picked, or null on a timeout or skip.
    int? chosenIndex,

    /// Seconds left on the clock when they answered — the speed bonus's input.
    @Default(0) int secondsLeft,

    /// Points this question added to the running total.
    @Default(0) int pointsEarned,
  }) = _AnsweredQuestion;

  const AnsweredQuestion._();

  factory AnsweredQuestion.fromJson(Map<String, dynamic> json) =>
      _$AnsweredQuestionFromJson(json);

  bool get isCorrect => outcome == AnswerOutcome.correct;

  /// What the player picked, for S-22's review list. Null when they never
  /// answered.
  String? get chosenAnswer =>
      chosenIndex == null ? null : question.options[chosenIndex!];
}

/// The whole of one attempt at a level.
///
/// This is what `QuizPlayCubit` hands to `QuizResultCubit` through the route's
/// `extra`, so the result screen never re-fetches data the app already holds.
@freezed
abstract class QuizRun with _$QuizRun {
  const factory QuizRun({
    /// The server-issued `level_attempts.id` `submit_level_attempt` needs to
    /// re-derive correctness against — one per `start_level_attempt` call, so
    /// a retried level gets a fresh id rather than reusing a stale one.
    required String attemptId,
    required String levelId,
    required String subcategoryId,
    required String subcategoryName,
    required String categoryId,
    required int levelNumber,
    required int secondsPerQuestion,
    required DateTime startedAt,
    @Default([]) List<AnsweredQuestion> answers,
    @Default(0) int score,
    @Default(0) int longestStreak,
    @Default(0) int currentStreak,
    @Default(3) int heartsRemaining,
    @Default(20) int questionCount,
    @Default(false) bool isBoss,

    /// True for the daily challenge's ten-question run through this same
    /// arena — hearts never deplete and there is no power-up dock, but the
    /// countdown, HUD, timer ring and answer options are identical to a
    /// level (design decision: one play surface, not two).
    @Default(false) bool isDaily,

    /// True once any power-up has been fired, which forfeits the clean-run
    /// bonus (§19).
    @Default(false) bool usedPowerUp,
    @Default(RunEnding.inProgress) RunEnding ending,
    DateTime? finishedAt,
  }) = _QuizRun;

  const QuizRun._();

  factory QuizRun.fromJson(Map<String, dynamic> json) =>
      _$QuizRunFromJson(json);

  int get correctCount => answers.where((answer) => answer.isCorrect).length;

  /// 1-based, for "Question 6 of 20".
  int get questionNumber => answers.length + 1;

  /// The questions the player got wrong or let time out — S-22's review list.
  List<AnsweredQuestion> get missed => [
    for (final answer in answers)
      if (!answer.isCorrect) answer,
  ];

  /// Correct answers as a share of the questions actually reached, which is
  /// what S-22 prints. A run that ended early is measured on what it played,
  /// not on the twenty it never saw.
  int get accuracyPercent =>
      answers.isEmpty ? 0 : ((correctCount / answers.length) * 100).round();

  /// True when the player answered all twenty and kept a heart.
  bool get isComplete => ending == RunEnding.finished;

  /// True when the player got every single question right (§19's "Flawless").
  bool get isFlawless =>
      answers.length == questionCount && correctCount == questionCount;
}
