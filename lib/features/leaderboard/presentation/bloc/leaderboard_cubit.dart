import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/leaderboard/data/leaderboard_repository.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_entry.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_scope.dart';

part 'leaderboard_state.dart';

/// Owns S-29 — the global/country/friends × week/month/all-time leaderboard.
///
/// Every scope/period change re-fetches from [LeaderboardRepository], which
/// re-slices the same fixture roster (plan 003, Scope) — from the Cubit's
/// side this is indistinguishable from a real time-boxed query, which is the
/// point: nothing here changes when a backend lands.
class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit(this._repository) : super(const LeaderboardInitial());

  final LeaderboardRepository _repository;

  Future<void> load({
    LeaderboardScope scope = LeaderboardScope.global,
    LeaderboardPeriod period = LeaderboardPeriod.week,
  }) async {
    emit(const LeaderboardLoading());
    try {
      final roster = await _repository.fetchRoster(
        scope: scope,
        period: period,
      );
      final self = await _repository.fetchSelfEntry(
        scope: scope,
        period: period,
      );
      if (isClosed) return;
      emit(
        LeaderboardLoaded(
          scope: scope,
          period: period,
          roster: roster,
          selfEntry: self,
        ),
      );
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(LeaderboardError(error));
    }
  }

  void changeScope(LeaderboardScope scope) {
    final current = state;
    load(
      scope: scope,
      period: current is LeaderboardLoaded
          ? current.period
          : LeaderboardPeriod.week,
    );
  }

  void changePeriod(LeaderboardPeriod period) {
    final current = state;
    load(
      scope: current is LeaderboardLoaded
          ? current.scope
          : LeaderboardScope.global,
      period: period,
    );
  }
}
