import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
}
