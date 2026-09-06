// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Quizoo';

  @override
  String homeGreeting(String name) {
    return 'Hey, $name 👋';
  }

  @override
  String homeSubtitle(int level, String title) {
    return 'Level $level · $title';
  }

  @override
  String get homePopularThisWeek => '🔥 Popular this week';

  @override
  String get homeCategories => 'Categories';

  @override
  String get homeDailyChallenge => '🎯 Daily challenge';

  @override
  String get homeSeeAll => 'See all';

  @override
  String homeLevelProgress(int cleared, int total) {
    return 'Lv $cleared/$total';
  }

  @override
  String get homeNew => 'New';

  @override
  String get tabHome => 'Home';

  @override
  String get tabRanks => 'Ranks';

  @override
  String get tabPlay => 'Play';

  @override
  String get tabDaily => 'Daily';

  @override
  String get tabYou => 'You';

  @override
  String get playSheetTitle => 'Play';

  @override
  String get playSheetSubtitle => 'Pick how you want to play right now.';

  @override
  String get playSheetDuel => '1v1 Duel';

  @override
  String get playSheetDuelMeta => '5 questions · winner takes 200 🪙';

  @override
  String get playSheetQuickPlay => 'Quick Play';

  @override
  String get playSheetQuickPlayMeta => 'A random level at your skill tier';

  @override
  String get playSheetDaily => 'Daily Challenge';

  @override
  String get playSheetDailyMeta => 'Not played yet · 4h 12m left';

  @override
  String get playSheetFriend => 'Challenge a friend';

  @override
  String get playSheetFriendMeta => 'Danish M. is online now';

  @override
  String get playSheetGo => 'Go →';

  @override
  String get playSheetClose => 'Close play menu';

  @override
  String questionCounter(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String questionLevelMeta(int level, int total, int seconds) {
    return 'Level $level of $total · ${seconds}s per question';
  }

  @override
  String get questionSample =>
      'Which planet has the shortest day in the Solar System?';

  @override
  String questionStreak(int count) {
    return '$count-day streak';
  }

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeAuto => 'Auto';

  @override
  String get devScreenIndexTitle => 'Screen index';

  @override
  String get devScreenIndexSubtitle => 'All 54 screens · debug only';

  @override
  String devPlaceholderBody(String plan) {
    return 'Not yet implemented — see plan $plan.';
  }

  @override
  String devStateOf(String id) {
    return 'A state of $id, not its own route.';
  }

  @override
  String get splashTagline => 'Play smarter.';

  @override
  String splashVersion(String version) {
    return 'v$version';
  }

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Let\'s play';

  @override
  String get onboardingPickTitle => 'Pick a topic\nyou actually like';

  @override
  String get onboardingPickBody =>
      'Fourteen categories and hundreds of topics. Start with the one you would argue about.';

  @override
  String get onboardingClimbTitle => 'Climb 20 levels\nin every topic';

  @override
  String get onboardingClimbBody =>
      'Each level is harder and faster than the last. Three stars means you truly know it.';

  @override
  String get onboardingBeatTitle => 'Beat your friends\nevery single week';

  @override
  String get onboardingBeatBody =>
      'Leagues reset every Sunday. Thirty players, one board, nowhere to hide.';

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get languageSubtitle => 'You can change this any time in Settings';

  @override
  String languageQuizCount(String count) {
    return '$count quizzes';
  }

  @override
  String languageQuizCountNamed(String name, String count) {
    return '$name · $count quizzes';
  }

  @override
  String get languageContinue => 'Continue';

  @override
  String get languagePartialSupport =>
      'Only English and Urdu are translated in this build — the others show English copy.';

  @override
  String get homeWelcome => 'Welcome 👋';

  @override
  String get homePlayingAsGuest => 'Playing as Guest';

  @override
  String get homeSaveProgressTitle => 'Save your progress';

  @override
  String get homeSaveProgressBody =>
      'Sign in later — play first, we\'ll remember';

  @override
  String get homeContinueHeading => '▶︎ Continue';

  @override
  String homeContinueTitle(String subcategory, int level) {
    return '$subcategory · Level $level';
  }

  @override
  String homeContinueMeta(String points, int lives) {
    return '$points pts · $lives lives left';
  }

  @override
  String get homeResume => 'Resume';

  @override
  String get homeDailyChallengeTitle => 'Daily Challenge';

  @override
  String homeDailyChallengeMeta(int questions, String remaining) {
    return '$questions questions · ends in $remaining';
  }

  @override
  String get homeDailyPlay => 'Play';

  @override
  String homeAllCategories(int count) {
    return 'All $count';
  }

  @override
  String homePlayedCount(String count) {
    return '👥 $count played';
  }

  @override
  String get homeHotBadge => 'HOT';

  @override
  String homeStreakLevel(int streak, int level) {
    return '🔥 $streak-day streak · Level $level';
  }

  @override
  String get homeSearchLabel => 'Search';

  @override
  String homeLevelsAvailable(int count) {
    return '$count levels';
  }

  @override
  String get homeLocked => 'Locked';

  @override
  String get homeFilterAll => '✨ All';

  @override
  String get searchHint => 'Search topics';

  @override
  String searchResultCount(int count) {
    return '$count RESULTS';
  }

  @override
  String searchBreadcrumb(String category, String path, int questions) {
    return '$category › $path · $questions questions';
  }

  @override
  String get searchPlay => 'Play';

  @override
  String get searchTrending => 'TRENDING SEARCHES';

  @override
  String get searchEmptyTitle => 'Nothing matched';

  @override
  String get searchEmptyBody =>
      'Try a shorter word, or pick one of the trending searches below.';

  @override
  String categoryMeta(int topics, String questions, String players) {
    return '$topics topics · $questions questions · $players players';
  }

  @override
  String get categoryTopics => 'Topics';

  @override
  String get categorySortPopular => 'Sort: Popular';

  @override
  String get categoryMore => 'More';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyExpert => 'Expert';

  @override
  String levelMapSubtitle(int questions, int levels) {
    return '$questions questions · $levels levels';
  }

  @override
  String get levelMapBestScore => 'BEST SCORE';

  @override
  String get levelMapStars => 'STARS';

  @override
  String get levelMapRank => 'RANK';

  @override
  String levelMapBand(String difficulty, int seconds) {
    return '$difficulty · ${seconds}s PER QUESTION';
  }

  @override
  String get levelMapYoureHere => 'YOU\'RE HERE';

  @override
  String get levelMapBossCleared => 'BOSS · CLEARED';

  @override
  String get levelMapPerfect => 'PERFECT';

  @override
  String get levelMapCleared => 'CLEARED';

  @override
  String levelMapCurrent(int questions, int seconds) {
    return '$questions QUESTIONS · ${seconds}s EACH';
  }

  @override
  String levelMapUnlockAfter(int level) {
    return 'CLEAR LEVEL $level';
  }

  @override
  String get levelMapLocked => 'LOCKED';

  @override
  String levelMapPlayLevel(int level) {
    return 'Play Level $level';
  }

  @override
  String levelMapPlaySub(String difficulty, int questions, int seconds) {
    return '$difficulty · $questions questions · ${seconds}s each';
  }

  @override
  String get levelMapLeaderboard => 'Leaderboard';

  @override
  String levelBriefTitle(int level) {
    return 'Level $level';
  }

  @override
  String levelBriefSubtitle(String subcategory, String difficulty) {
    return '$subcategory · $difficulty';
  }

  @override
  String levelBriefStreakMultiplier(String multiplier) {
    return '🔥 Streak ×$multiplier';
  }

  @override
  String get levelBriefQuestions => 'QUESTIONS';

  @override
  String get levelBriefPerQuestion => 'PER QUESTION';

  @override
  String get levelBriefLives => 'LIVES';

  @override
  String levelBriefSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get levelBriefPowerUps => 'POWER-UPS IN HAND';

  @override
  String get levelBriefShop => 'SHOP';

  @override
  String levelBriefStart(int level) {
    return 'Start Level $level';
  }

  @override
  String get levelBriefPreparing => 'Preparing level…';

  @override
  String countdownMeta(String subcategory, int level) {
    return '$subcategory · LEVEL $level';
  }

  @override
  String get countdownGetReady => 'Get ready…';

  @override
  String get countdownGo => 'GO';

  @override
  String get quizScore => 'Score';

  @override
  String get quizQuitLabel => 'Quit level';

  @override
  String get quizPauseLabel => 'Pause';

  @override
  String quizStreak(int count) {
    return '🔥 $count';
  }

  @override
  String get quizPowerUpFiftyFifty => '50:50';

  @override
  String get quizPowerUpAddTime => '+15s';

  @override
  String get quizPowerUpSkip => 'SKIP';

  @override
  String get feedbackCorrect => 'Correct!';

  @override
  String get feedbackWrong => 'Not quite';

  @override
  String get feedbackTimeout => 'Time\'s up';

  @override
  String feedbackPoints(String points) {
    return '+$points';
  }

  @override
  String get feedbackHeartLost => '−1 ❤️';

  @override
  String get feedbackNoHeartLost => 'No heart lost';

  @override
  String get feedbackNext => 'Next question';

  @override
  String get feedbackFinish => 'See results';

  @override
  String feedbackBreakdown(int speed, String difficulty, String streak) {
    return 'Speed +$speed · Difficulty ×$difficulty · Streak ×$streak';
  }

  @override
  String get feedbackStreakReset => 'Streak reset.';

  @override
  String get feedbackLastHeart =>
      'One heart left — the next wrong answer ends the level.';

  @override
  String get pauseTitle => 'Paused';

  @override
  String get pauseBody => 'Your timer is frozen. Nothing is lost.';

  @override
  String get pauseResume => 'Resume';

  @override
  String get pauseSoundOn => '🔊 Sound on';

  @override
  String get pauseSoundOff => '🔇 Sound off';

  @override
  String get pauseHapticsOn => '📳 Haptics on';

  @override
  String get pauseHapticsOff => '📴 Haptics off';

  @override
  String get pauseRestart => 'Restart level';

  @override
  String get pauseQuit => 'Quit — lose progress';

  @override
  String quitTitle(int level) {
    return 'Quit level $level?';
  }

  @override
  String quitBody(int questions, String points) {
    return 'You\'re $questions questions in with $points points. Quitting loses this level\'s score and one life. Your streak survives.';
  }

  @override
  String get quitKeepPlaying => 'Keep playing';

  @override
  String get quitConfirm => 'Quit level';

  @override
  String get outOfLivesTitle => 'Out of lives';

  @override
  String outOfLivesBody(String time) {
    return 'Lives refill one every 30 minutes — the next one lands at $time. Or keep this run going right now.';
  }

  @override
  String get outOfLivesWatchAd => '▶ Watch an ad for 1 ❤️';

  @override
  String outOfLivesRefill(int coins) {
    return 'Refill 5 ❤️ · $coins 🪙';
  }

  @override
  String get outOfLivesBackToMap => 'Back to level map';

  @override
  String get outOfLivesAdPlaying => 'Playing ad…';

  @override
  String get outOfLivesNotEnoughCoins => 'Not enough coins';

  @override
  String resultCompleteTitle(int level) {
    return 'Level $level complete!';
  }

  @override
  String resultStarsMeta(int stars, int needed) {
    return '$stars STARS · $needed MORE CORRECT FOR THE THIRD';
  }

  @override
  String get resultStarsPerfect => '3 STARS · A PERFECT RUN';

  @override
  String get resultFinalScore => 'FINAL SCORE';

  @override
  String resultBreakdownCorrect(int count) {
    return '$count correct × 100';
  }

  @override
  String get resultBreakdownSpeed => 'Speed bonus';

  @override
  String resultBreakdownStreak(int streak) {
    return 'Best streak ×$streak';
  }

  @override
  String get resultBreakdownCleanRun => 'Clean run — no power-ups';

  @override
  String get resultBreakdownFlawless => 'Flawless — 20 of 20';

  @override
  String resultBreakdownHearts(int count) {
    return '$count hearts unspent';
  }

  @override
  String get resultBreakdownBoss => 'Boss level ×2';

  @override
  String get resultBreakdownTotal => 'Total';

  @override
  String get resultCoins => 'COINS';

  @override
  String get resultExperience => 'EXPERIENCE';

  @override
  String resultCoinsValue(String coins) {
    return '+$coins 🪙';
  }

  @override
  String resultXpValue(String xp) {
    return '+$xp XP';
  }

  @override
  String resultPlayerLevel(int level) {
    return 'LEVEL $level';
  }

  @override
  String resultXpProgress(String current, String total) {
    return '$current / $total';
  }

  @override
  String get resultNextLevel => 'Next level →';

  @override
  String get resultReplay => 'Replay for 3 stars';

  @override
  String get resultBackToMap => 'Back to map';

  @override
  String get resultShare => 'Share';

  @override
  String get failedTitle => 'So close!';

  @override
  String failedRanOutOfHearts(int question) {
    return 'You ran out of hearts on question $question';
  }

  @override
  String failedQuitEarly(int question) {
    return 'You left on question $question';
  }

  @override
  String get failedCorrect => 'CORRECT';

  @override
  String get failedPoints => 'POINTS';

  @override
  String get failedAccuracy => 'ACCURACY';

  @override
  String failedAccuracyValue(int percent) {
    return '$percent%';
  }

  @override
  String get failedMissedHeading => 'YOU MISSED THESE — TAP TO REVIEW';

  @override
  String failedMissedAnswer(String correct, String chosen) {
    return '$correct — you said $chosen';
  }

  @override
  String failedMissedTimeout(String correct) {
    return '$correct — you ran out of time';
  }

  @override
  String get failedTryAgain => 'Try again';

  @override
  String get failedTryAgainCost => '· 1 ❤️';

  @override
  String saveProgressTitle(String points) {
    return 'Don\'t lose $points points';
  }

  @override
  String saveProgressBody(int percent, int level, int streak) {
    return 'You\'re $percent% through Level $level with a $streak-day streak. Sign in and it\'s saved on every device — free, 5 seconds.';
  }

  @override
  String get saveProgressGoogle => 'Continue with Google';

  @override
  String get saveProgressApple => 'Continue with Apple';

  @override
  String get saveProgressEmail => 'Continue with Email';

  @override
  String get saveProgressNotNow => 'Not now — keep playing as guest';

  @override
  String get saveProgressTerms =>
      'By continuing you agree to our Terms and Privacy Policy.';

  @override
  String get saveProgressSaved => 'Progress saved';

  @override
  String get profileTitle => 'Create your profile';

  @override
  String get profileChangeAvatar => 'Change avatar';

  @override
  String get profileUsername => 'USERNAME';

  @override
  String get profileCountry => 'COUNTRY';

  @override
  String get profileEmail => 'EMAIL';

  @override
  String get profileUsernameAvailable => '✓ available';

  @override
  String get profileUsernameTaken =>
      'Someone has this one — try adding a number';

  @override
  String get profileUsernameTooShort => 'Use at least three characters';

  @override
  String get profileEmailIncomplete =>
      'Add the part after the @ — like gmail.com';

  @override
  String get profileEmailMissing =>
      'Add an email so we can restore your progress';

  @override
  String get profileCreate => 'Create profile';

  @override
  String get profileCreated => 'Profile created';

  @override
  String get contentErrorTitle => 'That didn\'t load';

  @override
  String get contentErrorBody =>
      'Check your connection and give it another go.';
}
