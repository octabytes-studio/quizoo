import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/safety/domain/blocked_player.dart';
import 'package:quizoo/core/safety/safety_api.dart';
import 'package:quizoo/core/safety/safety_repository.dart';

class _MockSafetyApi extends Mock implements SafetyApi {}

void main() {
  late _MockSafetyApi api;
  late SafetyRepository repository;

  setUp(() {
    api = _MockSafetyApi();
    repository = SafetyRepository(api);
  });

  group('SafetyRepository', () {
    test('blockedIds passes the API set straight through', () async {
      when(() => api.blockedIds()).thenAnswer((_) async => {'user_a'});

      expect(await repository.blockedIds(), {'user_a'});
    });

    test('block/unblock delegate to the API', () async {
      when(() => api.block('user_a')).thenAnswer((_) async {});
      when(() => api.unblock('user_a')).thenAnswer((_) async {});

      await repository.block('user_a');
      await repository.unblock('user_a');

      verify(() => api.block('user_a')).called(1);
      verify(() => api.unblock('user_a')).called(1);
    });

    test('reportPlayer delegates with the reason code', () async {
      when(
        () => api.reportPlayer(
          playerId: any(named: 'playerId'),
          reason: any(named: 'reason'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async {});

      await repository.reportPlayer(playerId: 'user_a', reason: 'harassment');

      verify(
        () => api.reportPlayer(
          playerId: 'user_a',
          reason: 'harassment',
          note: null,
        ),
      ).called(1);
    });

    test('blockedPlayers maps rows to domain models', () async {
      when(() => api.blockedPlayers()).thenAnswer(
        (_) async => [
          BlockedPlayer(
            id: 'user_a',
            name: 'Ali',
            avatarEmoji: '🦊',
            blockedAt: DateTime(2026, 10, 17),
          ),
        ],
      );

      final players = await repository.blockedPlayers();

      expect(players, hasLength(1));
      expect(players.single.name, 'Ali');
      expect(players.single.id, 'user_a');
    });

    test('error-mapping path: the typed exception reaches the caller', () {
      when(() => api.blockedIds()).thenThrow(const ApiException.network());

      expect(
        repository.blockedIds,
        throwsA(
          isA<ApiException>().having(
            (error) => error.kind,
            'kind',
            ApiErrorKind.network,
          ),
        ),
      );
    });
  });
}
