import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/features/duel/domain/duel_challenge.dart';
import 'package:quizoo/features/duel/domain/duel_config.dart';
import 'package:quizoo/features/duel/domain/duel_lobby_me.dart';
import 'package:quizoo/features/duel/domain/incoming_join_request.dart';
import 'package:quizoo/features/duel/domain/outgoing_join_request.dart';

part 'duel_lobby_snapshot.freezed.dart';
part 'duel_lobby_snapshot.g.dart';

/// Everything the Duel Arena needs to render, from `get_duel_lobby` — loaded
/// on open and re-fetched after any channel re-subscribe, with Realtime
/// deltas applied on top in between (plan 017, "Snapshot + deltas").
///
/// [challenges] are ordered oldest first, which is the chat-style feed's
/// order (newest at the bottom).
@freezed
abstract class DuelLobbySnapshot with _$DuelLobbySnapshot {
  const factory DuelLobbySnapshot({
    required DateTime serverNow,
    required DuelConfig config,
    required DuelLobbyMe me,
    @Default([]) List<DuelChallenge> challenges,
    @Default([]) List<OutgoingJoinRequest> myRequests,
    IncomingJoinRequest? incoming,
  }) = _DuelLobbySnapshot;

  factory DuelLobbySnapshot.fromJson(Map<String, dynamic> json) =>
      _$DuelLobbySnapshotFromJson(json);
}
