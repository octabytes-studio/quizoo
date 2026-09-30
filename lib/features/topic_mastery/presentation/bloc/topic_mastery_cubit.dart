import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/topic_mastery/data/topic_mastery_repository.dart';
import 'package:quizoo/features/topic_mastery/domain/topic_mastery.dart';

part 'topic_mastery_state.dart';

/// Owns the Topic Mastered screen (plan 020).
///
/// A fetched [TopicMastery] that is not actually mastered yet (a deep link,
/// or stale navigation reached before the 30th level's `level_progress` row
/// landed) is emitted as an error rather than a congratulation — the screen
/// must never celebrate an unfinished topic.
class TopicMasteryCubit extends Cubit<TopicMasteryState> {
  TopicMasteryCubit(this._repository) : super(const TopicMasteryLoading());

  final TopicMasteryRepository _repository;

  Future<void> load({
    required String categoryId,
    required String subcategoryId,
    required String locale,
  }) async {
    emit(const TopicMasteryLoading());
    try {
      final mastery = await _repository.fetch(
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        locale: locale,
      );
      if (isClosed) return;
      if (!mastery.isMastered) {
        emit(
          const TopicMasteryError(
            ApiException(
              'Topic not yet mastered',
              kind: ApiErrorKind.notFound,
              code: 'ERR_CONTENT_404',
            ),
          ),
        );
        return;
      }
      emit(TopicMasteryLoaded(mastery));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(TopicMasteryError(error));
    }
  }
}
