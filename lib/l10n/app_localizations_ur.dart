// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'کوئزو';

  @override
  String homeGreeting(String name) {
    return 'ہیلو، $name 👋';
  }

  @override
  String homeSubtitle(int level, String title) {
    return 'لیول $level · $title';
  }

  @override
  String get homePopularThisWeek => '🔥 اس ہفتے مقبول';

  @override
  String get homeCategories => 'زمرے';

  @override
  String get homeDailyChallenge => '🎯 روزانہ کا چیلنج';

  @override
  String get homeSeeAll => 'سب دیکھیں';

  @override
  String homeLevelProgress(int cleared, int total) {
    return 'لیول $cleared/$total';
  }

  @override
  String get homeNew => 'نیا';

  @override
  String get tabHome => 'ہوم';

  @override
  String get tabRanks => 'درجہ بندی';

  @override
  String get tabPlay => 'کھیلیں';

  @override
  String get tabDaily => 'روزانہ';

  @override
  String get tabYou => 'آپ';

  @override
  String get playSheetTitle => 'کھیلیں';

  @override
  String get playSheetSubtitle => 'منتخب کریں کہ ابھی کیسے کھیلنا ہے۔';

  @override
  String get playSheetDuel => 'ایک بمقابلہ ایک مقابلہ';

  @override
  String get playSheetDuelMeta => '۵ سوالات · جیتنے والا لے گا ۲۰۰ 🪙';

  @override
  String get playSheetQuickPlay => 'فوری کھیل';

  @override
  String get playSheetQuickPlayMeta => 'آپ کی سطح کا ایک بے ترتیب لیول';

  @override
  String get playSheetDaily => 'روزانہ کا چیلنج';

  @override
  String get playSheetDailyMeta => 'ابھی نہیں کھیلا · ۴ گھنٹے ۱۲ منٹ باقی';

  @override
  String get playSheetFriend => 'دوست کو چیلنج کریں';

  @override
  String get playSheetFriendMeta => 'دانش ایم ابھی آن لائن ہیں';

  @override
  String get playSheetGo => 'چلیں ←';

  @override
  String get playSheetClose => 'کھیل کا مینو بند کریں';

  @override
  String questionCounter(int current, int total) {
    return 'سوال $current از $total';
  }

  @override
  String questionLevelMeta(int level, int total, int seconds) {
    return 'لیول $level از $total · فی سوال $seconds سیکنڈ';
  }

  @override
  String get questionSample => 'نظامِ شمسی میں سب سے چھوٹا دن کس سیارے کا ہے؟';

  @override
  String questionStreak(int count) {
    return '$count دن کا سلسلہ';
  }

  @override
  String get commonRetry => 'دوبارہ کوشش کریں';

  @override
  String get commonCancel => 'منسوخ کریں';

  @override
  String get commonClose => 'بند کریں';

  @override
  String get commonBack => 'واپس';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'تاریک';

  @override
  String get themeAuto => 'خودکار';

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
  String get languageTitle => 'اپنی زبان منتخب کریں';

  @override
  String get languageSubtitle => 'آپ اسے کسی بھی وقت ترتیبات میں بدل سکتے ہیں';

  @override
  String languageQuizCount(String count) {
    return '$count quizzes';
  }

  @override
  String languageQuizCountNamed(String name, String count) {
    return '$name · $count quizzes';
  }

  @override
  String get languageContinue => 'جاری رکھیں';

  @override
  String get languagePartialSupport =>
      'Only English and Urdu are translated in this build — the others show English copy.';

  @override
  String get homeWelcome => 'خوش آمدید 👋';

  @override
  String get homePlayingAsGuest => 'بطور مہمان کھیل رہے ہیں';

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
  String get homeResume => 'جاری رکھیں';

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
    return '🔥 $streak دن کا سلسلہ · لیول $level';
  }

  @override
  String get homeSearchLabel => 'تلاش';

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
    return '$subcategory · لیول $level';
  }

  @override
  String get countdownGetReady => 'تیار ہو جائیں…';

  @override
  String get countdownGo => 'شروع';

  @override
  String get quizScore => 'اسکور';

  @override
  String get quizQuitLabel => 'لیول چھوڑ دیں';

  @override
  String get quizPauseLabel => 'وقفہ';

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
  String get feedbackCorrect => 'درست!';

  @override
  String get feedbackWrong => 'بالکل نہیں';

  @override
  String get feedbackTimeout => 'وقت ختم';

  @override
  String feedbackPoints(String points) {
    return '+$points';
  }

  @override
  String get feedbackHeartLost => '−۱ ❤️';

  @override
  String get feedbackNoHeartLost => 'کوئی جان کم نہیں ہوئی';

  @override
  String get feedbackNext => 'اگلا سوال';

  @override
  String get feedbackFinish => 'نتائج دیکھیں';

  @override
  String feedbackBreakdown(int speed, String difficulty, String streak) {
    return 'Speed +$speed · Difficulty ×$difficulty · Streak ×$streak';
  }

  @override
  String get feedbackStreakReset => 'سلسلہ ختم ہو گیا۔';

  @override
  String get feedbackLastHeart =>
      'ایک جان باقی ہے — اگلا غلط جواب لیول ختم کر دے گا۔';

  @override
  String get pauseTitle => 'وقفہ';

  @override
  String get pauseBody => 'آپ کا وقت رک گیا ہے۔ کچھ ضائع نہیں ہوا۔';

  @override
  String get pauseResume => 'جاری رکھیں';

  @override
  String get pauseSoundOn => '🔊 آواز آن';

  @override
  String get pauseSoundOff => '🔇 آواز آف';

  @override
  String get pauseHapticsOn => '📳 ارتعاش آن';

  @override
  String get pauseHapticsOff => '📴 ارتعاش آف';

  @override
  String get pauseRestart => 'لیول دوبارہ شروع کریں';

  @override
  String get pauseQuit => 'چھوڑ دیں — پیش رفت ضائع ہو گی';

  @override
  String quitTitle(int level) {
    return 'لیول $level چھوڑ دیں؟';
  }

  @override
  String quitBody(int questions, String points) {
    return 'You\'re $questions questions in with $points points. Quitting loses this level\'s score and one life. Your streak survives.';
  }

  @override
  String get quitKeepPlaying => 'کھیلتے رہیں';

  @override
  String get quitConfirm => 'لیول چھوڑ دیں';

  @override
  String get outOfLivesTitle => 'جانیں ختم';

  @override
  String outOfLivesBody(String time) {
    return 'Lives refill one every 30 minutes — the next one lands at $time. Or keep this run going right now.';
  }

  @override
  String get outOfLivesWatchAd => '▶ ایک ❤️ کے لیے اشتہار دیکھیں';

  @override
  String outOfLivesRefill(int coins) {
    return '۵ ❤️ بھریں · $coins 🪙';
  }

  @override
  String get outOfLivesBackToMap => 'لیول نقشے پر واپس';

  @override
  String get outOfLivesAdPlaying => 'اشتہار چل رہا ہے…';

  @override
  String get outOfLivesNotEnoughCoins => 'سکے ناکافی ہیں';

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
  String get contentErrorTitle => 'یہ لوڈ نہیں ہو سکا';

  @override
  String get contentErrorBody => 'اپنا کنکشن دیکھ کر دوبارہ کوشش کریں۔';
}
