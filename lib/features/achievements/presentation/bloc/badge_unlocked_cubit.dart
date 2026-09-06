import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/achievements/data/achievements_repository.dart';
import 'package:quizoo/features/achievements/domain/badge_progress.dart';

part 'badge_unlocked_state.dart';

/// Owns S-23 — the badge-unlocked interstitial.
///
/// A second, small Cubit beyond this plan's own Design overview list: its
/// state shape (one badge, no filter) does not fit [AchievementsState]'s
/// list-plus-filter shape, and CLAUDE.md §3 defaults to a Cubit per distinct
/// state machine.
class BadgeUnlockedCubit extends Cubit<BadgeUnlockedState> {
  BadgeUnlockedCubit(this._repository) : super(const BadgeUnlockedLoading());

  final AchievementsRepository _repository;

  Future<void> load(String badgeId) async {
    emit(const BadgeUnlockedLoading());
    try {
      final progress = await _repository.fetchById(badgeId);
      if (isClosed) return;
      emit(BadgeUnlockedLoaded(progress));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(BadgeUnlockedError(error));
    }
  }
}
