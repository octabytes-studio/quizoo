import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/core/models/badge.dart';

part 'badge_progress.freezed.dart';
part 'badge_progress.g.dart';

/// S-33's filter chips.
enum BadgeCategory { skill, streak, social, rare }

/// Wraps `core.AppBadge` with the extra payload S-34's locked variant needs —
/// the closest qualifying path and the single next action.
///
/// [AppBadge] itself lives in `core/models/` because both this feature and
/// `features/profile` consume it (CLAUDE.md §2's 3+ bar; see 001's design
/// notes). Everything specific to *how close* a locked badge is stays here,
/// one layer up.
@freezed
abstract class BadgeProgress with _$BadgeProgress {
  const factory BadgeProgress({
    required AppBadge badge,
    required BadgeCategory category,

    /// "SPORTS · CLOSEST" — meaningful only for a locked badge.
    String? closestGroupLabel,

    /// "3 / 8 TOPICS".
    String? closestFractionLabel,

    /// 0…1, the thin progress bar under [closestFractionLabel].
    double? closestProgress,

    /// "Next up: Hockey — you're on Level 2 of 20."
    String? nextActionLabel,

    /// The subcategory the detail dialog's CTA deep-links into.
    String? nextSubcategoryId,

    /// The route ids the CTA needs, from the same server rows as
    /// [nextSubcategoryId] — plan 025 removed the `MockCatalog` lookup that
    /// crashed for any topic outside the 26-entry fixture.
    String? nextCategoryId,

    /// The topic's display name for the CTA label.
    String? nextSubcategoryName,
    int? rewardCoins,
  }) = _BadgeProgress;

  const BadgeProgress._();

  factory BadgeProgress.fromJson(Map<String, dynamic> json) =>
      _$BadgeProgressFromJson(json);

  bool get isLocked => badge.isLocked;
}
