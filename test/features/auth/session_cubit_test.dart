import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  const user = AuthUser(
    id: 'user_google',
    displayName: 'Waleed',
    provider: AuthProvider.google,
  );

  setUp(() {
    repository = _MockAuthRepository();
    registerFallbackValue(AuthProvider.google);
  });

  group('SessionCubit', () {
    test('starts as a guest, which is a fully playable state', () {
      final cubit = SessionCubit(repository);
      expect(cubit.state, isA<SessionGuest>());
      expect(cubit.isGuest, isTrue);
    });

    blocTest<SessionCubit, SessionState>(
      'success path: a vendor sign-in ends signed in',
      setUp: () {
        when(
          () => repository.signInWithVendor(any()),
        ).thenAnswer((_) async => user);
      },
      build: () => SessionCubit(repository),
      act: (cubit) => cubit.signInWithVendor(AuthProvider.google),
      expect: () => [
        isA<SessionAuthenticating>(),
        isA<SessionSignedIn>().having(
          (state) => state.user.displayName,
          'name',
          'Waleed',
        ),
      ],
    );

    blocTest<SessionCubit, SessionState>(
      'failure path: a failed sign-in leaves the player playable',
      setUp: () {
        when(
          () => repository.signInWithVendor(any()),
        ).thenThrow(const ApiException.network());
      },
      build: () => SessionCubit(repository),
      act: (cubit) => cubit.signInWithVendor(AuthProvider.apple),
      expect: () => [isA<SessionAuthenticating>(), isA<SessionFailure>()],
    );

    blocTest<SessionCubit, SessionState>(
      'the email route arrives with no profile yet, so S-25 is still needed',
      setUp: () {
        when(() => repository.startEmailSignIn()).thenAnswer(
          (_) async => const AuthUser(
            id: 'user_email',
            displayName: '',
            provider: AuthProvider.email,
            isProfileComplete: false,
          ),
        );
      },
      build: () => SessionCubit(repository),
      act: (cubit) => cubit.startEmailSignIn(),
      expect: () => [
        isA<SessionAuthenticating>(),
        isA<SessionSignedIn>().having(
          (state) => state.user.isProfileComplete,
          'isProfileComplete',
          isFalse,
        ),
      ],
    );

    blocTest<SessionCubit, SessionState>(
      'declining drops back to guest rather than to an error',
      build: () => SessionCubit(repository),
      seed: () => const SessionSignedIn(user),
      act: (cubit) => cubit.continueAsGuest(),
      expect: () => [isA<SessionGuest>()],
    );
  });

  group('AuthRepository save-progress rules', () {
    test('offers the sheet only after a completed level, and only once', () {
      // The flags are pure in-memory bookkeeping, so a real API instance is
      // fine here — nothing below is ever called.
      final repository = AuthRepository(AuthApi());

      // Nothing completed yet: never offered, guest or not.
      expect(repository.shouldOfferSaveProgress(isGuest: true), isFalse);

      repository.markLevelCompleted();
      expect(repository.shouldOfferSaveProgress(isGuest: true), isTrue);

      // Never to a signed-in player — there is nothing to convert.
      expect(repository.shouldOfferSaveProgress(isGuest: false), isFalse);

      repository.markSaveProgressPromptShown();
      expect(repository.shouldOfferSaveProgress(isGuest: true), isFalse);
    });
  });
}
