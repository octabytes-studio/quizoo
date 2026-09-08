import 'dart:async';

import 'package:quizoo/features/settings/domain/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The `shared_preferences`-backed store behind S-42's GAME toggles.
///
/// Still no `*_api.dart`/network round trip — these are per-device UX
/// preferences with no multi-device sync requirement (plan 006, Assumption
/// #5) — only the storage moved from in-memory to local disk, so a
/// preference set once survives a cold start against a real backend.
class SettingsRepository {
  SettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _soundOnKey = 'settings.soundOn';
  static const _musicOnKey = 'settings.musicOn';
  static const _hapticsOnKey = 'settings.hapticsOn';

  AppSettings get current => AppSettings(
    soundOn: _preferences.getBool(_soundOnKey) ?? true,
    musicOn: _preferences.getBool(_musicOnKey) ?? false,
    hapticsOn: _preferences.getBool(_hapticsOnKey) ?? true,
  );

  AppSettings update(AppSettings settings) {
    unawaited(_preferences.setBool(_soundOnKey, settings.soundOn));
    unawaited(_preferences.setBool(_musicOnKey, settings.musicOn));
    unawaited(_preferences.setBool(_hapticsOnKey, settings.hapticsOn));
    return settings;
  }
}
