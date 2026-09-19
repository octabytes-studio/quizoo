import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_result.freezed.dart';
part 'daily_result.g.dart';

/// S-28 — the payout after today's challenge.
///
/// [distributionPercents] is a genuinely global stat in the real product
/// (where every player answered the same ten questions); for mock data it is
/// a hardcoded, plausible-looking spread, and only [highlightedBucketIndex]
/// changes with the player's own score.
@freezed
abstract class DailyResult with _$DailyResult {
  const factory DailyResult({
    required int correctCount,
    required int totalCount,
    required int betterThanPercent,

    /// Five bucket heights, 0…100 — 0-2 / 3-4 / 5-6 / 7-8 / 9-10 correct.
    required List<int> distributionPercents,
    required int highlightedBucketIndex,
    required int coinsEarned,
    required int streakNow,

    /// One entry per question, true for a correct answer — the raw material
    /// for the share sheet's spoiler-free emoji grid.
    required List<bool> answerPattern,
    @Default([]) List<String> newlyEarnedBadgeIds,
  }) = _DailyResult;

  const DailyResult._();

  factory DailyResult.fromJson(Map<String, dynamic> json) =>
      _$DailyResultFromJson(json);

  /// A plausible fixed result for contexts with no real play to show —
  /// currently just the dev screen index's S-28 entry, opened with no
  /// route `extra`.
  factory DailyResult.preview() => const DailyResult(
    correctCount: 8,
    totalCount: 10,
    betterThanPercent: 82,
    distributionPercents: [14, 34, 72, 100, 41],
    highlightedBucketIndex: 3,
    coinsEarned: 300,
    streakNow: 13,
    answerPattern: [
      true,
      true,
      false,
      true,
      true,
      true,
      false,
      true,
      true,
      true,
    ],
  );

  /// The bible's own worked example — 🟩 for correct, ⬜ for wrong, in rows of
  /// five, e.g. "🟩🟩⬜🟩🟩\n🟩⬜🟩🟩🟩".
  String get shareGrid {
    final glyphs = [for (final correct in answerPattern) correct ? '🟩' : '⬜'];
    final rows = <String>[];
    for (var index = 0; index < glyphs.length; index += 5) {
      final end = (index + 5).clamp(0, glyphs.length);
      rows.add(glyphs.sublist(index, end).join());
    }
    return rows.join('\n');
  }

  /// The bucket boundaries S-28 draws: 0-2, 3-4, 5-6, 7-8, 9-10 correct.
  static int bucketIndexFor(int correctCount) => switch (correctCount) {
    <= 2 => 0,
    <= 4 => 1,
    <= 6 => 2,
    <= 8 => 3,
    _ => 4,
  };

  /// How many players this score plausibly beats, derived from the real
  /// (server-computed) [distributionPercents] rather than a second
  /// hardcoded spread, so it always agrees with which bucket is highlighted.
  static int betterThanPercentFor(
    int correctCount,
    List<int> distributionPercents,
  ) {
    final bucket = bucketIndexFor(correctCount);
    final below = distributionPercents
        .sublist(0, bucket)
        .fold<int>(0, (sum, value) => sum + value);
    final total = distributionPercents.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    if (total == 0) return 0;
    return ((below / total) * 100).round().clamp(1, 99);
  }
}
