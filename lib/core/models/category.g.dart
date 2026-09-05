// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Category _$CategoryFromJson(Map<String, dynamic> json) => _Category(
  id: json['id'] as String,
  name: json['name'] as String,
  emoji: json['emoji'] as String,
  colorFrom: json['colorFrom'] as String,
  colorTo: json['colorTo'] as String,
  order: (json['order'] as num).toInt(),
  subcategoryCount: (json['subcategoryCount'] as num?)?.toInt() ?? 0,
  questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
  isNew: json['isNew'] as bool? ?? false,
  isLocked: json['isLocked'] as bool? ?? false,
);

Map<String, dynamic> _$CategoryToJson(_Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'emoji': instance.emoji,
  'colorFrom': instance.colorFrom,
  'colorTo': instance.colorTo,
  'order': instance.order,
  'subcategoryCount': instance.subcategoryCount,
  'questionCount': instance.questionCount,
  'isNew': instance.isNew,
  'isLocked': instance.isLocked,
};
