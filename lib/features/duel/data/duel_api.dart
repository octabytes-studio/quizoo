import 'dart:math';

import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/domain/duel_opponent.dart';
import 'package:quizoo/features/duel/domain/duel_round.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The real duel endpoints.
///
/// There is still no real matchmaking server (plan 006, Assumption #3) —
/// [fetchBotOpponent] keeps dealing a bot, explicitly labelled as one, from
/// the same small fixed roster; only [fetchRoundQuestions] and
/// [submitBotDuel] talk to Supabase now. `playerElo` here still comes from
/// whatever the caller passes in (`matchmaking_screen.dart`'s constant) —
/// threading `profiles.elo` all the way up into that screen's construction
/// is flagged as a follow-up, not resolved by this rewrite, to keep this
/// change contained to the data layer.
class DuelApi {
  DuelApi(this._client);

  final SupabaseClient _client;

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

  /// A bot within roughly ±120 of [playerElo] — still a scripted opponent,
  /// not a real matchmaking search (plan 006, Assumption #3).
  Future<DuelOpponent> fetchBotOpponent({required int playerElo}) async {
    final random = Random();
    final (name, emoji) = _botRoster[random.nextInt(_botRoster.length)];
    final elo = (playerElo + random.nextInt(241) - 120).clamp(400, 2400);
    return DuelOpponent(
      id: 'bot_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      avatarEmoji: emoji,
      elo: elo,
    );
  }

  /// Five live questions for the duel — the same content pool
  /// `start_level_attempt` draws from, reused rather than duplicated. Only
  /// Football has seeded content today, so this pulls from there directly
  /// until more topics exist (plan 006, Design overview); Football only
  /// exists under the English category today, so a non-English duel
  /// currently finds no subcategory and deals nothing, same as any other
  /// as-yet-unauthored topic.
  Future<List<Question>> fetchRoundQuestions({
    required String languageCode,
  }) async {
    try {
      final subcategoryRow = await _client
          .from('subcategories')
          .select('id, categories!inner(language_code)')
          .eq('slug', 'football')
          .eq('categories.language_code', languageCode)
          .maybeSingle();
      if (subcategoryRow == null) return const [];

      final rows = await _client
          .from('questions')
          .select(
            'id, subcategory_id, difficulty, kind, media_url, '
            'prompt, options, correct_index, explanation',
          )
          .eq('subcategory_id', subcategoryRow['id'] as String)
          .eq('status', 'live')
          .eq('language_code', languageCode);

      final questions = [for (final row in rows) _questionFromRow(row)]
        ..shuffle(Random());
      return questions.take(roundCount).toList();
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// Persists a finished bot duel via `submit_bot_duel` (functions
  /// migration) — the one change plan 006 Phase 5 makes to the duel flow:
  /// the result is saved for real, rather than vanishing on next launch.
  Future<BotDuelRecord> submitBotDuel({
    required int opponentElo,
    required int playerRoundsWon,
    required int opponentRoundsWon,
    required List<DuelRoundRecord> rounds,
  }) async {
    try {
      final response = await _client.rpc<Map<String, dynamic>>(
        'submit_bot_duel',
        params: {
          'p_opponent_elo': opponentElo,
          'p_player_rounds_won': playerRoundsWon,
          'p_opponent_rounds_won': opponentRoundsWon,
          'p_rounds': [
            for (final round in rounds)
              {
                'roundNumber': round.roundNumber,
                'playerCorrect': round.playerCorrect,
                'playerAnswerSeconds': round.playerAnswerSeconds,
              },
          ],
        },
      );
      return BotDuelRecord(
        eloBefore: response['eloBefore'] as int,
        eloAfter: response['eloAfter'] as int,
        coinsEarned: response['coinsEarned'] as int,
        newlyEarnedBadgeIds:
            (response['newlyEarnedBadgeIds'] as List? ?? const [])
                .cast<String>(),
      );
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  static Question _questionFromRow(Map<String, dynamic> row) => Question(
    id: row['id'] as String,
    subcategoryId: row['subcategory_id'] as String,
    difficulty: row['difficulty'] as int,
    text: row['prompt'] as String,
    options: (row['options'] as List).cast<String>(),
    correctIndex: row['correct_index'] as int,
    explanation: row['explanation'] as String,
    hasImage: row['kind'] == 'image',
    imageAsset: row['media_url'] as String?,
  );
}

/// What the server settled a bot duel to — authoritative ELO/coins, per
/// `submit_bot_duel`'s response.
class BotDuelRecord {
  const BotDuelRecord({
    required this.eloBefore,
    required this.eloAfter,
    required this.coinsEarned,
    required this.newlyEarnedBadgeIds,
  });

  final int eloBefore;
  final int eloAfter;
  final int coinsEarned;
  final List<String> newlyEarnedBadgeIds;
}
