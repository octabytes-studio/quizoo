import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/core/models/badge.dart';

part 'profile_summary.freezed.dart';
part 'profile_summary.g.dart';

/// One row of S-32's "Best categories" list.
@freezed
abstract class BestCategoryEntry with _$BestCategoryEntry {
  const factory BestCategoryEntry({
    required String subcategoryId,
    required String name,
    required String emoji,
    required String plateColor,
    required int levelsCleared,
    required int levelCount,
    required int starsEarned,
    required int accuracyPercent,
  }) = _BestCategoryEntry;

  factory BestCategoryEntry.fromJson(Map<String, dynamic> json) =>
      _$BestCategoryEntryFromJson(json);
}

/// Everything S-32 renders — a public profile is the same model with
/// [isOwnProfile] decided by the screen, not carried here (see
/// `ProfileScreen`'s constructor).
@freezed
abstract class ProfileSummary with _$ProfileSummary {
  const factory ProfileSummary({
    required String username,
    required String avatarEmoji,

    /// "🇵🇰 Islamabad".
    required String cityLabel,

    /// "Joined Mar 2026".
    required String joinedLabel,
    required String leagueEmoji,
    required String leagueName,
    required int dayStreak,
    required int playerLevel,
    required String rankTitle,
    required int xpIntoLevel,
    required int xpToNextLevel,
    required int totalPoints,
    required int totalLevels,
    required int accuracyPercent,
    required int badgeCount,
    required List<AppBadge> recentBadges,
    required List<BestCategoryEntry> bestCategories,
  }) = _ProfileSummary;

  const ProfileSummary._();

  factory ProfileSummary.fromJson(Map<String, dynamic> json) =>
      _$ProfileSummaryFromJson(json);

  double get xpProgress => xpToNextLevel == 0
      ? 0
      : (xpIntoLevel / xpToNextLevel).clamp(0, 1).toDouble();
}
