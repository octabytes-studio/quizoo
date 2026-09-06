import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/leaderboard/data/leaderboard_repository.dart';
import 'package:quizoo/features/leaderboard/domain/league_standing.dart';

part 'league_state.dart';

/// Owns S-26 — the mini-standings card on the league promotion screen.
class LeagueCubit extends Cubit<LeagueState> {
  LeagueCubit(this._repository) : super(const LeagueInitial());

  final LeaderboardRepository _repository;

  Future<void> load() async {
    emit(const LeagueLoading());
    try {
      final neighbors = await _repository.fetchLeagueNeighbors();
      if (isClosed) return;
      emit(LeagueLoaded(neighbors));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(LeagueError(error));
    }
  }
}
