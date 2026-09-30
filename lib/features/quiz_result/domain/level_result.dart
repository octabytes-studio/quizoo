import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';

part 'level_result.freezed.dart';
part 'level_result.g.dart';

/// The tally of a finished run, plus what the app should do next.
///
/// The "what next" fields are the reason this exists rather than the screen
/// reading a [QuizRun] directly: deciding whether a badge was earned, whether
/// this was a first clear, and whether an account is worth offering is
/// business logic, and it belongs below the widget layer.
@freezed
abstract class LevelResult with _$LevelResult {
  const factory LevelResult({
    required QuizRun run,

    /// 0…3 (§19). Never shown on a failed run — there is nothing to grey out.
    required int stars,
    required int finalScore,
    required int coinsEarned,
    required int xpEarned,

    /// Where the player's XP bar sits after this run.
    required int playerLevel,
    required int xpIntoLevel,
    required int xpToNextLevel,

    /// True the first time this level is cleared, which pays a bonus.
    @Default(false) bool isFirstClear,

    /// Badge ids newly earned by this run. The result screen pushes S-23's
    /// route for the first of them — it never imports `features/achievements`
    /// (plan 001's no-cross-feature-orchestration rule).
    @Default([]) List<String> newlyEarnedBadgeIds,

    /// True when S-24 is allowed to appear after this run: a successful first
    /// level, a guest, and not already offered.
    @Default(false) bool shouldOfferSaveProgress,

    /// True when this run was played on the ladder's last level (30), so
    /// there is no next level to offer.
    @Default(false) bool isFinalLevel,

    /// True when this run just mastered the topic: the final level, cleared,
    /// for the first time. Drives the Topic Mastered push (plan 020).
    @Default(false) bool unlocksMastery,
  }) = _LevelResult;

  const LevelResult._();

  factory LevelResult.fromJson(Map<String, dynamic> json) =>
      _$LevelResultFromJson(json);

  /// How many more correct answers the third star needs, or zero at three.
  int get correctForThirdStar =>
      stars >= 3 ? 0 : run.questionCount - run.correctCount;

  /// 0…1, for the XP bar.
  double get xpProgress =>
      xpToNextLevel == 0 ? 0 : (xpIntoLevel / xpToNextLevel).clamp(0, 1);
}
