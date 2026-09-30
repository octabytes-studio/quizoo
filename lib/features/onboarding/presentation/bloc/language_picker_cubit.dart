import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/content_language/languages_repository.dart';
import 'package:quizoo/core/content_language/language_option.dart';

part 'language_picker_state.dart';

/// Owns S-03's live language list — sourced from `languages` where
/// `is_active = true` rather than a hardcoded row of options, so flipping a
/// language on needs a Supabase table edit, not an app release (plan 007,
/// Assumption #8).
class LanguagePickerCubit extends Cubit<LanguagePickerState> {
  LanguagePickerCubit(this._repository) : super(const LanguagePickerLoading());

  final LanguagesRepository _repository;

  Future<void> load() async {
    emit(const LanguagePickerLoading());
    try {
      final languages = await _repository.fetchActiveLanguages();
      if (isClosed) return;
      emit(LanguagePickerLoaded(languages));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(LanguagePickerError(error));
    }
  }
}
