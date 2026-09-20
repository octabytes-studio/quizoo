import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/core/router/app_route_observer.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_motion.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/report_question_sheet.dart';
import 'package:quizoo/core/widgets/share_sheet.dart';
import 'package:quizoo/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:quizoo/features/achievements/presentation/screens/badge_unlocked_screen.dart';
import 'package:quizoo/features/auth/presentation/screens/profile_creation_screen.dart';
import 'package:quizoo/features/auth/presentation/widgets/save_progress_sheet.dart';
import 'package:quizoo/features/catalog/presentation/screens/category_detail_screen.dart';
import 'package:quizoo/features/catalog/presentation/screens/level_map_screen.dart';
import 'package:quizoo/features/daily/domain/daily_result.dart';
import 'package:quizoo/features/daily/presentation/screens/daily_result_screen.dart';
import 'package:quizoo/features/daily/presentation/screens/daily_screen.dart';
import 'package:quizoo/features/dev/presentation/screens/screen_index_screen.dart';
import 'package:quizoo/features/duel/domain/duel_result.dart';
import 'package:quizoo/features/duel/presentation/screens/duel_play_screen.dart';
import 'package:quizoo/features/duel/presentation/screens/duel_result_screen.dart';
import 'package:quizoo/features/duel/presentation/screens/matchmaking_screen.dart';
import 'package:quizoo/features/home/presentation/screens/home_screen.dart';
import 'package:quizoo/features/home/presentation/screens/search_screen.dart';
import 'package:quizoo/features/leaderboard/presentation/screens/category_leaderboard_screen.dart';
import 'package:quizoo/features/leaderboard/presentation/screens/friends_screen.dart';
import 'package:quizoo/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:quizoo/features/leaderboard/presentation/screens/league_promotion_screen.dart';
import 'package:quizoo/features/onboarding/data/onboarding_repository.dart';
import 'package:quizoo/features/onboarding/presentation/screens/language_picker_screen.dart';
import 'package:quizoo/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:quizoo/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:quizoo/features/profile/presentation/screens/profile_screen.dart';
import 'package:quizoo/features/profile/presentation/screens/stats_screen.dart';
import 'package:quizoo/features/quiz_play/data/mock_questions.dart';
import 'package:quizoo/features/quiz_play/domain/quiz_run.dart';
import 'package:quizoo/features/quiz_play/presentation/screens/quiz_play_screen.dart';
import 'package:quizoo/features/quiz_result/presentation/screens/quiz_result_screen.dart';
import 'package:quizoo/features/settings/presentation/screens/delete_account_screen.dart';
import 'package:quizoo/features/settings/presentation/screens/force_update_screen.dart';
import 'package:quizoo/features/settings/presentation/screens/notification_permission_screen.dart';
import 'package:quizoo/features/settings/presentation/screens/notifications_screen.dart';
import 'package:quizoo/features/settings/presentation/screens/privacy_settings_screen.dart';
import 'package:quizoo/features/settings/presentation/screens/settings_screen.dart';
import 'package:quizoo/features/shell/presentation/screens/app_shell_screen.dart';
import 'package:quizoo/features/shell/presentation/widgets/play_launcher_sheet.dart';
import 'package:quizoo/l10n/app_localizations.dart';

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
      observers: [appRouteObserver],
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
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.ranks,
                  builder: (context, state) => const LeaderboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.daily,
                  builder: (context, state) => const DailyScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.you,
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
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
        GoRoute(
          path: AppRoutes.badgeUnlocked,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) =>
              BadgeUnlockedScreen(badgeId: state.pathParameters['badgeId']!),
        ),
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
        GoRoute(
          path: AppRoutes.leaguePromotion,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const LeaguePromotionScreen(),
        ),

        // Daily
        GoRoute(
          path: AppRoutes.dailyPlay,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const QuizPlayScreen.daily(),
        ),
        GoRoute(
          path: AppRoutes.dailyResult,
          parentNavigatorKey: rootNavigatorKey,
          // Real navigations always arrive with the just-scored `DailyResult`
          // as `extra` (from `QuizPlayScreen.daily`, via `QuizPlayCubit`'s
          // `_submitDaily`); the dev screen index's S-28 entry pushes this
          // route bare, so it falls back to a fixed preview rather than
          // crashing on a null `extra`.
          builder: (context, state) => DailyResultScreen(
            result: state.extra as DailyResult? ?? DailyResult.preview(),
          ),
        ),

        // Leaderboards & social
        GoRoute(
          path: AppRoutes.categoryLeaderboard,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => CategoryLeaderboardScreen(
            categoryId: state.pathParameters['categoryId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.friends,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const FriendsScreen(),
        ),

        // Profile
        GoRoute(
          path: AppRoutes.achievements,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const AchievementsScreen(),
        ),
        // S-34 is a dialog, so its path opens the grid it belongs to with the
        // dialog already presented, exactly like S-09's level-brief sheet.
        GoRoute(
          path: AppRoutes.badgeDetail,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => AchievementsScreen(
            initialBadgeId: state.pathParameters['badgeId'],
          ),
        ),
        GoRoute(
          path: AppRoutes.stats,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const StatsScreen(),
        ),

        // Duel
        GoRoute(
          path: AppRoutes.playLauncher,
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) =>
              _sheetPage(state, const PlayLauncherSheet()),
        ),
        GoRoute(
          path: AppRoutes.duelMatchmaking,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const MatchmakingScreen(),
        ),
        GoRoute(
          path: AppRoutes.duelPlay,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final args = state.extra as DuelPlayArgs?;
            return DuelPlayScreen(
              duelId: state.pathParameters['duelId']!,
              opponent: args?.opponent,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.duelResult,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) =>
              DuelResultScreen(result: state.extra as DuelResult?),
        ),

        // Settings
        GoRoute(
          path: AppRoutes.settings,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.notificationSettings,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.privacySettings,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const PrivacySettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.deleteAccount,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const DeleteAccountScreen(),
        ),
        GoRoute(
          path: AppRoutes.notificationPermission,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const NotificationPermissionScreen(),
        ),
        GoRoute(
          path: AppRoutes.forceUpdate,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ForceUpdateScreen(),
        ),

        // System states & overlays
        GoRoute(
          path: AppRoutes.offline,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const HomeScreen(forceOffline: true),
        ),
        // S-51 is a sheet, reached for design review directly at its own path
        // with a fixture question — every real call site opens it from
        // `features/quiz_play`'s HUD instead (see `QuizHud`).
        GoRoute(
          path: AppRoutes.reportQuestion,
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) =>
              _sheetPage(state, _reportQuestionDemo(context)),
        ),
        // S-53 likewise — every real call site (quiz result, daily result)
        // builds its own preview and opens `ShareSheet` directly.
        GoRoute(
          path: AppRoutes.share,
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) =>
              _sheetPage(state, _shareDemo(context)),
        ),

        GoRoute(
          path: AppRoutes.screenIndex,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ScreenIndexScreen(),
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

  /// S-51 built for design review — a fixture question, since there is no
  /// real "current question" outside `features/quiz_play`'s own HUD, which
  /// opens this same sheet directly (see `QuizHud`).
  static Widget _reportQuestionDemo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final question = MockQuestions.football.first;
    return ReportQuestionSheet(
      title: l10n.reportQuestionTitle,
      message: l10n.reportQuestionMeta(question.text),
      reasons: [
        l10n.reportReasonWrong,
        l10n.reportReasonUnclear,
        l10n.reportReasonTranslation,
        l10n.reportReasonOffensive,
        l10n.reportReasonImage,
      ],
      submitLabel: l10n.reportQuestionSubmit,
      onSubmit: (_) {
        Navigator.of(context).pop();
        AppSnackbar.show(
          context,
          title: l10n.reportQuestionSent,
          intent: SnackbarIntent.success,
        );
      },
    );
  }

  /// S-53 likewise — every real call site (quiz result, daily result) builds
  /// its own preview and opens [ShareSheet] directly.
  static Widget _shareDemo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void confirm() {
      Navigator.of(context).pop();
      AppSnackbar.show(
        context,
        title: l10n.commonSharedMock,
        intent: SnackbarIntent.success,
      );
    }

    return ShareSheet(
      title: l10n.shareDemoTitle,
      message: l10n.shareSpoilerFree,
      preview: Text(l10n.shareDemoPreview),
      targets: [
        ShareTarget(emoji: '💬', label: 'WhatsApp', onTap: confirm),
        ShareTarget(emoji: '✖️', label: 'X', onTap: confirm),
        ShareTarget(emoji: '🔗', label: 'Copy', onTap: confirm),
      ],
    );
  }
}
