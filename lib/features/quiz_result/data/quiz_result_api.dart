import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The real "submit this run" endpoint, over `submit_level_attempt`
/// (functions migration) — the server recomputes score from the answer log
/// rather than trusting [QuizRun.score] (§19: "the client's own total is
/// display only").
class QuizResultApi {
  QuizResultApi(this._client);

  final SupabaseClient _client;

  Future<RunRecord> submit(QuizRun run) async {
    try {
      final response = await _client.rpc<Map<String, dynamic>>(
        'submit_level_attempt',
        params: {
          'p_attempt_id': run.attemptId,
          'p_answers': [
            for (final answer in run.answers)
              {
                'questionId': answer.question.id,
                'chosenIndex': answer.chosenIndex,
                'secondsLeft': answer.secondsLeft,
                'action': switch (answer.outcome) {
                  AnswerOutcome.timedOut => 'timedOut',
                  _ => 'answered',
                },
              },
          ],
          'p_used_power_up': run.usedPowerUp,
          'p_ending': switch (run.ending) {
            RunEnding.finished => 'finished',
            RunEnding.outOfHearts => 'outOfHearts',
            RunEnding.quit => 'quit',
            RunEnding.inProgress => throw StateError(
              'cannot submit an in-progress run',
            ),
          },
        },
      );

      final totalXp = await _fetchTotalXp();
      return RunRecord.fromResponse(response, totalXp: totalXp);
    } on PostgrestException catch (error) {
      // A retried network call after a timeout that actually succeeded
      // server-side — treat "already have a result" as success, not a hard
      // failure (plan 005's Edge cases).
      if (error.message.contains('attempt_already_submitted')) {
        return _fetchExistingRecord(run.attemptId);
      }
      throw ApiException.fromSupabase(error);
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  Future<RunRecord> _fetchExistingRecord(String attemptId) async {
    try {
      final row = await _client
          .from('level_attempts')
          .select('server_score, stars, correct_count, user_id')
          .eq('id', attemptId)
          .single();
      final profileRow = await _client
          .from('profiles')
          .select('player_level, xp')
          .eq('id', row['user_id'] as String)
          .single();
      return RunRecord(
        isFirstClear: false,
        finalScore: row['server_score'] as int? ?? 0,
        stars: row['stars'] as int? ?? 0,
        coinsEarned: 0,
        xpEarned: 0,
        playerLevel: profileRow['player_level'] as int? ?? 1,
        totalXp: profileRow['xp'] as int? ?? 0,
        newlyEarnedBadgeIds: const [],
      );
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  Future<int> _fetchTotalXp() async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('profiles')
        .select('xp')
        .eq('id', userId)
        .single();
    return row['xp'] as int? ?? 0;
  }
}

/// What the server computed for a submitted run — authoritative, per §19:
/// "the client's own total is display only".
class RunRecord {
  const RunRecord({
    required this.isFirstClear,
    required this.finalScore,
    required this.stars,
    required this.coinsEarned,
    required this.xpEarned,
    required this.playerLevel,
    required this.totalXp,
    required this.newlyEarnedBadgeIds,
  });

  factory RunRecord.fromResponse(
    Map<String, dynamic> response, {
    required int totalXp,
  }) => RunRecord(
    isFirstClear: response['isFirstClear'] as bool? ?? false,
    finalScore: response['finalScore'] as int? ?? 0,
    stars: response['stars'] as int? ?? 0,
    coinsEarned: response['coinsEarned'] as int? ?? 0,
    xpEarned: response['xpEarned'] as int? ?? 0,
    playerLevel: response['playerLevel'] as int? ?? 1,
    totalXp: totalXp,
    newlyEarnedBadgeIds: (response['newlyEarnedBadgeIds'] as List? ?? const [])
        .cast<String>(),
  );

  final bool isFirstClear;
  final int finalScore;
  final int stars;
  final int coinsEarned;
  final int xpEarned;
  final int playerLevel;

  /// The player's total XP after this run — [QuizResultRepository] derives
  /// `xpIntoLevel`/`xpToNextLevel` from this, since the RPC only returns the
  /// level, not where inside it the player sits.
  final int totalXp;
  final List<String> newlyEarnedBadgeIds;
}
