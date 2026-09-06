import 'package:quizoo/core/mock/mock_player.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_play/domain/scoring.dart';
import 'package:quizoo/features/quiz_result/data/quiz_result_api.dart';
import 'package:quizoo/features/quiz_result/domain/level_result.dart';

/// Turns a finished [QuizRun] into the [LevelResult] the two result screens
/// render, and records what the run changed.
class QuizResultRepository {
  QuizResultRepository(this._api, this._authRepository);

  final QuizResultApi _api;

  /// Consulted for the save-progress rules, and told when a level is cleared.
  final AuthRepository _authRepository;

  Future<LevelResult> submit(QuizRun run, {required bool isGuest}) async {
    final record = await _api.submit(run);

    final stars = run.isComplete ? Scoring.stars(run.correctCount) : 0;
    final finalScore = run.isComplete ? Scoring.total(run) : run.score;

    if (run.isComplete) {
      // Recorded before the prompt rules are evaluated, because "has the
      // player ever completed a level" must include the one they just
      // finished.
      _authRepository.markLevelCompleted();
    }

    final shouldOffer =
        run.isComplete &&
        _authRepository.shouldOfferSaveProgress(isGuest: isGuest);

    return LevelResult(
      run: run,
      stars: stars,
      finalScore: finalScore,
      coinsEarned: run.isComplete
          ? Scoring.coinsEarned(
              levelNumber: run.levelNumber,
              stars: stars,
              isBoss: run.isBoss,
            )
          : 0,
      xpEarned: run.isComplete
          ? Scoring.xpEarned(
              levelNumber: run.levelNumber,
              stars: stars,
              isFirstClear: record.isFirstClear,
            )
          : 0,
      playerLevel: MockPlayer.playerLevel,
      xpIntoLevel: MockPlayer.xpIntoLevel,
      xpToNextLevel: Scoring.xpToNextLevel(MockPlayer.playerLevel),
      isFirstClear: record.isFirstClear,
      newlyEarnedBadgeIds: record.newlyEarnedBadgeIds,
      shouldOfferSaveProgress: shouldOffer,
    );
  }

  /// Marks S-24 as offered so it never appears twice in one session.
  void markSaveProgressShown() => _authRepository.markSaveProgressPromptShown();
}
