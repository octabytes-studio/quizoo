import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_api.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_round.dart';
import 'package:quizoo/features/quiz_play/data/mock_questions.dart';

class _MockDuelApi extends Mock implements DuelApi {}

void main() {
  late _MockDuelApi api;
  late DuelRepository repository;

  const bot = DuelPlayer(
    id: 'bot_1',
    name: 'Fox',
    avatarEmoji: '🦊',
    elo: 1200,
    isBot: true,
  );

  const rounds = [
    DuelRoundRecord(
      roundNumber: 1,
      playerCorrect: true,
      opponentCorrect: false,
      playerAnswerSeconds: 3,
      opponentAnswerSeconds: 7,
      outcome: RoundOutcome.playerWon,
    ),
  ];

  const record = BotDuelRecord(
    eloBefore: 1240,
    eloAfter: 1256,
    coinsEarned: 200,
    newlyEarnedBadgeIds: ['badge_duelist'],
  );

  setUp(() {
    api = _MockDuelApi();
    repository = DuelRepository(api);
  });

  void stubSubmit() {
    when(
      () => api.submitBotDuel(
        opponentElo: any(named: 'opponentElo'),
        playerRoundsWon: any(named: 'playerRoundsWon'),
        opponentRoundsWon: any(named: 'opponentRoundsWon'),
        rounds: any(named: 'rounds'),
        subcategoryId: any(named: 'subcategoryId'),
      ),
    ).thenAnswer((_) async => record);
  }

  group('DuelRepository', () {
    test('success path: hands back the labelled bot unchanged', () async {
      when(
        () => api.fetchBotOpponent(playerElo: any(named: 'playerElo')),
      ).thenAnswer((_) async => bot);

      final result = await repository.fetchBotOpponent(playerElo: 1240);

      verify(() => api.fetchBotOpponent(playerElo: 1240)).called(1);
      expect(result, bot);
      expect(result.isBot, isTrue);
    });

    test('failure path: the API\'s ApiException reaches the caller', () async {
      when(
        () => api.fetchBotOpponent(playerElo: any(named: 'playerElo')),
      ).thenThrow(const ApiException.network());

      expect(
        () => repository.fetchBotOpponent(playerElo: 1240),
        throwsA(isA<ApiException>()),
      );
    });

    test('fetches the chosen topic\'s round questions', () async {
      final questions = MockQuestions.football.take(5).toList();
      when(
        () => api.fetchRoundQuestions(
          subcategoryId: any(named: 'subcategoryId'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => questions);

      final result = await repository.fetchRoundQuestions(
        subcategoryId: 'sub-cricket',
        languageCode: 'en',
      );

      verify(
        () => api.fetchRoundQuestions(
          subcategoryId: 'sub-cricket',
          languageCode: 'en',
        ),
      ).called(1);
      expect(result, questions);
    });

    test('submitBotDuel forwards the topic and returns the server '
        'record', () async {
      stubSubmit();

      final result = await repository.submitBotDuel(
        opponentElo: 1200,
        playerRoundsWon: 3,
        opponentRoundsWon: 1,
        rounds: rounds,
        subcategoryId: 'sub-cricket',
      );

      verify(
        () => api.submitBotDuel(
          opponentElo: 1200,
          playerRoundsWon: 3,
          opponentRoundsWon: 1,
          rounds: rounds,
          subcategoryId: 'sub-cricket',
        ),
      ).called(1);
      expect(result, same(record));
    });

    test('submitBotDuel without a topic forwards null', () async {
      stubSubmit();

      await repository.submitBotDuel(
        opponentElo: 1200,
        playerRoundsWon: 2,
        opponentRoundsWon: 2,
        rounds: rounds,
      );

      final captured = verify(
        () => api.submitBotDuel(
          opponentElo: any(named: 'opponentElo'),
          playerRoundsWon: any(named: 'playerRoundsWon'),
          opponentRoundsWon: any(named: 'opponentRoundsWon'),
          rounds: any(named: 'rounds'),
          subcategoryId: captureAny(named: 'subcategoryId'),
        ),
      ).captured;
      expect(captured, [null]);
    });

    test(
      'submitBotDuel failure: the ApiException reaches the caller',
      () async {
        const error = ApiException('boom', code: 'not_authenticated');
        when(
          () => api.submitBotDuel(
            opponentElo: any(named: 'opponentElo'),
            playerRoundsWon: any(named: 'playerRoundsWon'),
            opponentRoundsWon: any(named: 'opponentRoundsWon'),
            rounds: any(named: 'rounds'),
            subcategoryId: any(named: 'subcategoryId'),
          ),
        ).thenAnswer((_) async => throw error);

        await expectLater(
          repository.submitBotDuel(
            opponentElo: 1200,
            playerRoundsWon: 3,
            opponentRoundsWon: 1,
            rounds: rounds,
            subcategoryId: 'sub-cricket',
          ),
          throwsA(same(error)),
        );
      },
    );
  });
}
