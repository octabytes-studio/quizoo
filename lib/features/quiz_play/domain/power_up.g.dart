// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'power_up.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PowerUpInventory _$PowerUpInventoryFromJson(Map<String, dynamic> json) =>
    _PowerUpInventory(
      fiftyFifty: (json['fiftyFifty'] as num?)?.toInt() ?? 0,
      addTime: (json['addTime'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PowerUpInventoryToJson(_PowerUpInventory instance) =>
    <String, dynamic>{
      'fiftyFifty': instance.fiftyFifty,
      'addTime': instance.addTime,
      'skip': instance.skip,
    };
