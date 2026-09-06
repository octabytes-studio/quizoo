import 'package:freezed_annotation/freezed_annotation.dart';

part 'streak_status.freezed.dart';
part 'streak_status.g.dart';

/// One circle in S-27's 7-day streak row.
enum StreakDayMark {
  /// ✓ on mint — already played.
  done,

  /// 🔥 on mango — today, not yet played.
  today,

  /// A plain day number on the sunken surface.
  future,

  /// 🎁 on the lemon gradient — the week's reward day.
  reward,
}

/// One day-circle: its letter (`M`, `T`, …) and which of the four states it
/// is in.
@freezed
abstract class StreakDay with _$StreakDay {
  const factory StreakDay({
    required String label,
    required StreakDayMark mark,
  }) = _StreakDay;

  factory StreakDay.fromJson(Map<String, dynamic> json) =>
      _$StreakDayFromJson(json);
}

/// One row in the "Milestones" list — an upcoming streak-length reward.
@freezed
abstract class Milestone with _$Milestone {
  const factory Milestone({
    required String title,
    required int daysAway,
    required String rewardLabel,
  }) = _Milestone;

  factory Milestone.fromJson(Map<String, dynamic> json) =>
      _$MilestoneFromJson(json);
}

/// Everything S-27's "Your streak" card and milestones list render.
@freezed
abstract class StreakStatus with _$StreakStatus {
  const factory StreakStatus({
    required int currentStreak,
    required int freezesLeft,
    required List<StreakDay> days,
    required List<Milestone> milestones,
  }) = _StreakStatus;

  factory StreakStatus.fromJson(Map<String, dynamic> json) =>
      _$StreakStatusFromJson(json);
}
