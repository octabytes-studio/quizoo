import 'package:quizoo/core/ladder/ladder_config_repository.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_play/domain/scoring.dart';
import 'package:quizoo/features/quiz_result/data/quiz_result_api.dart';
import 'package:quizoo/features/quiz_result/domain/level_result.dart';

/// Turns a finished [QuizRun] into the [LevelResult] the two result screens
/// render, using the server's authoritative score/stars/coins/xp rather than
/// recomputing them client-side (§19: "the client's own total is display
/// only") — the SQL in `submit_level_attempt` was transcribed from the same
/// `Scoring` formulas specifically so client and server agree during play;
/// this repository is about *which* number becomes the one shown on the
/// result screen, not about the formulas disagreeing.
class QuizResultRepository {
  QuizResultRepository(this._api, this._authRepository, this._ladderConfig);

  final QuizResultApi _api;

  /// Consulted for the save-progress rules, and told when a level is cleared.
  final AuthRepository _authRepository;

  /// Tells us where the ladder ends, so the last level can hide "Next level"
  /// and open the Topic Mastered screen instead (plan 020).
  final LadderConfigRepository _ladderConfig;

  Future<LevelResult> submit(QuizRun run, {required bool isGuest}) async {
    final record = await _api.submit(run);

    if (run.isComplete) {
      // Recorded before the prompt rules are evaluated, because "has the
      // player ever completed a level" must include the one they just
      // finished.
      _authRepository.markLevelCompleted();
    }

    final shouldOffer =
        run.isComplete &&
        _authRepository.shouldOfferSaveProgress(isGuest: isGuest);

    final progress = Scoring.levelProgress(record.totalXp);
    final isFinalLevel = run.levelNumber >= _ladderConfig.totalLevels;

    return LevelResult(
      run: run,
      stars: record.stars,
      finalScore: record.finalScore,
      coinsEarned: record.coinsEarned,
      xpEarned: record.xpEarned,
      playerLevel: record.playerLevel,
      xpIntoLevel: progress.xpIntoLevel,
      xpToNextLevel: progress.xpToNextLevel,
      isFirstClear: record.isFirstClear,
      newlyEarnedBadgeIds: record.newlyEarnedBadgeIds,
      shouldOfferSaveProgress: shouldOffer,
      isFinalLevel: isFinalLevel,
      unlocksMastery: run.isComplete && isFinalLevel && record.isFirstClear,
    );
  }

  /// Marks S-24 as offered so it never appears twice in one session.
  void markSaveProgressShown() => _authRepository.markSaveProgressPromptShown();
}
