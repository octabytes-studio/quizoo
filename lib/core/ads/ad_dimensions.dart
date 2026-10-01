/// The sizes AdMob itself fixes for an ad, in logical pixels.
///
/// **Deliberately not `flutter_screenutil`-scaled** — the one stated
/// exception to CLAUDE.md §6. These are the SDK's own dimensions for a
/// platform view: scaling a 300×250 rectangle or a native template with `.w` /
/// `.h` would clip or letterbox the ad on any device that isn't the design
/// size. The padding *around* an ad still uses `AppSpacing` + screenutil.
///
/// The native heights sit inside Google's template limits (small 90–200 high,
/// medium 320–400 high, both 320–400 wide).
abstract final class AdDimensions {
  /// Medium rectangle (MREC) banner.
  static const double rectangleWidth = 300;
  static const double rectangleHeight = 250;

  /// Small native template.
  static const double nativeSmallHeight = 100;

  /// Medium native template.
  static const double nativeMediumHeight = 340;

  /// Widest a native template may be laid out.
  static const double nativeMaxWidth = 400;
}
