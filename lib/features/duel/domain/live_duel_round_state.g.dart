// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_duel_round_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiveDuelRoundState _$LiveDuelRoundStateFromJson(Map<String, dynamic> json) =>
    _LiveDuelRoundState(
      number: (json['number'] as num).toInt(),
      startsAt: json['startsAt'] == null
          ? null
          : DateTime.parse(json['startsAt'] as String),
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      myLocked: json['myLocked'] as bool? ?? false,
      myChoice: (json['myChoice'] as num?)?.toInt(),
      myMs: (json['myMs'] as num?)?.toInt(),
      opponentLocked: json['opponentLocked'] as bool? ?? false,
      opponentMs: (json['opponentMs'] as num?)?.toInt(),
      question: json['question'] == null
          ? null
          : DuelQuestion.fromJson(json['question'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LiveDuelRoundStateToJson(_LiveDuelRoundState instance) =>
    <String, dynamic>{
      'number': instance.number,
      'startsAt': instance.startsAt?.toIso8601String(),
      'deadline': instance.deadline?.toIso8601String(),
      'myLocked': instance.myLocked,
      'myChoice': instance.myChoice,
      'myMs': instance.myMs,
      'opponentLocked': instance.opponentLocked,
      'opponentMs': instance.opponentMs,
      'question': instance.question,
    };
