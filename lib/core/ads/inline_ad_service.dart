import 'dart:ui';

import 'package:quizoo/core/ads/ad_dimensions.dart';
import 'package:quizoo/core/ads/ad_placement.dart';

/// A banner or native ad that has loaded and is ready to be put on screen.
abstract class LoadedInlineAd {
  /// Logical pixels.
  double get height;

  /// Logical pixels — `double.infinity` for an ad that fills its container.
  double get width;

  void dispose();
}

/// Which native template an ad is rendered with.
enum NativeAdSize { small, medium }

/// The app-token colours a native template is painted with, resolved by the
/// widget (which has a `BuildContext`) so the service needs none.
class NativeAdPalette {
  const NativeAdPalette({
    required this.background,
    required this.text,
    required this.secondaryText,
    required this.ctaBackground,
    required this.ctaText,
  });

  final Color background;
  final Color text;
  final Color secondaryText;
  final Color ctaBackground;
  final Color ctaText;
}

/// What an ad slot asks the [InlineAdService] for.
sealed class InlineAdRequest {
  const InlineAdRequest({required this.placement});

  final AdPlacement placement;

  /// The slot's height when the format fixes it; null when it has to be
  /// asked of the SDK (an adaptive banner's height depends on the device).
  double? get fixedHeight;
}

/// An adaptive banner anchored to a screen edge, [widthDp] wide.
final class AnchoredBannerRequest extends InlineAdRequest {
  const AnchoredBannerRequest({
    required super.placement,
    required this.widthDp,
  });

  final int widthDp;

  @override
  double? get fixedHeight => null;
}

/// A fixed 300×250 medium rectangle.
final class RectangleBannerRequest extends InlineAdRequest {
  const RectangleBannerRequest({required super.placement});

  @override
  double get fixedHeight => AdDimensions.rectangleHeight;
}

/// A native ad rendered with one of Google's templates.
final class NativeAdRequest extends InlineAdRequest {
  const NativeAdRequest({
    required super.placement,
    required this.size,
    required this.palette,
  });

  final NativeAdSize size;
  final NativeAdPalette palette;

  @override
  double get fixedHeight => switch (size) {
    NativeAdSize.small => AdDimensions.nativeSmallHeight,
    NativeAdSize.medium => AdDimensions.nativeMediumHeight,
  };
}

/// A seam over the concrete AdMob banner/native loading so `InlineAdCubit`
/// stays pure Dart and testable without a plugin channel.
abstract class InlineAdService {
  /// Height to reserve before the ad loads; null if it can't be sized.
  /// Never throws.
  Future<double?> reservedHeight(InlineAdRequest request);

  /// Null when the load fails. Never throws.
  Future<LoadedInlineAd?> load(InlineAdRequest request);
}
