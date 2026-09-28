import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/domain/auth_user.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Session, User;

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAuthApi extends Mock implements AuthApi {}

/// A signed-in (non-anonymous) session — what a real OAuth deep link hands
/// `authStateChanges` once it lands.
Session _fakeSession({Map<String, dynamic> userMetadata = const {}}) => Session(
  accessToken: 'token',
  tokenType: 'bearer',
  user: User(
    id: 'user_google',
    appMetadata: const {'provider': 'google'},
    userMetadata: userMetadata,
    aud: 'authenticated',
    createdAt: DateTime(2026).toIso8601String(),
  ),
);

void main() {
  late _MockAuthRepository repository;
  late StreamController<AuthState> authStateController;

  const user = AuthUser(
    id: 'user_google',
    displayName: 'Waleed',
    provider: AuthProvider.google,
  );

  setUp(() {
    repository = _MockAuthRepository();
    registerFallbackValue(AuthProvider.google);
    // `SessionCubit`'s constructor subscribes to this immediately, to react
    // to a vendor OAuth deep link landing back in the app.
    authStateController = StreamController<AuthState>.broadcast();
    when(
      () => repository.authStateChanges,
    ).thenAnswer((_) => authStateController.stream);
    // Dismisses the vendor OAuth browser sheet once the deep link lands —
    // every test that drives `authStateController` needs this stubbed.
    when(() => repository.closeVendorSignInBrowser()).thenAnswer((_) async {});
  });

  tearDown(() => authStateController.close());

  group('SessionCubit', () {
    test('starts as a guest, which is a fully playable state', () {
      final cubit = SessionCubit(repository);
      expect(cubit.state, isA<SessionGuest>());
      expect(cubit.isGuest, isTrue);
    });

    blocTest<SessionCubit, SessionState>(
      'success path: a vendor sign-in ends signed in once the OAuth deep '
      'link lands',
      setUp: () {
        when(() => repository.signInWithVendor(any())).thenAnswer((_) async {});
        when(
          () => repository.restoreSignedInUser(),
        ).thenAnswer((_) async => user);
      },
      build: () => SessionCubit(repository),
      act: (cubit) async {
        await cubit.signInWithVendor(AuthProvider.google);
        authStateController.add(
          AuthState(AuthChangeEvent.signedIn, _fakeSession()),
        );
        await Future<void>.delayed(Duration.zero);
      },
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
      "a vendor sign-in with an incomplete profile carries the vendor's own "
      'suggested display name through to SessionSignedIn (plan 015)',
      setUp: () {
        when(() => repository.signInWithVendor(any())).thenAnswer((_) async {});
        when(() => repository.restoreSignedInUser()).thenAnswer(
          (_) async => const AuthUser(
            id: 'user_google',
            displayName: '',
            provider: AuthProvider.google,
            isProfileComplete: false,
            suggestedDisplayName: 'Waleed Shah',
          ),
        );
      },
      build: () => SessionCubit(repository),
      act: (cubit) async {
        await cubit.signInWithVendor(AuthProvider.google);
        authStateController.add(
          AuthState(
            AuthChangeEvent.signedIn,
            _fakeSession(userMetadata: const {'full_name': 'Waleed Shah'}),
          ),
        );
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        isA<SessionAuthenticating>(),
        isA<SessionSignedIn>().having(
          (state) => state.user.suggestedDisplayName,
          'suggestedDisplayName',
          'Waleed Shah',
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
      'failure path: a rejected OAuth code exchange (a deep-link-time '
      'stream error, not a launch-time exception) still ends in '
      'SessionFailure rather than hanging forever',
      setUp: () {
        when(() => repository.signInWithVendor(any())).thenAnswer((_) async {});
      },
      build: () => SessionCubit(repository),
      act: (cubit) async {
        await cubit.signInWithVendor(AuthProvider.apple);
        authStateController.addError(
          const ApiException('Unable to exchange external code'),
        );
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [isA<SessionAuthenticating>(), isA<SessionFailure>()],
      verify: (_) {
        verify(() => repository.closeVendorSignInBrowser()).called(1);
      },
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

    blocTest<SessionCubit, SessionState>(
      'success path: signing out invalidates the session and drops back to '
      'guest',
      setUp: () {
        when(() => repository.signOut()).thenAnswer((_) async {});
      },
      build: () => SessionCubit(repository),
      seed: () => const SessionSignedIn(user),
      act: (cubit) => cubit.signOut(),
      expect: () => [isA<SessionGuest>()],
    );

    blocTest<SessionCubit, SessionState>(
      'failure path: a failed sign-out rethrows and leaves the player '
      'signed in rather than silently dropping to guest',
      setUp: () {
        when(
          () => repository.signOut(),
        ).thenThrow(const ApiException.network());
      },
      build: () => SessionCubit(repository),
      seed: () => const SessionSignedIn(user),
      act: (cubit) => cubit.signOut(),
      expect: () => <SessionState>[],
      errors: () => [isA<ApiException>()],
    );

    blocTest<SessionCubit, SessionState>(
      'success path: Edit Profile saves the new username/avatar directly '
      'into SessionSignedIn, with no SessionAuthenticating step',
      setUp: () {
        when(
          () => repository.updateProfile(
            username: any(named: 'username'),
            avatarEmoji: any(named: 'avatarEmoji'),
          ),
        ).thenAnswer(
          (_) async => const AuthUser(
            id: 'user_google',
            displayName: 'NewName',
            provider: AuthProvider.google,
            avatarEmoji: '🐸',
          ),
        );
      },
      build: () => SessionCubit(repository),
      seed: () => const SessionSignedIn(user),
      act: (cubit) =>
          cubit.updateProfile(username: 'NewName', avatarEmoji: '🐸'),
      expect: () => [
        isA<SessionSignedIn>().having(
          (state) => state.user.displayName,
          'name',
          'NewName',
        ),
      ],
    );

    blocTest<SessionCubit, SessionState>(
      'failure path: a failed Edit Profile save rethrows and leaves the '
      'player signed in exactly as before, like signOut',
      setUp: () {
        when(
          () => repository.updateProfile(
            username: any(named: 'username'),
            avatarEmoji: any(named: 'avatarEmoji'),
          ),
        ).thenThrow(const ApiException.network());
      },
      build: () => SessionCubit(repository),
      seed: () => const SessionSignedIn(user),
      act: (cubit) =>
          cubit.updateProfile(username: 'NewName', avatarEmoji: '🐸'),
      expect: () => <SessionState>[],
      errors: () => [isA<ApiException>()],
    );
  });

  group('AuthRepository save-progress rules', () {
    test(
      'offers the sheet only after a completed level, and only once',
      () async {
        // The flags are backed by shared_preferences now, not a network
        // call — nothing on `AuthApi` is ever called here.
        SharedPreferences.setMockInitialValues({});
        final repository = AuthRepository(
          _MockAuthApi(),
          await SharedPreferences.getInstance(),
        );

        // Nothing completed yet: never offered, guest or not.
        expect(repository.shouldOfferSaveProgress(isGuest: true), isFalse);

        repository.markLevelCompleted();
        expect(repository.shouldOfferSaveProgress(isGuest: true), isTrue);

        // Never to a signed-in player — there is nothing to convert.
        expect(repository.shouldOfferSaveProgress(isGuest: false), isFalse);

        repository.markSaveProgressPromptShown();
        expect(repository.shouldOfferSaveProgress(isGuest: true), isFalse);
      },
    );
  });
}
