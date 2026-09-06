import 'package:flutter/rendering.dart';

/// Corner radii from §05's shape table.
abstract final class AppRadius {
  /// Bottom sheet — 28, top corners only.
  static const double sheet = 28;

  /// Dialog — 26.
  static const double dialog = 26;

  /// Card — 20. Tiles use the tighter [tile].
  static const double card = 20;

  /// Tile — 18. The bible gives cards and tiles a 18–20 range; tiles sit at
  /// the bottom of it (`.tile`, `.bg .m` at 20, `.c` at 20).
  static const double tile = 18;

  /// Button — 18, and the small variant drops to [buttonSmall].
  static const double button = 18;

  /// `.btn.sm` — 14.
  static const double buttonSmall = 14;

  /// Answer option — 18.
  static const double answer = 18;

  /// Icon button — 12.
  static const double iconButton = 12;

  /// The inline action pill inside a banner (S-05's daily "Play") — 12.
  /// Distinct from [pill], which is fully round.
  static const double inlineAction = 12;

  /// Pill / chip — fully round.
  static const double pill = 999;

  /// Snackbar (`.toast`) — 16.
  static const double snackbar = 16;

  /// Level node (`.node`) — 22.
  static const double node = 22;

  /// Segmented-control track (`.tabsel`) — 14, with 10 on the thumb.
  static const double segmentedTrack = 14;
  static const double segmentedThumb = 10;

  /// Power-up dock tile (`.pup`) — 16.
  static const double powerUp = 16;

  /// List row (`.row`) — 16.
  static const double listRow = 16;

  /// Row avatar plate (`.row .av`) — 14.
  static const double rowAvatar = 14;

  /// Tile emoji plate (`.tile .av`) and share-target plate — 16 and 18.
  static const double emojiPlate = 16;
  static const double shareTarget = 18;

  /// Dialog icon plate (`.dlg .ico`) — 22.
  static const double dialogIcon = 22;

  /// Answer-option key badge (`.opt .k`) — 10.
  static const double answerKey = 10;

  /// Skeleton default (`.sk`) — 10.
  static const double skeleton = 10;

  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
  static const BorderRadius dialogAll = BorderRadius.all(
    Radius.circular(dialog),
  );
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius tileAll = BorderRadius.all(Radius.circular(tile));
  static const BorderRadius buttonAll = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}
