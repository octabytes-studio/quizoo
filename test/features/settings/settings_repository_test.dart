import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';
import 'package:quizoo/features/settings/domain/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A `shared_preferences`-backed store with no API layer to mock (see the
/// class doc) — tested against the plugin's own mock backend.
void main() {
  group('SettingsRepository', () {
    test('starts on the bible\'s stated defaults', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = SettingsRepository(
        await SharedPreferences.getInstance(),
      );
      expect(repository.current, const AppSettings());
    });

    test(
      'update replaces the current settings and is read back exactly',
      () async {
        SharedPreferences.setMockInitialValues({});
        final repository = SettingsRepository(
          await SharedPreferences.getInstance(),
        );

        final updated = repository.update(const AppSettings(soundOn: false));

        expect(updated, const AppSettings(soundOn: false));
        expect(repository.current, const AppSettings(soundOn: false));
      },
    );
  });
}
