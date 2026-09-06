// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LevelResult _$LevelResultFromJson(Map<String, dynamic> json) => _LevelResult(
  run: QuizRun.fromJson(json['run'] as Map<String, dynamic>),
  stars: (json['stars'] as num).toInt(),
  finalScore: (json['finalScore'] as num).toInt(),
  coinsEarned: (json['coinsEarned'] as num).toInt(),
  xpEarned: (json['xpEarned'] as num).toInt(),
  playerLevel: (json['playerLevel'] as num).toInt(),
  xpIntoLevel: (json['xpIntoLevel'] as num).toInt(),
  xpToNextLevel: (json['xpToNextLevel'] as num).toInt(),
  isFirstClear: json['isFirstClear'] as bool? ?? false,
  newlyEarnedBadgeIds:
      (json['newlyEarnedBadgeIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  shouldOfferSaveProgress: json['shouldOfferSaveProgress'] as bool? ?? false,
);

Map<String, dynamic> _$LevelResultToJson(_LevelResult instance) =>
    <String, dynamic>{
      'run': instance.run,
      'stars': instance.stars,
      'finalScore': instance.finalScore,
      'coinsEarned': instance.coinsEarned,
      'xpEarned': instance.xpEarned,
      'playerLevel': instance.playerLevel,
      'xpIntoLevel': instance.xpIntoLevel,
      'xpToNextLevel': instance.xpToNextLevel,
      'isFirstClear': instance.isFirstClear,
      'newlyEarnedBadgeIds': instance.newlyEarnedBadgeIds,
      'shouldOfferSaveProgress': instance.shouldOfferSaveProgress,
    };
