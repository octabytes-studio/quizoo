// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailyResult _$DailyResultFromJson(Map<String, dynamic> json) => _DailyResult(
  correctCount: (json['correctCount'] as num).toInt(),
  totalCount: (json['totalCount'] as num).toInt(),
  betterThanPercent: (json['betterThanPercent'] as num).toInt(),
  distributionPercents: (json['distributionPercents'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  highlightedBucketIndex: (json['highlightedBucketIndex'] as num).toInt(),
  coinsEarned: (json['coinsEarned'] as num).toInt(),
  streakNow: (json['streakNow'] as num).toInt(),
  answerPattern: (json['answerPattern'] as List<dynamic>)
      .map((e) => e as bool)
      .toList(),
  newlyEarnedBadgeIds:
      (json['newlyEarnedBadgeIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$DailyResultToJson(_DailyResult instance) =>
    <String, dynamic>{
      'correctCount': instance.correctCount,
      'totalCount': instance.totalCount,
      'betterThanPercent': instance.betterThanPercent,
      'distributionPercents': instance.distributionPercents,
      'highlightedBucketIndex': instance.highlightedBucketIndex,
      'coinsEarned': instance.coinsEarned,
      'streakNow': instance.streakNow,
      'answerPattern': instance.answerPattern,
      'newlyEarnedBadgeIds': instance.newlyEarnedBadgeIds,
    };
