import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/features/topic_mastery/domain/tier_mastery.dart';

part 'topic_mastery.freezed.dart';

/// Everything the Topic Mastered screen (plan 020) renders: a fully-cleared
/// topic's tally, read from data already stored in `level_progress` /
/// `level_attempts` — there is no new backend for this screen.
@freezed
abstract class TopicMastery with _$TopicMastery {
  const factory TopicMastery({
    required String categoryId,
    required String subcategoryId,
    required String topicName,
    required String emoji,

    /// The topic tile's plate tint, as `#RRGGBB`.
    required String plateColor,
    required int levelsCleared,

    /// The ladder total (30) at the time this was fetched.
    required int levelCount,
    required int starsEarned,

    /// Levels cleared with all three stars.
    required int perfectLevels,

    /// Sum of `level_progress.best_score` across every cleared level.
    required int totalScore,

    /// In ladder order (Easy → Medium → Hard).
    required List<TierMastery> tiers,

    /// `min(level_attempts.created_at)` for this topic. Null if there is no
    /// attempt row (progress written some other way).
    DateTime? startedAt,

    /// `level_progress.completed_at` of the final level.
    DateTime? masteredAt,
  }) = _TopicMastery;

  const TopicMastery._();

  int get starsAvailable => levelCount * 3;

  int get missingStars => starsAvailable - starsEarned;

  bool get isFlawless => missingStars == 0;

  bool get isMastered => levelsCleared >= levelCount;

  /// Whole days between [startedAt] and [masteredAt], at least 1. Null if
  /// either is missing.
  int? get daysToMaster {
    final started = startedAt;
    final mastered = masteredAt;
    if (started == null || mastered == null) return null;
    final days = mastered.difference(started).inDays;
    return days < 1 ? 1 : days;
  }
}
