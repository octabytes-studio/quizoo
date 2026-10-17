import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthApi extends Mock implements AuthApi {}

void main() {
  group('AuthRepository.updateProfile', () {
    late _MockAuthApi api;
    late AuthRepository repository;

    setUp(() async {
      api = _MockAuthApi();
      SharedPreferences.setMockInitialValues({});
      repository = AuthRepository(api, await SharedPreferences.getInstance());
    });

    test(
      'passes through to AuthApi.updateProfile and returns its result',
      () async {
        const updated = AuthUser(
          id: 'user_google',
          displayName: 'NewName',
          provider: AuthProvider.google,
          avatarEmoji: '🐸',
        );
        when(
          () => api.updateProfile(username: 'NewName', avatarEmoji: '🐸'),
        ).thenAnswer((_) async => updated);

        final result = await repository.updateProfile(
          username: 'NewName',
          avatarEmoji: '🐸',
        );

        expect(result, updated);
        verify(
          () => api.updateProfile(username: 'NewName', avatarEmoji: '🐸'),
        ).called(1);
      },
    );
  });

  group('AuthRepository.deleteAccount', () {
    late _MockAuthApi api;
    late AuthRepository repository;

    setUp(() async {
      api = _MockAuthApi();
      SharedPreferences.setMockInitialValues({});
      repository = AuthRepository(api, await SharedPreferences.getInstance());
    });

    test('delegates to AuthApi.deleteAccount', () async {
      when(() => api.deleteAccount()).thenAnswer((_) async {});

      await repository.deleteAccount();

      verify(() => api.deleteAccount()).called(1);
    });

    test('propagates the typed ApiException unchanged', () {
      when(() => api.deleteAccount()).thenThrow(const ApiException.network());

      expect(
        () => repository.deleteAccount(),
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
