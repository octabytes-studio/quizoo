import 'package:freezed_annotation/freezed_annotation.dart';

part 'power_up.freezed.dart';
part 'power_up.g.dart';

/// The power-ups the app knows about (§14).
///
/// Every level grants exactly one of each, spent at most once per level —
/// see `QuizPlayCubit.startLevel`/`startDaily`.
enum PowerUp {
  /// Removes two wrong options.
  fiftyFifty,

  /// Adds five seconds to the current question.
  addTime,
}

/// The shop-row glyph a purchase or a use of [PowerUp] once carried.
///
/// Kept as a plain extension rather than fields on [PowerUp] itself, matching
/// how [Category]/[Subcategory] carry a bare `emoji` string with no
/// localization coupling — `core/models/` never imports `l10n/`.
extension PowerUpPricing on PowerUp {
  /// The power-up's leading glyph.
  String get emoji => switch (this) {
    PowerUp.fiftyFifty => '🎯',
    PowerUp.addTime => '⏱️',
  };
}

/// What the player is carrying into a level.
@freezed
abstract class PowerUpInventory with _$PowerUpInventory {
  const factory PowerUpInventory({
    @Default(0) int fiftyFifty,
    @Default(0) int addTime,
  }) = _PowerUpInventory;

  const PowerUpInventory._();

  factory PowerUpInventory.fromJson(Map<String, dynamic> json) =>
      _$PowerUpInventoryFromJson(json);

  int countOf(PowerUp powerUp) => switch (powerUp) {
    PowerUp.fiftyFifty => fiftyFifty,
    PowerUp.addTime => addTime,
  };

  bool has(PowerUp powerUp) => countOf(powerUp) > 0;

  /// One spent. A power-up the player has none of is never spent — the tile
  /// is inert at zero.
  PowerUpInventory spend(PowerUp powerUp) => switch (powerUp) {
    PowerUp.fiftyFifty => copyWith(fiftyFifty: (fiftyFifty - 1).clamp(0, 99)),
    PowerUp.addTime => copyWith(addTime: (addTime - 1).clamp(0, 99)),
  };

  /// How many seconds [PowerUp.addTime] buys.
  static const int addTimeSeconds = 5;
}
