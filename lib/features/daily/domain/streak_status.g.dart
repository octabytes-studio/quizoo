// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StreakDay _$StreakDayFromJson(Map<String, dynamic> json) => _StreakDay(
  label: json['label'] as String,
  mark: $enumDecode(_$StreakDayMarkEnumMap, json['mark']),
);

Map<String, dynamic> _$StreakDayToJson(_StreakDay instance) =>
    <String, dynamic>{
      'label': instance.label,
      'mark': _$StreakDayMarkEnumMap[instance.mark]!,
    };

const _$StreakDayMarkEnumMap = {
  StreakDayMark.done: 'done',
  StreakDayMark.today: 'today',
  StreakDayMark.future: 'future',
  StreakDayMark.reward: 'reward',
};

_Milestone _$MilestoneFromJson(Map<String, dynamic> json) => _Milestone(
  title: json['title'] as String,
  daysAway: (json['daysAway'] as num).toInt(),
  rewardLabel: json['rewardLabel'] as String,
);

Map<String, dynamic> _$MilestoneToJson(_Milestone instance) =>
    <String, dynamic>{
      'title': instance.title,
      'daysAway': instance.daysAway,
      'rewardLabel': instance.rewardLabel,
    };

_StreakStatus _$StreakStatusFromJson(Map<String, dynamic> json) =>
    _StreakStatus(
      currentStreak: (json['currentStreak'] as num).toInt(),
      freezesLeft: (json['freezesLeft'] as num).toInt(),
      days: (json['days'] as List<dynamic>)
          .map((e) => StreakDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      milestones: (json['milestones'] as List<dynamic>)
          .map((e) => Milestone.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StreakStatusToJson(_StreakStatus instance) =>
    <String, dynamic>{
      'currentStreak': instance.currentStreak,
      'freezesLeft': instance.freezesLeft,
      'days': instance.days,
      'milestones': instance.milestones,
    };
