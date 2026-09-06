import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/catalog/data/catalog_repository.dart';
import 'package:quizoo/features/catalog/domain/category_detail.dart';

part 'category_detail_state.dart';

/// Owns S-07: one category, its topics, and the active sort.
class CategoryDetailCubit extends Cubit<CategoryDetailState> {
  CategoryDetailCubit(this._repository) : super(const CategoryDetailInitial());

  final CatalogRepository _repository;

  Future<void> load(String categoryId) async {
    emit(const CategoryDetailLoading());
    try {
      final detail = await _repository.fetchCategory(categoryId);
      if (isClosed) return;
      emit(
        CategoryDetailLoaded(
          detail: CatalogRepository.sorted(detail, TopicSort.popular),
        ),
      );
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(CategoryDetailError(error));
    }
  }

  void changeSort(TopicSort sort) {
    final current = state;
    if (current is! CategoryDetailLoaded) return;
    emit(
      CategoryDetailLoaded(
        detail: CatalogRepository.sorted(current.detail, sort),
        sort: sort,
      ),
    );
  }
}
