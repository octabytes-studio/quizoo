// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duel_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DuelResult _$DuelResultFromJson(Map<String, dynamic> json) => _DuelResult(
  me: DuelPlayer.fromJson(json['me'] as Map<String, dynamic>),
  opponent: DuelPlayer.fromJson(json['opponent'] as Map<String, dynamic>),
  playerRoundsWon: (json['playerRoundsWon'] as num).toInt(),
  opponentRoundsWon: (json['opponentRoundsWon'] as num).toInt(),
  playerAverageAnswerSeconds: (json['playerAverageAnswerSeconds'] as num)
      .toDouble(),
  opponentAverageAnswerSeconds: (json['opponentAverageAnswerSeconds'] as num)
      .toDouble(),
  eloBefore: (json['eloBefore'] as num).toInt(),
  eloAfter: (json['eloAfter'] as num).toInt(),
  rewardCoins: (json['rewardCoins'] as num).toInt(),
  newlyEarnedBadgeIds:
      (json['newlyEarnedBadgeIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  duelId: json['duelId'] as String?,
  isBot: json['isBot'] as bool? ?? true,
  topic: json['topic'] == null
      ? null
      : DuelTopic.fromJson(json['topic'] as Map<String, dynamic>),
  isRanked: json['isRanked'] as bool? ?? true,
  xpEarned: (json['xpEarned'] as num?)?.toInt() ?? 0,
  endReason:
      $enumDecodeNullable(_$DuelEndReasonEnumMap, json['endReason']) ??
      DuelEndReason.completed,
);

Map<String, dynamic> _$DuelResultToJson(_DuelResult instance) =>
    <String, dynamic>{
      'me': instance.me,
      'opponent': instance.opponent,
      'playerRoundsWon': instance.playerRoundsWon,
      'opponentRoundsWon': instance.opponentRoundsWon,
      'playerAverageAnswerSeconds': instance.playerAverageAnswerSeconds,
      'opponentAverageAnswerSeconds': instance.opponentAverageAnswerSeconds,
      'eloBefore': instance.eloBefore,
      'eloAfter': instance.eloAfter,
      'rewardCoins': instance.rewardCoins,
      'newlyEarnedBadgeIds': instance.newlyEarnedBadgeIds,
      'duelId': instance.duelId,
      'isBot': instance.isBot,
      'topic': instance.topic,
      'isRanked': instance.isRanked,
      'xpEarned': instance.xpEarned,
      'endReason': _$DuelEndReasonEnumMap[instance.endReason]!,
    };

const _$DuelEndReasonEnumMap = {
  DuelEndReason.completed: 'completed',
  DuelEndReason.opponentForfeited: 'opponentForfeited',
  DuelEndReason.youForfeited: 'youForfeited',
};
