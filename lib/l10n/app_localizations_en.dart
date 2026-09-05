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
}
