import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_arena_repository.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';

part 'duel_topic_picker_state.dart';

/// The "pick your battleground" sheet's topic list (plan 017, Phase 8):
/// `list_duel_topics` for the content language, which only offers topics
/// with enough live questions to duel in.
class DuelTopicPickerCubit extends Cubit<DuelTopicPickerState> {
  DuelTopicPickerCubit(this._repository)
    : super(const DuelTopicPickerLoading());

  final DuelArenaRepository _repository;

  String? _languageCode;

  Future<void> load(String languageCode) async {
    _languageCode = languageCode;
    emit(const DuelTopicPickerLoading());
    try {
      final topics = await _repository.fetchTopics(languageCode);
      if (!isClosed) emit(DuelTopicPickerLoaded(topics));
    } on ApiException catch (error) {
      if (!isClosed) emit(DuelTopicPickerFailed(error));
    }
  }

  /// Loads again in the last language asked for.
  Future<void> retry() async {
    final languageCode = _languageCode;
    if (languageCode == null) return;
    await load(languageCode);
  }
}
