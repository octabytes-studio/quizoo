/// Every route path in the app, declared once.
///
/// No feature file ever writes a path string. `context.go(AppRoutes.home)`,
/// never `context.go('/home')` (CLAUDE.md §4). Paths with a dynamic segment
/// get a matching `…Path(...)` builder so call sites never do string
/// interpolation on the template either.
///
/// All 54 screen IDs from the design bible are reserved here up front, so
/// plans 002–004 only ever fill in a builder in `app/router.dart` — they never
/// add or rename a constant. The [s01]–[s54] aliases at the bottom are the
/// by-ID view of the same set.
///
/// Some bible "screens" are *states* of another screen rather than their own
/// destination — S-05 (Home, signed-in) is Home with a session, S-13 (Wrong)
/// is the question screen mid-feedback, S-45 (Home loading) is Home's loading
/// state. Those IDs alias the path they are a state of; see [stateAliases].
abstract final class AppRoutes {
  // ------------------------------------------------------- entry & home
  /// S-01 Splash — the launch route.
  static const String splash = '/';

  /// S-02 Onboarding carousel.
  static const String onboarding = '/onboarding';

  /// S-03 Language picker.
  static const String languagePicker = '/language';

  /// S-04 Home (guest) / S-05 Home (signed-in) — shell tab 1.
  static const String home = '/home';

  /// S-06 Search.
  static const String search = '/search';

  // -------------------------------------------------- browse & level map
  /// S-07 Category detail.
  static const String categoryDetail = '/category/:categoryId';

  static String categoryDetailPath(String categoryId) =>
      '/category/$categoryId';

  /// S-08 Level map.
  static const String levelMap =
      '/category/:categoryId/subcategory/:subcategoryId/levels';

  static String levelMapPath(String categoryId, String subcategoryId) =>
      '/category/$categoryId/subcategory/$subcategoryId/levels';

  /// S-09 Level brief sheet.
  static const String levelBrief =
      '/category/:categoryId/subcategory/:subcategoryId/levels/:levelNumber/brief';

  static String levelBriefPath(
    String categoryId,
    String subcategoryId,
    int levelNumber,
  ) =>
      '/category/$categoryId/subcategory/$subcategoryId/levels/$levelNumber/brief';

  // --------------------------------------------------------- gameplay
  /// S-10 Countdown.
  static const String countdown = '/play/:levelId/countdown';

  static String countdownPath(String levelId) => '/play/$levelId/countdown';

  /// S-11 Question — and, as states of it, S-12 Correct, S-13 Wrong,
  /// S-14 Danger, S-15 image question, S-16 Urdu/RTL, S-20 audio question.
  static const String quizPlay = '/play/:levelId';

  static String quizPlayPath(String levelId) => '/play/$levelId';

  /// S-17 Pause sheet.
  static const String quizPause = '/play/:levelId/pause';

  static String quizPausePath(String levelId) => '/play/$levelId/pause';

  /// S-18 Quit confirmation.
  static const String quizQuit = '/play/:levelId/quit';

  static String quizQuitPath(String levelId) => '/play/$levelId/quit';

  /// S-19 Out of lives.
  static const String outOfLives = '/play/:levelId/out-of-lives';

  static String outOfLivesPath(String levelId) => '/play/$levelId/out-of-lives';

  // ---------------------------------------------- results & progression
  /// S-21 Level complete.
  static const String levelComplete = '/play/:levelId/complete';

  static String levelCompletePath(String levelId) => '/play/$levelId/complete';

  /// S-22 Level failed.
  static const String levelFailed = '/play/:levelId/failed';

  static String levelFailedPath(String levelId) => '/play/$levelId/failed';

  /// S-23 Badge unlocked.
  static const String badgeUnlocked = '/badge-unlocked/:badgeId';

  static String badgeUnlockedPath(String badgeId) => '/badge-unlocked/$badgeId';

  /// S-24 Save-progress sheet.
  static const String saveProgress = '/save-progress';

  /// S-25 Profile creation.
  static const String profileCreation = '/profile/create';

  /// S-26 League promotion.
  static const String leaguePromotion = '/league-promotion';

  /// Topic Mastered — the congratulations screen after a topic's final level
  /// (plan 020). Not one of the bible's 54 IDs, so it has no `sXX` alias.
  static const String topicMastered =
      '/category/:categoryId/subcategory/:subcategoryId/mastered';

  static String topicMasteredPath(String categoryId, String subcategoryId) =>
      '/category/$categoryId/subcategory/$subcategoryId/mastered';

  // ------------------------------------------------------- Quizoo Pro (023)
  // The paywall and the two screens a member sees. None of these is one of
  // the bible's 54 IDs (see this class's doc comment), so they have no `sXX`
  // alias below.
  /// The Quizoo Pro paywall; `extra`: `PaywallSource`.
  static const String paywall = '/pro';

  /// Shown once, right after a purchase or a restore that found Pro.
  static const String proWelcome = '/pro/welcome';

  /// What a Pro member sees instead of the paywall.
  static const String proMembership = '/pro/membership';

  /// Post-level answer review; `extra`: `QuizRun`.
  static const String answerReview = '/play/:levelId/review';

  static String answerReviewPath(String levelId) => '/play/$levelId/review';

  // ------------------------------------------------------------- daily
  /// S-27 Daily tab — shell tab 4.
  static const String daily = '/daily';

  /// The daily challenge's real ten-question run, between S-27 and S-28.
  static const String dailyPlay = '/daily/play';

  /// S-28 Daily result.
  static const String dailyResult = '/daily/result';

  // ------------------------------------------------- leaderboards & social
  /// S-29 Global leaderboard — shell tab 2.
  static const String ranks = '/ranks';

  /// S-30 Category leaderboard.
  static const String categoryLeaderboard = '/ranks/category/:categoryId';

  static String categoryLeaderboardPath(String categoryId) =>
      '/ranks/category/$categoryId';

  /// S-31 Friends.
  static const String friends = '/friends';

  // ----------------------------------------------------------- profile
  /// S-32 Profile — shell tab 5.
  static const String you = '/you';

  /// S-33 Achievements grid.
  static const String achievements = '/you/achievements';

  /// S-34 Badge detail dialog.
  static const String badgeDetail = '/you/achievements/:badgeId';

  static String badgeDetailPath(String badgeId) => '/you/achievements/$badgeId';

  /// S-35 Stats.
  static const String stats = '/you/stats';

  /// Edit Profile — avatar/display-name/language editing, reached by tapping
  /// the player's own avatar on Home or the You screen (plan 019). Not one of
  /// the bible's 54 IDs (see this class's own doc comment), so it has no
  /// `sXX` alias below.
  static const String editProfile = '/you/edit-profile';

  // -------------------------------------------------------------- duel
  /// S-38 — Duel arena; the centre FAB pushes it (plan 017).
  static const String duelArena = '/duel';

  /// S-39 Matchmaking; `extra`: the `DuelTopic` to match in.
  static const String duelMatchmaking = '/duel/matchmaking';

  /// The labelled bot duel (S-40 variant); `extra`: `BotDuelArgs`.
  static const String duelBot = '/duel/bot';

  /// S-40 live duel by server id.
  static const String duelPlay = '/duel/:duelId';

  static String duelPlayPath(String duelId) => '/duel/$duelId';

  /// S-41 Duel result.
  static const String duelResult = '/duel/:duelId/result';

  static String duelResultPath(String duelId) => '/duel/$duelId/result';

  // ---------------------------------------------------------- settings
  /// S-42 Settings — and S-43, which is this app under an RTL locale.
  static const String settings = '/settings';

  /// S-44 Notification settings.
  static const String notificationSettings = '/settings/notifications';

  /// Privacy & leaderboard visibility — a settings row the bible names but
  /// never mockups (plan 004, Assumption 4). Not one of the 54 IDs, so it has
  /// no `sXX` alias below.
  static const String privacySettings = '/settings/privacy';

  /// Blocked players management (plan 025) — reached from Privacy.
  static const String blockedPlayers = '/settings/blocked-players';

  // ----------------------------------------------- system states & overlays
  /// S-46 Offline.
  static const String offline = '/offline';

  /// S-50 Force update.
  static const String forceUpdate = '/force-update';

  /// S-51 Report a question.
  static const String reportQuestion = '/report-question';

  /// S-52 Delete account.
  static const String deleteAccount = '/settings/delete-account';

  /// S-53 Share sheet.
  static const String share = '/share';

  /// S-54 Notification permission pre-prompt.
  static const String notificationPermission = '/notification-permission';

  /// Debug-only index of all 54 screen IDs, so every one is reachable by tap
  /// while the real bodies are still placeholders.
  static const String screenIndex = '/dev/screens';

  // --------------------------------------------------------- ID aliases
  // The bible's S-01…S-54, in order. Each is the same constant as above; the
  // ones that alias another screen's path are states of it, not destinations
  // of their own — see [stateAliases] for that list and its reasoning.
  static const String s01 = splash;
  static const String s02 = onboarding;
  static const String s03 = languagePicker;
  static const String s04 = home;
  static const String s05 = home;
  static const String s06 = search;
  static const String s07 = categoryDetail;
  static const String s08 = levelMap;
  static const String s09 = levelBrief;
  static const String s10 = countdown;
  static const String s11 = quizPlay;
  static const String s12 = quizPlay;
  static const String s13 = quizPlay;
  static const String s14 = quizPlay;
  static const String s15 = quizPlay;
  static const String s16 = quizPlay;
  static const String s17 = quizPause;
  static const String s18 = quizQuit;
  static const String s19 = outOfLives;
  static const String s20 = quizPlay;
  static const String s21 = levelComplete;
  static const String s22 = levelFailed;
  static const String s23 = badgeUnlocked;
  static const String s24 = saveProgress;
  static const String s25 = profileCreation;
  static const String s26 = leaguePromotion;
  static const String s27 = daily;
  static const String s28 = dailyResult;
  static const String s29 = ranks;
  static const String s30 = categoryLeaderboard;
  static const String s31 = friends;
  static const String s32 = you;
  static const String s33 = achievements;
  static const String s34 = badgeDetail;
  static const String s35 = stats;
  static const String s38 = duelArena;
  static const String s39 = duelMatchmaking;
  static const String s40 = duelPlay;
  static const String s41 = duelResult;
  static const String s42 = settings;
  static const String s43 = settings;
  static const String s44 = notificationSettings;
  static const String s45 = home;
  static const String s46 = offline;
  static const String s47 = levelMap;
  static const String s48 = levelMap;
  static const String s49 = home;
  static const String s50 = forceUpdate;
  static const String s51 = reportQuestion;
  static const String s52 = deleteAccount;
  static const String s53 = share;
  static const String s54 = notificationPermission;

  /// Screen IDs that are a *state* of another screen rather than a
  /// destination, mapped to the ID whose route they live on.
  ///
  /// Kept explicit so nobody later mistakes the shared path for an oversight
  /// and adds a duplicate route for it.
  static const Map<String, String> stateAliases = {
    'S-05': 'S-04', // Home, signed-in — Home with a session
    'S-12': 'S-11', // Correct — question screen mid-feedback
    'S-13': 'S-11', // Wrong — question screen mid-feedback
    'S-14': 'S-11', // Danger (last 5s) — question screen under 5 seconds
    'S-15': 'S-11', // Image question — a question with media
    'S-16': 'S-11', // Urdu / RTL question — the same screen under `ur`
    'S-20': 'S-11', // Audio question — a question with media
    'S-43': 'S-42', // Home in Urdu — the app under an RTL locale
    'S-45': 'S-04', // Home loading — Home's loading state
    'S-47': 'S-08', // Empty state — a content screen with nothing to show
    'S-48': 'S-08', // Content error — a content screen that failed to load
    'S-49': 'S-04', // Snackbar in place — an overlay on any screen
  };
}

/// One row of the debug screen index: a bible screen ID, its name, the path it
/// lives on, and which plan fills its body in.
class ScreenRef {
  const ScreenRef(this.id, this.name, this.path, this.plan, {this.group = ''});

  /// e.g. `S-11`.
  final String id;

  /// e.g. `Question (default)`.
  final String name;

  /// The route this screen is reached at. Screens sharing a path with another
  /// ID are states of it — see [AppRoutes.stateAliases].
  final String path;

  /// The plan that implements this screen's real body: `001`…`004`.
  final String plan;

  /// The bible's own grouping heading.
  final String group;

  /// True when this ID renders on another screen's route.
  bool get isState => AppRoutes.stateAliases.containsKey(id);
}

/// All 54 screens, in the bible's own order and grouping.
///
/// Drives the debug screen index and the router's placeholder bodies, so the
/// list and the routes cannot drift apart.
const List<ScreenRef> kScreenIndex = [
  ScreenRef('S-01', 'Splash', AppRoutes.splash, '002', group: 'Entry & home'),
  ScreenRef('S-02', 'Onboarding', AppRoutes.onboarding, '002'),
  ScreenRef('S-03', 'Language picker', AppRoutes.languagePicker, '002'),
  ScreenRef('S-04', 'Home (guest)', AppRoutes.home, '002'),
  ScreenRef('S-05', 'Home (signed-in)', AppRoutes.home, '002'),
  ScreenRef('S-06', 'Search', AppRoutes.search, '002'),
  ScreenRef(
    'S-07',
    'Category detail',
    AppRoutes.categoryDetail,
    '002',
    group: 'Browse & level map',
  ),
  ScreenRef('S-08', 'Level map', AppRoutes.levelMap, '002'),
  ScreenRef('S-09', 'Level brief sheet', AppRoutes.levelBrief, '002'),
  ScreenRef('S-10', 'Countdown', AppRoutes.countdown, '002'),
  ScreenRef(
    'S-11',
    'Question (default)',
    AppRoutes.quizPlay,
    '002',
    group: 'Gameplay',
  ),
  ScreenRef('S-12', 'Correct', AppRoutes.quizPlay, '002'),
  ScreenRef('S-13', 'Wrong', AppRoutes.quizPlay, '002'),
  ScreenRef('S-14', 'Danger (last 5s)', AppRoutes.quizPlay, '002'),
  ScreenRef('S-15', 'Question (image)', AppRoutes.quizPlay, '002'),
  ScreenRef('S-16', 'Question (Urdu / RTL)', AppRoutes.quizPlay, '002'),
  ScreenRef('S-17', 'Pause sheet', AppRoutes.quizPause, '002'),
  ScreenRef('S-18', 'Quit confirmation', AppRoutes.quizQuit, '002'),
  ScreenRef('S-19', 'Out of lives', AppRoutes.outOfLives, '002'),
  ScreenRef('S-20', 'Question (audio)', AppRoutes.quizPlay, '002'),
  ScreenRef(
    'S-21',
    'Level complete',
    AppRoutes.levelComplete,
    '002',
    group: 'Results & progression',
  ),
  ScreenRef('S-22', 'Level failed', AppRoutes.levelFailed, '002'),
  ScreenRef('S-23', 'Badge unlocked', AppRoutes.badgeUnlocked, '002'),
  ScreenRef('S-24', 'Save-progress sheet', AppRoutes.saveProgress, '002'),
  ScreenRef('S-25', 'Profile creation', AppRoutes.profileCreation, '002'),
  ScreenRef('S-26', 'League promotion', AppRoutes.leaguePromotion, '003'),
  ScreenRef('S-27', 'Daily tab', AppRoutes.daily, '003', group: 'Daily'),
  ScreenRef('S-28', 'Daily result', AppRoutes.dailyResult, '003'),
  ScreenRef(
    'S-29',
    'Global leaderboard',
    AppRoutes.ranks,
    '003',
    group: 'Leaderboards & social',
  ),
  ScreenRef(
    'S-30',
    'Category leaderboard',
    AppRoutes.categoryLeaderboard,
    '003',
  ),
  ScreenRef('S-31', 'Friends', AppRoutes.friends, '003'),
  ScreenRef('S-32', 'Profile', AppRoutes.you, '003', group: 'Profile'),
  ScreenRef('S-33', 'Achievements grid', AppRoutes.achievements, '003'),
  ScreenRef('S-34', 'Badge detail dialog', AppRoutes.badgeDetail, '003'),
  ScreenRef('S-35', 'Stats', AppRoutes.stats, '003'),
  ScreenRef(
    'S-38',
    'Duel arena (FAB)',
    AppRoutes.duelArena,
    '017',
    group: 'Duel',
  ),
  ScreenRef('S-39', 'Matchmaking', AppRoutes.duelMatchmaking, '004'),
  ScreenRef('S-40', 'Duel in play', AppRoutes.duelPlay, '004'),
  ScreenRef('S-41', 'Duel result', AppRoutes.duelResult, '004'),
  ScreenRef('S-42', 'Settings', AppRoutes.settings, '004', group: 'Settings'),
  ScreenRef('S-43', 'Home (Urdu / RTL)', AppRoutes.settings, '004'),
  ScreenRef('S-44', 'Notifications', AppRoutes.notificationSettings, '004'),
  ScreenRef(
    'S-45',
    'Home loading',
    AppRoutes.home,
    '004',
    group: 'System states',
  ),
  ScreenRef('S-46', 'Offline', AppRoutes.offline, '004'),
  ScreenRef('S-47', 'Empty state', AppRoutes.levelMap, '004'),
  ScreenRef('S-48', 'Content error', AppRoutes.levelMap, '004'),
  ScreenRef(
    'S-49',
    'Snackbar in place',
    AppRoutes.home,
    '004',
    group: 'Overlays',
  ),
  ScreenRef('S-50', 'Force update', AppRoutes.forceUpdate, '004'),
  ScreenRef('S-51', 'Report a question', AppRoutes.reportQuestion, '004'),
  ScreenRef('S-52', 'Delete account', AppRoutes.deleteAccount, '004'),
  ScreenRef('S-53', 'Share sheet', AppRoutes.share, '004'),
  ScreenRef(
    'S-54',
    'Notification permission',
    AppRoutes.notificationPermission,
    '004',
  ),
];
