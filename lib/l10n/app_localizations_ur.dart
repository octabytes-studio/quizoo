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
}
