import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/features/duel/domain/duel_config.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_round.dart';
import 'package:quizoo/features/duel/domain/duel_side.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/domain/live_duel_outcome.dart';
import 'package:quizoo/features/duel/domain/live_duel_round_state.dart';

part 'live_duel_snapshot.freezed.dart';

/// A live duel's server lifecycle (`duels.status`).
enum LiveDuelStatus { pending, active, complete, forfeit, abandoned }

/// Everything needed to (re)build the live duel screen, already mapped to the
/// player's perspective (`get_duel_state`, plan 017).
///
/// Built by `LiveDuelRepository` rather than decoded directly, because
/// [history] is mapped into the same [DuelRoundRecord] the bot duel uses.
@freezed
abstract class LiveDuelSnapshot with _$LiveDuelSnapshot {
  const factory LiveDuelSnapshot({
    required DateTime serverNow,
    required String duelId,
    required LiveDuelStatus status,
    required DuelSide mySide,
    required bool isRanked,
    required String origin,
    required DuelTopic topic,
    required DuelPlayer me,
    required DuelPlayer opponent,
    required DuelConfig config,
    required int currentRound,
    required List<DuelRoundRecord> history,
    required int myScore,
    required int opponentScore,
    LiveDuelRoundState? round,
    LiveDuelOutcome? result,
  }) = _LiveDuelSnapshot;

  const LiveDuelSnapshot._();

  /// Still being played (or about to be).
  bool get isLive =>
      status == LiveDuelStatus.pending || status == LiveDuelStatus.active;
}
