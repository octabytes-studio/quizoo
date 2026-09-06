import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/leaderboard/data/leaderboard_repository.dart';
import 'package:quizoo/features/leaderboard/domain/leaderboard_entry.dart';

part 'category_leaderboard_state.dart';

/// Owns S-30 — a single subcategory's own leaderboard.
class CategoryLeaderboardCubit extends Cubit<CategoryLeaderboardState> {
  CategoryLeaderboardCubit(this._repository)
    : super(const CategoryLeaderboardInitial());

  final LeaderboardRepository _repository;

  Future<void> load(String subcategoryId) async {
    emit(const CategoryLeaderboardLoading());
    try {
      final roster = await _repository.fetchCategoryRoster(subcategoryId);
      final (rank, pointsFromTop, countryName) = await _repository
          .fetchCategoryHeader(subcategoryId);
      if (isClosed) return;
      emit(
        CategoryLeaderboardLoaded(
          roster: roster,
          selfRank: rank,
          pointsFromTop: pointsFromTop,
          countryName: countryName,
        ),
      );
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(CategoryLeaderboardError(error));
    }
  }
}
