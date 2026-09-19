part of 'quiz_play_cubit.dart';

/// Where a question sits in the 3-2-1/TTS/reveal sequence (plan 007, §4).
///
/// A deliberate 3-value simplification of the source spec's 4-value
/// `speaking → revealing → answering → answered` list: "answered" is already
/// fully represented by [QuestionFeedback] once `feedback is! NoFeedback`, so
/// a 4th phase value would be redundant state.
enum QuestionPhase {
  /// TTS is reading the question aloud (or about to). The clock has not
  /// started and options are not yet shown.
  speaking,

  /// TTS has finished (or was skipped); the staggered fade+slide reveal is
  /// animating the options in. The clock still has not started.
  revealing,

  /// The reveal has finished. The clock is running and every option is
  /// tappable — today's original instant behavior when audio is off.
  answering,
}

/// The verdict banner's contents, sealed so the screen switches over it
/// exhaustively instead of juggling booleans (CLAUDE.md §3).
sealed class QuestionFeedback extends Equatable {
  const QuestionFeedback();

  @override
  List<Object?> get props => const [];
}

/// No verdict yet — the question is live and every option is interactive.
final class NoFeedback extends QuestionFeedback {
  const NoFeedback();
}

/// S-12. Carries the score breakdown the banner prints under the explanation.
final class CorrectFeedback extends QuestionFeedback {
  const CorrectFeedback({
    required this.chosenIndex,
    required this.pointsEarned,
    required this.speedBonus,
    required this.difficultyMultiplier,
    required this.streakMultiplier,
  });

  final int chosenIndex;
  final int pointsEarned;
  final int speedBonus;
  final double difficultyMultiplier;
  final double streakMultiplier;

  @override
  List<Object?> get props => [
    chosenIndex,
    pointsEarned,
    speedBonus,
    difficultyMultiplier,
    streakMultiplier,
  ];
}

/// S-13. The correct option is still revealed — the bible is explicit that the
/// right answer is never hidden.
final class WrongFeedback extends QuestionFeedback {
  const WrongFeedback({
    required this.chosenIndex,
    required this.heartsRemaining,
    required this.brokeStreak,
  });

  final int chosenIndex;
  final int heartsRemaining;

  /// True when this answer ended a streak, which is what puts "Streak reset."
  /// in the banner.
  final bool brokeStreak;

  @override
  List<Object?> get props => [chosenIndex, heartsRemaining, brokeStreak];
}

/// The clock ran out with nothing selected.
///
/// **Not a wrong answer**: §19 says a timeout costs the question but not a
/// heart. It is rendered like S-13 because the bible shows no separate frame
/// for it, and that interpretation is flagged in plan 002's edge cases rather
/// than assumed silently.
final class TimeoutFeedback extends QuestionFeedback {
  const TimeoutFeedback({required this.brokeStreak});

  final bool brokeStreak;

  @override
  List<Object?> get props => [brokeStreak];
}

/// The player spent a Skip.
final class SkippedFeedback extends QuestionFeedback {
  const SkippedFeedback();
}

/// The play surface's states.
///
/// [QuizPlayPaused], [QuizPlayQuitting] and [QuizPlayOutOfLives] each **wrap**
/// the in-progress state rather than copying its fields. That keeps them true
/// sealed states — the screen switches over them, and the overlays are driven
/// by state rather than by an ad-hoc `showDialog` somewhere in the tree — while
/// the run's data stays in exactly one place.
sealed class QuizPlayState extends Equatable {
  const QuizPlayState();

  /// The live run, on every state that has one.
  QuizRun? get run => switch (this) {
    QuizPlayPreparing() ||
    QuizPlayFailed() ||
    QuizPlayDailyFinished() ||
    QuizPlayDailyAlreadyPlayed() => null,
    QuizPlayCountdown(:final run) => run,
    QuizPlayInProgress(:final run) => run,
    QuizPlayPaused(:final underlying) => underlying.run,
    QuizPlayQuitting(:final underlying) => underlying.run,
    QuizPlayOutOfLives(:final underlying) => underlying.run,
    QuizPlayEnded(:final run) => run,
    QuizPlaySubmittingDaily(:final run) => run,
  };

  /// The question screen underneath, which the pause sheet blurs and the two
  /// dialogs sit over.
  QuizPlayInProgress? get playing => switch (this) {
    QuizPlayInProgress() => this as QuizPlayInProgress,
    QuizPlayPaused(:final underlying) => underlying,
    QuizPlayQuitting(:final underlying) => underlying,
    QuizPlayOutOfLives(:final underlying) => underlying,
    _ => null,
  };

  @override
  List<Object?> get props => const [];
}

/// Loading the level's twenty questions. Usually instant, because S-09
/// prefetched them.
final class QuizPlayPreparing extends QuizPlayState {
  const QuizPlayPreparing();
}

/// The level could not be loaded at all.
final class QuizPlayFailed extends QuizPlayState {
  const QuizPlayFailed(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}

/// S-10 — 3 · 2 · 1 · GO.
final class QuizPlayCountdown extends QuizPlayState {
  const QuizPlayCountdown({required this.run, required this.beat});

  @override
  final QuizRun run;

  /// 3, 2, 1, then 0 for "GO".
  final int beat;

  bool get isGo => beat == 0;

  @override
  List<Object?> get props => [run, beat];
}

/// S-11 through S-16 — a live question, in whatever state its verdict is.
final class QuizPlayInProgress extends QuizPlayState {
  const QuizPlayInProgress({
    required this.run,
    required this.question,
    required this.secondsRemaining,
    required this.powerUps,
    this.feedback = const NoFeedback(),
    this.eliminatedIndexes = const {},
    this.selectedIndex,
    this.phase = QuestionPhase.answering,
    this.isAudioOn = true,
  });

  @override
  final QuizRun run;

  final Question question;

  /// Whole seconds left, which is what the ring's numeral shows.
  final int secondsRemaining;

  final PowerUpInventory powerUps;
  final QuestionFeedback feedback;

  /// Options removed by 50:50.
  final Set<int> eliminatedIndexes;

  /// Tapped and awaiting the verdict — the lemon ring on S-11's option.
  final int? selectedIndex;

  /// Where this question sits in the speak/reveal/answer sequence. Defaults
  /// to [QuestionPhase.answering] — today's behavior — when audio is off or
  /// [Question.ttsExcluded].
  final QuestionPhase phase;

  /// The HUD speaker icon's own state, backed by `AppSettings.soundOn`.
  final bool isAudioOn;

  /// True while no verdict has landed, which is the only time an option is
  /// tappable.
  bool get isAwaitingAnswer => feedback is NoFeedback;

  /// S-14 — the last five seconds. Only ever true on a live question, never
  /// while a verdict banner is up.
  bool get isDanger =>
      isAwaitingAnswer && secondsRemaining <= dangerThresholdSeconds;

  /// True on the twentieth question, which changes the banner's button.
  bool get isLastQuestion => run.questionNumber >= run.questionCount;

  /// §09: the arena turns crimson for the last five seconds.
  static const int dangerThresholdSeconds = 5;

  QuizPlayInProgress copyWith({
    QuizRun? run,
    Question? question,
    int? secondsRemaining,
    PowerUpInventory? powerUps,
    QuestionFeedback? feedback,
    Set<int>? eliminatedIndexes,
    int? selectedIndex,
    QuestionPhase? phase,
    bool? isAudioOn,
  }) => QuizPlayInProgress(
    run: run ?? this.run,
    question: question ?? this.question,
    secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    powerUps: powerUps ?? this.powerUps,
    feedback: feedback ?? this.feedback,
    eliminatedIndexes: eliminatedIndexes ?? this.eliminatedIndexes,
    selectedIndex: selectedIndex ?? this.selectedIndex,
    phase: phase ?? this.phase,
    isAudioOn: isAudioOn ?? this.isAudioOn,
  );

  @override
  List<Object?> get props => [
    run,
    question,
    secondsRemaining,
    powerUps,
    feedback,
    eliminatedIndexes,
    selectedIndex,
    phase,
    isAudioOn,
  ];
}

/// S-17 — the pause sheet is up and the clock is frozen.
final class QuizPlayPaused extends QuizPlayState {
  const QuizPlayPaused({
    required this.underlying,
    this.isSoundOn = true,
    this.isHapticsOn = true,
  });

  final QuizPlayInProgress underlying;

  /// The sheet's two quick-toggles. Mocked: nothing plays sound or vibrates
  /// in this phase (plan 002, Scope), so they record a preference and no more.
  final bool isSoundOn;
  final bool isHapticsOn;

  @override
  List<Object?> get props => [underlying, isSoundOn, isHapticsOn];
}

/// S-18 — the quit confirmation dialog is up. The clock is frozen.
final class QuizPlayQuitting extends QuizPlayState {
  const QuizPlayQuitting(this.underlying);

  final QuizPlayInProgress underlying;

  @override
  List<Object?> get props => [underlying];
}

/// S-19 — hearts hit zero. Never a hard wall: the run is still recoverable.
final class QuizPlayOutOfLives extends QuizPlayState {
  const QuizPlayOutOfLives({
    required this.underlying,
    required this.coins,
    required this.heartRefillAt,
    this.isWatchingAd = false,
  });

  final QuizPlayInProgress underlying;

  /// The wallet, which decides whether the paid refill is affordable.
  final int coins;

  /// When the next heart arrives on its own — printed as a clock time, never
  /// as a countdown.
  final DateTime heartRefillAt;

  /// True while the mocked rewarded ad "plays".
  final bool isWatchingAd;

  bool get canAffordRefill => coins >= MockPlayer.refillCost;

  @override
  List<Object?> get props => [underlying, coins, heartRefillAt, isWatchingAd];
}

/// The run is over, however it ended. The screen navigates to the result on
/// this state and never renders it.
///
/// Never reached for a daily run — [QuizRun.isDaily] runs end at
/// [QuizPlaySubmittingDaily] instead, since a daily result has to come back
/// from the server rather than being computed locally the way a level's is.
final class QuizPlayEnded extends QuizPlayState {
  const QuizPlayEnded(this.run);

  @override
  final QuizRun run;

  @override
  List<Object?> get props => [run];
}

/// The daily run's tenth answer just landed; scoring it with the server via
/// `play_daily_challenge`. The arena shows a spinner on this state, same as
/// [QuizPlayEnded] does for a level.
final class QuizPlaySubmittingDaily extends QuizPlayState {
  const QuizPlaySubmittingDaily(this.run);

  @override
  final QuizRun run;

  @override
  List<Object?> get props => [run];
}

/// The daily run was scored — the screen navigates to S-28 with [result] and
/// never renders this state, mirroring [QuizPlayEnded]'s own contract.
final class QuizPlayDailyFinished extends QuizPlayState {
  const QuizPlayDailyFinished(this.result);

  final DailyResult result;

  @override
  List<Object?> get props => [result];
}

/// The player already has a `daily_attempts` row for today — surfaced as its
/// own state (reached either from the initial fetch or from submitting a
/// finished run) rather than a generic [QuizPlayFailed], so the screen can
/// show real "come back tomorrow" copy instead of a network-error template.
final class QuizPlayDailyAlreadyPlayed extends QuizPlayState {
  const QuizPlayDailyAlreadyPlayed();
}
