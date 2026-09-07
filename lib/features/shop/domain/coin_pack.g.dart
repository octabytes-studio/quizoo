// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coin_pack.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CoinPack _$CoinPackFromJson(Map<String, dynamic> json) => _CoinPack(
  id: json['id'] as String,
  coins: (json['coins'] as num).toInt(),
  priceLabel: json['priceLabel'] as String,
  bonusPercent: (json['bonusPercent'] as num?)?.toInt() ?? 0,
  isHighlighted: json['isHighlighted'] as bool? ?? false,
);

Map<String, dynamic> _$CoinPackToJson(_CoinPack instance) => <String, dynamic>{
  'id': instance.id,
  'coins': instance.coins,
  'priceLabel': instance.priceLabel,
  'bonusPercent': instance.bonusPercent,
  'isHighlighted': instance.isHighlighted,
};
