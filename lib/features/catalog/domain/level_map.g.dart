// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_map.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LevelMap _$LevelMapFromJson(Map<String, dynamic> json) => _LevelMap(
  category: Category.fromJson(json['category'] as Map<String, dynamic>),
  subcategory: Subcategory.fromJson(
    json['subcategory'] as Map<String, dynamic>,
  ),
  levels:
      (json['levels'] as List<dynamic>?)
          ?.map((e) => Level.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  rank: (json['rank'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$LevelMapToJson(_LevelMap instance) => <String, dynamic>{
  'category': instance.category,
  'subcategory': instance.subcategory,
  'levels': instance.levels,
  'rank': instance.rank,
};
