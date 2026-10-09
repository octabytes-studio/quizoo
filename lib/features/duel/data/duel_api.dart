import 'dart:math';

import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_round.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The labelled practice-bot duel's endpoints.
///
/// Real player-vs-player duels run on the server (`LiveDuelApi`, plan 017);
/// this is only the fallback Quick match offers after 30 s with nobody
/// around. [fetchBotOpponent] deals a bot — always labelled as one (bible
/// §14) — from a small fixed roster near the player's real ELO;
/// [fetchRoundQuestions] draws the chosen topic's questions, and
/// [submitBotDuel] settles the result server-side.
class DuelApi {
  DuelApi(this._client);

  final SupabaseClient _client;

  /// Questions per duel — the same count as a live duel
  /// (`duel_config.rounds`).
  static const int roundCount = 10;

  static const List<(String name, String emoji)> _botRoster = [
    ('Fennec', '🦊'),
    ('Athena', '🦉'),
    ('Rajah', '🐯'),
    ('Coalie', '🐨'),
    ('Fang', '🐺'),
    ('Talon', '🦅'),
  ];

  /// A bot within roughly ±120 of [playerElo] — a scripted, explicitly
  /// labelled opponent, never a secret one.
  Future<DuelPlayer> fetchBotOpponent({required int playerElo}) async {
    final random = Random();
    final (name, emoji) = _botRoster[random.nextInt(_botRoster.length)];
    final elo = (playerElo + random.nextInt(241) - 120).clamp(400, 2400);
    return DuelPlayer(
      id: 'bot_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      avatarEmoji: emoji,
      elo: elo,
      isBot: true,
    );
  }

  /// Five live questions from the duel's topic ([subcategoryId]) — the same
  /// content pool `start_level_attempt` draws from. The bot duel is
  /// simulated locally, so it needs `correct_index`; a live duel never reads
  /// this table (plan 017, A8/A9).
  Future<List<Question>> fetchRoundQuestions({
    required String subcategoryId,
    required String languageCode,
  }) async {
    try {
      final rows = await _client
          .from('questions')
          .select(
            'id, subcategory_id, difficulty, kind, media_url, figure_svg, '
            'prompt, options, correct_index, explanation, '
            'audio_url, tts_excluded',
          )
          .eq('subcategory_id', subcategoryId)
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
    String? subcategoryId,
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
          'p_subcategory_id': ?subcategoryId,
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
    mediaUrl: row['media_url'] as String?,
    figureSvg: row['figure_svg'] as String?,
    audioUrl: row['audio_url'] as String?,
    ttsExcluded: row['tts_excluded'] as bool? ?? false,
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
