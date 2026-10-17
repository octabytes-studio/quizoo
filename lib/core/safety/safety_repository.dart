import 'package:quizoo/core/safety/domain/blocked_player.dart';
import 'package:quizoo/core/safety/safety_api.dart';

/// Thin domain-facing wrapper over [SafetyApi] — the only layer Cubits talk
/// to (CLAUDE.md §9).
class SafetyRepository {
  SafetyRepository(this._api);

  final SafetyApi _api;

  Future<Set<String>> blockedIds() => _api.blockedIds();

  Future<List<BlockedPlayer>> blockedPlayers() => _api.blockedPlayers();

  Future<void> block(String playerId) => _api.block(playerId);

  Future<void> unblock(String playerId) => _api.unblock(playerId);

  Future<void> reportPlayer({
    required String playerId,
    required String reason,
    String? note,
  }) => _api.reportPlayer(playerId: playerId, reason: reason, note: note);
}
