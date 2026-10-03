/// Where a paywall visit was launched from (plan 023).
///
/// Lives in `core/` rather than in the subscription feature because the
/// shared upsell widgets and eight different features pass it in — see
/// Assumption 5 of the plan.
///
/// Kept purely as a routing argument today; the plan's "further
/// suggestions" list logging it for conversion analytics as a later, separate
/// decision.
enum PaywallSource {
  /// Opened directly (a deep link, a stale card).
  direct,

  /// A locked level node on the level map.
  lockedLevel,

  /// The dismissible Home promo card.
  homeCard,

  /// The "Go Pro" row on the You tab.
  profile,

  /// The Settings row.
  settings,

  /// The quiet link under the out-of-lives buttons.
  outOfLives,

  /// The "Remove ads" link beside an ad label.
  adLabel,

  /// The one-time sheet after the third interstitial.
  adBreak,

  /// A Pro avatar tapped by a free player.
  proAvatar,

  /// "Review answers" on a result screen, tapped by a free player.
  answerReview,
}
