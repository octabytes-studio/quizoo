import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
  ];

  /// The application name.
  ///
  /// In en, this message translates to:
  /// **'Quizoo'**
  String get appTitle;

  /// S-04/S-05 Home top bar greeting.
  ///
  /// In en, this message translates to:
  /// **'Hey, {name} 👋'**
  String homeGreeting(String name);

  /// S-04 Home top bar second line: player level and rank title.
  ///
  /// In en, this message translates to:
  /// **'Level {level} · {title}'**
  String homeSubtitle(int level, String title);

  /// S-04 Home popular rail heading.
  ///
  /// In en, this message translates to:
  /// **'🔥 Popular this week'**
  String get homePopularThisWeek;

  /// S-04 Home daily banner heading.
  ///
  /// In en, this message translates to:
  /// **'🎯 Daily challenge'**
  String get homeDailyChallenge;

  /// Trailing link on a Home section header.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// S-04 subcategory tile progress caption.
  ///
  /// In en, this message translates to:
  /// **'Lv {cleared}/{total}'**
  String homeLevelProgress(int cleared, int total);

  /// Caption on a subcategory tile never played.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get homeNew;

  /// Shell tab 1.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// Shell tab 2.
  ///
  /// In en, this message translates to:
  /// **'Ranks'**
  String get tabRanks;

  /// Shell centre FAB.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get tabPlay;

  /// Shell tab 4.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get tabDaily;

  /// Shell tab 5.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get tabYou;

  /// S-11 question screen HUD counter.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionCounter(int current, int total);

  /// S-11 meta line above the question card.
  ///
  /// In en, this message translates to:
  /// **'Level {level} of {total} · {seconds}s per question'**
  String questionLevelMeta(int level, int total, int seconds);

  /// The bible's sample question, used by the S-11 placeholder and the RTL proof of concept.
  ///
  /// In en, this message translates to:
  /// **'Which planet has the shortest day in the Solar System?'**
  String get questionSample;

  /// Streak chip.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak'**
  String questionStreak(int count);

  /// Error state primary action.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// Dialog secondary action.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Sheet / dialog dismiss action.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Back affordance semantic label.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Settings theme option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Settings theme option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Settings theme option — follow the system.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// Debug screen listing all 54 bible screens.
  ///
  /// In en, this message translates to:
  /// **'Screen index'**
  String get devScreenIndexTitle;

  /// Subtitle of the debug screen index.
  ///
  /// In en, this message translates to:
  /// **'All 54 screens · debug only'**
  String get devScreenIndexSubtitle;

  /// Body of a placeholder screen awaiting a later plan.
  ///
  /// In en, this message translates to:
  /// **'Not yet implemented — see plan {plan}.'**
  String devPlaceholderBody(String plan);

  /// Note on a placeholder for a screen ID that shares another screen's route.
  ///
  /// In en, this message translates to:
  /// **'A state of {id}, not its own route.'**
  String devStateOf(String id);

  /// S-01 Splash wordmark subtitle.
  ///
  /// In en, this message translates to:
  /// **'Play smarter.'**
  String get splashTagline;

  /// S-01 Splash build version, pinned to the bottom of the screen.
  ///
  /// In en, this message translates to:
  /// **'v{version}'**
  String splashVersion(String version);

  /// S-02 Onboarding skip affordance, present from card one.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// S-02 Onboarding advance button.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// S-02 Onboarding final-card button.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play'**
  String get onboardingStart;

  /// S-02 Onboarding card 1 heading.
  ///
  /// In en, this message translates to:
  /// **'Pick a topic\nyou actually like'**
  String get onboardingPickTitle;

  /// S-02 Onboarding card 1 body.
  ///
  /// In en, this message translates to:
  /// **'Fourteen categories and hundreds of topics. Start with the one you would argue about.'**
  String get onboardingPickBody;

  /// S-02 Onboarding card 2 heading.
  ///
  /// In en, this message translates to:
  /// **'Climb 20 levels\nin every topic'**
  String get onboardingClimbTitle;

  /// S-02 Onboarding card 2 body.
  ///
  /// In en, this message translates to:
  /// **'Each level is harder and faster than the last. Three stars means you truly know it.'**
  String get onboardingClimbBody;

  /// S-02 Onboarding card 3 heading.
  ///
  /// In en, this message translates to:
  /// **'Beat your friends\nevery single week'**
  String get onboardingBeatTitle;

  /// S-02 Onboarding card 3 body.
  ///
  /// In en, this message translates to:
  /// **'Leagues reset every Sunday. Thirty players, one board, nowhere to hide.'**
  String get onboardingBeatBody;

  /// S-03 Language picker heading.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageTitle;

  /// S-03 Language picker subheading.
  ///
  /// In en, this message translates to:
  /// **'You can change this any time in Settings'**
  String get languageSubtitle;

  /// S-03 live question count on the selected-language row.
  ///
  /// In en, this message translates to:
  /// **'{count} quizzes'**
  String languageQuizCount(String count);

  /// S-03 row caption for a language whose native name is not in Latin script.
  ///
  /// In en, this message translates to:
  /// **'{name} · {count} quizzes'**
  String languageQuizCountNamed(String name, String count);

  /// S-03 Language picker CTA.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get languageContinue;

  /// S-03 honest note about which locales actually re-render.
  ///
  /// In en, this message translates to:
  /// **'Only English and Urdu are translated in this build — the others show English copy.'**
  String get languagePartialSupport;

  /// S-04 Home top bar greeting for a guest.
  ///
  /// In en, this message translates to:
  /// **'Welcome 👋'**
  String get homeWelcome;

  /// S-04 Home top bar second line for a guest.
  ///
  /// In en, this message translates to:
  /// **'Playing as Guest'**
  String get homePlayingAsGuest;

  /// S-04 Home informational grape card heading.
  ///
  /// In en, this message translates to:
  /// **'Save your progress'**
  String get homeSaveProgressTitle;

  /// S-04 Home informational grape card body.
  ///
  /// In en, this message translates to:
  /// **'Sign in later — play first, we\'ll remember'**
  String get homeSaveProgressBody;

  /// S-05 Home continue-rail heading.
  ///
  /// In en, this message translates to:
  /// **'▶︎ Continue'**
  String get homeContinueHeading;

  /// S-05 Home continue row title.
  ///
  /// In en, this message translates to:
  /// **'{subcategory} · Level {level}'**
  String homeContinueTitle(String subcategory, int level);

  /// S-05 Home continue row caption.
  ///
  /// In en, this message translates to:
  /// **'{points} pts · {lives} lives left'**
  String homeContinueMeta(String points, int lives);

  /// S-05 Home continue row trailing affordance.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get homeResume;

  /// S-05 Home daily banner heading.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get homeDailyChallengeTitle;

  /// S-05 Home daily banner caption.
  ///
  /// In en, this message translates to:
  /// **'{questions} questions · ends in {remaining}'**
  String homeDailyChallengeMeta(int questions, String remaining);

  /// S-05 Home daily banner action.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get homeDailyPlay;

  /// S-04 popular card play count.
  ///
  /// In en, this message translates to:
  /// **'👥 {count} played'**
  String homePlayedCount(String count);

  /// S-04 popular card badge on a trending quiz.
  ///
  /// In en, this message translates to:
  /// **'HOT'**
  String get homeHotBadge;

  /// S-05 Home top bar second line.
  ///
  /// In en, this message translates to:
  /// **'🔥 {streak}-day streak · Level {level}'**
  String homeStreakLevel(int streak, int level);

  /// Semantic label for Home's search icon button.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeSearchLabel;

  /// S-04 subcategory tile caption before anything is played.
  ///
  /// In en, this message translates to:
  /// **'{count} levels'**
  String homeLevelsAvailable(int count);

  /// Caption on a subcategory tile that is not open yet.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get homeLocked;

  /// S-05 category section header topic count, shown when a category has ten or fewer topics.
  ///
  /// In en, this message translates to:
  /// **'{count} topics'**
  String homeTopicCount(int count);

  /// S-05 category section header See-all pill, shown once a category passes ten topics.
  ///
  /// In en, this message translates to:
  /// **'See all {count}'**
  String homeSeeAllCount(int count);

  /// Subcategory card status line before any of its levels are cleared.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String homeQuestionCount(int count);

  /// Subcategory card status line once at least one level is cleared but not all.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String homeLevelShort(int level);

  /// Subcategory card status line once every level is cleared.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get homeComplete;

  /// Semantic label read for a whole tappable category section header row.
  ///
  /// In en, this message translates to:
  /// **'{name}, {count} topics'**
  String homeCategorySectionLabel(String name, int count);

  /// S-06 search field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Search topics'**
  String get searchHint;

  /// S-06 result count meta label.
  ///
  /// In en, this message translates to:
  /// **'{count} RESULTS'**
  String searchResultCount(int count);

  /// S-06 result row caption showing the parent category and sub-path.
  ///
  /// In en, this message translates to:
  /// **'{category} › {path} · {questions} questions'**
  String searchBreadcrumb(String category, String path, int questions);

  /// S-06 result row trailing affordance.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get searchPlay;

  /// S-06 trending chip cloud heading.
  ///
  /// In en, this message translates to:
  /// **'TRENDING SEARCHES'**
  String get searchTrending;

  /// S-06 empty state heading.
  ///
  /// In en, this message translates to:
  /// **'Nothing matched'**
  String get searchEmptyTitle;

  /// S-06 empty state body.
  ///
  /// In en, this message translates to:
  /// **'Try a shorter word, or pick one of the trending searches below.'**
  String get searchEmptyBody;

  /// S-07 category header meta line.
  ///
  /// In en, this message translates to:
  /// **'{topics} topics · {questions} questions · {players} players'**
  String categoryMeta(int topics, String questions, String players);

  /// S-07 topics section heading.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get categoryTopics;

  /// S-07 sort control, currently display-only.
  ///
  /// In en, this message translates to:
  /// **'Sort: Popular'**
  String get categorySortPopular;

  /// Semantic label for S-07's overflow button.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get categoryMore;

  /// S-07 header stat chip — total stars earned across the category's topics.
  ///
  /// In en, this message translates to:
  /// **'⭐ {count} stars'**
  String categoryStatsStars(int count);

  /// S-07 header stat chip — total levels cleared across the category's topics.
  ///
  /// In en, this message translates to:
  /// **'🏁 {count} levels'**
  String categoryStatsLevels(int count);

  /// S-07 resume card eyebrow label.
  ///
  /// In en, this message translates to:
  /// **'PICK UP WHERE YOU LEFT'**
  String get categoryResumeEyebrow;

  /// Levels 1–5 difficulty band (§19).
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// Levels 6–10 difficulty band.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// Levels 11–15 difficulty band.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// Levels 16–20 difficulty band.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get difficultyExpert;

  /// Levels 41–50 difficulty band.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get difficultyMaster;

  /// S-08 subcategory header card caption.
  ///
  /// In en, this message translates to:
  /// **'{questions} questions · {levels} levels'**
  String levelMapSubtitle(int questions, int levels);

  /// S-08 header stat label.
  ///
  /// In en, this message translates to:
  /// **'BEST SCORE'**
  String get levelMapBestScore;

  /// S-08 header stat label.
  ///
  /// In en, this message translates to:
  /// **'STARS'**
  String get levelMapStars;

  /// S-08 header stat label.
  ///
  /// In en, this message translates to:
  /// **'RANK'**
  String get levelMapRank;

  /// S-08 difficulty band divider.
  ///
  /// In en, this message translates to:
  /// **'{difficulty} · {seconds}s PER QUESTION'**
  String levelMapBand(String difficulty, int seconds);

  /// S-08 flag above the current node.
  ///
  /// In en, this message translates to:
  /// **'YOU\'RE HERE'**
  String get levelMapYoureHere;

  /// S-08 label under a cleared boss node.
  ///
  /// In en, this message translates to:
  /// **'BOSS · CLEARED'**
  String get levelMapBossCleared;

  /// S-08 label under a 3-starred node.
  ///
  /// In en, this message translates to:
  /// **'PERFECT'**
  String get levelMapPerfect;

  /// S-08 label under a cleared node.
  ///
  /// In en, this message translates to:
  /// **'CLEARED'**
  String get levelMapCleared;

  /// S-08 label under the current node.
  ///
  /// In en, this message translates to:
  /// **'{questions} QUESTIONS · {seconds}s EACH'**
  String levelMapCurrent(int questions, int seconds);

  /// S-08 unlock condition on the next locked node.
  ///
  /// In en, this message translates to:
  /// **'CLEAR LEVEL {level}'**
  String levelMapUnlockAfter(int level);

  /// S-08 label under a locked node further down the path.
  ///
  /// In en, this message translates to:
  /// **'LOCKED'**
  String get levelMapLocked;

  /// S-08 bottom CTA.
  ///
  /// In en, this message translates to:
  /// **'Play Level {level}'**
  String levelMapPlayLevel(int level);

  /// S-08 bottom CTA sub-line.
  ///
  /// In en, this message translates to:
  /// **'{difficulty} · {questions} questions · {seconds}s each'**
  String levelMapPlaySub(String difficulty, int questions, int seconds);

  /// Semantic label for S-08's trophy button.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get levelMapLeaderboard;

  /// S-09 level brief sheet heading.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelBriefTitle(int level);

  /// S-09 level brief sheet subheading.
  ///
  /// In en, this message translates to:
  /// **'{subcategory} · {difficulty}'**
  String levelBriefSubtitle(String subcategory, String difficulty);

  /// S-09 streak multiplier chip.
  ///
  /// In en, this message translates to:
  /// **'🔥 Streak ×{multiplier}'**
  String levelBriefStreakMultiplier(String multiplier);

  /// S-09 stat label.
  ///
  /// In en, this message translates to:
  /// **'QUESTIONS'**
  String get levelBriefQuestions;

  /// S-09 stat label.
  ///
  /// In en, this message translates to:
  /// **'PER QUESTION'**
  String get levelBriefPerQuestion;

  /// S-09 stat label.
  ///
  /// In en, this message translates to:
  /// **'LIVES'**
  String get levelBriefLives;

  /// S-09 per-question seconds value.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String levelBriefSeconds(int seconds);

  /// S-09 power-up row heading.
  ///
  /// In en, this message translates to:
  /// **'POWER-UPS IN HAND'**
  String get levelBriefPowerUps;

  /// S-09 primary CTA.
  ///
  /// In en, this message translates to:
  /// **'Start Level {level}'**
  String levelBriefStart(int level);

  /// S-09 CTA label while the level's questions are still prefetching.
  ///
  /// In en, this message translates to:
  /// **'Preparing level…'**
  String get levelBriefPreparing;

  /// S-10 countdown meta label.
  ///
  /// In en, this message translates to:
  /// **'{subcategory} · LEVEL {level}'**
  String countdownMeta(String subcategory, int level);

  /// S-10 countdown caption.
  ///
  /// In en, this message translates to:
  /// **'Get ready…'**
  String get countdownGetReady;

  /// S-10 final countdown beat.
  ///
  /// In en, this message translates to:
  /// **'GO'**
  String get countdownGo;

  /// S-11 HUD score label, followed by the value.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get quizScore;

  /// Semantic label for S-11's ✕ button.
  ///
  /// In en, this message translates to:
  /// **'Quit level'**
  String get quizQuitLabel;

  /// Semantic label for S-11's pause affordance.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get quizPauseLabel;

  /// S-11 HUD streak badge.
  ///
  /// In en, this message translates to:
  /// **'🔥 {count}'**
  String quizStreak(int count);

  /// Power-up that removes two wrong options.
  ///
  /// In en, this message translates to:
  /// **'50:50'**
  String get quizPowerUpFiftyFifty;

  /// Power-up that adds five seconds.
  ///
  /// In en, this message translates to:
  /// **'+5s'**
  String get quizPowerUpAddTime;

  /// S-12 feedback banner heading.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get feedbackCorrect;

  /// S-13 feedback banner heading.
  ///
  /// In en, this message translates to:
  /// **'Not quite'**
  String get feedbackWrong;

  /// Feedback banner heading when the clock ran out unanswered.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up'**
  String get feedbackTimeout;

  /// S-12 points earned, top-right of the banner.
  ///
  /// In en, this message translates to:
  /// **'+{points}'**
  String feedbackPoints(String points);

  /// S-13 / timeout banner cost, top-right of the banner.
  ///
  /// In en, this message translates to:
  /// **'−1 ❤️'**
  String get feedbackHeartLost;

  /// S-12 / S-13 banner action.
  ///
  /// In en, this message translates to:
  /// **'Next question'**
  String get feedbackNext;

  /// Banner action on the last question of a level.
  ///
  /// In en, this message translates to:
  /// **'See results'**
  String get feedbackFinish;

  /// S-12 per-question score breakdown appended to the explanation.
  ///
  /// In en, this message translates to:
  /// **'Speed +{speed} · Difficulty ×{difficulty} · Streak ×{streak}'**
  String feedbackBreakdown(int speed, String difficulty, String streak);

  /// S-13 sentence appended when a streak was broken.
  ///
  /// In en, this message translates to:
  /// **'Streak reset.'**
  String get feedbackStreakReset;

  /// S-13 sentence appended when exactly one heart remains.
  ///
  /// In en, this message translates to:
  /// **'One heart left — the next wrong answer ends the level.'**
  String get feedbackLastHeart;

  /// S-17 pause sheet heading.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pauseTitle;

  /// S-17 pause sheet body.
  ///
  /// In en, this message translates to:
  /// **'Your timer is frozen. Nothing is lost.'**
  String get pauseBody;

  /// S-17 primary action.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get pauseResume;

  /// S-17 sound toggle, currently on.
  ///
  /// In en, this message translates to:
  /// **'🔊 Sound on'**
  String get pauseSoundOn;

  /// S-17 sound toggle, currently off.
  ///
  /// In en, this message translates to:
  /// **'🔇 Sound off'**
  String get pauseSoundOff;

  /// S-17 haptics toggle, currently on.
  ///
  /// In en, this message translates to:
  /// **'📳 Haptics on'**
  String get pauseHapticsOn;

  /// S-17 haptics toggle, currently off.
  ///
  /// In en, this message translates to:
  /// **'📴 Haptics off'**
  String get pauseHapticsOff;

  /// S-17 restart action.
  ///
  /// In en, this message translates to:
  /// **'Restart level'**
  String get pauseRestart;

  /// S-17 destructive action.
  ///
  /// In en, this message translates to:
  /// **'Quit — lose progress'**
  String get pauseQuit;

  /// S-18 quit dialog heading.
  ///
  /// In en, this message translates to:
  /// **'Quit level {level}?'**
  String quitTitle(int level);

  /// S-18 quit dialog body, quoting the player's own live numbers.
  ///
  /// In en, this message translates to:
  /// **'You\'re {questions} questions in with {points} points. Quitting loses this level\'s score and one life. Your streak survives.'**
  String quitBody(int questions, String points);

  /// S-18 safe action, listed first and dominant.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get quitKeepPlaying;

  /// S-18 destructive action, listed second and never pre-focused.
  ///
  /// In en, this message translates to:
  /// **'Quit level'**
  String get quitConfirm;

  /// S-19 dialog heading.
  ///
  /// In en, this message translates to:
  /// **'Out of lives'**
  String get outOfLivesTitle;

  /// S-19 dialog body. Never claims hearts regenerate on a timer — a fresh level start simply grants 3 again.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad for one more heart, or come back with 3 fresh hearts next time you start this level.'**
  String get outOfLivesBody;

  /// S-19 free action, listed first and loudest.
  ///
  /// In en, this message translates to:
  /// **'▶ Watch an ad for 1 ❤️'**
  String get outOfLivesWatchAd;

  /// S-19 abandon action.
  ///
  /// In en, this message translates to:
  /// **'Back to level map'**
  String get outOfLivesBackToMap;

  /// S-19 label while the rewarded ad is loading, right after the player taps the button.
  ///
  /// In en, this message translates to:
  /// **'Loading ad…'**
  String get outOfLivesAdLoading;

  /// S-19 label while the rewarded ad runs.
  ///
  /// In en, this message translates to:
  /// **'Playing ad…'**
  String get outOfLivesAdPlaying;

  /// S-19 snackbar when the rewarded ad fails to load or show — the button must always stay recoverable via retry.
  ///
  /// In en, this message translates to:
  /// **'Ad failed to load'**
  String get outOfLivesAdFailedTitle;

  /// S-21 heading.
  ///
  /// In en, this message translates to:
  /// **'Level {level} complete!'**
  String resultCompleteTitle(int level);

  /// S-21 star caption when the third star is still available.
  ///
  /// In en, this message translates to:
  /// **'{stars} STARS · {needed} MORE CORRECT FOR THE THIRD'**
  String resultStarsMeta(int stars, int needed);

  /// S-21 star caption at three stars.
  ///
  /// In en, this message translates to:
  /// **'3 STARS · A PERFECT RUN'**
  String get resultStarsPerfect;

  /// S-21 score card label.
  ///
  /// In en, this message translates to:
  /// **'FINAL SCORE'**
  String get resultFinalScore;

  /// S-21 breakdown row: base points.
  ///
  /// In en, this message translates to:
  /// **'{count} correct × 100'**
  String resultBreakdownCorrect(int count);

  /// S-21 breakdown row.
  ///
  /// In en, this message translates to:
  /// **'Speed bonus'**
  String get resultBreakdownSpeed;

  /// S-21 breakdown row.
  ///
  /// In en, this message translates to:
  /// **'Best streak ×{streak}'**
  String resultBreakdownStreak(int streak);

  /// S-21 breakdown row.
  ///
  /// In en, this message translates to:
  /// **'Clean run — no power-ups'**
  String get resultBreakdownCleanRun;

  /// S-21 breakdown row.
  ///
  /// In en, this message translates to:
  /// **'Flawless — 20 of 20'**
  String get resultBreakdownFlawless;

  /// S-21 breakdown row.
  ///
  /// In en, this message translates to:
  /// **'{count} hearts unspent'**
  String resultBreakdownHearts(int count);

  /// S-21 breakdown row on levels 5, 10, 15 and 20.
  ///
  /// In en, this message translates to:
  /// **'Boss level ×2'**
  String get resultBreakdownBoss;

  /// S-21 breakdown total row.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get resultBreakdownTotal;

  /// S-21 payout stat label.
  ///
  /// In en, this message translates to:
  /// **'COINS'**
  String get resultCoins;

  /// S-21 payout stat label.
  ///
  /// In en, this message translates to:
  /// **'EXPERIENCE'**
  String get resultExperience;

  /// S-21 coin payout.
  ///
  /// In en, this message translates to:
  /// **'+{coins} 🪙'**
  String resultCoinsValue(String coins);

  /// S-21 XP payout.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String resultXpValue(String xp);

  /// S-21 XP bar leading label.
  ///
  /// In en, this message translates to:
  /// **'LEVEL {level}'**
  String resultPlayerLevel(int level);

  /// S-21 XP bar trailing label.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String resultXpProgress(String current, String total);

  /// S-21 primary CTA.
  ///
  /// In en, this message translates to:
  /// **'Next level →'**
  String get resultNextLevel;

  /// S-21 secondary CTA, only when three stars are still unearned.
  ///
  /// In en, this message translates to:
  /// **'Replay for 3 stars'**
  String get resultReplay;

  /// S-21 / S-22 return action.
  ///
  /// In en, this message translates to:
  /// **'Back to map'**
  String get resultBackToMap;

  /// Semantic label for S-21's share button.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get resultShare;

  /// S-22 heading. Reframed as nearly-there, never as a scolding.
  ///
  /// In en, this message translates to:
  /// **'So close!'**
  String get failedTitle;

  /// S-22 subheading after a natural loss.
  ///
  /// In en, this message translates to:
  /// **'You ran out of hearts on question {question}'**
  String failedRanOutOfHearts(int question);

  /// S-22 subheading after a quit — deliberately different copy from a loss.
  ///
  /// In en, this message translates to:
  /// **'You left on question {question}'**
  String failedQuitEarly(int question);

  /// S-22 stat label.
  ///
  /// In en, this message translates to:
  /// **'CORRECT'**
  String get failedCorrect;

  /// S-22 stat label.
  ///
  /// In en, this message translates to:
  /// **'POINTS'**
  String get failedPoints;

  /// S-22 stat label.
  ///
  /// In en, this message translates to:
  /// **'ACCURACY'**
  String get failedAccuracy;

  /// S-22 accuracy stat value.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String failedAccuracyValue(int percent);

  /// S-22 review-list heading.
  ///
  /// In en, this message translates to:
  /// **'YOU MISSED THESE — TAP TO REVIEW'**
  String get failedMissedHeading;

  /// S-22 review row caption.
  ///
  /// In en, this message translates to:
  /// **'{correct} — you said {chosen}'**
  String failedMissedAnswer(String correct, String chosen);

  /// S-22 review row caption for a question that timed out.
  ///
  /// In en, this message translates to:
  /// **'{correct} — you ran out of time'**
  String failedMissedTimeout(String correct);

  /// S-22 primary CTA.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get failedTryAgain;

  /// S-22 primary CTA cost, shown inline after the label.
  ///
  /// In en, this message translates to:
  /// **'· 1 ❤️'**
  String get failedTryAgainCost;

  /// S-24 sheet heading, quoting the player's own score.
  ///
  /// In en, this message translates to:
  /// **'Don\'t lose {points} points'**
  String saveProgressTitle(String points);

  /// S-24 sheet body.
  ///
  /// In en, this message translates to:
  /// **'You\'re {percent}% through Level {level} with a {streak}-day streak. Sign in and it\'s saved on every device — free, 5 seconds.'**
  String saveProgressBody(int percent, int level, int streak);

  /// S-24 vendor sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get saveProgressGoogle;

  /// S-24 vendor sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get saveProgressApple;

  /// S-24 email sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get saveProgressEmail;

  /// S-24 decline. Always plain text, never disabled or hidden.
  ///
  /// In en, this message translates to:
  /// **'Not now — keep playing as guest'**
  String get saveProgressNotNow;

  /// S-24 legal microcopy.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms and Privacy Policy.'**
  String get saveProgressTerms;

  /// Snackbar shown once a vendor or email sign-in actually completes.
  ///
  /// In en, this message translates to:
  /// **'Progress saved'**
  String get saveProgressSaved;

  /// S-24 snackbar shown when a vendor sign-in is cancelled or fails after the OAuth browser closes.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign you in'**
  String get saveProgressFailed;

  /// S-25 heading.
  ///
  /// In en, this message translates to:
  /// **'Create your profile'**
  String get profileTitle;

  /// S-25 avatar action.
  ///
  /// In en, this message translates to:
  /// **'Change avatar'**
  String get profileChangeAvatar;

  /// S-25 field label.
  ///
  /// In en, this message translates to:
  /// **'USERNAME'**
  String get profileUsername;

  /// S-25 field label.
  ///
  /// In en, this message translates to:
  /// **'COUNTRY'**
  String get profileCountry;

  /// S-25 field label.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get profileLanguage;

  /// S-25 country picker sheet title.
  ///
  /// In en, this message translates to:
  /// **'Choose your country'**
  String get profileChooseCountry;

  /// S-25 country picker search field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Search countries'**
  String get profileCountrySearchHint;

  /// S-25 country picker empty search-results state.
  ///
  /// In en, this message translates to:
  /// **'No countries found'**
  String get profileCountryNoResults;

  /// S-25 field label.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get profileEmail;

  /// S-25 live availability result.
  ///
  /// In en, this message translates to:
  /// **'✓ available'**
  String get profileUsernameAvailable;

  /// S-25 error copy that says what to do, never 'invalid'.
  ///
  /// In en, this message translates to:
  /// **'Someone has this one — try adding a number'**
  String get profileUsernameTaken;

  /// S-25 error copy.
  ///
  /// In en, this message translates to:
  /// **'Use at least three characters'**
  String get profileUsernameTooShort;

  /// S-25 email error copy, verbatim from the bible.
  ///
  /// In en, this message translates to:
  /// **'Add the part after the @ — like gmail.com'**
  String get profileEmailIncomplete;

  /// S-25 empty-email error copy.
  ///
  /// In en, this message translates to:
  /// **'Add an email so we can restore your progress'**
  String get profileEmailMissing;

  /// S-25 CTA, visibly disabled until every field validates.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get profileCreate;

  /// Snackbar after a mocked profile creation.
  ///
  /// In en, this message translates to:
  /// **'Profile created'**
  String get profileCreated;

  /// S-25 avatar picker sheet title.
  ///
  /// In en, this message translates to:
  /// **'Choose your avatar'**
  String get profileChooseAvatar;

  /// Edit Profile screen's SimpleTopBar title (plan 019).
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTitle;

  /// Semantic label for the tappable avatar on Home/You that opens Edit Profile (plan 019).
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditAction;

  /// Edit Profile's CTA, visibly disabled until valid (plan 019).
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSaveChanges;

  /// Snackbar shown after Edit Profile saves successfully (plan 019).
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get profileChangesSaved;

  /// Snackbar shown when Edit Profile's save fails (plan 019).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your changes'**
  String get profileUpdateError;

  /// Generic content-error heading for this plan's screens.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t load'**
  String get contentErrorTitle;

  /// Generic content-error body.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and give it another go.'**
  String get contentErrorBody;

  /// Snackbar for a plan-003 tap that has no real backend behind it (search, invite, duel, add-friend).
  ///
  /// In en, this message translates to:
  /// **'Mock — no real sharing wired yet'**
  String get commonMockFeature;

  /// Snackbar after tapping a mock share target in ShareSheet.
  ///
  /// In en, this message translates to:
  /// **'Shared! (mock — no real sharing wired yet)'**
  String get commonSharedMock;

  /// ShareSheet message line for the daily result and badge-unlocked shares.
  ///
  /// In en, this message translates to:
  /// **'Spoiler-free — no answers included.'**
  String get shareSpoilerFree;

  /// S-27 top bar title.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyTitle;

  /// S-27 top bar streak chip, paired with a 🔥 leading glyph.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String dailyStreakChip(int count);

  /// S-27 challenge card eyebrow.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S CHALLENGE'**
  String get dailyTodaysChallenge;

  /// S-27 challenge card meta line.
  ///
  /// In en, this message translates to:
  /// **'{questions} questions from {categories} categories · {seconds}s each'**
  String dailyQuestionsMeta(int questions, int categories, int seconds);

  /// S-27 challenge card reward chip — time left in today's window.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m left'**
  String dailyTimeRemaining(int hours, int minutes);

  /// S-27 challenge card footer, count already locale-formatted.
  ///
  /// In en, this message translates to:
  /// **'{count} PLAYED TODAY'**
  String dailyPlayedToday(String count);

  /// S-27 challenge card footer.
  ///
  /// In en, this message translates to:
  /// **'AVG {correct}/{outOf}'**
  String dailyAverage(int correct, int outOf);

  /// S-27 challenge card CTA.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get dailyPlayNow;

  /// Daily-play screen's already-played state title.
  ///
  /// In en, this message translates to:
  /// **'Already played today'**
  String get dailyPlayAlreadyPlayedTitle;

  /// Daily-play screen's already-played state body.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already completed today\'s challenge. Come back tomorrow for a new one!'**
  String get dailyPlayAlreadyPlayedBody;

  /// S-27 section header.
  ///
  /// In en, this message translates to:
  /// **'Your streak'**
  String get dailyYourStreak;

  /// S-27 streak section trailing link.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get dailyRules;

  /// Snackbar for the non-functional Rules link.
  ///
  /// In en, this message translates to:
  /// **'Streak rules — coming soon'**
  String get dailyRulesUnavailable;

  /// S-27 streak-freeze explainer, bold segment.
  ///
  /// In en, this message translates to:
  /// **'{count} streak freezes left.'**
  String dailyFreezesLeft(int count);

  /// S-27 streak-freeze explainer, remainder.
  ///
  /// In en, this message translates to:
  /// **'Miss a day and one is spent automatically.'**
  String get dailyFreezeExplainer;

  /// S-27 section header.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get dailyMilestones;

  /// S-28 headline.
  ///
  /// In en, this message translates to:
  /// **'{correct} out of {total}'**
  String dailyResultScoreLine(int correct, int total);

  /// S-28 subheadline.
  ///
  /// In en, this message translates to:
  /// **'Better than {percent}% of players today'**
  String dailyResultBetterThan(int percent);

  /// S-28 chart card eyebrow.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S DISTRIBUTION'**
  String get dailyResultDistribution;

  /// S-28 stat pair label.
  ///
  /// In en, this message translates to:
  /// **'EARNED'**
  String get dailyResultEarned;

  /// S-28 stat pair label.
  ///
  /// In en, this message translates to:
  /// **'STREAK NOW'**
  String get dailyResultStreakNow;

  /// S-28 primary CTA.
  ///
  /// In en, this message translates to:
  /// **'Share result 📤'**
  String get dailyResultShare;

  /// S-28 ShareSheet title.
  ///
  /// In en, this message translates to:
  /// **'Share your daily result'**
  String get dailyResultShareTitle;

  /// S-28 secondary CTA.
  ///
  /// In en, this message translates to:
  /// **'Back to Daily'**
  String get dailyResultBackToDaily;

  /// S-29 top bar title.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardTitle;

  /// S-29 segmented control.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get leaderboardScopeGlobal;

  /// S-29 segmented control.
  ///
  /// In en, this message translates to:
  /// **'🇵🇰 Country'**
  String get leaderboardScopeCountry;

  /// S-29 segmented control.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get leaderboardScopeFriends;

  /// S-29 period chip.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get leaderboardPeriodWeek;

  /// S-29 period chip.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get leaderboardPeriodMonth;

  /// S-29 period chip.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get leaderboardPeriodAllTime;

  /// S-29 podium — 1st place's rank label.
  ///
  /// In en, this message translates to:
  /// **'1st'**
  String get leaderboardPodiumFirst;

  /// S-29 podium — 2nd place's rank label.
  ///
  /// In en, this message translates to:
  /// **'2nd'**
  String get leaderboardPodiumSecond;

  /// S-29 podium — 3rd place's rank label.
  ///
  /// In en, this message translates to:
  /// **'3rd'**
  String get leaderboardPodiumThird;

  /// S-29 pinned self-row title, signed in.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get leaderboardSelfTitle;

  /// S-29 pinned self-row subtitle, signed in.
  ///
  /// In en, this message translates to:
  /// **'Top {percent}% · {location}'**
  String leaderboardSelfSubtitle(int percent, String location);

  /// S-29 pinned self-row title, guest.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get leaderboardSelfGuestTitle;

  /// S-29 pinned self-row subtitle, guest.
  ///
  /// In en, this message translates to:
  /// **'Not ranked — sign in to compete'**
  String get leaderboardSelfGuestSubtitle;

  /// S-29 empty state, shown when a scope/period has no ranked players.
  ///
  /// In en, this message translates to:
  /// **'No rankings yet'**
  String get leaderboardEmptyTitle;

  /// S-29 empty state body.
  ///
  /// In en, this message translates to:
  /// **'Play a few rounds to put yourself on the board.'**
  String get leaderboardEmptyBody;

  /// S-29 empty state action button.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get leaderboardEmptyCta;

  /// S-30 top bar subtitle.
  ///
  /// In en, this message translates to:
  /// **'Category leaderboard · this week'**
  String get categoryLeaderboardSubtitle;

  /// S-30 header card headline.
  ///
  /// In en, this message translates to:
  /// **'You\'re #{rank} in {country}'**
  String categoryLeaderboardRank(int rank, String country);

  /// S-30 header card subhead, points already locale-formatted.
  ///
  /// In en, this message translates to:
  /// **'{points} points from the top 10'**
  String categoryLeaderboardGap(String points);

  /// S-30 footer CTA.
  ///
  /// In en, this message translates to:
  /// **'Play {subcategory} Level {level}'**
  String categoryLeaderboardPlay(String subcategory, int level);

  /// S-30 empty state, shown when nobody has scored in this category yet.
  ///
  /// In en, this message translates to:
  /// **'No rankings yet'**
  String get categoryLeaderboardEmptyTitle;

  /// S-30 empty state body.
  ///
  /// In en, this message translates to:
  /// **'Be the first to set a score here.'**
  String get categoryLeaderboardEmptyBody;

  /// S-30 header card headline shown instead of the rank line when the player hasn't scored in this category yet.
  ///
  /// In en, this message translates to:
  /// **'Play a level to get ranked'**
  String get categoryLeaderboardUnranked;

  /// S-30 header card subhead shown instead of the points gap when the player hasn't scored in this category yet.
  ///
  /// In en, this message translates to:
  /// **'Finish a level here and your rank will show up.'**
  String get categoryLeaderboardUnrankedBody;

  /// S-31 top bar title.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// S-31 top bar subtitle.
  ///
  /// In en, this message translates to:
  /// **'{friends} friends · {pending} pending'**
  String friendsSubtitle(int friends, int pending);

  /// S-31 top bar trailing icon semantic label.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get friendsAdd;

  /// S-31 invite card title / empty-state action.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get friendsInvite;

  /// S-31 invite card body.
  ///
  /// In en, this message translates to:
  /// **'You both get 200 🪙'**
  String get friendsInviteReward;

  /// S-31 invite card button.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get friendsShare;

  /// S-31 requests section header.
  ///
  /// In en, this message translates to:
  /// **'REQUESTS · {count}'**
  String friendsRequestsHeading(int count);

  /// S-31 friends section header.
  ///
  /// In en, this message translates to:
  /// **'FRIENDS'**
  String get friendsListHeading;

  /// S-31 request row accept button semantic label.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get friendsAccept;

  /// S-31 request row decline button semantic label.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get friendsDecline;

  /// S-31 friend row duel pill.
  ///
  /// In en, this message translates to:
  /// **'⚔️ Duel'**
  String get friendsDuel;

  /// S-31 empty state, the bible's own S-47 worked example.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get friendsEmptyTitle;

  /// S-31 empty state body.
  ///
  /// In en, this message translates to:
  /// **'Add friends to see who is playing, compare scores, and duel for bragging rights.'**
  String get friendsEmptyBody;

  /// S-31 empty state secondary action.
  ///
  /// In en, this message translates to:
  /// **'Find people you know'**
  String get friendsFindPeople;

  /// S-26 eyebrow.
  ///
  /// In en, this message translates to:
  /// **'RANK UP'**
  String get leaguePromotionEyebrow;

  /// S-26 dimmed previous-league label.
  ///
  /// In en, this message translates to:
  /// **'SILVER'**
  String get leaguePromotionPreviousLeague;

  /// S-26 new-league label.
  ///
  /// In en, this message translates to:
  /// **'GOLD'**
  String get leaguePromotionNewLeague;

  /// S-26 headline.
  ///
  /// In en, this message translates to:
  /// **'You\'re in Gold League'**
  String get leaguePromotionHeadline;

  /// S-26 explainer, verbatim from the bible.
  ///
  /// In en, this message translates to:
  /// **'Top 30 finish this week promotes you to Platinum. Bottom 10 drops back to Silver. Resets Sunday 00:00 UTC.'**
  String get leaguePromotionExplainer;

  /// S-26 CTA.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get leaguePromotionCta;

  /// S-33 top bar title.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// S-33 top bar subtitle.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} of {total} unlocked'**
  String achievementsUnlockedCount(int unlocked, int total);

  /// S-33 filter chip.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get achievementsFilterAll;

  /// S-33 filter chip.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get achievementsFilterSkill;

  /// S-33 filter chip.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get achievementsFilterStreak;

  /// S-33 filter chip.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get achievementsFilterSocial;

  /// S-33 filter chip.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get achievementsFilterRare;

  /// S-33 empty state when a filter matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No badges here yet'**
  String get achievementsEmptyTitle;

  /// S-33 empty state body.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter, or come back once you\'ve earned a few more.'**
  String get achievementsEmptyBody;

  /// S-34 locked-badge deep-link CTA.
  ///
  /// In en, this message translates to:
  /// **'Play {subcategory}'**
  String badgeDetailPlay(String subcategory);

  /// S-34 rarity chip.
  ///
  /// In en, this message translates to:
  /// **'🏆 Rare · {percent}%'**
  String badgeDetailRarity(double percent);

  /// S-34 reward chip, also reused on S-23.
  ///
  /// In en, this message translates to:
  /// **'+{coins} 🪙'**
  String badgeDetailReward(int coins);

  /// S-34 unlocked-variant line, date already locale-formatted.
  ///
  /// In en, this message translates to:
  /// **'Unlocked {date}'**
  String badgeDetailUnlockedOn(String date);

  /// S-34 progress hint: badge_sharpshooter.
  ///
  /// In en, this message translates to:
  /// **'Clear every question in one level to go flawless.'**
  String get achievementHintSharpshooter;

  /// S-34 progress hint: badge_on_fire.
  ///
  /// In en, this message translates to:
  /// **'Keep answering correctly in a row without missing one.'**
  String get achievementHintOnFire;

  /// S-34 progress hint: badge_boss_slayer (binary, no fraction).
  ///
  /// In en, this message translates to:
  /// **'Clear a boss level to earn this one.'**
  String get achievementHintBossSlayer;

  /// S-34 progress hint: badge_big_brain.
  ///
  /// In en, this message translates to:
  /// **'Go flawless on IQ levels to build up this count.'**
  String get achievementHintBigBrain;

  /// S-34 progress hint: badge_category_king.
  ///
  /// In en, this message translates to:
  /// **'Keep clearing topics in this category with 3 stars.'**
  String get achievementHintCategoryKing;

  /// S-34 progress hint: badge_centurion.
  ///
  /// In en, this message translates to:
  /// **'String together correct answers across levels without a miss.'**
  String get achievementHintCenturion;

  /// S-34 progress hint: badge_flawless (perfect_week).
  ///
  /// In en, this message translates to:
  /// **'Go flawless on at least one level every day this week.'**
  String get achievementHintFlawless;

  /// S-34 progress hint: badge_globetrotter.
  ///
  /// In en, this message translates to:
  /// **'Play a level in every category to round out your passport.'**
  String get achievementHintGlobetrotter;

  /// S-34 progress hint: badge_night_owl.
  ///
  /// In en, this message translates to:
  /// **'Answer a question between midnight and 3am on more nights.'**
  String get achievementHintNightOwl;

  /// S-34 progress hint: badge_quick_draw.
  ///
  /// In en, this message translates to:
  /// **'Answer faster on average to beat the 3-second bar.'**
  String get achievementHintQuickDraw;

  /// S-34 progress hint: badge_rocket.
  ///
  /// In en, this message translates to:
  /// **'Answer faster on average to beat the 2-second bar.'**
  String get achievementHintRocket;

  /// S-34 progress hint: badge_scholar.
  ///
  /// In en, this message translates to:
  /// **'Reach level 20 in more subcategories.'**
  String get achievementHintScholar;

  /// S-34 progress hint: badge_duelist.
  ///
  /// In en, this message translates to:
  /// **'Win more bot duels to close in on this one.'**
  String get achievementHintDuelist;

  /// S-34 progress hint: badge_week_warrior.
  ///
  /// In en, this message translates to:
  /// **'Keep your daily streak alive to reach a full week.'**
  String get achievementHintWeekWarrior;

  /// S-23 eyebrow.
  ///
  /// In en, this message translates to:
  /// **'ACHIEVEMENT UNLOCKED'**
  String get badgeUnlockedEyebrow;

  /// S-23 body — the badge's own description plus the rarity framing.
  ///
  /// In en, this message translates to:
  /// **'{description} Only {percent}% of players have this one.'**
  String badgeUnlockedDescription(String description, double percent);

  /// S-23 primary CTA.
  ///
  /// In en, this message translates to:
  /// **'Share this 📤'**
  String get badgeUnlockedShare;

  /// S-23 ShareSheet title.
  ///
  /// In en, this message translates to:
  /// **'Share your new badge'**
  String get badgeUnlockedShareTitle;

  /// S-23 dismiss CTA.
  ///
  /// In en, this message translates to:
  /// **'Nice'**
  String get badgeUnlockedNice;

  /// S-32 stat strip label.
  ///
  /// In en, this message translates to:
  /// **'POINTS'**
  String get profileStatPoints;

  /// S-32 stat strip label.
  ///
  /// In en, this message translates to:
  /// **'LEVELS'**
  String get profileStatLevels;

  /// S-32 stat strip label.
  ///
  /// In en, this message translates to:
  /// **'ACCURACY'**
  String get profileStatAccuracy;

  /// S-32 stat strip label.
  ///
  /// In en, this message translates to:
  /// **'BADGES'**
  String get profileStatBadges;

  /// S-32 section header.
  ///
  /// In en, this message translates to:
  /// **'Recent badges'**
  String get profileRecentBadges;

  /// S-32 recent-badges section trailing link.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String profileAllBadges(int count);

  /// S-32 section header.
  ///
  /// In en, this message translates to:
  /// **'Best categories'**
  String get profileBestCategories;

  /// S-32 best-category row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Level {cleared}/{total} · {stars} ⭐'**
  String profileBestCategoryMeta(int cleared, int total, int stars);

  /// S-32 best-category row trailing caption.
  ///
  /// In en, this message translates to:
  /// **'accuracy'**
  String get profileAccuracyLabel;

  /// S-32 header XP-bar caption.
  ///
  /// In en, this message translates to:
  /// **'LEVEL {level} · {rankTitle}'**
  String profileLevelLine(int level, String rankTitle);

  /// S-32 header settings-gear semantic label.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// S-32 header username shown for a guest session.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get profileGuestUsername;

  /// S-32 guest empty-state title.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your profile'**
  String get profileGuestTitle;

  /// S-32 guest empty-state body.
  ///
  /// In en, this message translates to:
  /// **'Track your stats, badges and progress across every device.'**
  String get profileGuestBody;

  /// S-32 guest empty-state CTA.
  ///
  /// In en, this message translates to:
  /// **'Sign in / Sign up'**
  String get profileGuestAction;

  /// S-32 guest sign-in nudge row subtitle, shown above a guest's own (real, anonymous-session) data.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save your progress'**
  String get profileGuestBannerSubtitle;

  /// S-32 logout button, shown only to a signed-in (non-guest, non-anonymous) player.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogout;

  /// S-32 logout confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Log out of your account?'**
  String get profileLogoutTitle;

  /// S-32 logout confirmation dialog body.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to see your progress on this device.'**
  String get profileLogoutBody;

  /// S-32 logout confirmation dialog's dominant, ghost-styled action.
  ///
  /// In en, this message translates to:
  /// **'Stay signed in'**
  String get profileLogoutCancel;

  /// S-32 logout confirmation dialog's destructive action.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogoutConfirm;

  /// Snackbar shown when the real sign-out call fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t log out — check your connection and try again'**
  String get profileLogoutError;

  /// S-35 top bar title.
  ///
  /// In en, this message translates to:
  /// **'Your stats'**
  String get statsTitle;

  /// S-35 non-functional date-range chip (plan 003, Assumption 3).
  ///
  /// In en, this message translates to:
  /// **'Last 30 days ▾'**
  String get statsRangeChip;

  /// S-35 chart card eyebrow.
  ///
  /// In en, this message translates to:
  /// **'POINTS PER DAY'**
  String get statsPointsPerDay;

  /// S-35 chart's seven bar labels, comma-separated.
  ///
  /// In en, this message translates to:
  /// **'M,T,W,T,F,S,S'**
  String get statsWeekdayLabels;

  /// S-35 section header.
  ///
  /// In en, this message translates to:
  /// **'Accuracy by category'**
  String get statsAccuracyByCategory;

  /// S-35 coaching card, first segment.
  ///
  /// In en, this message translates to:
  /// **'{category} is your weakest category.'**
  String statsCoachingIntro(String category);

  /// S-35 coaching card, bold segment.
  ///
  /// In en, this message translates to:
  /// **'Ten minutes a day for a week'**
  String get statsCoachingBold;

  /// S-35 coaching card, final segment.
  ///
  /// In en, this message translates to:
  /// **'would move you past {percent}%.'**
  String statsCoachingOutcome(int percent);

  /// S-35 section header.
  ///
  /// In en, this message translates to:
  /// **'Fastest answers'**
  String get statsFastestAnswers;

  /// S-35 fastest-answers row title, seconds already formatted to one decimal.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s average'**
  String statsFastestAverage(String seconds);

  /// S-39 heading.
  ///
  /// In en, this message translates to:
  /// **'Finding an opponent'**
  String get duelMatchmakingTitle;

  /// S-39/S-40 VS row caption under the player's own avatar.
  ///
  /// In en, this message translates to:
  /// **'{elo} ELO'**
  String duelEloLabel(int elo);

  /// S-39 VS row caption under the shimmering skeleton avatar.
  ///
  /// In en, this message translates to:
  /// **'❓ Searching…'**
  String get duelSearchingCaption;

  /// S-39 status line under the spinner.
  ///
  /// In en, this message translates to:
  /// **'Searching for {seconds}s · widening range in {next}s'**
  String duelSearchingStatus(int seconds, int next);

  /// S-40 round counter under the timer ring.
  ///
  /// In en, this message translates to:
  /// **'QUESTION {current}/{total}'**
  String duelRoundLabel(int current, int total);

  /// S-40 status chip once a side has locked an answer.
  ///
  /// In en, this message translates to:
  /// **'Answered in {seconds}s'**
  String duelAnsweredIn(int seconds);

  /// S-40 status chip while a side has not answered yet.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get duelThinking;

  /// S-41 victory headline.
  ///
  /// In en, this message translates to:
  /// **'🏆 Victory!'**
  String get duelResultVictoryTitle;

  /// S-41 defeat headline.
  ///
  /// In en, this message translates to:
  /// **'Good game'**
  String get duelResultDefeatTitle;

  /// S-41 stat card row label — each player's points (one per correct answer).
  ///
  /// In en, this message translates to:
  /// **'Correct answers'**
  String get duelResultRoundsWon;

  /// S-41 stat card row label.
  ///
  /// In en, this message translates to:
  /// **'Average answer time'**
  String get duelResultAvgTime;

  /// S-41 stat card row value.
  ///
  /// In en, this message translates to:
  /// **'{player}s vs {opponent}s'**
  String duelResultAvgTimeValue(String player, String opponent);

  /// S-41 stat card row label.
  ///
  /// In en, this message translates to:
  /// **'ELO'**
  String get duelResultElo;

  /// S-41 stat card row label.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get duelResultReward;

  /// S-41 primary action.
  ///
  /// In en, this message translates to:
  /// **'Rematch'**
  String get duelResultRematch;

  /// S-41 secondary action.
  ///
  /// In en, this message translates to:
  /// **'Find a new opponent'**
  String get duelResultFindNew;

  /// S-38 arena top bar title.
  ///
  /// In en, this message translates to:
  /// **'Duel Arena'**
  String get duelArenaTitle;

  /// S-38 presence pill — players currently on the arena screen.
  ///
  /// In en, this message translates to:
  /// **'{count} in the arena'**
  String duelArenaOnline(int count);

  /// S-38 chip replacing the presence pill while the live feed reconnects.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get duelArenaReconnecting;

  /// S-38 ✕ button semantics label.
  ///
  /// In en, this message translates to:
  /// **'Close arena'**
  String get duelArenaCloseLabel;

  /// S-38 Quick match hero card title.
  ///
  /// In en, this message translates to:
  /// **'Quick match'**
  String get duelQuickMatchTitle;

  /// S-38 Quick match hero card body.
  ///
  /// In en, this message translates to:
  /// **'Auto-paired with a player near your level'**
  String get duelQuickMatchBody;

  /// S-38 Quick match hero card button.
  ///
  /// In en, this message translates to:
  /// **'Find match'**
  String get duelQuickMatchCta;

  /// S-38 feed section header.
  ///
  /// In en, this message translates to:
  /// **'Live challenges'**
  String get duelLiveChallengesHeader;

  /// S-38 empty feed title.
  ///
  /// In en, this message translates to:
  /// **'No live challenges yet'**
  String get duelFeedEmptyTitle;

  /// S-38 empty feed body.
  ///
  /// In en, this message translates to:
  /// **'Throw down the first one — players in the same topic see it instantly.'**
  String get duelFeedEmptyBody;

  /// S-38 empty feed call to action.
  ///
  /// In en, this message translates to:
  /// **'Create challenge'**
  String get duelFeedEmptyCta;

  /// S-38 pill shown when new challenges arrive while scrolled up.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new challenge} other{{count} new challenges}}'**
  String duelFeedNewPill(int count);

  /// S-38 rejoin banner title.
  ///
  /// In en, this message translates to:
  /// **'You have a duel in progress'**
  String get duelRejoinTitle;

  /// S-38 rejoin banner button.
  ///
  /// In en, this message translates to:
  /// **'Rejoin'**
  String get duelRejoinCta;

  /// S-38 challenge card reward line.
  ///
  /// In en, this message translates to:
  /// **'{rounds} questions · winner +{coins} 🪙'**
  String duelCardReward(int rounds, int coins);

  /// S-38 challenge card join button.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get duelCardJoin;

  /// S-38 challenge card while the viewer's request is queued behind others.
  ///
  /// In en, this message translates to:
  /// **'Request sent · {ahead} ahead'**
  String duelCardQueued(int ahead);

  /// S-38 challenge card right after the viewer requested to join.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get duelCardSent;

  /// S-38 challenge card while the creator decides on the viewer's request.
  ///
  /// In en, this message translates to:
  /// **'{name} is deciding…'**
  String duelCardDeciding(String name);

  /// S-38 challenge card briefly after a decline or no answer.
  ///
  /// In en, this message translates to:
  /// **'Not this time'**
  String get duelCardNotThisTime;

  /// S-38 challenge card retry cool-down.
  ///
  /// In en, this message translates to:
  /// **'Try again in {seconds}s'**
  String duelCardRetryIn(int seconds);

  /// S-38 challenge card chip while the creator is off the arena.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get duelCardAway;

  /// S-38 in-progress challenge card live marker.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get duelCardLive;

  /// S-38 in-progress challenge card caption.
  ///
  /// In en, this message translates to:
  /// **'In progress · vs {name}'**
  String duelCardInProgress(String name);

  /// S-38 the viewer's own challenge card title.
  ///
  /// In en, this message translates to:
  /// **'Your challenge'**
  String get duelCardYours;

  /// S-38 the viewer's own open challenge card status.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a challenger…'**
  String get duelCardWaiting;

  /// S-38 the viewer's own challenge card while they are away.
  ///
  /// In en, this message translates to:
  /// **'Paused while you\'re away'**
  String get duelCardPaused;

  /// S-38 the viewer's own challenge card cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get duelCardCancel;

  /// S-38 fairness hint: ELO difference within 100.
  ///
  /// In en, this message translates to:
  /// **'Even match'**
  String get duelFairnessEven;

  /// S-38 fairness hint: opponent 150+ ELO above the viewer.
  ///
  /// In en, this message translates to:
  /// **'Tough one'**
  String get duelFairnessTough;

  /// S-38 fairness hint: opponent 150+ ELO below the viewer.
  ///
  /// In en, this message translates to:
  /// **'Favourable'**
  String get duelFairnessFavourable;

  /// Display name for a guest player (no username).
  ///
  /// In en, this message translates to:
  /// **'Guest {tag}'**
  String duelGuestName(String tag);

  /// A player's level in the duel's topic.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String duelTopicLevel(int level);

  /// S-38 challenge card accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Challenge from {name}, {league}, {elo} ELO, {topic}, {time} left'**
  String duelCardSemantics(
    String name,
    String league,
    int elo,
    String topic,
    String time,
  );

  /// S-38 composer button.
  ///
  /// In en, this message translates to:
  /// **'Create challenge'**
  String get duelComposerCreate;

  /// S-38 composer during the creation cool-off.
  ///
  /// In en, this message translates to:
  /// **'New challenge in {time}'**
  String duelComposerCooldown(String time);

  /// S-38 composer while the viewer's own challenge is open.
  ///
  /// In en, this message translates to:
  /// **'Your {topic} challenge · {time} left'**
  String duelComposerOpen(String topic, String time);

  /// S-38 composer for guests.
  ///
  /// In en, this message translates to:
  /// **'Sign in to create challenges'**
  String get duelComposerSignIn;

  /// S-38 composer while the viewer is in a duel.
  ///
  /// In en, this message translates to:
  /// **'You\'re in a duel'**
  String get duelComposerInDuel;

  /// S-38 incoming join request banner title.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to duel!'**
  String duelIncomingTitle(String name);

  /// S-38 incoming join request banner meta line.
  ///
  /// In en, this message translates to:
  /// **'{league} · {elo} ELO · {topic} Lv {level}'**
  String duelIncomingMeta(String league, int elo, String topic, int level);

  /// S-38 incoming join request accept button.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get duelIncomingAccept;

  /// S-38 incoming join request decline button.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get duelIncomingDecline;

  /// S-38 incoming banner: more requests queued behind this one.
  ///
  /// In en, this message translates to:
  /// **'+{count} waiting'**
  String duelIncomingMore(int count);

  /// Topic picker title when creating a challenge.
  ///
  /// In en, this message translates to:
  /// **'Pick your battleground'**
  String get duelPickerTitleCreate;

  /// Topic picker title when matchmaking.
  ///
  /// In en, this message translates to:
  /// **'Match in which topic?'**
  String get duelPickerTitleMatch;

  /// Topic picker body.
  ///
  /// In en, this message translates to:
  /// **'You\'ll only face players in the same topic.'**
  String get duelPickerBody;

  /// Topic picker activity chip: players matchmaking in this topic.
  ///
  /// In en, this message translates to:
  /// **'{count} searching'**
  String duelPickerSearching(int count);

  /// Topic picker activity chip: open challenges in this topic.
  ///
  /// In en, this message translates to:
  /// **'{count} open'**
  String duelPickerOpen(int count);

  /// Topic picker empty state.
  ///
  /// In en, this message translates to:
  /// **'No duel topics in this language yet.'**
  String get duelPickerEmpty;

  /// Arena snackbar: challenge creation cool-off.
  ///
  /// In en, this message translates to:
  /// **'You can create another challenge in {time}'**
  String duelNoticeCooldown(String time);

  /// Arena snackbar.
  ///
  /// In en, this message translates to:
  /// **'You already have a live challenge'**
  String get duelNoticeAlreadyOpen;

  /// Arena snackbar.
  ///
  /// In en, this message translates to:
  /// **'Daily challenge limit reached — try Quick match'**
  String get duelNoticeDailyCap;

  /// Arena snackbar.
  ///
  /// In en, this message translates to:
  /// **'You can wait on up to {max} challenges at once'**
  String duelNoticeTooManyRequests(int max);

  /// Arena snackbar.
  ///
  /// In en, this message translates to:
  /// **'Slow down a little — try again in a moment'**
  String get duelNoticeRateLimited;

  /// Arena snackbar: the challenge's creator left the arena.
  ///
  /// In en, this message translates to:
  /// **'{name} stepped away'**
  String duelNoticeCreatorAway(String name);

  /// Arena snackbar.
  ///
  /// In en, this message translates to:
  /// **'That challenge is no longer available'**
  String get duelNoticeChallengeGone;

  /// Arena snackbar: the creator declined the viewer's request.
  ///
  /// In en, this message translates to:
  /// **'{name} passed this time'**
  String duelNoticeDeclined(String name);

  /// Arena snackbar: the creator let the request lapse.
  ///
  /// In en, this message translates to:
  /// **'No answer from {name}'**
  String duelNoticeNoResponse(String name);

  /// Arena snackbar.
  ///
  /// In en, this message translates to:
  /// **'{name} started a duel with someone else'**
  String duelNoticeTakenByOther(String name);

  /// Arena snackbar: the requester the viewer accepted is already busy.
  ///
  /// In en, this message translates to:
  /// **'{name} just started another duel'**
  String duelNoticeRequesterBusy(String name);

  /// Snackbar when a live duel is abandoned because the opponent never loaded it.
  ///
  /// In en, this message translates to:
  /// **'Your opponent didn\'t show up'**
  String get duelNoticeOpponentNoShow;

  /// Arena snackbar.
  ///
  /// In en, this message translates to:
  /// **'That topic isn\'t available for duels right now'**
  String get duelNoticeTopicUnavailable;

  /// Arena snackbar: a guest tried to create a challenge.
  ///
  /// In en, this message translates to:
  /// **'Sign in to create challenges'**
  String get duelNoticeSignInRequired;

  /// Arena snackbar: any other failure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong — please try again'**
  String get duelNoticeGeneric;

  /// S-39 VS row caption under the searching side.
  ///
  /// In en, this message translates to:
  /// **'Searching… {min} – {max} ELO'**
  String duelSearchingBand(int min, int max);

  /// S-39 bot offer card title.
  ///
  /// In en, this message translates to:
  /// **'No one\'s around in {topic} right now'**
  String duelBotOfferTitle(String topic);

  /// S-39 bot offer card body.
  ///
  /// In en, this message translates to:
  /// **'Play a practice bot — clearly labelled, results count at half ELO.'**
  String get duelBotOfferBody;

  /// S-39 bot offer primary button.
  ///
  /// In en, this message translates to:
  /// **'🤖 Play a bot'**
  String get duelBotOfferPlay;

  /// S-39 bot offer secondary button.
  ///
  /// In en, this message translates to:
  /// **'Keep searching'**
  String get duelKeepSearching;

  /// Label on a practice bot's avatar/name.
  ///
  /// In en, this message translates to:
  /// **'BOT'**
  String get duelBotBadge;

  /// S-39 ✕ button semantics label.
  ///
  /// In en, this message translates to:
  /// **'Stop searching'**
  String get duelLeaveQueueLabel;

  /// S-39 VS row caption under the player's own avatar: league (emoji + name) and formatted ELO.
  ///
  /// In en, this message translates to:
  /// **'{league} · {elo} ELO'**
  String duelLeagueEloCaption(String league, String elo);

  /// S-40 intro chip: this duel moves ELO.
  ///
  /// In en, this message translates to:
  /// **'Ranked'**
  String get duelIntroRanked;

  /// S-40 intro chip: this duel does not move ELO.
  ///
  /// In en, this message translates to:
  /// **'Unranked'**
  String get duelIntroUnranked;

  /// S-40 intro countdown.
  ///
  /// In en, this message translates to:
  /// **'Starting in {seconds}'**
  String duelIntroStartsIn(int seconds);

  /// S-40 intro while the opponent loads.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}…'**
  String duelWaitingFor(String name);

  /// S-40 question card placeholder while the question loads.
  ///
  /// In en, this message translates to:
  /// **'Get ready…'**
  String get duelGetReady;

  /// S-40 chip while the opponent's connection is down.
  ///
  /// In en, this message translates to:
  /// **'{name} reconnecting… {seconds}s'**
  String duelOpponentReconnecting(String name, int seconds);

  /// S-40 quit dialog title.
  ///
  /// In en, this message translates to:
  /// **'Leave the duel?'**
  String get duelQuitTitle;

  /// S-40 quit dialog body.
  ///
  /// In en, this message translates to:
  /// **'Leaving gives your opponent the remaining questions.'**
  String get duelQuitBody;

  /// S-40 quit dialog confirm button.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get duelQuitConfirm;

  /// S-40 quit dialog cancel button.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get duelQuitStay;

  /// S-40 ✕ button semantics label.
  ///
  /// In en, this message translates to:
  /// **'Leave duel'**
  String get duelQuitLabel;

  /// S-41 draw headline.
  ///
  /// In en, this message translates to:
  /// **'It\'s a draw'**
  String get duelResultDrawTitle;

  /// S-41 note when the pair's ranked cap was reached.
  ///
  /// In en, this message translates to:
  /// **'Unranked — you\'ve played {name} {count} times today'**
  String duelResultUnranked(String name, int count);

  /// S-41 note when the duel did not count for ELO.
  ///
  /// In en, this message translates to:
  /// **'Unranked — ELO unchanged'**
  String get duelResultUnrankedShort;

  /// S-41 caption when the opponent forfeited.
  ///
  /// In en, this message translates to:
  /// **'{name} left — the remaining questions count for you'**
  String duelResultOpponentForfeit(String name);

  /// S-41 caption when the player forfeited.
  ///
  /// In en, this message translates to:
  /// **'You left the duel'**
  String get duelResultYouForfeited;

  /// S-41 stat card row label.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get duelResultXp;

  /// S-41 rematch button while waiting for the opponent.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}…'**
  String duelRematchWaiting(String name);

  /// S-41 rematch prompt when the opponent asked first.
  ///
  /// In en, this message translates to:
  /// **'{name} wants a rematch!'**
  String duelRematchOffered(String name);

  /// S-41 rematch accept button.
  ///
  /// In en, this message translates to:
  /// **'Accept rematch'**
  String get duelRematchAccept;

  /// S-41 rematch button once the rematch window closed.
  ///
  /// In en, this message translates to:
  /// **'{name} has left'**
  String duelRematchUnavailable(String name);

  /// S-42 top bar title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// S-42 group label.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get settingsAppearance;

  /// S-42 group label.
  ///
  /// In en, this message translates to:
  /// **'GAME'**
  String get settingsGame;

  /// S-42 row title, opens S-03's picker.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// S-42 toggle row title.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get settingsSoundEffects;

  /// S-42 toggle row title.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get settingsMusic;

  /// S-42 toggle row title.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get settingsHaptics;

  /// S-42 group label.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get settingsAccount;

  /// S-42 row title, opens S-44.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// S-42 row title — plan 004's Assumption 4 stub destination.
  ///
  /// In en, this message translates to:
  /// **'Privacy & leaderboard visibility'**
  String get settingsPrivacy;

  /// S-42 row title, styled raspberry, opens S-52.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// Debug-only group label (plan 001's Assumption 7) — not a bible-specified section.
  ///
  /// In en, this message translates to:
  /// **'DEVELOPER'**
  String get settingsDeveloper;

  /// Debug toggle driving Home's S-46 variant via ConnectivityCubit.
  ///
  /// In en, this message translates to:
  /// **'Simulate offline'**
  String get settingsSimulateOffline;

  /// Debug row reaching S-50, which has no real version-check trigger in this mock phase.
  ///
  /// In en, this message translates to:
  /// **'Preview: force update screen'**
  String get settingsPreviewForceUpdate;

  /// Debug row reaching S-54, which has no real 3-levels-completed trigger wired by default.
  ///
  /// In en, this message translates to:
  /// **'Preview: notification permission'**
  String get settingsPreviewNotificationPermission;

  /// S-42 footer version string.
  ///
  /// In en, this message translates to:
  /// **'Quizoo v1.0.0 (mock build)'**
  String get settingsVersion;

  /// S-44 top bar title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// S-44 top bar trailing action.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// S-44 duel-challenge row's inline action — must never require a second screen.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get notificationsAccept;

  /// S-44 empty-list copy.
  ///
  /// In en, this message translates to:
  /// **'Nothing new right now.'**
  String get notificationsEmpty;

  /// S-52 dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// S-52 body, quoting the player's own live mock numbers rather than a hardcoded example.
  ///
  /// In en, this message translates to:
  /// **'You\'ll lose {points} points, {badges} badges and a {streak}-day streak. This can\'t be undone.'**
  String deleteAccountBody(int points, int badges, int streak);

  /// S-52 body while the player's numbers are still loading.
  ///
  /// In en, this message translates to:
  /// **'Loading your account details…'**
  String get deleteAccountBodyLoading;

  /// S-52 confirmation field label — the match is case-sensitive and exact.
  ///
  /// In en, this message translates to:
  /// **'Type \"{username}\" to confirm'**
  String deleteAccountTypeUsername(String username);

  /// S-52 dominant, ghost-styled action.
  ///
  /// In en, this message translates to:
  /// **'Keep my account'**
  String get deleteAccountKeep;

  /// S-52 destructive action, disabled until the typed username matches exactly.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteAccountDelete;

  /// Snackbar after the mocked delete signs the player out to Guest.
  ///
  /// In en, this message translates to:
  /// **'Account deleted (mock) — you\'re browsing as a guest'**
  String get deleteAccountDone;

  /// S-50 headline.
  ///
  /// In en, this message translates to:
  /// **'Time to update'**
  String get forceUpdateTitle;

  /// S-50 body.
  ///
  /// In en, this message translates to:
  /// **'Version 1.4 adds 1v1 duels and 12 new topics. This version can no longer connect.'**
  String get forceUpdateBody;

  /// S-50 sole action.
  ///
  /// In en, this message translates to:
  /// **'Update Quizoo'**
  String get forceUpdateCta;

  /// Snackbar after tapping S-50's CTA, which has nowhere real to send the player.
  ///
  /// In en, this message translates to:
  /// **'Mock — no app store wired up'**
  String get forceUpdateMock;

  /// S-54 dialog title.
  ///
  /// In en, this message translates to:
  /// **'Keep your streak alive?'**
  String get notificationPermissionTitle;

  /// S-54 dialog body.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send one reminder a day at a time you choose. Nothing else — no marketing, no \"we miss you\".'**
  String get notificationPermissionBody;

  /// S-54 time-picker row label.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get notificationPermissionTimeLabel;

  /// S-54 primary action.
  ///
  /// In en, this message translates to:
  /// **'Turn on reminders'**
  String get notificationPermissionTurnOn;

  /// S-54 secondary action.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notificationPermissionNotNow;

  /// Snackbar after accepting S-54.
  ///
  /// In en, this message translates to:
  /// **'Reminders on for {time}'**
  String notificationPermissionOnTitle(String time);

  /// Privacy stub screen top bar title (plan 004, Assumption 4).
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// Privacy stub toggle row.
  ///
  /// In en, this message translates to:
  /// **'Show my rank on leaderboards'**
  String get privacyShowOnLeaderboards;

  /// Privacy stub toggle row.
  ///
  /// In en, this message translates to:
  /// **'Show my activity to friends'**
  String get privacyShowActivityToFriends;

  /// S-11 HUD '⋯' semantic label, opening S-51 (plan 004).
  ///
  /// In en, this message translates to:
  /// **'Report this question'**
  String get quizReportLabel;

  /// S-11 HUD speaker icon's semantic label when TTS read-aloud is on (plan 007, §4.2).
  ///
  /// In en, this message translates to:
  /// **'Turn off question read-aloud'**
  String get quizAudioOnLabel;

  /// S-11 HUD speaker icon's semantic label when TTS read-aloud is off.
  ///
  /// In en, this message translates to:
  /// **'Turn on question read-aloud'**
  String get quizAudioOffLabel;

  /// S-46 top-of-screen label replacing Home's usual top bar subtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get homeOfflineMode;

  /// S-46 inline warning card body.
  ///
  /// In en, this message translates to:
  /// **'No connection. You can still play {count} downloaded topics. Scores sync when you\'re back.'**
  String homeOfflineWarning(int count);

  /// S-46 section header.
  ///
  /// In en, this message translates to:
  /// **'Available offline'**
  String get homeOfflineAvailable;

  /// S-46 dimmed strip heading.
  ///
  /// In en, this message translates to:
  /// **'NEEDS CONNECTION'**
  String get homeOfflineNeedsConnection;

  /// S-46 dimmed strip body.
  ///
  /// In en, this message translates to:
  /// **'Duels · Leaderboards · Daily challenge'**
  String get homeOfflineNeedsConnectionList;

  /// S-51 sheet title.
  ///
  /// In en, this message translates to:
  /// **'Report this question'**
  String get reportQuestionTitle;

  /// S-51 sheet body, quoting the question being reported.
  ///
  /// In en, this message translates to:
  /// **'\"{question}\"'**
  String reportQuestionMeta(String question);

  /// S-51 reason.
  ///
  /// In en, this message translates to:
  /// **'The answer is wrong'**
  String get reportReasonWrong;

  /// S-51 reason.
  ///
  /// In en, this message translates to:
  /// **'Question is unclear'**
  String get reportReasonUnclear;

  /// S-51 reason.
  ///
  /// In en, this message translates to:
  /// **'Bad translation'**
  String get reportReasonTranslation;

  /// S-51 reason.
  ///
  /// In en, this message translates to:
  /// **'Offensive content'**
  String get reportReasonOffensive;

  /// S-51 reason.
  ///
  /// In en, this message translates to:
  /// **'Image doesn\'t load'**
  String get reportReasonImage;

  /// S-51 CTA.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportQuestionSubmit;

  /// S-51 snackbar confirmation.
  ///
  /// In en, this message translates to:
  /// **'Report sent — thanks for the flag'**
  String get reportQuestionSent;

  /// S-53's own reserved path, reached with no real result to share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareDemoTitle;

  /// S-53 demo preview card body.
  ///
  /// In en, this message translates to:
  /// **'Quizoo — the quiz that plays like a game.'**
  String get shareDemoPreview;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
