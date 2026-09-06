import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/models/subcategory.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/home/data/home_repository.dart';
import 'package:quizoo/features/home/domain/home_content.dart';

part 'home_state.dart';

/// Owns Home's content and its category filter.
///
/// The load is deliberately two-stage, because §01's cold-open budget is a
/// two-stage paint rather than one slow one: [load] emits a [HomeLoaded] from
/// cache almost immediately (so Splash → Home stays inside 1.2 s) with
/// `isPopularRailLoading` set, then fills the rail when the network leg
/// returns. A failure on the second leg leaves Home usable and simply drops
/// the rail — the bible's "never end on a dead end" applied to a partial load.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository) : super(const HomeInitial());

  final HomeRepository _repository;

  Future<void> load({required bool isSignedIn}) async {
    emit(const HomeLoading());
    final HomeContent cached;
    try {
      cached = await _repository.fetchCachedHome(isSignedIn: isSignedIn);
    } on ApiException catch (error) {
      emit(HomeError(error));
      return;
    }
    if (isClosed) return;
    emit(HomeLoaded(content: cached, isPopularRailLoading: true));

    try {
      final popular = await _repository.fetchPopularRail();
      if (isClosed) return;
      emit(
        HomeLoaded(
          content: cached.copyWith(popular: popular),
          selectedCategoryId: _selectedCategoryId,
        ),
      );
    } on ApiException {
      // The rail is merchandising, not content: losing it must not take the
      // rest of Home down with it.
      if (isClosed) return;
      emit(
        HomeLoaded(content: cached, selectedCategoryId: _selectedCategoryId),
      );
    }
  }

  String? _selectedCategoryId;

  /// Filters the tile grid. Passing null — or the already-selected id —
  /// clears the filter, which is what makes the "✨ All" chip and a second tap
  /// on the active chip behave the same.
  void selectCategory(String? categoryId) {
    final current = state;
    if (current is! HomeLoaded) return;
    _selectedCategoryId = categoryId == current.selectedCategoryId
        ? null
        : categoryId;
    emit(current.copyWith(selectedCategoryId: _selectedCategoryId));
  }
}
