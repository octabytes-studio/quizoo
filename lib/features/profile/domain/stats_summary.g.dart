// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StatsSummary _$StatsSummaryFromJson(Map<String, dynamic> json) =>
    _StatsSummary(
      pointsPerDayPercents: (json['pointsPerDayPercents'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      todayIndex: (json['todayIndex'] as num).toInt(),
      categoryAccuracies: (json['categoryAccuracies'] as List<dynamic>)
          .map((e) => CategoryAccuracy.fromJson(e as Map<String, dynamic>))
          .toList(),
      fastestAverageSeconds: (json['fastestAverageSeconds'] as num).toDouble(),
      fastestSubcategoryName: json['fastestSubcategoryName'] as String,
      fastestLevelNumber: (json['fastestLevelNumber'] as num).toInt(),
      fastestPercentileLabel: json['fastestPercentileLabel'] as String,
    );

Map<String, dynamic> _$StatsSummaryToJson(_StatsSummary instance) =>
    <String, dynamic>{
      'pointsPerDayPercents': instance.pointsPerDayPercents,
      'todayIndex': instance.todayIndex,
      'categoryAccuracies': instance.categoryAccuracies,
      'fastestAverageSeconds': instance.fastestAverageSeconds,
      'fastestSubcategoryName': instance.fastestSubcategoryName,
      'fastestLevelNumber': instance.fastestLevelNumber,
      'fastestPercentileLabel': instance.fastestPercentileLabel,
    };
