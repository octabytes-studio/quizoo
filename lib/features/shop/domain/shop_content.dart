import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/core/models/power_up.dart';
import 'package:quizoo/features/shop/domain/coin_pack.dart';

part 'shop_content.freezed.dart';
part 'shop_content.g.dart';

/// Everything S-36 renders.
///
/// The wallet lives here rather than being read off `SessionCubit` because
/// there is no persistent economy in this mock phase (plan 004, Scope) — the
/// shop's own copy of the balance is deliberately the only one that moves
/// when a purchase happens, exactly like `QuizPlayCubit`'s in-run hearts.
@freezed
abstract class ShopContent with _$ShopContent {
  const factory ShopContent({
    required int coins,
    required int gems,
    required int freeAdsWatchedToday,
    required int freeAdsPerDay,
    required int freeCoinsReward,
    required PowerUpInventory inventory,
    required List<CoinPack> coinPacks,
  }) = _ShopContent;

  const ShopContent._();

  factory ShopContent.fromJson(Map<String, dynamic> json) =>
      _$ShopContentFromJson(json);

  int get freeAdsRemainingToday =>
      (freeAdsPerDay - freeAdsWatchedToday).clamp(0, freeAdsPerDay);

  bool get hasFreeAdsRemaining => freeAdsRemainingToday > 0;
}
