import 'package:freezed_annotation/freezed_annotation.dart';

part 'coin_pack.freezed.dart';
part 'coin_pack.g.dart';

/// One tile in S-36's 3-up coin-pack grid.
@freezed
abstract class CoinPack with _$CoinPack {
  const factory CoinPack({
    required String id,
    required int coins,
    required String priceLabel,

    /// "+20%", "+50%" — zero means no bonus badge at all.
    @Default(0) int bonusPercent,

    /// The bible's middle, most-favourable pack — the one the grid highlights.
    @Default(false) bool isHighlighted,
  }) = _CoinPack;

  factory CoinPack.fromJson(Map<String, dynamic> json) =>
      _$CoinPackFromJson(json);
}
