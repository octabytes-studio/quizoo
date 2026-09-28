// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_duel_outcome.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiveDuelOutcome _$LiveDuelOutcomeFromJson(Map<String, dynamic> json) =>
    _LiveDuelOutcome(
      reason: json['reason'] as String,
      won: json['won'] as bool? ?? false,
      draw: json['draw'] as bool? ?? false,
      eloBefore: (json['eloBefore'] as num?)?.toInt() ?? 0,
      eloAfter: (json['eloAfter'] as num?)?.toInt() ?? 0,
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      badgeIds:
          (json['badgeIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      opponentForfeited: json['opponentForfeited'] as bool? ?? false,
      youForfeited: json['youForfeited'] as bool? ?? false,
      myAvgMs: (json['myAvgMs'] as num?)?.toDouble(),
      opponentAvgMs: (json['opponentAvgMs'] as num?)?.toDouble(),
      cause: json['cause'] as String?,
    );

Map<String, dynamic> _$LiveDuelOutcomeToJson(_LiveDuelOutcome instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'won': instance.won,
      'draw': instance.draw,
      'eloBefore': instance.eloBefore,
      'eloAfter': instance.eloAfter,
      'coins': instance.coins,
      'xp': instance.xp,
      'badgeIds': instance.badgeIds,
      'opponentForfeited': instance.opponentForfeited,
      'youForfeited': instance.youForfeited,
      'myAvgMs': instance.myAvgMs,
      'opponentAvgMs': instance.opponentAvgMs,
      'cause': instance.cause,
    };
