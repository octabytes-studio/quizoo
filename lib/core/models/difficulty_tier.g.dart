// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'difficulty_tier.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DifficultyTier _$DifficultyTierFromJson(Map<String, dynamic> json) =>
    _DifficultyTier(
      code: json['code'] as String,
      label: json['label'] as String,
      secondsPerQuestion: (json['secondsPerQuestion'] as num).toInt(),
      levelStart: (json['levelStart'] as num).toInt(),
      levelEnd: (json['levelEnd'] as num).toInt(),
    );

Map<String, dynamic> _$DifficultyTierToJson(_DifficultyTier instance) =>
    <String, dynamic>{
      'code': instance.code,
      'label': instance.label,
      'secondsPerQuestion': instance.secondsPerQuestion,
      'levelStart': instance.levelStart,
      'levelEnd': instance.levelEnd,
    };
