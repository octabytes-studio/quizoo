import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/models/level.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/catalog/data/catalog_repository.dart';
import 'package:quizoo/features/catalog/domain/level_map.dart';

part 'level_map_state.dart';

/// Owns S-08: one topic's twenty levels.
class LevelMapCubit extends Cubit<LevelMapState> {
  LevelMapCubit(this._repository) : super(const LevelMapInitial());

  final CatalogRepository _repository;

  /// Loads one topic's levels.
  ///
  /// [isPro] is the Quizoo Pro entitlement (plan 023): when true every
  /// locked level becomes [LevelStatus.open], so a member can play any of
  /// them. The server enforces the same rule — this is only what the map
  /// *draws*.
  Future<void> load({
    required String categoryId,
    required String subcategoryId,
    required String locale,
    required bool isPro,
  }) async {
    emit(const LevelMapLoading());
    try {
      final fetched = await _repository.fetchLevelMap(
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        locale: locale,
      );
      if (isClosed) return;
      final map = isPro ? fetched.withAllLevelsOpen() : fetched;
      emit(
        // A topic with no levels behind it yet is an empty state (S-47), not
        // an error — most of the taxonomy is deliberately unbuilt content.
        map.levels.isEmpty ? LevelMapEmpty(map) : LevelMapLoaded(map),
      );
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(LevelMapError(error));
    }
  }
}
