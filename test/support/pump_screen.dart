import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_api.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';

import 'pump_app.dart';

/// Pumps a screen with the same app-root providers the real app gives it.
///
/// Screens in plan 002 read three things off the root — `SessionCubit`,
/// `AuthRepository` and `QuizPlayRepository` — so a widget test that pumps one
/// without them is testing a different widget than the one that ships.
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
  }) {
    final auth = authRepository ?? AuthRepository(AuthApi());

    return pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<QuizPlayRepository>.value(
            value: quizPlayRepository ?? QuizPlayRepository(QuizPlayApi()),
          ),
        ],
        child: BlocProvider<SessionCubit>.value(
          value: session ?? SessionCubit(auth),
          child: _RouterHost(child: screen),
        ),
      ),
      brightness: brightness,
      locale: locale,
      disableAnimations: disableAnimations,
    );
  }
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
