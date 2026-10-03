/// The eight Quizoo Pro benefits, as data (plan 023).
///
/// Titles and descriptions are **not** stored here — they come from l10n in
/// the widget via an exhaustive `switch` (CLAUDE.md §5: no hardcoded copy in
/// a feature file). This enum is what the paywall, the membership screen and
/// the tests iterate over, so a ninth benefit cannot be drawn on one screen
/// and forgotten on another.
enum ProBenefit {
  /// 1 — Crown on the avatar, tick after the name, visible to everyone.
  badge,

  /// 2 — Every level of every topic unlocked.
  allLevels,

  /// 3 — No interstitial, banner or native ads. The rewarded heart ad stays.
  noAds,

  /// 4 — One instant extra life per level, no ad.
  freeRevive,

  /// 5 — 2× 50:50 and 2× +5s per level.
  doublePowerUps,

  /// 6 — Streak freezes refill to 2 every month.
  streakShield,

  /// 7 — The Pro-only avatar set.
  avatars,

  /// 8 — Every question back with the right answer and an explanation.
  answerReview,
}

extension ProBenefitGlyph on ProBenefit {
  /// The plate glyph on the paywall and the membership screen. Decoration
  /// only — the words carry the meaning — so it stays out of l10n.
  String get emoji => switch (this) {
    ProBenefit.badge => '👑',
    ProBenefit.allLevels => '🔓',
    ProBenefit.noAds => '🚫',
    ProBenefit.freeRevive => '❤️',
    ProBenefit.doublePowerUps => '🎯',
    ProBenefit.streakShield => '🛡️',
    ProBenefit.avatars => '🦄',
    ProBenefit.answerReview => '📖',
  };
}
