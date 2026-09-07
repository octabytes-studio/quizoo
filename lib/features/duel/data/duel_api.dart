import 'dart:math';

import 'package:quizoo/core/mock/mock_api.dart';
import 'package:quizoo/features/duel/domain/duel_opponent.dart';
import 'package:quizoo/features/quiz_play/data/mock_questions.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';

/// The mocked duel endpoints.
///
/// There is no real matchmaking server (plan 004, Scope) — [fetchBotOpponent]
/// always deals a bot, explicitly labelled as one, drawn from a small fixed
/// roster rather than pretending to be a person the bible's "never a secret
/// bot" rule forbids.
class DuelApi extends MockApi {
  DuelApi({
    super.minLatency,
    super.maxLatency,
    super.failureRate,
    super.random,
  });

  /// Best-of-5 (§14).
  static const int roundCount = 5;

  static const List<(String name, String emoji)> _botRoster = [
    ('Fennec', '🦊'),
    ('Athena', '🦉'),
    ('Rajah', '🐯'),
    ('Coalie', '🐨'),
    ('Fang', '🐺'),
    ('Talon', '🦅'),
  ];

  /// A bot within roughly ±120 of [playerElo] — the mock stand-in for
  /// `MatchmakingCubit`'s widening ELO-band search.
  Future<DuelOpponent> fetchBotOpponent({required int playerElo}) =>
      respond(() {
        final random = Random();
        final (name, emoji) = _botRoster[random.nextInt(_botRoster.length)];
        final elo = (playerElo + random.nextInt(241) - 120).clamp(400, 2400);
        return DuelOpponent(
          id: 'bot_${DateTime.now().microsecondsSinceEpoch}',
          name: name,
          avatarEmoji: emoji,
          elo: elo,
        );
      });

  /// Five questions for the duel — the same authored Football pool
  /// `features/quiz_play` draws from (plan 002's Assumption 4 fixture),
  /// reused rather than duplicated, shuffled with a fixed seed so a duel's
  /// question order is stable across a single mocked session.
  Future<List<Question>> fetchRoundQuestions() => respond(() {
    final pool = [...MockQuestions.football]..shuffle(Random(7));
    return pool.take(roundCount).toList();
  });
}
