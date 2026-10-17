/// The five reasons the player-report flow offers, each carrying the stable
/// code stored in `user_reports.reason` (plan 025). Display labels are
/// resolved by the sheet from ARB, so this stays localization-free.
enum PlayerReportReason {
  offensiveName('offensive_name'),
  harassment('harassment'),
  cheating('cheating'),
  impersonation('impersonation'),
  other('other');

  const PlayerReportReason(this.code);

  /// The value written to `user_reports.reason`.
  final String code;
}
