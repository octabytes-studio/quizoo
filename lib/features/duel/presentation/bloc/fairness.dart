/// The fairness hint on a challenge card, from the ELO gap between the
/// creator and the viewer (plan 017, "Challenge card states").
enum Fairness {
  /// Within ±100 ELO, or the 100–150 grey zone either way.
  even,

  /// The creator is at least 150 ELO above the viewer.
  tough,

  /// The creator is at least 150 ELO below the viewer.
  favourable,
}
