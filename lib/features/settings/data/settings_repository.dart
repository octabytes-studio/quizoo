import 'package:quizoo/features/settings/domain/app_settings.dart';

/// The in-memory store behind S-42's GAME toggles.
///
/// No `*_api.dart`/`MockApi` here, deliberately: there is no network round
/// trip to simulate for a local preference, exactly like
/// `AuthRepository.markLevelCompleted`'s synchronous in-memory bookkeeping.
/// Resets with the app, like every other mock-phase preference.
class SettingsRepository {
  AppSettings _current = const AppSettings();

  AppSettings get current => _current;

  AppSettings update(AppSettings settings) => _current = settings;
}
