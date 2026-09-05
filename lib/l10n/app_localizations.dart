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
