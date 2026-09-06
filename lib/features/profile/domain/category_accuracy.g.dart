// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_accuracy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CategoryAccuracy _$CategoryAccuracyFromJson(Map<String, dynamic> json) =>
    _CategoryAccuracy(
      categoryName: json['categoryName'] as String,
      emoji: json['emoji'] as String,
      accuracyPercent: (json['accuracyPercent'] as num).toInt(),
    );

Map<String, dynamic> _$CategoryAccuracyToJson(_CategoryAccuracy instance) =>
    <String, dynamic>{
      'categoryName': instance.categoryName,
      'emoji': instance.emoji,
      'accuracyPercent': instance.accuracyPercent,
    };
