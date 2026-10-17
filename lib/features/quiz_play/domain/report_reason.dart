/// The five reasons S-51's sheet offers, each carrying the stable code the
/// server stores in `question_reports.reason` (plan 025).
///
/// The enum deliberately has no label: the display string is resolved by the
/// screen from ARB, and this file stays importable by any feature without
/// dragging localization into the domain layer.
enum ReportReason {
  wrong('wrong'),
  unclear('unclear'),
  translation('translation'),
  offensive('offensive'),
  image('image');

  const ReportReason(this.code);

  /// The value written to `question_reports.reason`.
  final String code;
}
