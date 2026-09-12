import 'package:quizoo/features/duel/data/duel_api.dart';
import 'package:quizoo/features/duel/domain/duel_opponent.dart';
import 'package:quizoo/features/duel/domain/duel_round.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';

/// The only thing that talks to [DuelApi].
class DuelRepository {
  DuelRepository(this._api);

  final DuelApi _api;

  Future<DuelOpponent> fetchBotOpponent({required int playerElo}) =>
      _api.fetchBotOpponent(playerElo: playerElo);

  Future<List<Question>> fetchRoundQuestions({required String languageCode}) =>
      _api.fetchRoundQuestions(languageCode: languageCode);

  Future<BotDuelRecord> submitBotDuel({
    required int opponentElo,
    required int playerRoundsWon,
    required int opponentRoundsWon,
    required List<DuelRoundRecord> rounds,
  }) => _api.submitBotDuel(
    opponentElo: opponentElo,
    playerRoundsWon: playerRoundsWon,
    opponentRoundsWon: opponentRoundsWon,
    rounds: rounds,
  );
}
