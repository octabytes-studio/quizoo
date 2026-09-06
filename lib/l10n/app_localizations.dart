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

  /// S-04 Home category chip row heading.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get homeCategories;

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

  /// S-38 play sheet heading.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playSheetTitle;

  /// S-38 play sheet body.
  ///
  /// In en, this message translates to:
  /// **'Pick how you want to play right now.'**
  String get playSheetSubtitle;

  /// S-38 row 1 title.
  ///
  /// In en, this message translates to:
  /// **'1v1 Duel'**
  String get playSheetDuel;

  /// S-38 row 1 caption.
  ///
  /// In en, this message translates to:
  /// **'5 questions · winner takes 200 🪙'**
  String get playSheetDuelMeta;

  /// S-38 row 2 title.
  ///
  /// In en, this message translates to:
  /// **'Quick Play'**
  String get playSheetQuickPlay;

  /// S-38 row 2 caption.
  ///
  /// In en, this message translates to:
  /// **'A random level at your skill tier'**
  String get playSheetQuickPlayMeta;

  /// S-38 row 3 title.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get playSheetDaily;

  /// S-38 row 3 caption.
  ///
  /// In en, this message translates to:
  /// **'Not played yet · 4h 12m left'**
  String get playSheetDailyMeta;

  /// S-38 row 4 title.
  ///
  /// In en, this message translates to:
  /// **'Challenge a friend'**
  String get playSheetFriend;

  /// S-38 row 4 caption.
  ///
  /// In en, this message translates to:
  /// **'Danish M. is online now'**
  String get playSheetFriendMeta;

  /// S-38 primary row trailing affordance.
  ///
  /// In en, this message translates to:
  /// **'Go →'**
  String get playSheetGo;

  /// Semantic label for the FAB while the play sheet is open.
  ///
  /// In en, this message translates to:
  /// **'Close play menu'**
  String get playSheetClose;

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

  /// S-05 Home categories section trailing link.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String homeAllCategories(int count);

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

  /// S-04 category filter chip that clears the filter.
  ///
  /// In en, this message translates to:
  /// **'✨ All'**
  String get homeFilterAll;

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

  /// S-09 dimmed shop tile label.
  ///
  /// In en, this message translates to:
  /// **'SHOP'**
  String get levelBriefShop;

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

  /// Power-up that adds fifteen seconds.
  ///
  /// In en, this message translates to:
  /// **'+15s'**
  String get quizPowerUpAddTime;

  /// Power-up that skips a question.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get quizPowerUpSkip;

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

  /// S-13 cost, top-right of the banner.
  ///
  /// In en, this message translates to:
  /// **'−1 ❤️'**
  String get feedbackHeartLost;

  /// Timeout banner cost line — a timeout costs the question, not a heart (§19).
  ///
  /// In en, this message translates to:
  /// **'No heart lost'**
  String get feedbackNoHeartLost;

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

  /// S-19 dialog body. The refill is a clock time, never a relative countdown.
  ///
  /// In en, this message translates to:
  /// **'Lives refill one every 30 minutes — the next one lands at {time}. Or keep this run going right now.'**
  String outOfLivesBody(String time);

  /// S-19 free action, listed first and loudest.
  ///
  /// In en, this message translates to:
  /// **'▶ Watch an ad for 1 ❤️'**
  String get outOfLivesWatchAd;

  /// S-19 paid action.
  ///
  /// In en, this message translates to:
  /// **'Refill 5 ❤️ · {coins} 🪙'**
  String outOfLivesRefill(int coins);

  /// S-19 abandon action.
  ///
  /// In en, this message translates to:
  /// **'Back to level map'**
  String get outOfLivesBackToMap;

  /// S-19 label while the mocked rewarded ad runs.
  ///
  /// In en, this message translates to:
  /// **'Playing ad…'**
  String get outOfLivesAdPlaying;

  /// S-19 sub-label on the refill action when the balance is short.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins'**
  String get outOfLivesNotEnoughCoins;

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

  /// Snackbar shown after a mocked sign-in.
  ///
  /// In en, this message translates to:
  /// **'Progress saved'**
  String get saveProgressSaved;

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
