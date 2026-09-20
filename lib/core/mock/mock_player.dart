import 'package:quizoo/core/models/player_currency.dart';

/// The signed-in player fixture the bible's own frames are drawn against —
/// Waleed, 🐼, twelve-day streak, level 12, 1,240 coins, four hearts.
///
/// Home's two variants, the level brief's power-up row, S-19's refill maths
/// and S-24's "don't lose 3,470 points" headline all quote these numbers, so
/// they live in one place rather than being re-typed per screen.
abstract final class MockPlayer {
  static const String name = 'Waleed';
  static const String avatarEmoji = '🐼';

  /// §19's rank titles: 10–14 is "Curious Mind".
  static const int playerLevel = 12;
  static const String rankTitle = 'Curious Mind';

  static const int dayStreak = 12;

  /// XP inside the current player level, and what the next one costs.
  ///
  /// §19: `xpToNext(n) = 300 + 100 × n`, so level 12 → 13 costs 1,500.
  static const int xpIntoLevel = 1240;
  static int get xpToNextLevel => 300 + 100 * playerLevel;

  /// The player's rank inside their best topic, shown on S-08.
  static const int subcategoryRank = 412;

  /// The wallet a signed-in player carries.
  static PlayerCurrency get currency => PlayerCurrency(
    coins: 1240,
    gems: 18,
    hearts: 4,
    heartRefillAt: DateTime.now().add(const Duration(minutes: 28)),
  );

  /// A guest's wallet: full hearts, nothing earned, so Home shows no pills.
  static const PlayerCurrency guestCurrency = PlayerCurrency();

  /// Power-ups a fresh level grants, as the level brief's preview row shows.
  static const int fiftyFiftyCount = 1;
  static const int addTimeCount = 1;

  /// Hearts spent per level attempt, and the wall a run fails at.
  static const int livesPerLevel = 3;

  /// Usernames the mocked availability check reports as taken.
  static const Set<String> takenUsernames = {'waleed', 'quizoo', 'admin'};
}
