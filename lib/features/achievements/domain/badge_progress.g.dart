// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BadgeProgress _$BadgeProgressFromJson(Map<String, dynamic> json) =>
    _BadgeProgress(
      badge: AppBadge.fromJson(json['badge'] as Map<String, dynamic>),
      category: $enumDecode(_$BadgeCategoryEnumMap, json['category']),
      closestGroupLabel: json['closestGroupLabel'] as String?,
      closestFractionLabel: json['closestFractionLabel'] as String?,
      closestProgress: (json['closestProgress'] as num?)?.toDouble(),
      nextActionLabel: json['nextActionLabel'] as String?,
      nextSubcategoryId: json['nextSubcategoryId'] as String?,
      rewardCoins: (json['rewardCoins'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BadgeProgressToJson(_BadgeProgress instance) =>
    <String, dynamic>{
      'badge': instance.badge,
      'category': _$BadgeCategoryEnumMap[instance.category]!,
      'closestGroupLabel': instance.closestGroupLabel,
      'closestFractionLabel': instance.closestFractionLabel,
      'closestProgress': instance.closestProgress,
      'nextActionLabel': instance.nextActionLabel,
      'nextSubcategoryId': instance.nextSubcategoryId,
      'rewardCoins': instance.rewardCoins,
    };

const _$BadgeCategoryEnumMap = {
  BadgeCategory.skill: 'skill',
  BadgeCategory.streak: 'streak',
  BadgeCategory.social: 'social',
  BadgeCategory.rare: 'rare',
};
