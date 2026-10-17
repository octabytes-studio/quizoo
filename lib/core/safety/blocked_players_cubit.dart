import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/safety/domain/blocked_player.dart';
import 'package:quizoo/core/safety/safety_repository.dart';

part 'blocked_players_state.dart';

/// Owns Privacy → Blocked players (plan 025): the list and the unblock
/// action.
class BlockedPlayersCubit extends Cubit<BlockedPlayersState> {
  BlockedPlayersCubit(this._repository) : super(const BlockedPlayersInitial());

  final SafetyRepository _repository;

  Future<void> load() async {
    emit(const BlockedPlayersLoading());
    try {
      final players = await _repository.blockedPlayers();
      if (isClosed) return;
      emit(BlockedPlayersLoaded(players));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(BlockedPlayersError(error));
    }
  }

  /// Unblocks, then reloads so the row disappears — the same list query the
  /// initial load uses, rather than trying to mutate the loaded state twice.
  Future<void> unblock(String playerId) async {
    try {
      await _repository.unblock(playerId);
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(BlockedPlayersError(error));
      return;
    }
    await load();
  }
}
