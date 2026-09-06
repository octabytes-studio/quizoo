import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Turns the design bible's CSS gradients into Flutter ones without anybody
/// hand-deriving alignments at the call site.
///
/// Category and badge colours arrive from content as `#RRGGBB` pairs (see
/// `Category.colorFrom` / `colorTo`), and the bible always paints them with a
/// CSS `linear-gradient(150deg, …)`. Both conversions live here so Home,
/// Browse and the play surface read the same tile the same way.
abstract final class AppGradients {
  /// The angle the bible uses for every tile, card and plate gradient.
  static const double tileAngle = 150;

  /// The angle used by the full-bleed washes — splash, result screens, the
  /// arena.
  static const double washAngle = 178;

  /// The angle used by the wide informational banners on Home.
  static const double bannerAngle = 120;

  /// A CSS `linear-gradient(<degrees>, …)`.
  ///
  /// CSS angles are measured clockwise from "to top", so 0° runs bottom-to-top
  /// and 90° runs left-to-right. Flutter's [Alignment] space is x-right,
  /// y-down, which makes the direction vector `(sin θ, −cos θ)` and the
  /// gradient the line through the origin along it.
  static LinearGradient linear(
    double degrees,
    List<Color> colors, {
    List<double>? stops,
  }) {
    final radians = degrees * math.pi / 180;
    final x = math.sin(radians);
    final y = -math.cos(radians);
    return LinearGradient(
      begin: Alignment(-x, -y),
      end: Alignment(x, y),
      colors: colors,
      stops: stops,
    );
  }

  /// The 150° gradient a category, subcategory plate or popular card wears.
  static LinearGradient tile(Color from, Color to) =>
      linear(tileAngle, [from, to]);

  /// The 150° gradient for a `#RRGGBB` pair straight off a content model.
  static LinearGradient tileFromHex(String from, String to) =>
      tile(hex(from), hex(to));

  /// Parses `#RRGGBB` or `#AARRGGBB` (with or without the leading `#`).
  ///
  /// Content is authored by hand, so an unparseable value returns
  /// [fallback] rather than throwing a screen down — a mistyped hex in the CMS
  /// should cost a wrong tile colour, not a crash.
  static Color hex(String value, {Color fallback = const Color(0xFF7B4DFF)}) {
    final digits = value.startsWith('#') ? value.substring(1) : value;
    final normalized = switch (digits.length) {
      6 => 'FF$digits',
      8 => digits,
      _ => null,
    };
    if (normalized == null) return fallback;
    final parsed = int.tryParse(normalized, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }
}
