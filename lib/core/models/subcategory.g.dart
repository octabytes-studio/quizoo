// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subcategory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Subcategory _$SubcategoryFromJson(Map<String, dynamic> json) => _Subcategory(
  id: json['id'] as String,
  categoryId: json['categoryId'] as String,
  name: json['name'] as String,
  emoji: json['emoji'] as String,
  plateColor: json['plateColor'] as String,
  questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
  levelsCleared: (json['levelsCleared'] as num?)?.toInt() ?? 0,
  levelCount: (json['levelCount'] as num?)?.toInt() ?? 20,
  bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
  starsEarned: (json['starsEarned'] as num?)?.toInt() ?? 0,
  isNew: json['isNew'] as bool? ?? false,
  isLocked: json['isLocked'] as bool? ?? false,
);

Map<String, dynamic> _$SubcategoryToJson(_Subcategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'categoryId': instance.categoryId,
      'name': instance.name,
      'emoji': instance.emoji,
      'plateColor': instance.plateColor,
      'questionCount': instance.questionCount,
      'levelsCleared': instance.levelsCleared,
      'levelCount': instance.levelCount,
      'bestScore': instance.bestScore,
      'starsEarned': instance.starsEarned,
      'isNew': instance.isNew,
      'isLocked': instance.isLocked,
    };
