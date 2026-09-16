import 'dart:async';

import 'package:quizoo/core/content_language/content_language_api.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The `shared_preferences`-backed cache behind the content-language pick,
/// decoupled from `LocaleCubit`'s UI-locale concern (plan 008, Design
/// overview). [current] is synchronous so a fresh `ContentLanguageCubit` has
/// its initial state with no network wait, matching `SettingsRepository`'s
/// own convention.
class ContentLanguageRepository {
  ContentLanguageRepository(this._api, this._preferences);

  final ContentLanguageApi _api;
  final SharedPreferences _preferences;

  static const _key = 'content_language.code';
  static const fallback = 'en';

  String get current => _preferences.getString(_key) ?? fallback;

  /// Persists [code] locally (awaited, so [current] is correct the instant
  /// this returns), then fires-and-forgets the backend leg — a failure there
  /// is swallowed, matching every other `unawaited`-persisted setting in this
  /// codebase.
  Future<void> select(String code) async {
    await _preferences.setString(_key, code);
    unawaited(_api.updateProfileLocale(code).catchError((_) {}));
  }

  /// Best-effort: returns the backend's value only if it differs from the
  /// local cache (and adopts it locally too), null otherwise/on failure.
  Future<String?> reconcileWithBackend() async {
    try {
      final backend = await _api.fetchProfileLocale();
      if (backend == null || backend == current) return null;
      await _preferences.setString(_key, backend);
      return backend;
    } catch (_) {
      return null;
    }
  }

  /// Best-effort, matching `reconcileWithBackend`'s own convention: a lookup
  /// failure disables TTS for this level rather than blocking it from
  /// starting.
  Future<String?> voiceIdFor(String code) async {
    try {
      return await _api.fetchVoiceId(code);
    } on ApiException {
      return null;
    }
  }
}
