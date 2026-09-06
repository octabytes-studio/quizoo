// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_challenge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailyChallenge _$DailyChallengeFromJson(Map<String, dynamic> json) =>
    _DailyChallenge(
      title: json['title'] as String,
      questionCount: (json['questionCount'] as num).toInt(),
      categoryCount: (json['categoryCount'] as num).toInt(),
      secondsPerQuestion: (json['secondsPerQuestion'] as num).toInt(),
      coinReward: (json['coinReward'] as num).toInt(),
      xpReward: (json['xpReward'] as num).toInt(),
      timeRemainingMinutes: (json['timeRemainingMinutes'] as num).toInt(),
      playedTodayCount: (json['playedTodayCount'] as num).toInt(),
      averageCorrect: (json['averageCorrect'] as num).toInt(),
      averageOutOf: (json['averageOutOf'] as num).toInt(),
    );

Map<String, dynamic> _$DailyChallengeToJson(_DailyChallenge instance) =>
    <String, dynamic>{
      'title': instance.title,
      'questionCount': instance.questionCount,
      'categoryCount': instance.categoryCount,
      'secondsPerQuestion': instance.secondsPerQuestion,
      'coinReward': instance.coinReward,
      'xpReward': instance.xpReward,
      'timeRemainingMinutes': instance.timeRemainingMinutes,
      'playedTodayCount': instance.playedTodayCount,
      'averageCorrect': instance.averageCorrect,
      'averageOutOf': instance.averageOutOf,
    };
