part of 'content_language_cubit.dart';

/// The picked content language (CLAUDE.md §3). [ContentLanguageLoaded] is the
/// only concrete subclass: [ContentLanguageRepository.current] is a
/// synchronous read, so there is nothing for this Cubit to be "loading".
sealed class ContentLanguageState extends Equatable {
  const ContentLanguageState(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

final class ContentLanguageLoaded extends ContentLanguageState {
  const ContentLanguageLoaded(super.code);
}
