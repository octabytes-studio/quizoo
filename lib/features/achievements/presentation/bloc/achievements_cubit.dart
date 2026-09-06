import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/achievements/data/achievements_repository.dart';
import 'package:quizoo/features/achievements/domain/badge_progress.dart';

part 'achievements_state.dart';

/// Owns S-33 — the achievements grid and its filter chips.
///
/// Filtering is real client-side filtering over the fixed set, not mock
/// chrome, since it is cheap to make functional (plan 003, Phase C).
class AchievementsCubit extends Cubit<AchievementsState> {
  AchievementsCubit(this._repository) : super(const AchievementsInitial());

  final AchievementsRepository _repository;

  Future<void> load() async {
    emit(const AchievementsLoading());
    try {
      final all = await _repository.fetchAll();
      if (isClosed) return;
      emit(AchievementsLoaded(all: all));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(AchievementsError(error));
    }
  }

  void selectFilter(BadgeCategory? filter) {
    final current = state;
    if (current is! AchievementsLoaded) return;
    emit(current.copyWith(filter: filter, clearFilter: filter == null));
  }
}
