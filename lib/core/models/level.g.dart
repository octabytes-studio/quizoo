// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Level _$LevelFromJson(Map<String, dynamic> json) => _Level(
  id: json['id'] as String,
  subcategoryId: json['subcategoryId'] as String,
  number: (json['number'] as num).toInt(),
  difficultyBand: $enumDecode(_$DifficultyBandEnumMap, json['difficultyBand']),
  secondsPerQuestion: (json['secondsPerQuestion'] as num).toInt(),
  status: $enumDecode(_$LevelStatusEnumMap, json['status']),
  isBoss: json['isBoss'] as bool? ?? false,
  questionCount: (json['questionCount'] as num?)?.toInt() ?? 20,
  starsEarned: (json['starsEarned'] as num?)?.toInt() ?? 0,
  bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$LevelToJson(_Level instance) => <String, dynamic>{
  'id': instance.id,
  'subcategoryId': instance.subcategoryId,
  'number': instance.number,
  'difficultyBand': _$DifficultyBandEnumMap[instance.difficultyBand]!,
  'secondsPerQuestion': instance.secondsPerQuestion,
  'status': _$LevelStatusEnumMap[instance.status]!,
  'isBoss': instance.isBoss,
  'questionCount': instance.questionCount,
  'starsEarned': instance.starsEarned,
  'bestScore': instance.bestScore,
};

const _$DifficultyBandEnumMap = {
  DifficultyBand.warmUp: 'warmUp',
  DifficultyBand.steady: 'steady',
  DifficultyBand.sharp: 'sharp',
  DifficultyBand.brutal: 'brutal',
};

const _$LevelStatusEnumMap = {
  LevelStatus.locked: 'locked',
  LevelStatus.current: 'current',
  LevelStatus.done: 'done',
};
