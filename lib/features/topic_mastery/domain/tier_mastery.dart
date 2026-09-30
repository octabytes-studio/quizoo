import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/core/models/level.dart';

part 'tier_mastery.freezed.dart';

/// One tier's worth of stars inside a mastered topic — one pill in the
/// Topic Mastered screen's tier journey strip (plan 020).
@freezed
abstract class TierMastery with _$TierMastery {
  const factory TierMastery({
    required DifficultyBand band,
    required int starsEarned,
    required int starsAvailable,
    required int secondsPerQuestion,
  }) = _TierMastery;
}
