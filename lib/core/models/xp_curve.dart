/// The player-level XP curve — shared by `quiz_result` (a run's payout) and
/// `profile` (where the XP bar sits today), so it lives in `core/` rather
/// than either feature (CLAUDE.md §2's 3+ bar; this is the one genuinely
/// cross-feature piece of §19's scoring maths).
///
/// Mirrors `_xp_for_level`/`_player_level_from_xp` in the functions
/// migration exactly.
abstract final class XpCurve {
  /// `xpToNext(n) = 300 + 100 × n` — cost, in XP, to go from level `n` to
  /// `n + 1`.
  static int costFor(int playerLevel) => 300 + 100 * playerLevel;

  /// Inverts [costFor] over a total-XP figure.
  static ({int level, int xpIntoLevel, int xpToNextLevel}) progressFor(
    int totalXp,
  ) {
    var level = 1;
    var remaining = totalXp < 0 ? 0 : totalXp;
    var cost = costFor(level);
    while (remaining >= cost) {
      remaining -= cost;
      level++;
      cost = costFor(level);
    }
    return (level: level, xpIntoLevel: remaining, xpToNextLevel: cost);
  }
}
