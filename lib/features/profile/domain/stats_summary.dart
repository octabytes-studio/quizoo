import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/features/profile/domain/category_accuracy.dart';

part 'stats_summary.freezed.dart';
part 'stats_summary.g.dart';

/// Everything S-35 renders.
@freezed
abstract class StatsSummary with _$StatsSummary {
  const factory StatsSummary({
    /// Seven bars, Monday..Sunday, 0…100 — today's is the highlighted one.
    required List<int> pointsPerDayPercents,
    required int todayIndex,
    required List<CategoryAccuracy> categoryAccuracies,
    required double fastestAverageSeconds,
    required String fastestSubcategoryName,
    required int fastestLevelNumber,
    required String fastestPercentileLabel,
  }) = _StatsSummary;

  const StatsSummary._();

  factory StatsSummary.fromJson(Map<String, dynamic> json) =>
      _$StatsSummaryFromJson(json);

  /// The single category the coaching card targets — never a
  /// zero-attempt category, which is excluded upstream so it cannot look
  /// like a misleadingly weak one (plan 003, Edge cases).
  CategoryAccuracy get weakest => categoryAccuracies.reduce(
    (a, b) => a.accuracyPercent <= b.accuracyPercent ? a : b,
  );
}
