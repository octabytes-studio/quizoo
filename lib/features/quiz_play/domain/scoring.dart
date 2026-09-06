import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';

/// §19's scoring maths, transcribed from the bible's own pseudocode.
///
/// **What this is and is not** (plan 002, Scope): it produces plausible,
/// internally consistent numbers so the result screen is exercised with
/// realistic values. It is not a certified scoring engine, and the bible says
/// as much about the real thing — "the server recomputes every submitted level
/// from the answer log; the client's own total is display only".
abstract final class Scoring {
  /// `base = 100`
  static const int base = 100;

  /// `+250` for finishing without firing a power-up.
  static const int cleanRunBonus = 250;

  /// `+1,000` for 20 of 20.
  static const int flawlessBonus = 1000;

  /// `+150` per heart still in hand at the end.
  static const int heartBonus = 150;

  /// `100 × longest streak`.
  static const int streakBonusPerStep = 100;

  /// Levels 5, 10, 15 and 20 pay double.
  static const int bossMultiplier = 2;

  /// `speedBonus = round(100 × secondsLeft / secondsTotal)`, 0…100.
  static int speedBonus({required int secondsLeft, required int secondsTotal}) {
    if (secondsTotal <= 0) return 0;
    return (100 * secondsLeft / secondsTotal).round().clamp(0, 100);
  }

  /// `diffMult = 1 + (level − 1) × 0.05` — L1 = 1.00 … L20 = 1.95.
  static double difficultyMultiplier(int levelNumber) =>
      1 + (levelNumber - 1) * 0.05;

  /// The streak ladder: 3+ → ×1.2, 5+ → ×1.5, 8+ → ×1.8, 12+ → ×2.0.
  static double streakMultiplier(int streak) => switch (streak) {
    >= 12 => 2,
    >= 8 => 1.8,
    >= 5 => 1.5,
    >= 3 => 1.2,
    _ => 1,
  };

  /// `questionScore = round((base + speedBonus) × diffMult × streakMult)`.
  ///
  /// [streak] is the streak the answer *lands on* — the bible's worked
  /// example scores a 5-answer streak at ×1.5, meaning the multiplier counts
  /// the run before this answer, not including it.
  static int questionScore({
    required int levelNumber,
    required int secondsLeft,
    required int secondsTotal,
    required int streak,
  }) {
    final speed = speedBonus(
      secondsLeft: secondsLeft,
      secondsTotal: secondsTotal,
    );
    final score =
        (base + speed) *
        difficultyMultiplier(levelNumber) *
        streakMultiplier(streak);
    return score.round();
  }

  /// Stars from correct answers: 12–15 → ⭐, 16–19 → ⭐⭐, 20 → ⭐⭐⭐.
  static int stars(int correctCount) => switch (correctCount) {
    >= 20 => 3,
    >= 16 => 2,
    >= 12 => 1,
    _ => 0,
  };

  /// How many more correct answers the next star needs, or zero at three.
  static int correctForNextStar(int correctCount) =>
      switch (stars(correctCount)) {
        3 => 0,
        2 => 20 - correctCount,
        1 => 16 - correctCount,
        _ => 12 - correctCount,
      };

  /// `xpToNext(n) = 300 + 100 × n`.
  static int xpToNextLevel(int playerLevel) => 300 + 100 * playerLevel;

  /// `xpEarned = 100 + 10 × level + star bonus + first-clear bonus`.
  static int xpEarned({
    required int levelNumber,
    required int stars,
    required bool isFirstClear,
  }) =>
      100 +
      10 * levelNumber +
      switch (stars) {
        3 => 200,
        2 => 100,
        _ => 0,
      } +
      (isFirstClear ? 150 : 0);

  /// Coins paid out for a completed level.
  ///
  /// §19 fixes the score and XP curves precisely but leaves the coin payout
  /// to Remote Config, so this is a plausible stand-in rather than a
  /// transcription: a flat base, more for stars, doubled on a boss level.
  static int coinsEarned({
    required int levelNumber,
    required int stars,
    required bool isBoss,
  }) {
    final coins = 60 + 10 * levelNumber + stars * 20;
    return isBoss ? coins * bossMultiplier : coins;
  }

  /// The end-of-level bonuses, in the order S-21's breakdown lists them.
  ///
  /// Returned as a list rather than a total so the screen can render the
  /// breakdown and the sum from one source — which is what makes "the
  /// breakdown sums to the total shown" true by construction rather than by
  /// two pieces of code agreeing.
  static List<ScoreLine> breakdown(QuizRun run) {
    final lines = <ScoreLine>[
      ScoreLine(kind: ScoreLineKind.correct, value: run.correctCount * base),
    ];

    final speed = run.answers.fold<int>(
      0,
      (total, answer) =>
          total +
          (answer.isCorrect
              ? speedBonus(
                  secondsLeft: answer.secondsLeft,
                  secondsTotal: run.secondsPerQuestion,
                )
              : 0),
    );
    if (speed > 0) {
      lines.add(ScoreLine(kind: ScoreLineKind.speed, value: speed));
    }

    if (run.longestStreak > 0) {
      lines.add(
        ScoreLine(
          kind: ScoreLineKind.streak,
          value: streakBonusPerStep * run.longestStreak,
        ),
      );
    }
    if (!run.usedPowerUp) {
      lines.add(
        const ScoreLine(kind: ScoreLineKind.cleanRun, value: cleanRunBonus),
      );
    }
    if (run.isFlawless) {
      lines.add(
        const ScoreLine(kind: ScoreLineKind.flawless, value: flawlessBonus),
      );
    }
    if (run.heartsRemaining > 0) {
      lines.add(
        ScoreLine(
          kind: ScoreLineKind.hearts,
          value: heartBonus * run.heartsRemaining,
        ),
      );
    }

    if (run.isBoss) {
      final subtotal = lines.fold<int>(0, (sum, line) => sum + line.value);
      lines.add(ScoreLine(kind: ScoreLineKind.boss, value: subtotal));
    }

    return lines;
  }

  /// The total S-21 counts up to — always the sum of [breakdown].
  static int total(QuizRun run) =>
      breakdown(run).fold<int>(0, (sum, line) => sum + line.value);
}

/// Which bonus a breakdown row is, so the screen resolves its own copy rather
/// than the domain layer shipping display strings.
enum ScoreLineKind { correct, speed, streak, cleanRun, flawless, hearts, boss }

/// One row of S-21's score breakdown.
class ScoreLine {
  const ScoreLine({required this.kind, required this.value});

  final ScoreLineKind kind;
  final int value;
}
