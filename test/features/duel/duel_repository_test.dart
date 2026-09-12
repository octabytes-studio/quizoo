import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_api.dart';
import 'package:quizoo/features/duel/data/duel_repository.dart';
import 'package:quizoo/features/duel/domain/duel_opponent.dart';
import 'package:quizoo/features/quiz_play/data/mock_questions.dart';

class _MockDuelApi extends Mock implements DuelApi {}

void main() {
  late _MockDuelApi api;
  late DuelRepository repository;

  const bot = DuelOpponent(
    id: 'bot_1',
    name: 'Fox',
    avatarEmoji: '🦊',
    elo: 1200,
  );

  setUp(() {
    api = _MockDuelApi();
    repository = DuelRepository(api);
  });

  group('DuelRepository', () {
    test('success path: hands back the bot opponent unchanged', () async {
      when(
        () => api.fetchBotOpponent(playerElo: any(named: 'playerElo')),
      ).thenAnswer((_) async => bot);

      final result = await repository.fetchBotOpponent(playerElo: 1240);

      expect(result, bot);
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

    test('fetches the duel\'s round questions', () async {
      final questions = MockQuestions.football.take(5).toList();
      when(
        () => api.fetchRoundQuestions(languageCode: any(named: 'languageCode')),
      ).thenAnswer((_) async => questions);

      final result = await repository.fetchRoundQuestions(languageCode: 'en');

      expect(result, questions);
    });
  });
}
