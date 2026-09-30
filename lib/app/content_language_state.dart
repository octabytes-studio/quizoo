part of 'content_language_cubit.dart';

/// The picked content language (CLAUDE.md §3). [ContentLanguageLoaded] is the
/// only concrete subclass: [ContentLanguageRepository.current] is a
/// synchronous read, so there is nothing for this Cubit to be "loading".
sealed class ContentLanguageState extends Equatable {
  const ContentLanguageState(this.code, this.leadCode);

  final String code;

  /// The language Home's pill row pins first for this process (plan 021).
  /// Frozen across Home pill taps ([ContentLanguageCubit.switchTo]) so the row
  /// never reorders under the player's finger; re-pinned by every explicit
  /// default change ([ContentLanguageCubit.select],
  /// [ContentLanguageCubit.adoptFromBackend]) and on each cold start.
  final String leadCode;

  @override
  List<Object?> get props => [code, leadCode];
}

final class ContentLanguageLoaded extends ContentLanguageState {
  const ContentLanguageLoaded(String code, {String? leadCode})
    : super(code, leadCode ?? code);
}
