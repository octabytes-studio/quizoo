import 'package:quizoo/core/mock/mock_api.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';

/// The mocked "submit this run" endpoint.
///
/// A real backend recomputes the score from the answer log and returns the
/// authoritative tally (§19: "the client's own total is display only"). This
/// stands in for that round trip, and returns the two things only a server
/// could know: whether this was a first clear, and which achievements it
/// unlocked.
class QuizResultApi extends MockApi {
  QuizResultApi({
    super.minLatency,
    super.maxLatency,
    super.failureRate,
    super.random,
  });

  /// Submitting is fast — the result screen's payout animation should never
  /// be waiting on it.
  static const Duration submitLatency = Duration(milliseconds: 120);

  Future<RunRecord> submit(QuizRun run) => respond(latency: submitLatency, () {
    final subcategory = MockCatalog.subcategories
        .where((candidate) => candidate.id == run.subcategoryId)
        .firstOrNull;

    return RunRecord(
      // A level beyond the topic's cleared count has never been finished.
      isFirstClear:
          run.isComplete && run.levelNumber > (subcategory?.levelsCleared ?? 0),
      newlyEarnedBadgeIds: _badgesFor(run),
    );
  });

  /// The mock achievement rules — a small, honest subset of §13's grid.
  static List<String> _badgesFor(QuizRun run) {
    if (!run.isComplete) return const [];
    return [
      // "Finish a level with 20/20 correct answers."
      if (run.isFlawless) 'badge_sharpshooter',
      // A long streak inside a single level.
      if (run.longestStreak >= 10) 'badge_on_fire',
      // Cleared a boss level.
      if (run.isBoss) 'badge_boss_slayer',
    ];
  }
}

/// What the server knows about a submitted run that the client does not.
class RunRecord {
  const RunRecord({
    required this.isFirstClear,
    required this.newlyEarnedBadgeIds,
  });

  final bool isFirstClear;
  final List<String> newlyEarnedBadgeIds;
}
