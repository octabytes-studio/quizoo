/// Layout breakpoints, in logical pixels.
///
/// These are for **layout branching only**, always via `LayoutBuilder` — never
/// for sizing, which is `flutter_screenutil`'s job (CLAUDE.md §6). The design
/// bible is authored at 390×844, so [phone] is the design width and anything
/// wider is a progressive enhancement rather than a separate design.
abstract final class Breakpoints {
  /// The width the design bible is drawn at (iPhone 14 / Pixel class).
  static const double designWidth = 390;

  /// The height the design bible is drawn at.
  static const double designHeight = 844;

  /// Below this, treat the viewport as a compact phone and tighten grids.
  static const double compact = 360;

  /// At or above this, a phone layout gains room for a wider grid.
  static const double phone = 480;

  /// At or above this, switch single-column screens to two columns and the
  /// bottom tab bar to a navigation rail.
  static const double tablet = 720;

  /// At or above this, cap content width rather than stretching it.
  static const double desktop = 1080;

  /// The widest a content column ever grows, so a tablet or desktop window
  /// keeps the phone-authored rhythm instead of stretching every row.
  static const double maxContentWidth = 560;
}
