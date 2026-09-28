// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duel_round.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DuelRoundRecord _$DuelRoundRecordFromJson(Map<String, dynamic> json) =>
    _DuelRoundRecord(
      roundNumber: (json['roundNumber'] as num).toInt(),
      playerCorrect: json['playerCorrect'] as bool,
      opponentCorrect: json['opponentCorrect'] as bool,
      playerAnswerSeconds: (json['playerAnswerSeconds'] as num).toInt(),
      opponentAnswerSeconds: (json['opponentAnswerSeconds'] as num).toInt(),
      outcome: $enumDecode(_$RoundOutcomeEnumMap, json['outcome']),
      correctIndex: (json['correctIndex'] as num?)?.toInt(),
      playerChoice: (json['playerChoice'] as num?)?.toInt(),
      opponentChoice: (json['opponentChoice'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DuelRoundRecordToJson(_DuelRoundRecord instance) =>
    <String, dynamic>{
      'roundNumber': instance.roundNumber,
      'playerCorrect': instance.playerCorrect,
      'opponentCorrect': instance.opponentCorrect,
      'playerAnswerSeconds': instance.playerAnswerSeconds,
      'opponentAnswerSeconds': instance.opponentAnswerSeconds,
      'outcome': _$RoundOutcomeEnumMap[instance.outcome]!,
      'correctIndex': instance.correctIndex,
      'playerChoice': instance.playerChoice,
      'opponentChoice': instance.opponentChoice,
    };

const _$RoundOutcomeEnumMap = {
  RoundOutcome.playerWon: 'playerWon',
  RoundOutcome.opponentWon: 'opponentWon',
  RoundOutcome.draw: 'draw',
};
