/// Whether an identity should carry the Quizoo Pro badge — the gold
/// verified tick (plan 023).
///
/// The server's `profiles.is_pro` is the truth for **other** players. For
/// the player's *own* identity the badge must appear the instant a purchase
/// lands on this device — well before a webhook or `sync-pro-status` has
/// written the server flag — so the local entitlement is OR'd in. That is
/// the treatment the profile header has had since plan 023; this puts the
/// same rule behind every own-identity surface.
///
/// Pure, so the rule is unit-testable without a widget.
bool proBadge({
  required bool serverIsPro,
  required bool isSelf,
  required bool localIsPro,
}) => serverIsPro || (isSelf && localIsPro);
