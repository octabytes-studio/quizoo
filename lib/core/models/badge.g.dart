// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppBadge _$AppBadgeFromJson(Map<String, dynamic> json) => _AppBadge(
  id: json['id'] as String,
  name: json['name'] as String,
  emoji: json['emoji'] as String,
  description: json['description'] as String,
  gradientFrom: json['gradientFrom'] as String,
  gradientTo: json['gradientTo'] as String,
  isLocked: json['isLocked'] as bool? ?? true,
  rarityPercent: (json['rarityPercent'] as num?)?.toDouble() ?? 100,
  unlockedAt: json['unlockedAt'] == null
      ? null
      : DateTime.parse(json['unlockedAt'] as String),
);

Map<String, dynamic> _$AppBadgeToJson(_AppBadge instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'emoji': instance.emoji,
  'description': instance.description,
  'gradientFrom': instance.gradientFrom,
  'gradientTo': instance.gradientTo,
  'isLocked': instance.isLocked,
  'rarityPercent': instance.rarityPercent,
  'unlockedAt': instance.unlockedAt?.toIso8601String(),
};
