import 'package:freezed_annotation/freezed_annotation.dart';

part 'power_up.freezed.dart';
part 'power_up.g.dart';

/// The three power-ups in the dock (§14). There is no fourth — the "+ SHOP"
/// tile on S-09 is a link, not a power-up.
enum PowerUp {
  /// Removes two wrong options.
  fiftyFifty,

  /// Adds fifteen seconds to the current question.
  addTime,

  /// Skips the question without costing a heart.
  skip,
}

/// What the player is carrying into a level.
@freezed
abstract class PowerUpInventory with _$PowerUpInventory {
  const factory PowerUpInventory({
    @Default(0) int fiftyFifty,
    @Default(0) int addTime,
    @Default(0) int skip,
  }) = _PowerUpInventory;

  const PowerUpInventory._();

  factory PowerUpInventory.fromJson(Map<String, dynamic> json) =>
      _$PowerUpInventoryFromJson(json);

  int countOf(PowerUp powerUp) => switch (powerUp) {
    PowerUp.fiftyFifty => fiftyFifty,
    PowerUp.addTime => addTime,
    PowerUp.skip => skip,
  };

  bool has(PowerUp powerUp) => countOf(powerUp) > 0;

  /// One spent. A power-up the player has none of is never spent — the tile
  /// routes to the shop instead.
  PowerUpInventory spend(PowerUp powerUp) => switch (powerUp) {
    PowerUp.fiftyFifty => copyWith(fiftyFifty: (fiftyFifty - 1).clamp(0, 99)),
    PowerUp.addTime => copyWith(addTime: (addTime - 1).clamp(0, 99)),
    PowerUp.skip => copyWith(skip: (skip - 1).clamp(0, 99)),
  };

  /// How many seconds [PowerUp.addTime] buys.
  static const int addTimeSeconds = 15;
}
