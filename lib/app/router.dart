import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/features/dev/presentation/screens/placeholder_screen.dart';
import 'package:quizoo/features/dev/presentation/screens/screen_index_screen.dart';
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
            _branch(AppRoutes.home, _screen('S-04')),
            _branch(AppRoutes.ranks, _screen('S-29')),
            _branch(AppRoutes.daily, _screen('S-27')),
            _branch(AppRoutes.you, _screen('S-32')),
          ],
        ),

        // Entry & home
        _route(AppRoutes.splash, 'S-01'),
        _route(AppRoutes.onboarding, 'S-02'),
        _route(AppRoutes.languagePicker, 'S-03'),
        _route(AppRoutes.search, 'S-06'),

        // Browse & level map
        _route(AppRoutes.categoryDetail, 'S-07'),
        _route(AppRoutes.levelMap, 'S-08'),
        _route(AppRoutes.levelBrief, 'S-09'),

        // Gameplay — the arena, which looks the same in light and dark.
        _route(AppRoutes.countdown, 'S-10', isArena: true),
        _route(AppRoutes.quizPlay, 'S-11', isArena: true),
        _route(AppRoutes.quizPause, 'S-17', isArena: true),
        _route(AppRoutes.quizQuit, 'S-18', isArena: true),
        _route(AppRoutes.outOfLives, 'S-19', isArena: true),

        // Results & progression
        _route(AppRoutes.levelComplete, 'S-21'),
        _route(AppRoutes.levelFailed, 'S-22'),
        _route(AppRoutes.badgeUnlocked, 'S-23'),
        _route(AppRoutes.saveProgress, 'S-24'),
        _route(AppRoutes.profileCreation, 'S-25'),
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
