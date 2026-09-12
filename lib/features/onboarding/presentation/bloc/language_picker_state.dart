part of 'language_picker_cubit.dart';

/// S-03's states, sealed so the screen switches over them exhaustively
/// (CLAUDE.md §3).
sealed class LanguagePickerState extends Equatable {
  const LanguagePickerState();

  @override
  List<Object?> get props => const [];
}

/// Fetching `languages` where `is_active = true`.
final class LanguagePickerLoading extends LanguagePickerState {
  const LanguagePickerLoading();
}

/// The live, orderable list S-03 renders.
final class LanguagePickerLoaded extends LanguagePickerState {
  const LanguagePickerLoaded(this.languages);

  final List<LanguageOption> languages;

  @override
  List<Object?> get props => [languages];
}

final class LanguagePickerError extends LanguagePickerState {
  const LanguagePickerError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
