// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShopContent _$ShopContentFromJson(Map<String, dynamic> json) => _ShopContent(
  coins: (json['coins'] as num).toInt(),
  gems: (json['gems'] as num).toInt(),
  freeAdsWatchedToday: (json['freeAdsWatchedToday'] as num).toInt(),
  freeAdsPerDay: (json['freeAdsPerDay'] as num).toInt(),
  freeCoinsReward: (json['freeCoinsReward'] as num).toInt(),
  inventory: PowerUpInventory.fromJson(
    json['inventory'] as Map<String, dynamic>,
  ),
  coinPacks: (json['coinPacks'] as List<dynamic>)
      .map((e) => CoinPack.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ShopContentToJson(_ShopContent instance) =>
    <String, dynamic>{
      'coins': instance.coins,
      'gems': instance.gems,
      'freeAdsWatchedToday': instance.freeAdsWatchedToday,
      'freeAdsPerDay': instance.freeAdsPerDay,
      'freeCoinsReward': instance.freeCoinsReward,
      'inventory': instance.inventory,
      'coinPacks': instance.coinPacks,
    };
