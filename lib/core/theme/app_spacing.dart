/// The 4pt spacing grid from §05 of the design bible.
///
/// **Naming**: the bible calls these `space.1 … space.7`; CLAUDE.md §5 mandates
/// an `xs/sm/md/lg/xl` scale. CLAUDE.md wins on naming (its own precedence
/// rule), so all seven of the bible's raw values survive under these names:
///
/// | bible   | px | here    | used for                                   |
/// |---------|----|---------|--------------------------------------------|
/// | space.1 |  4 | [xs]    | icon-to-label, badge insets                |
/// | space.2 |  8 | [sm]    | chip gaps, dense list gaps                 |
/// | space.3 | 12 | [md]    | card inner gap, grid gutters               |
/// | space.4 | 16 | [base]  | card padding, option gaps                  |
/// | space.5 | 20 | [lg]    | **screen horizontal margin — invariant**   |
/// | space.6 | 24 | [xl]    | section separation                         |
/// | space.7 | 32 | [xxl]   | above a primary CTA                        |
abstract final class AppSpacing {
  /// 4 — icon-to-label, badge insets.
  static const double xs = 4;

  /// 8 — chip gaps, dense list gaps.
  static const double sm = 8;

  /// 12 — card inner gap, grid gutters.
  static const double md = 12;

  /// 16 — card padding, option gaps.
  static const double base = 16;

  /// 20 — section separation is 24, but this is the one value that never
  /// varies: see [screenMargin].
  static const double lg = 20;

  /// 24 — section separation.
  static const double xl = 24;

  /// 32 — the gap above a primary CTA.
  static const double xxl = 32;

  /// The screen's horizontal margin, **20px on every screen without
  /// exception, including inside sheets** (§05).
  ///
  /// Horizontal rails are the one thing that bleeds past it: the rail's own
  /// padding is 20 and its cards overflow to the edge, which is what signals
  /// "scroll me".
  static const double screenMargin = lg;
}
