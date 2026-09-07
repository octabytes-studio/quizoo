import 'package:freezed_annotation/freezed_annotation.dart';

part 'power_up.freezed.dart';
part 'power_up.g.dart';

/// The power-ups the app knows about (§14).
///
/// **Promoted here from `features/quiz_play/domain/` in plan 004** (plan
/// 004's Assumption 1): `features/shop` needs the same enum to price and
/// describe its rows, and CLAUDE.md §2's "reused by 3+ features" bar for
/// `core/` is met the moment a second feature needs it rather than waited out
/// to a literal third.
///
/// [freeze] is genuinely new here — the bible's shop sells it (§14, S-36) as
/// a duel-only power-up ("freezes the opponent's timer for 5s"), but no
/// solo-play mechanic exists for it and `features/duel`'s Scope note is
/// explicit that real duel networking is out of this series. The shop still
/// sells it — a purchase increments [PowerUpInventory.freeze] for display —
/// there is simply no play surface that spends it yet, which is an honest
/// mock-phase gap rather than a silently invented feature.
enum PowerUp {
  /// Removes two wrong options.
  fiftyFifty,

  /// Adds fifteen seconds to the current question.
  addTime,

  /// Skips the question without costing a heart.
  skip,

  /// Freezes the opponent's timer for 5s in a duel. Shop-only for now.
  freeze,
}

/// What a purchase or a use of [PowerUp] costs, and its shop-row glyph.
///
/// Kept as a plain extension rather than fields on [PowerUp] itself, matching
/// how [Category]/[Subcategory] carry a bare `emoji` string with no
/// localization coupling — `core/models/` never imports `l10n/`.
extension PowerUpPricing on PowerUp {
  /// The shop row's leading glyph.
  String get emoji => switch (this) {
    PowerUp.fiftyFifty => '🎯',
    PowerUp.addTime => '⏱️',
    PowerUp.skip => '⏭️',
    PowerUp.freeze => '🧊',
  };

  /// Coin price, or null when the power-up is gem-priced instead.
  int? get costCoins => switch (this) {
    PowerUp.fiftyFifty => 40,
    PowerUp.addTime => 60,
    PowerUp.skip => 80,
    PowerUp.freeze => null,
  };

  /// Gem price — only [PowerUp.freeze] (§14: "Freeze priced in gems").
  int? get costGems => switch (this) {
    PowerUp.freeze => 5,
    _ => null,
  };
}

/// What the player is carrying into a level.
@freezed
abstract class PowerUpInventory with _$PowerUpInventory {
  const factory PowerUpInventory({
    @Default(0) int fiftyFifty,
    @Default(0) int addTime,
    @Default(0) int skip,
    @Default(0) int freeze,
  }) = _PowerUpInventory;

  const PowerUpInventory._();

  factory PowerUpInventory.fromJson(Map<String, dynamic> json) =>
      _$PowerUpInventoryFromJson(json);

  int countOf(PowerUp powerUp) => switch (powerUp) {
    PowerUp.fiftyFifty => fiftyFifty,
    PowerUp.addTime => addTime,
    PowerUp.skip => skip,
    PowerUp.freeze => freeze,
  };

  bool has(PowerUp powerUp) => countOf(powerUp) > 0;

  /// One spent. A power-up the player has none of is never spent — the tile
  /// routes to the shop instead.
  PowerUpInventory spend(PowerUp powerUp) => switch (powerUp) {
    PowerUp.fiftyFifty => copyWith(fiftyFifty: (fiftyFifty - 1).clamp(0, 99)),
    PowerUp.addTime => copyWith(addTime: (addTime - 1).clamp(0, 99)),
    PowerUp.skip => copyWith(skip: (skip - 1).clamp(0, 99)),
    PowerUp.freeze => copyWith(freeze: (freeze - 1).clamp(0, 99)),
  };

  /// One bought — the shop's side of [spend].
  PowerUpInventory grant(PowerUp powerUp, {int count = 1}) => switch (powerUp) {
    PowerUp.fiftyFifty => copyWith(fiftyFifty: fiftyFifty + count),
    PowerUp.addTime => copyWith(addTime: addTime + count),
    PowerUp.skip => copyWith(skip: skip + count),
    PowerUp.freeze => copyWith(freeze: freeze + count),
  };

  /// How many seconds [PowerUp.addTime] buys.
  static const int addTimeSeconds = 15;
}
