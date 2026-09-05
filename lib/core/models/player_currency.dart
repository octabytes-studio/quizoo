import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_currency.freezed.dart';
part 'player_currency.g.dart';

/// The player's wallet — the three pills in every top bar.
@freezed
abstract class PlayerCurrency with _$PlayerCurrency {
  const factory PlayerCurrency({
    /// Lemon pill. Buys power-ups.
    @Default(0) int coins,

    /// Sky pill. Premium currency.
    @Default(0) int gems,

    /// Raspberry pill. Spent on a failed level, refilled on a timer.
    @Default(5) int hearts,
    @Default(5) int maxHearts,

    /// When the next heart returns. Null when the player is already full.
    DateTime? heartRefillAt,
  }) = _PlayerCurrency;

  const PlayerCurrency._();

  factory PlayerCurrency.fromJson(Map<String, dynamic> json) =>
      _$PlayerCurrencyFromJson(json);

  bool get hasHearts => hearts > 0;

  bool get isHeartsFull => hearts >= maxHearts;
}
