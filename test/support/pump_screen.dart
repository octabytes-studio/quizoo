import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/app/ads_cubit.dart';
import 'package:quizoo/app/connectivity_cubit.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/ads/inline_ad_service.dart';
import 'package:quizoo/core/content_language/content_language_api.dart';
import 'package:quizoo/core/content_language/content_language_repository.dart';
import 'package:quizoo/core/ladder/ladder_config_api.dart';
import 'package:quizoo/core/ladder/ladder_config_repository.dart';
import 'package:quizoo/core/models/difficulty_tier.dart';
import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/duel/data/duel_realtime.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_api.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_ads.dart';
import 'pump_app.dart';

/// A no-op stand-in for the real `AuthApi`/`QuizPlayApi`/`ContentLanguageApi`,
/// per CLAUDE.md §11's convention: tests mock the `*_api.dart` boundary,
/// never a raw `SupabaseClient`. Nothing in `pumpScreen`'s default wiring ever
/// calls a network method on these — they exist only so `AuthRepository`/
/// `QuizPlayRepository`/`ContentLanguageRepository` have something to hold.
class FakeAuthApi extends Mock implements AuthApi {}

class FakeQuizPlayApi extends Mock implements QuizPlayApi {}

class FakeContentLanguageApi extends Mock implements ContentLanguageApi {}

/// A stand-in for the real `LadderConfigApi`, stubbed to the seeded 30-level,
/// 3-tier ladder (plan 020) so any screen that reads `LadderConfigRepository`
/// sees the same tiers the live app does.
class FakeLadderConfigApi extends Mock implements LadderConfigApi {}

/// A stand-in for the app-root `DuelRealtime` (plan 017). Duel screen tests
/// inject a mocked repository or Bloc instead of opening real channels, so
/// nothing is stubbed here by default.
class FakeDuelRealtime extends Mock implements DuelRealtime {}

/// Pumps a screen with the same app-root providers the real app gives it.
///
/// Screens read these off the root — `SessionCubit`, `AuthRepository`,
/// `QuizPlayRepository`, `SettingsRepository` (plan 007), (plan 004)
/// `ConnectivityCubit`, (plan 017) `DuelRealtime` + `ServerClock`, and (plan
/// 022) `AdsCubit` + `InlineAdService` — so a widget test that pumps one
/// without them is testing a different widget than the one that ships.
///
/// Ads default to **off** ([FakeAdsCubit] in `AdsDisabled`), so a screen
/// renders exactly as it did before ads existed; pass `ads:
/// FakeAdsCubit.ready()` to exercise a screen's ad slots and breaks.
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
    SettingsRepository? settingsRepository,
    ConnectivityCubit? connectivity,
    ContentLanguageCubit? contentLanguage,
    DuelRealtime? duelRealtime,
    ServerClock? serverClock,
    LadderConfigRepository? ladderConfig,
    AdsCubit? ads,
    InlineAdService? inlineAds,
  }) async {
    final auth = authRepository ?? await _fakeAuthRepository();
    // `QuizPlayScreen` builds a real `StoredAudioTtsService` inline (it isn't
    // injected via context), so a pumped screen would otherwise reach an
    // actual network URL to play. Defaulting audio off here keeps
    // `QuizPlayCubit` from ever calling into it, the same way the app's own
    // default sound-on preference never touches this screen's pre-TTS
    // behavior in tests — the phase machine itself is covered by
    // `QuizPlayCubit`'s own unit tests with a fake `TtsService`.
    SharedPreferences.setMockInitialValues({'settings.soundOn': false});

    final contentLanguageRepository = await _fakeContentLanguageRepository();
    final contentLanguageCubit =
        contentLanguage ?? ContentLanguageCubit(contentLanguageRepository);

    return pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<QuizPlayRepository>.value(
            value: quizPlayRepository ?? QuizPlayRepository(FakeQuizPlayApi()),
          ),
          RepositoryProvider<SettingsRepository>.value(
            value:
                settingsRepository ??
                SettingsRepository(await SharedPreferences.getInstance()),
          ),
          RepositoryProvider<ContentLanguageRepository>.value(
            value: contentLanguageRepository,
          ),
          RepositoryProvider<DuelRealtime>.value(
            value: duelRealtime ?? FakeDuelRealtime(),
          ),
          RepositoryProvider<ServerClock>.value(
            value: serverClock ?? ServerClock(),
          ),
          RepositoryProvider<LadderConfigRepository>.value(
            value: ladderConfig ?? _fakeLadderConfigRepository(),
          ),
          RepositoryProvider<InlineAdService>.value(
            value: inlineAds ?? FakeInlineAdService(),
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
            BlocProvider<ContentLanguageCubit>.value(
              value: contentLanguageCubit,
            ),
            BlocProvider<AdsCubit>.value(value: ads ?? FakeAdsCubit()),
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

/// Reads an empty `content_language.code` key, so `ContentLanguageCubit`
/// defaults to `'en'` — matching `pumpApp`'s own default `locale: Locale('en')`.
Future<ContentLanguageRepository> _fakeContentLanguageRepository() async {
  return ContentLanguageRepository(
    FakeContentLanguageApi(),
    await SharedPreferences.getInstance(),
  );
}

/// A `LadderConfigRepository` over the seeded 30-level, 3-tier ladder (plan
/// 020), so a widget that calls `ensureLoaded()` resolves to the same tiers
/// the live app does rather than erroring against an unstubbed mock.
LadderConfigRepository _fakeLadderConfigRepository() {
  final api = FakeLadderConfigApi();
  when(
    () => api.fetchTiers(
      defaultQuestionsPerLevel: any(named: 'defaultQuestionsPerLevel'),
    ),
  ).thenAnswer(
    (_) async => const [
      DifficultyTier(
        code: 'easy',
        label: 'Easy',
        secondsPerQuestion: 20,
        levelStart: 1,
        levelEnd: 10,
        questionsPerLevel: 10,
      ),
      DifficultyTier(
        code: 'medium',
        label: 'Medium',
        secondsPerQuestion: 15,
        levelStart: 11,
        levelEnd: 20,
        questionsPerLevel: 15,
      ),
      DifficultyTier(
        code: 'hard',
        label: 'Hard',
        secondsPerQuestion: 10,
        levelStart: 21,
        levelEnd: 30,
        questionsPerLevel: 20,
      ),
    ],
  );
  when(() => api.fetchBossLevelInterval()).thenAnswer((_) async => 10);
  when(() => api.fetchDefaultQuestionsPerLevel()).thenAnswer((_) async => 20);
  return LadderConfigRepository(api);
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
