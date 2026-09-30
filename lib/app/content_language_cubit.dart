import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/content_language/content_language_repository.dart';

part 'content_language_state.dart';

/// The persisted content language — distinct from [LocaleCubit]'s UI locale
/// (plan 008, Design overview). App-root like `ThemeCubit`/`LocaleCubit`:
/// every content-fetching screen is downstream of it.
class ContentLanguageCubit extends Cubit<ContentLanguageState> {
  ContentLanguageCubit(this._repository)
    : super(ContentLanguageLoaded(_repository.current));

  final ContentLanguageRepository _repository;

  /// An explicit "change my default" (Settings, onboarding S-03, Edit
  /// Profile) — persists [code] and re-pins it as Home's lead pill. Picking
  /// the current language while [ContentLanguageState.leadCode] differs (after
  /// Home pill switches) still re-pins it.
  Future<void> select(String code) async {
    if (code == state.code && code == state.leadCode) return;
    await _repository.select(code);
    if (!isClosed) emit(ContentLanguageLoaded(code));
  }

  /// Home's pill tap. Persists exactly like [select] (so the next cold
  /// launch leads with [code]) but leaves [ContentLanguageState.leadCode]
  /// alone, so the row does not reorder under the player's finger (plan 021).
  Future<void> switchTo(String code) async {
    if (code == state.code) return;
    await _repository.select(code);
    if (!isClosed) {
      emit(ContentLanguageLoaded(code, leadCode: state.leadCode));
    }
  }

  /// Adopts the backend's `profiles.locale` when it differs from the local
  /// cache — called once on a guest→signed-in transition (Assumption 2), so
  /// a returning identity's own pick wins over whatever this device cached.
  Future<void> adoptFromBackend() async {
    final backend = await _repository.reconcileWithBackend();
    if (backend != null && !isClosed) emit(ContentLanguageLoaded(backend));
  }
}
