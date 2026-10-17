import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/safety/domain/player_report_reason.dart';
import 'package:quizoo/core/safety/safety_repository.dart';

part 'safety_state.dart';

/// What a completed safety action achieved — the sheet maps each outcome to
/// its own ARB confirmation (the Cubit stays localization-free, CLAUDE.md §3).
enum SafetyOutcome { blocked, unblocked, reported }

/// Owns the player-actions sheet's server round trips (plan 025): the
/// report/block/unblock for one target player.
class SafetyCubit extends Cubit<SafetyState> {
  SafetyCubit(
    this._repository, {
    required this.playerId,
    required this.isBlocked,
  }) : super(const SafetyIdle());

  final SafetyRepository _repository;

  /// The player this sheet acts on.
  final String playerId;

  /// Whether the viewer has this player blocked right now — flipped by
  /// [toggleBlock] and re-read by the sheet after every state change so the
  /// row's label is correct.
  bool isBlocked;

  /// Blocks or unblocks [playerId] depending on the current state.
  Future<void> toggleBlock() async {
    if (state is SafetyBusy) return;
    emit(const SafetyBusy());
    try {
      if (isBlocked) {
        await _repository.unblock(playerId);
        isBlocked = false;
        if (isClosed) return;
        emit(const SafetyDone(SafetyOutcome.unblocked));
      } else {
        await _repository.block(playerId);
        isBlocked = true;
        if (isClosed) return;
        emit(const SafetyDone(SafetyOutcome.blocked));
      }
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(SafetyFailed(error));
    }
  }

  Future<void> report(PlayerReportReason reason) async {
    if (state is SafetyBusy) return;
    emit(const SafetyBusy());
    try {
      await _repository.reportPlayer(playerId: playerId, reason: reason.code);
      if (isClosed) return;
      emit(const SafetyDone(SafetyOutcome.reported));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(SafetyFailed(error));
    }
  }
}
