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
  String homeTopicCount(int count) {
    return '$count موضوعات';
  }

  @override
  String homeSeeAllCount(int count) {
    return 'سب دیکھیں $count';
  }

  @override
  String homeQuestionCount(int count) {
    return '$count سوالات';
  }

  @override
  String homeLevelShort(int level) {
    return 'لیول $level';
  }

  @override
  String get homeComplete => 'مکمل';

  @override
  String homeCategorySectionLabel(String name, int count) {
    return '$name، $count موضوعات';
  }

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
  String categoryStatsStars(int count) {
    return '⭐ $count ستارے';
  }

  @override
  String categoryStatsLevels(int count) {
    return '🏁 $count لیول';
  }

  @override
  String get categoryResumeEyebrow => 'جہاں سے چھوڑا تھا وہیں سے شروع کریں';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyExpert => 'Expert';

  @override
  String get difficultyMaster => 'Master';

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
  String get quizPowerUpAddTime => '+5s';

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
  String get outOfLivesBody =>
      'Watch an ad for one more heart, or come back with 3 fresh hearts next time you start this level.';

  @override
  String get outOfLivesWatchAd => '▶ ایک ❤️ کے لیے اشتہار دیکھیں';

  @override
  String get outOfLivesBackToMap => 'لیول نقشے پر واپس';

  @override
  String get outOfLivesAdLoading => 'اشتہار لوڈ ہو رہا ہے…';

  @override
  String get outOfLivesAdPlaying => 'اشتہار چل رہا ہے…';

  @override
  String get outOfLivesAdFailedTitle => 'Ad failed to load';

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
  String get saveProgressFailed => 'Couldn\'t sign you in';

  @override
  String get profileTitle => 'Create your profile';

  @override
  String get profileChangeAvatar => 'Change avatar';

  @override
  String get profileUsername => 'USERNAME';

  @override
  String get profileCountry => 'COUNTRY';

  @override
  String get profileLanguage => 'LANGUAGE';

  @override
  String get profileChooseCountry => 'Choose your country';

  @override
  String get profileCountrySearchHint => 'Search countries';

  @override
  String get profileCountryNoResults => 'No countries found';

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
  String get profileChooseAvatar => 'Choose your avatar';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileEditAction => 'Edit profile';

  @override
  String get profileSaveChanges => 'Save changes';

  @override
  String get profileChangesSaved => 'Changes saved';

  @override
  String get profileUpdateError => 'Couldn\'t save your changes';

  @override
  String get contentErrorTitle => 'یہ لوڈ نہیں ہو سکا';

  @override
  String get contentErrorBody => 'اپنا کنکشن دیکھ کر دوبارہ کوشش کریں۔';

  @override
  String get commonMockFeature => 'Mock — no real sharing wired yet';

  @override
  String get commonSharedMock => 'Shared! (mock — no real sharing wired yet)';

  @override
  String get shareSpoilerFree => 'Spoiler-free — no answers included.';

  @override
  String get dailyTitle => 'Daily';

  @override
  String dailyStreakChip(int count) {
    return '$count days';
  }

  @override
  String get dailyTodaysChallenge => 'TODAY\'S CHALLENGE';

  @override
  String dailyQuestionsMeta(int questions, int categories, int seconds) {
    return '$questions questions from $categories categories · ${seconds}s each';
  }

  @override
  String dailyTimeRemaining(int hours, int minutes) {
    return '${hours}h ${minutes}m left';
  }

  @override
  String dailyPlayedToday(String count) {
    return '$count PLAYED TODAY';
  }

  @override
  String dailyAverage(int correct, int outOf) {
    return 'AVG $correct/$outOf';
  }

  @override
  String get dailyPlayNow => 'Play now';

  @override
  String get dailyPlayAlreadyPlayedTitle => 'Already played today';

  @override
  String get dailyPlayAlreadyPlayedBody =>
      'You\'ve already completed today\'s challenge. Come back tomorrow for a new one!';

  @override
  String get dailyYourStreak => 'Your streak';

  @override
  String get dailyRules => 'Rules';

  @override
  String get dailyRulesUnavailable => 'Streak rules — coming soon';

  @override
  String dailyFreezesLeft(int count) {
    return '$count streak freezes left.';
  }

  @override
  String get dailyFreezeExplainer =>
      'Miss a day and one is spent automatically.';

  @override
  String get dailyMilestones => 'Milestones';

  @override
  String dailyResultScoreLine(int correct, int total) {
    return '$correct out of $total';
  }

  @override
  String dailyResultBetterThan(int percent) {
    return 'Better than $percent% of players today';
  }

  @override
  String get dailyResultDistribution => 'TODAY\'S DISTRIBUTION';

  @override
  String get dailyResultEarned => 'EARNED';

  @override
  String get dailyResultStreakNow => 'STREAK NOW';

  @override
  String get dailyResultShare => 'Share result 📤';

  @override
  String get dailyResultShareTitle => 'Share your daily result';

  @override
  String get dailyResultBackToDaily => 'Back to Daily';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardScopeGlobal => 'Global';

  @override
  String get leaderboardScopeCountry => '🇵🇰 Country';

  @override
  String get leaderboardScopeFriends => 'Friends';

  @override
  String get leaderboardPeriodWeek => 'This week';

  @override
  String get leaderboardPeriodMonth => 'This month';

  @override
  String get leaderboardPeriodAllTime => 'All time';

  @override
  String get leaderboardPodiumFirst => '1st';

  @override
  String get leaderboardPodiumSecond => '2nd';

  @override
  String get leaderboardPodiumThird => '3rd';

  @override
  String get leaderboardSelfTitle => 'You';

  @override
  String leaderboardSelfSubtitle(int percent, String location) {
    return 'Top $percent% · $location';
  }

  @override
  String get leaderboardSelfGuestTitle => 'You';

  @override
  String get leaderboardSelfGuestSubtitle => 'Not ranked — sign in to compete';

  @override
  String get leaderboardEmptyTitle => 'No rankings yet';

  @override
  String get leaderboardEmptyBody =>
      'Play a few rounds to put yourself on the board.';

  @override
  String get leaderboardEmptyCta => 'Play now';

  @override
  String get categoryLeaderboardSubtitle => 'Category leaderboard · this week';

  @override
  String categoryLeaderboardRank(int rank, String country) {
    return 'You\'re #$rank in $country';
  }

  @override
  String categoryLeaderboardGap(String points) {
    return '$points points from the top 10';
  }

  @override
  String categoryLeaderboardPlay(String subcategory, int level) {
    return 'Play $subcategory Level $level';
  }

  @override
  String get categoryLeaderboardEmptyTitle => 'No rankings yet';

  @override
  String get categoryLeaderboardEmptyBody =>
      'Be the first to set a score here.';

  @override
  String get categoryLeaderboardUnranked => 'Play a level to get ranked';

  @override
  String get categoryLeaderboardUnrankedBody =>
      'Finish a level here and your rank will show up.';

  @override
  String get friendsTitle => 'Friends';

  @override
  String friendsSubtitle(int friends, int pending) {
    return '$friends friends · $pending pending';
  }

  @override
  String get friendsAdd => 'Add friend';

  @override
  String get friendsInvite => 'Invite friends';

  @override
  String get friendsInviteReward => 'You both get 200 🪙';

  @override
  String get friendsShare => 'Share';

  @override
  String friendsRequestsHeading(int count) {
    return 'REQUESTS · $count';
  }

  @override
  String get friendsListHeading => 'FRIENDS';

  @override
  String get friendsAccept => 'Accept';

  @override
  String get friendsDecline => 'Decline';

  @override
  String get friendsDuel => '⚔️ Duel';

  @override
  String get friendsEmptyTitle => 'No friends yet';

  @override
  String get friendsEmptyBody =>
      'Add friends to see who is playing, compare scores, and duel for bragging rights.';

  @override
  String get friendsFindPeople => 'Find people you know';

  @override
  String get leaguePromotionEyebrow => 'RANK UP';

  @override
  String get leaguePromotionPreviousLeague => 'SILVER';

  @override
  String get leaguePromotionNewLeague => 'GOLD';

  @override
  String get leaguePromotionHeadline => 'You\'re in Gold League';

  @override
  String get leaguePromotionExplainer =>
      'Top 30 finish this week promotes you to Platinum. Bottom 10 drops back to Silver. Resets Sunday 00:00 UTC.';

  @override
  String get leaguePromotionCta => 'Let\'s go';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String achievementsUnlockedCount(int unlocked, int total) {
    return '$unlocked of $total unlocked';
  }

  @override
  String get achievementsFilterAll => 'All';

  @override
  String get achievementsFilterSkill => 'Skill';

  @override
  String get achievementsFilterStreak => 'Streak';

  @override
  String get achievementsFilterSocial => 'Social';

  @override
  String get achievementsFilterRare => 'Rare';

  @override
  String get achievementsEmptyTitle => 'No badges here yet';

  @override
  String get achievementsEmptyBody =>
      'Try a different filter, or come back once you\'ve earned a few more.';

  @override
  String badgeDetailPlay(String subcategory) {
    return 'Play $subcategory';
  }

  @override
  String badgeDetailRarity(double percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return '🏆 Rare · $percentString%';
  }

  @override
  String badgeDetailReward(int coins) {
    return '+$coins 🪙';
  }

  @override
  String badgeDetailUnlockedOn(String date) {
    return 'Unlocked $date';
  }

  @override
  String get achievementHintSharpshooter =>
      'Clear every question in one level to go flawless.';

  @override
  String get achievementHintOnFire =>
      'Keep answering correctly in a row without missing one.';

  @override
  String get achievementHintBossSlayer =>
      'Clear a boss level to earn this one.';

  @override
  String get achievementHintBigBrain =>
      'Go flawless on IQ levels to build up this count.';

  @override
  String get achievementHintCategoryKing =>
      'Keep clearing topics in this category with 3 stars.';

  @override
  String get achievementHintCenturion =>
      'String together correct answers across levels without a miss.';

  @override
  String get achievementHintFlawless =>
      'Go flawless on at least one level every day this week.';

  @override
  String get achievementHintGlobetrotter =>
      'Play a level in every category to round out your passport.';

  @override
  String get achievementHintNightOwl =>
      'Answer a question between midnight and 3am on more nights.';

  @override
  String get achievementHintQuickDraw =>
      'Answer faster on average to beat the 3-second bar.';

  @override
  String get achievementHintRocket =>
      'Answer faster on average to beat the 2-second bar.';

  @override
  String get achievementHintScholar => 'Reach level 20 in more subcategories.';

  @override
  String get achievementHintDuelist =>
      'Win more bot duels to close in on this one.';

  @override
  String get achievementHintWeekWarrior =>
      'Keep your daily streak alive to reach a full week.';

  @override
  String get badgeUnlockedEyebrow => 'ACHIEVEMENT UNLOCKED';

  @override
  String badgeUnlockedDescription(String description, double percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return '$description Only $percentString% of players have this one.';
  }

  @override
  String get badgeUnlockedShare => 'Share this 📤';

  @override
  String get badgeUnlockedShareTitle => 'Share your new badge';

  @override
  String get badgeUnlockedNice => 'Nice';

  @override
  String get profileStatPoints => 'POINTS';

  @override
  String get profileStatLevels => 'LEVELS';

  @override
  String get profileStatAccuracy => 'ACCURACY';

  @override
  String get profileStatBadges => 'BADGES';

  @override
  String get profileRecentBadges => 'Recent badges';

  @override
  String profileAllBadges(int count) {
    return 'All $count';
  }

  @override
  String get profileBestCategories => 'Best categories';

  @override
  String profileBestCategoryMeta(int cleared, int total, int stars) {
    return 'Level $cleared/$total · $stars ⭐';
  }

  @override
  String get profileAccuracyLabel => 'accuracy';

  @override
  String profileLevelLine(int level, String rankTitle) {
    return 'LEVEL $level · $rankTitle';
  }

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileGuestUsername => 'Guest';

  @override
  String get profileGuestTitle => 'Sign in to see your profile';

  @override
  String get profileGuestBody =>
      'Track your stats, badges and progress across every device.';

  @override
  String get profileGuestAction => 'Sign in / Sign up';

  @override
  String get profileGuestBannerSubtitle => 'Sign in to save your progress';

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileLogoutTitle => 'Log out of your account?';

  @override
  String get profileLogoutBody =>
      'You\'ll need to sign in again to see your progress on this device.';

  @override
  String get profileLogoutCancel => 'Stay signed in';

  @override
  String get profileLogoutConfirm => 'Log out';

  @override
  String get profileLogoutError =>
      'Couldn\'t log out — check your connection and try again';

  @override
  String get statsTitle => 'Your stats';

  @override
  String get statsRangeChip => 'Last 30 days ▾';

  @override
  String get statsPointsPerDay => 'POINTS PER DAY';

  @override
  String get statsWeekdayLabels => 'M,T,W,T,F,S,S';

  @override
  String get statsAccuracyByCategory => 'Accuracy by category';

  @override
  String statsCoachingIntro(String category) {
    return '$category is your weakest category.';
  }

  @override
  String get statsCoachingBold => 'Ten minutes a day for a week';

  @override
  String statsCoachingOutcome(int percent) {
    return 'would move you past $percent%.';
  }

  @override
  String get statsFastestAnswers => 'Fastest answers';

  @override
  String statsFastestAverage(String seconds) {
    return '${seconds}s average';
  }

  @override
  String get duelMatchmakingTitle => 'Finding an opponent';

  @override
  String duelEloLabel(int elo) {
    return '$elo ELO';
  }

  @override
  String get duelSearchingCaption => '❓ Searching…';

  @override
  String duelSearchingStatus(int seconds, int next) {
    return 'Searching for ${seconds}s · widening range in ${next}s';
  }

  @override
  String duelRoundLabel(int current, int total) {
    return 'QUESTION $current/$total';
  }

  @override
  String duelAnsweredIn(int seconds) {
    return 'Answered in ${seconds}s';
  }

  @override
  String get duelThinking => 'Thinking…';

  @override
  String get duelResultVictoryTitle => '🏆 Victory!';

  @override
  String get duelResultDefeatTitle => 'Good game';

  @override
  String get duelResultRoundsWon => 'Correct answers';

  @override
  String get duelResultAvgTime => 'Average answer time';

  @override
  String duelResultAvgTimeValue(String player, String opponent) {
    return '${player}s vs ${opponent}s';
  }

  @override
  String get duelResultElo => 'ELO';

  @override
  String get duelResultReward => 'Reward';

  @override
  String get duelResultRematch => 'Rematch';

  @override
  String get duelResultFindNew => 'Find a new opponent';

  @override
  String get duelArenaTitle => 'Duel Arena';

  @override
  String duelArenaOnline(int count) {
    return '$count in the arena';
  }

  @override
  String get duelArenaReconnecting => 'Reconnecting…';

  @override
  String get duelArenaCloseLabel => 'Close arena';

  @override
  String get duelQuickMatchTitle => 'Quick match';

  @override
  String get duelQuickMatchBody => 'Auto-paired with a player near your level';

  @override
  String get duelQuickMatchCta => 'Find match';

  @override
  String get duelLiveChallengesHeader => 'Live challenges';

  @override
  String get duelFeedEmptyTitle => 'No live challenges yet';

  @override
  String get duelFeedEmptyBody =>
      'Throw down the first one — players in the same topic see it instantly.';

  @override
  String get duelFeedEmptyCta => 'Create challenge';

  @override
  String duelFeedNewPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new challenges',
      one: '1 new challenge',
    );
    return '$_temp0';
  }

  @override
  String get duelRejoinTitle => 'You have a duel in progress';

  @override
  String get duelRejoinCta => 'Rejoin';

  @override
  String duelCardReward(int rounds, int coins) {
    return '$rounds questions · winner +$coins 🪙';
  }

  @override
  String get duelCardJoin => 'Join';

  @override
  String duelCardQueued(int ahead) {
    return 'Request sent · $ahead ahead';
  }

  @override
  String get duelCardSent => 'Request sent';

  @override
  String duelCardDeciding(String name) {
    return '$name is deciding…';
  }

  @override
  String get duelCardNotThisTime => 'Not this time';

  @override
  String duelCardRetryIn(int seconds) {
    return 'Try again in ${seconds}s';
  }

  @override
  String get duelCardAway => 'Away';

  @override
  String get duelCardLive => 'LIVE';

  @override
  String duelCardInProgress(String name) {
    return 'In progress · vs $name';
  }

  @override
  String get duelCardYours => 'Your challenge';

  @override
  String get duelCardWaiting => 'Waiting for a challenger…';

  @override
  String get duelCardPaused => 'Paused while you\'re away';

  @override
  String get duelCardCancel => 'Cancel';

  @override
  String get duelFairnessEven => 'Even match';

  @override
  String get duelFairnessTough => 'Tough one';

  @override
  String get duelFairnessFavourable => 'Favourable';

  @override
  String duelGuestName(String tag) {
    return 'Guest $tag';
  }

  @override
  String duelTopicLevel(int level) {
    return 'Lv $level';
  }

  @override
  String duelCardSemantics(
    String name,
    String league,
    int elo,
    String topic,
    String time,
  ) {
    return 'Challenge from $name, $league, $elo ELO, $topic, $time left';
  }

  @override
  String get duelComposerCreate => 'Create challenge';

  @override
  String duelComposerCooldown(String time) {
    return 'New challenge in $time';
  }

  @override
  String duelComposerOpen(String topic, String time) {
    return 'Your $topic challenge · $time left';
  }

  @override
  String get duelComposerSignIn => 'Sign in to create challenges';

  @override
  String get duelComposerInDuel => 'You\'re in a duel';

  @override
  String duelIncomingTitle(String name) {
    return '$name wants to duel!';
  }

  @override
  String duelIncomingMeta(String league, int elo, String topic, int level) {
    return '$league · $elo ELO · $topic Lv $level';
  }

  @override
  String get duelIncomingAccept => 'Accept';

  @override
  String get duelIncomingDecline => 'Decline';

  @override
  String duelIncomingMore(int count) {
    return '+$count waiting';
  }

  @override
  String get duelPickerTitleCreate => 'Pick your battleground';

  @override
  String get duelPickerTitleMatch => 'Match in which topic?';

  @override
  String get duelPickerBody => 'You\'ll only face players in the same topic.';

  @override
  String duelPickerSearching(int count) {
    return '$count searching';
  }

  @override
  String duelPickerOpen(int count) {
    return '$count open';
  }

  @override
  String get duelPickerEmpty => 'No duel topics in this language yet.';

  @override
  String duelNoticeCooldown(String time) {
    return 'You can create another challenge in $time';
  }

  @override
  String get duelNoticeAlreadyOpen => 'You already have a live challenge';

  @override
  String get duelNoticeDailyCap =>
      'Daily challenge limit reached — try Quick match';

  @override
  String duelNoticeTooManyRequests(int max) {
    return 'You can wait on up to $max challenges at once';
  }

  @override
  String get duelNoticeRateLimited =>
      'Slow down a little — try again in a moment';

  @override
  String duelNoticeCreatorAway(String name) {
    return '$name stepped away';
  }

  @override
  String get duelNoticeChallengeGone => 'That challenge is no longer available';

  @override
  String duelNoticeDeclined(String name) {
    return '$name passed this time';
  }

  @override
  String duelNoticeNoResponse(String name) {
    return 'No answer from $name';
  }

  @override
  String duelNoticeTakenByOther(String name) {
    return '$name started a duel with someone else';
  }

  @override
  String duelNoticeRequesterBusy(String name) {
    return '$name just started another duel';
  }

  @override
  String get duelNoticeOpponentNoShow => 'Your opponent didn\'t show up';

  @override
  String get duelNoticeTopicUnavailable =>
      'That topic isn\'t available for duels right now';

  @override
  String get duelNoticeSignInRequired => 'Sign in to create challenges';

  @override
  String get duelNoticeGeneric => 'Something went wrong — please try again';

  @override
  String duelSearchingBand(int min, int max) {
    return 'Searching… $min – $max ELO';
  }

  @override
  String duelBotOfferTitle(String topic) {
    return 'No one\'s around in $topic right now';
  }

  @override
  String get duelBotOfferBody =>
      'Play a practice bot — clearly labelled, results count at half ELO.';

  @override
  String get duelBotOfferPlay => '🤖 Play a bot';

  @override
  String get duelKeepSearching => 'Keep searching';

  @override
  String get duelBotBadge => 'BOT';

  @override
  String get duelLeaveQueueLabel => 'Stop searching';

  @override
  String duelLeagueEloCaption(String league, String elo) {
    return '$league · $elo ELO';
  }

  @override
  String get duelIntroRanked => 'Ranked';

  @override
  String get duelIntroUnranked => 'Unranked';

  @override
  String duelIntroStartsIn(int seconds) {
    return 'Starting in $seconds';
  }

  @override
  String duelWaitingFor(String name) {
    return 'Waiting for $name…';
  }

  @override
  String get duelGetReady => 'Get ready…';

  @override
  String duelOpponentReconnecting(String name, int seconds) {
    return '$name reconnecting… ${seconds}s';
  }

  @override
  String get duelQuitTitle => 'Leave the duel?';

  @override
  String get duelQuitBody =>
      'Leaving gives your opponent the remaining questions.';

  @override
  String get duelQuitConfirm => 'Leave';

  @override
  String get duelQuitStay => 'Stay';

  @override
  String get duelQuitLabel => 'Leave duel';

  @override
  String get duelResultDrawTitle => 'It\'s a draw';

  @override
  String duelResultUnranked(String name, int count) {
    return 'Unranked — you\'ve played $name $count times today';
  }

  @override
  String get duelResultUnrankedShort => 'Unranked — ELO unchanged';

  @override
  String duelResultOpponentForfeit(String name) {
    return '$name left — the remaining questions count for you';
  }

  @override
  String get duelResultYouForfeited => 'You left the duel';

  @override
  String get duelResultXp => 'XP';

  @override
  String duelRematchWaiting(String name) {
    return 'Waiting for $name…';
  }

  @override
  String duelRematchOffered(String name) {
    return '$name wants a rematch!';
  }

  @override
  String get duelRematchAccept => 'Accept rematch';

  @override
  String duelRematchUnavailable(String name) {
    return '$name has left';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'APPEARANCE';

  @override
  String get settingsGame => 'GAME';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSoundEffects => 'Sound effects';

  @override
  String get settingsMusic => 'Music';

  @override
  String get settingsHaptics => 'Haptics';

  @override
  String get settingsAccount => 'ACCOUNT';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPrivacy => 'Privacy & leaderboard visibility';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeveloper => 'DEVELOPER';

  @override
  String get settingsSimulateOffline => 'Simulate offline';

  @override
  String get settingsPreviewForceUpdate => 'Preview: force update screen';

  @override
  String get settingsPreviewNotificationPermission =>
      'Preview: notification permission';

  @override
  String get settingsVersion => 'Quizoo v1.0.0 (mock build)';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsAccept => 'Accept';

  @override
  String get notificationsEmpty => 'Nothing new right now.';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String deleteAccountBody(int points, int badges, int streak) {
    return 'You\'ll lose $points points, $badges badges and a $streak-day streak. This can\'t be undone.';
  }

  @override
  String get deleteAccountBodyLoading => 'Loading your account details…';

  @override
  String deleteAccountTypeUsername(String username) {
    return 'Type \"$username\" to confirm';
  }

  @override
  String get deleteAccountKeep => 'Keep my account';

  @override
  String get deleteAccountDelete => 'Delete permanently';

  @override
  String get deleteAccountDone =>
      'Account deleted (mock) — you\'re browsing as a guest';

  @override
  String get forceUpdateTitle => 'Time to update';

  @override
  String get forceUpdateBody =>
      'Version 1.4 adds 1v1 duels and 12 new topics. This version can no longer connect.';

  @override
  String get forceUpdateCta => 'Update Quizoo';

  @override
  String get forceUpdateMock => 'Mock — no app store wired up';

  @override
  String get notificationPermissionTitle => 'Keep your streak alive?';

  @override
  String get notificationPermissionBody =>
      'We\'ll send one reminder a day at a time you choose. Nothing else — no marketing, no \"we miss you\".';

  @override
  String get notificationPermissionTimeLabel => 'Reminder time';

  @override
  String get notificationPermissionTurnOn => 'Turn on reminders';

  @override
  String get notificationPermissionNotNow => 'Not now';

  @override
  String notificationPermissionOnTitle(String time) {
    return 'Reminders on for $time';
  }

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyShowOnLeaderboards => 'Show my rank on leaderboards';

  @override
  String get privacyShowActivityToFriends => 'Show my activity to friends';

  @override
  String get quizReportLabel => 'Report this question';

  @override
  String get quizAudioOnLabel => 'Turn off question read-aloud';

  @override
  String get quizAudioOffLabel => 'Turn on question read-aloud';

  @override
  String get homeOfflineMode => 'Offline mode';

  @override
  String homeOfflineWarning(int count) {
    return 'No connection. You can still play $count downloaded topics. Scores sync when you\'re back.';
  }

  @override
  String get homeOfflineAvailable => 'Available offline';

  @override
  String get homeOfflineNeedsConnection => 'NEEDS CONNECTION';

  @override
  String get homeOfflineNeedsConnectionList =>
      'Duels · Leaderboards · Daily challenge';

  @override
  String get reportQuestionTitle => 'Report this question';

  @override
  String reportQuestionMeta(String question) {
    return '\"$question\"';
  }

  @override
  String get reportReasonWrong => 'The answer is wrong';

  @override
  String get reportReasonUnclear => 'Question is unclear';

  @override
  String get reportReasonTranslation => 'Bad translation';

  @override
  String get reportReasonOffensive => 'Offensive content';

  @override
  String get reportReasonImage => 'Image doesn\'t load';

  @override
  String get reportQuestionSubmit => 'Send report';

  @override
  String get reportQuestionSent => 'Report sent — thanks for the flag';

  @override
  String get shareDemoTitle => 'Share';

  @override
  String get shareDemoPreview => 'Quizoo — the quiz that plays like a game.';
}
