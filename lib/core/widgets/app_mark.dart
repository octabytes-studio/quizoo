import 'package:flutter/material.dart';

/// The Quizoo brand mark — the app icon (plan 023).
///
/// Both variants are declared in `pubspec.yaml`: the colour mark for light
/// surfaces, the white mark for the deep grape-to-night Pro wash. [AppMark]
/// picks the colour one by default because a light surface is the common
/// case; pass [variant] where the surface is dark.
///
/// Shared by the paywall hero, the Pro Welcome hero and the You screen's
/// membership row — three callers across two features, which is why it lives
/// in `core/` (CLAUDE.md §2).
class AppMark extends StatelessWidget {
  const AppMark({
    required this.size,
    super.key,
    this.variant = AppMarkVariant.color,
  });

  /// The purple mark for light surfaces.
  static const String colorAsset = 'assets/branding/quizoo-mark-color.png';

  /// The white mark for the dark Pro wash.
  static const String whiteAsset = 'assets/branding/quizoo-mark-white.png';

  /// Edge length of the square the mark is drawn into. The mark is square
  /// art, so it is fitted with [BoxFit.contain] and never stretched.
  final double size;

  final AppMarkVariant variant;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      variant == AppMarkVariant.white ? whiteAsset : colorAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// Which brand-mark artwork a surface needs.
enum AppMarkVariant {
  /// Purple owl — light and mid surfaces.
  color,

  /// White owl — the dark Pro wash.
  white,
}
