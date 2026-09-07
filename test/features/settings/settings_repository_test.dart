import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';
import 'package:quizoo/features/settings/domain/app_settings.dart';

/// A synchronous in-memory store with no API layer to mock (see the class
/// doc) — this is the same shape as `AuthRepository`'s save-progress flags,
/// tested the same plain way.
void main() {
  group('SettingsRepository', () {
    test('starts on the bible\'s stated defaults', () {
      final repository = SettingsRepository();
      expect(repository.current, const AppSettings());
    });

    test('update replaces the current settings and is read back exactly', () {
      final repository = SettingsRepository();

      final updated = repository.update(const AppSettings(soundOn: false));

      expect(updated, const AppSettings(soundOn: false));
      expect(repository.current, const AppSettings(soundOn: false));
    });
  });
}
