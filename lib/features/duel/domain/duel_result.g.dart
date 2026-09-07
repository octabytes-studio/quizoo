// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duel_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DuelResult _$DuelResultFromJson(Map<String, dynamic> json) => _DuelResult(
  opponent: DuelOpponent.fromJson(json['opponent'] as Map<String, dynamic>),
  playerRoundsWon: (json['playerRoundsWon'] as num).toInt(),
  opponentRoundsWon: (json['opponentRoundsWon'] as num).toInt(),
  playerAverageAnswerSeconds: (json['playerAverageAnswerSeconds'] as num)
      .toDouble(),
  opponentAverageAnswerSeconds: (json['opponentAverageAnswerSeconds'] as num)
      .toDouble(),
  eloBefore: (json['eloBefore'] as num).toInt(),
  eloAfter: (json['eloAfter'] as num).toInt(),
  rewardCoins: (json['rewardCoins'] as num).toInt(),
);

Map<String, dynamic> _$DuelResultToJson(_DuelResult instance) =>
    <String, dynamic>{
      'opponent': instance.opponent,
      'playerRoundsWon': instance.playerRoundsWon,
      'opponentRoundsWon': instance.opponentRoundsWon,
      'playerAverageAnswerSeconds': instance.playerAverageAnswerSeconds,
      'opponentAverageAnswerSeconds': instance.opponentAverageAnswerSeconds,
      'eloBefore': instance.eloBefore,
      'eloAfter': instance.eloAfter,
      'rewardCoins': instance.rewardCoins,
    };
