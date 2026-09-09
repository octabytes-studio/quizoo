import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/app/connectivity_cubit.dart';
import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_api.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pump_app.dart';

/// A no-op stand-in for the real `AuthApi`/`QuizPlayApi`, per CLAUDE.md §11's
/// convention: tests mock the `*_api.dart` boundary, never a raw
/// `SupabaseClient`. Nothing in `pumpScreen`'s default wiring ever calls a
/// network method on these — they exist only so `AuthRepository`/
/// `QuizPlayRepository` have something to hold.
class FakeAuthApi extends Mock implements AuthApi {}

class FakeQuizPlayApi extends Mock implements QuizPlayApi {}

/// Pumps a screen with the same app-root providers the real app gives it.
///
/// Screens read four things off the root — `SessionCubit`, `AuthRepository`,
/// `QuizPlayRepository` and (plan 004) `ConnectivityCubit` — so a widget test
/// that pumps one without them is testing a different widget than the one
/// that ships.
///
/// A [GoRouter] is stood up too, because these screens navigate: `context.pop`
/// and `context.push` need a router above them, and a bare `MaterialApp` has
/// none.
extension PumpScreen on WidgetTester {
  Future<void> pumpScreen(
    Widget screen, {
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en'),
    bool disableAnimations = false,
    SessionCubit? session,
    AuthRepository? authRepository,
    QuizPlayRepository? quizPlayRepository,
    ConnectivityCubit? connectivity,
  }) async {
    final auth = authRepository ?? await _fakeAuthRepository();

    return pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<QuizPlayRepository>.value(
            value: quizPlayRepository ?? QuizPlayRepository(FakeQuizPlayApi()),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(
              value: session ?? SessionCubit(auth),
            ),
            BlocProvider<ConnectivityCubit>.value(
              value: connectivity ?? ConnectivityCubit(),
            ),
          ],
          child: _RouterHost(child: screen),
        ),
      ),
      brightness: brightness,
      locale: locale,
      disableAnimations: disableAnimations,
    );
  }
}

Future<AuthRepository> _fakeAuthRepository() async {
  SharedPreferences.setMockInitialValues({});
  final api = FakeAuthApi();
  when(() => api.authStateChanges).thenAnswer((_) => const Stream.empty());
  return AuthRepository(api, await SharedPreferences.getInstance());
}

/// A minimal router so the screen under test can navigate without a real one.
class _RouterHost extends StatefulWidget {
  const _RouterHost({required this.child});

  final Widget child;

  @override
  State<_RouterHost> createState() => _RouterHostState();
}

class _RouterHostState extends State<_RouterHost> {
  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => widget.child),
      // Anything the screen pushes lands here, which is enough to assert that
      // it navigated without standing up the whole app.
      GoRoute(
        path: '/:rest(.*)',
        builder: (context, state) =>
            Scaffold(body: Center(child: Text('pushed:${state.uri.path}'))),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Router.withConfig(config: _router);
  }
}
