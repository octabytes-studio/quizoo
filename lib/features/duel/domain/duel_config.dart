import 'package:freezed_annotation/freezed_annotation.dart';

part 'duel_config.freezed.dart';
part 'duel_config.g.dart';

/// The client-visible slice of `app_settings.duel_config` (plan 017), as
/// `get_duel_lobby` returns it.
///
/// Every field defaults to the server's own default so a screen reached
/// without a lobby snapshot (a rejoin, a design-review deep link) can use
/// [DuelConfig.fallback] and still agree with the backend.
@freezed
abstract class DuelConfig with _$DuelConfig {
  const factory DuelConfig({
    @Default(300) int challengeTtlSeconds,
    @Default(120) int cooldownSeconds,
    @Default(5) int joinWindowSeconds,
    @Default(10) int lobbyHeartbeatSeconds,
    @Default(3) int mmHeartbeatSeconds,
    @Default(30) int botAfterSeconds,
    @Default(5) int bandStepSeconds,
    @Default(10) int rounds,
    @Default(15) int roundSeconds,
    @Default(2) int revealSeconds,
    @Default(3) int introSeconds,
    @Default(5) int duelHeartbeatSeconds,
    @Default(30) int rematchWindowSeconds,
    @Default(true) bool presenceEnabled,
    @Default(200) int winCoins,
  }) = _DuelConfig;

  factory DuelConfig.fromJson(Map<String, dynamic> json) =>
      _$DuelConfigFromJson(json);

  /// The server defaults, for screens reached without a lobby snapshot.
  static const DuelConfig fallback = DuelConfig();
}
