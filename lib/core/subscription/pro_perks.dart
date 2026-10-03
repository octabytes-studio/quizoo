/// The per-level numbers a player plays under, free or Pro (plan 023).
///
/// The single home of these values: `QuizPlayCubit` and `LevelBriefSheet`
/// read them from here rather than from `MockPlayer`, so the paywall's
/// promises and the play surface cannot drift apart.
class ProPerks {
  const ProPerks.free()
    : fiftyFifty = 1,
      addTime = 1,
      freeRevives = 0,
      livesPerLevel = 3;

  const ProPerks.pro()
    : fiftyFifty = 2,
      addTime = 2,
      freeRevives = 1,
      livesPerLevel = 3;

  /// 50:50 power-ups available per level.
  final int fiftyFifty;

  /// +5s power-ups available per level.
  final int addTime;

  /// Instant extra lives per level with no ad (benefit 4).
  final int freeRevives;

  /// Hearts at the start of a level. The same for everyone — Pro's extra
  /// life comes from [freeRevives], not from a bigger starting stack.
  final int livesPerLevel;

  /// The one way to pick one. Everything that needs perks takes a [ProPerks],
  /// never a bare `isPro` bool, so the numbers stay in one place.
  factory ProPerks.of({required bool isPro}) =>
      isPro ? const ProPerks.pro() : const ProPerks.free();

  @override
  bool operator ==(Object other) =>
      other is ProPerks &&
      other.fiftyFifty == fiftyFifty &&
      other.addTime == addTime &&
      other.freeRevives == freeRevives &&
      other.livesPerLevel == livesPerLevel;

  @override
  int get hashCode =>
      Object.hash(fiftyFifty, addTime, freeRevives, livesPerLevel);
}
