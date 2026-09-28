// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duel_side_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DuelSideResult _$DuelSideResultFromJson(Map<String, dynamic> json) =>
    _DuelSideResult(
      eloBefore: (json['eloBefore'] as num).toInt(),
      eloAfter: (json['eloAfter'] as num).toInt(),
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      badgeIds:
          (json['badgeIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DuelSideResultToJson(_DuelSideResult instance) =>
    <String, dynamic>{
      'eloBefore': instance.eloBefore,
      'eloAfter': instance.eloAfter,
      'coins': instance.coins,
      'xp': instance.xp,
      'badgeIds': instance.badgeIds,
    };
