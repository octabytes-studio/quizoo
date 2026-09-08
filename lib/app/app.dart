import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/connectivity_cubit.dart';
import 'package:quizoo/app/locale_cubit.dart';
import 'package:quizoo/app/router.dart';
import 'package:quizoo/app/theme_cubit.dart';
import 'package:quizoo/core/breakpoints.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/theme/app_theme.dart';
import 'package:quizoo/features/auth/data/auth_api.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:quizoo/features/onboarding/data/onboarding_repository.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_api.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';
import 'package:quizoo/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The application root.
///
/// Four things live here and nowhere else: the single [ScreenUtilInit] (at
/// the bible's 390×844 design size), the [MaterialApp.router] carrying both
/// `ThemeData`s, the genuinely app-wide Cubits, and the two mock repositories
/// that hold session-lifetime state.
///
/// **What earns an app-root `BlocProvider`** (CLAUDE.md §3 is explicit that
/// this is the exception, not the default): [ThemeCubit] and [LocaleCubit],
/// because every screen renders through them, and [SessionCubit], which
/// §3 names by example — Home switches its entire layout on it and plans 003
/// and 004 read it for the profile tab and the player's own leaderboard row.
/// [ConnectivityCubit] joins them in plan 004: Settings' debug "Simulate
/// offline" toggle and Home's offline variant (S-46) are on different
/// routes, so the flag has to live above both.
///
/// **Why the `RepositoryProvider`s**: each of the three holds state that
/// outlives any one screen's Cubit, written on one route and read on another.
/// [OnboardingRepository] remembers that first-run happened; [AuthRepository]
/// remembers whether the save-progress sheet has already been offered; and
/// [QuizPlayRepository] is the prefetch cache the level brief sheet (S-09)
/// warms and the play surface (S-11) reads, on a different route. All three
/// are in-memory for this phase; see each class for what that costs.
class QuizooApp extends StatefulWidget {
  const QuizooApp({required this.preferences, super.key, this.router});

  /// Overridable so a test can pump the app against its own router.
  final GoRouter? router;

  /// Backs [OnboardingRepository] and [AuthRepository]'s device-local flags.
  /// Obtained once in `main()`, before `runApp`, since loading it is async.
  final SharedPreferences preferences;

  @override
  State<QuizooApp> createState() => _QuizooAppState();
}

class _QuizooAppState extends State<QuizooApp> {
  late final GoRouter _router = widget.router ?? AppRouter.create();
  late final OnboardingRepository _onboardingRepository = OnboardingRepository(
    widget.preferences,
  );
  late final AuthRepository _authRepository = AuthRepository(
    AuthApi(supabase),
    widget.preferences,
  );
  late final QuizPlayRepository _quizPlayRepository = QuizPlayRepository(
    QuizPlayApi(supabase),
  );
  late final SettingsRepository _settingsRepository = SettingsRepository(
    widget.preferences,
  );
  late final SessionCubit _sessionCubit = SessionCubit(_authRepository);

  @override
  void initState() {
    super.initState();
    // §05: every screen's own background runs behind the status bar and the
    // navigation bar. Set once here; per-route icon brightness comes from each
    // screen's `AppBarTheme.systemOverlayStyle`.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    // Restores `SessionSignedIn` across a cold start for a previously
    // signed-in player — a real Supabase session persists where the mock's
    // never did (plan 005, Design overview).
    unawaited(_sessionCubit.restore());
  }

  @override
  void dispose() {
    unawaited(_sessionCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OnboardingRepository>.value(
          value: _onboardingRepository,
        ),
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<QuizPlayRepository>.value(
          value: _quizPlayRepository,
        ),
        RepositoryProvider<SettingsRepository>.value(
          value: _settingsRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          BlocProvider<LocaleCubit>(create: (_) => LocaleCubit()),
          BlocProvider<ConnectivityCubit>(create: (_) => ConnectivityCubit()),
          BlocProvider<SessionCubit>.value(value: _sessionCubit),
        ],
        child: ScreenUtilInit(
          designSize: const Size(
            Breakpoints.designWidth,
            Breakpoints.designHeight,
          ),
          minTextAdapt: true,
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return BlocBuilder<LocaleCubit, LocaleState>(
                builder: (context, localeState) {
                  return MaterialApp.router(
                    onGenerateTitle: (context) =>
                        AppLocalizations.of(context).appTitle,
                    debugShowCheckedModeBanner: false,
                    routerConfig: _router,
                    theme: AppTheme.light,
                    darkTheme: AppTheme.dark,
                    themeMode: themeState.mode.toThemeMode(),
                    // Null follows the device. A language this build does not
                    // translate resolves back to English by Flutter's own
                    // rules, which is exactly what S-03 warns about on screen.
                    locale: localeState.locale,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: AppLocalizations.supportedLocales,
                    // The locale-dependent half of the type system — Nastaliq
                    // families and their taller line-height — can only be
                    // applied below `Localizations`, which is here.
                    builder: (context, child) => Theme(
                      data: AppTheme.localize(
                        Theme.of(context),
                        Localizations.localeOf(context),
                      ),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
