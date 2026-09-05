// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_currency.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayerCurrency _$PlayerCurrencyFromJson(Map<String, dynamic> json) =>
    _PlayerCurrency(
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      gems: (json['gems'] as num?)?.toInt() ?? 0,
      hearts: (json['hearts'] as num?)?.toInt() ?? 5,
      maxHearts: (json['maxHearts'] as num?)?.toInt() ?? 5,
      heartRefillAt: json['heartRefillAt'] == null
          ? null
          : DateTime.parse(json['heartRefillAt'] as String),
    );

Map<String, dynamic> _$PlayerCurrencyToJson(_PlayerCurrency instance) =>
    <String, dynamic>{
      'coins': instance.coins,
      'gems': instance.gems,
      'hearts': instance.hearts,
      'maxHearts': instance.maxHearts,
      'heartRefillAt': instance.heartRefillAt?.toIso8601String(),
    };
