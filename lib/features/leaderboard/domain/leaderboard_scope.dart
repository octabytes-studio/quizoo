/// The segmented control atop S-29 — who the board ranks against.
enum LeaderboardScope { global, country, friends }

/// The secondary chip row atop S-29 — which window the scores cover.
///
/// All three re-slice the *same* fixture roster with different numbers
/// rather than hitting a real time-boxed query (plan 003, Scope).
enum LeaderboardPeriod { week, month, allTime }
