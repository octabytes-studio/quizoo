import 'package:freezed_annotation/freezed_annotation.dart';

part 'difficulty_tier.freezed.dart';
part 'difficulty_tier.g.dart';

/// One rung of the 50-level, 5-tier ladder (`difficulty_tiers`), fetched
/// once from Supabase rather than hardcoded — a Supabase table edit changes
/// the ladder, not an app release.
@freezed
abstract class DifficultyTier with _$DifficultyTier {
  const factory DifficultyTier({
    required String code,
    required String label,
    required int secondsPerQuestion,
    required int levelStart,
    required int levelEnd,
  }) = _DifficultyTier;

  factory DifficultyTier.fromJson(Map<String, dynamic> json) =>
      _$DifficultyTierFromJson(json);
}
