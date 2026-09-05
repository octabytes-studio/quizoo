import 'package:freezed_annotation/freezed_annotation.dart';

part 'badge.freezed.dart';
part 'badge.g.dart';

/// An achievement — the cell in the profile's 4-up achievements grid, the
/// subject of the badge-unlocked celebration, and the payload of the badge
/// detail dialog.
///
/// Named `AppBadge` rather than `Badge` because Material already exports a
/// `Badge` widget, and a feature importing both should not have to prefix one.
@freezed
abstract class AppBadge with _$AppBadge {
  const factory AppBadge({
    required String id,
    required String name,
    required String emoji,

    /// One-line explanation of what earns it.
    required String description,

    /// Start of the medallion's gradient, as `#RRGGBB`.
    required String gradientFrom,

    /// End of the medallion's gradient, as `#RRGGBB`.
    required String gradientTo,
    @Default(true) bool isLocked,

    /// Share of players holding this badge, 0…100 — the "Top 3%" line.
    @Default(100) double rarityPercent,
    DateTime? unlockedAt,
  }) = _AppBadge;

  factory AppBadge.fromJson(Map<String, dynamic> json) =>
      _$AppBadgeFromJson(json);
}
