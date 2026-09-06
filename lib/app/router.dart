import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/features/auth/presentation/screens/profile_creation_screen.dart';
import 'package:quizoo/features/auth/presentation/widgets/save_progress_sheet.dart';
import 'package:quizoo/features/catalog/presentation/screens/category_detail_screen.dart';
import 'package:quizoo/features/catalog/presentation/screens/level_map_screen.dart';
import 'package:quizoo/features/dev/presentation/screens/placeholder_screen.dart';
import 'package:quizoo/features/dev/presentation/screens/screen_index_screen.dart';
import 'package:quizoo/features/home/presentation/screens/home_screen.dart';
import 'package:quizoo/features/home/presentation/screens/search_screen.dart';
import 'package:quizoo/features/onboarding/data/onboarding_repository.dart';
import 'package:quizoo/features/onboarding/presentation/screens/language_picker_screen.dart';
import 'package:quizoo/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:quizoo/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_play/presentation/screens/quiz_play_screen.dart';
import 'package:quizoo/features/quiz_result/presentation/screens/quiz_result_screen.dart';
import 'package:quizoo/features/shell/presentation/screens/app_shell_screen.dart';

/// The app's one and only [GoRouter].
///
/// Shape, fixed here so plans 002–004 only ever swap a builder's body:
///
/// * A [StatefulShellRoute.indexedStack] holding the four tab branches. The
///   centre "Play" slot is not a branch — it opens a sheet, it does not push.
/// * Everything else as a **top-level** route on the root navigator, so it
///   covers the tab bar. That is what implements the bible's "the play surface
///   is a full-screen route pushed over the shell with the tab bar hidden".
///
/// Exiting a pushed route returns to whatever launched it, never to Home,
/// because these are pushes onto the root navigator rather than branch
/// switches.
abstract final class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GlobalKey<NavigatorState> shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static GoRouter create() {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: AppRoutes.splash,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShellScreen(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            _branch(AppRoutes.ranks, _screen('S-29')),
            _branch(AppRoutes.daily, _screen('S-27')),
            _branch(AppRoutes.you, _screen('S-32')),
          ],
        ),

        // Entry & home
        GoRoute(
          path: AppRoutes.splash,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) =>
              SplashScreen(repository: context.read<OnboardingRepository>()),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => OnboardingScreen(
            repository: context.read<OnboardingRepository>(),
          ),
        ),
        GoRoute(
          path: AppRoutes.languagePicker,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => LanguagePickerScreen(
            repository: context.read<OnboardingRepository>(),
          ),
        ),
        GoRoute(
          path: AppRoutes.search,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SearchScreen(),
        ),

        // Browse & level map
        GoRoute(
          path: AppRoutes.categoryDetail,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => CategoryDetailScreen(
            categoryId: state.pathParameters['categoryId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.levelMap,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => LevelMapScreen(
            categoryId: state.pathParameters['categoryId']!,
            subcategoryId: state.pathParameters['subcategoryId']!,
          ),
        ),
        // S-09 is a sheet, so its path opens the map it belongs to with the
        // sheet already presented rather than routing to a screen of its own.
        GoRoute(
          path: AppRoutes.levelBrief,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => LevelMapScreen(
            categoryId: state.pathParameters['categoryId']!,
            subcategoryId: state.pathParameters['subcategoryId']!,
            initialBriefLevelNumber: int.tryParse(
              state.pathParameters['levelNumber'] ?? '',
            ),
          ),
        ),

        // Gameplay — the arena, which looks the same in light and dark.
        //
        // All five paths build the same screen. The countdown and each of the
        // three overlays are *states* of the play surface, owned by one
        // `QuizPlayCubit`; giving them routes of their own would be the surest
        // way to let the clock and the UI drift apart. The reserved paths
        // still resolve, so every one stays reachable for design review.
        _playRoute(AppRoutes.countdown, QuizPlayEntry.play),
        _playRoute(AppRoutes.quizPlay, QuizPlayEntry.play),
        _playRoute(AppRoutes.quizPause, QuizPlayEntry.paused),
        _playRoute(AppRoutes.quizQuit, QuizPlayEntry.quitting),
        _playRoute(AppRoutes.outOfLives, QuizPlayEntry.outOfLives),

        // Results & progression
        //
        // Both result paths build the same host: which of S-21 and S-22
        // renders is decided by how the run ended, not by which path was
        // pushed, so a quit can never land on the completion screen.
        _resultRoute(AppRoutes.levelComplete),
        _resultRoute(AppRoutes.levelFailed),
        _route(AppRoutes.badgeUnlocked, 'S-23'),
        // S-24 is a sheet, so it is a transparent page over whatever pushed
        // it rather than a screen that replaces it.
        GoRoute(
          path: AppRoutes.saveProgress,
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) => _sheetPage(
            state,
            SaveProgressSheet.forRun(
              score: (state.extra as SaveProgressArgs?)?.score ?? 0,
              levelNumber: (state.extra as SaveProgressArgs?)?.levelNumber ?? 1,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.profileCreation,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ProfileCreationScreen(),
        ),
        _route(AppRoutes.leaguePromotion, 'S-26'),

        // Daily
        _route(AppRoutes.dailyResult, 'S-28'),

        // Leaderboards & social
        _route(AppRoutes.categoryLeaderboard, 'S-30'),
        _route(AppRoutes.friends, 'S-31'),

        // Profile
        _route(AppRoutes.achievements, 'S-33'),
        _route(AppRoutes.badgeDetail, 'S-34'),
        _route(AppRoutes.stats, 'S-35'),

        // Shop
        _route(AppRoutes.shop, 'S-36'),
        _route(AppRoutes.rewardedAd, 'S-37'),

        // Duel
        _route(AppRoutes.playLauncher, 'S-38'),
        _route(AppRoutes.duelMatchmaking, 'S-39'),
        _route(AppRoutes.duelPlay, 'S-40', isArena: true),
        _route(AppRoutes.duelResult, 'S-41'),

        // Settings
        _route(AppRoutes.settings, 'S-42'),
        _route(AppRoutes.notificationSettings, 'S-44'),

        // System states & overlays
        _route(AppRoutes.offline, 'S-46'),
        _route(AppRoutes.forceUpdate, 'S-50'),
        _route(AppRoutes.reportQuestion, 'S-51'),
        _route(AppRoutes.deleteAccount, 'S-52'),
        _route(AppRoutes.share, 'S-53'),
        _route(AppRoutes.notificationPermission, 'S-54'),

        GoRoute(
          path: AppRoutes.screenIndex,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ScreenIndexScreen(),
        ),
      ],
    );
  }

  /// One tab branch of the shell.
  static StatefulShellBranch _branch(String path, ScreenRef screen) {
    return StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          builder: (context, state) => PlaceholderScreen(screen: screen),
        ),
      ],
    );
  }

  /// S-21 / S-22's shared host. The finished run rides on the route's
  /// `extra`, so the result screen never re-fetches what the app already has.
  static GoRoute _resultRoute(String path) {
    return GoRoute(
      path: path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          QuizResultScreen(run: state.extra as QuizRun?),
    );
  }

  /// A modal sheet presented as a route: transparent, so whatever pushed it
  /// stays visible underneath.
  static Page<void> _sheetPage(GoRouterState state, Widget sheet) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0x801B1438),
      transitionDuration: AppMotion.sheet,
      reverseTransitionDuration: AppMotion.scrim,
      transitionsBuilder: (context, animation, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: AppMotion.sheetCurve),
            ),
        child: child,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          child: Align(alignment: Alignment.bottomCenter, child: sheet),
        ),
      ),
    );
  }

  /// One of the play surface's five paths, all of which build the same
  /// screen with a different entry state.
  static GoRoute _playRoute(String path, QuizPlayEntry entry) {
    return GoRoute(
      path: path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => QuizPlayScreen(
        levelId: state.pathParameters['levelId']!,
        entry: entry,
      ),
    );
  }

  /// A screen pushed over the shell, on the root navigator so it covers the
  /// tab bar.
  static GoRoute _route(String path, String screenId, {bool isArena = false}) {
    final screen = _screen(screenId);
    return GoRoute(
      path: path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          PlaceholderScreen(screen: screen, isArena: isArena),
    );
  }

  static ScreenRef _screen(String id) =>
      kScreenIndex.firstWhere((screen) => screen.id == id);
}
