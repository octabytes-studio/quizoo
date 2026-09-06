// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CategoryDetail _$CategoryDetailFromJson(Map<String, dynamic> json) =>
    _CategoryDetail(
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      topics:
          (json['topics'] as List<dynamic>?)
              ?.map((e) => Subcategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      playerCount: (json['playerCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CategoryDetailToJson(_CategoryDetail instance) =>
    <String, dynamic>{
      'category': instance.category,
      'topics': instance.topics,
      'playerCount': instance.playerCount,
    };
