import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';
import 'package:quizoo/features/settings/presentation/bloc/settings_cubit.dart';

/// **On the missing failure-path test** (CLAUDE.md §11): like `ThemeCubit`,
/// [SettingsCubit] performs no IO — [SettingsRepository] is a synchronous
/// in-memory store — so there is no failure transition to assert. `N/A` is
/// recorded here deliberately rather than the test being skipped.
void main() {
  group('SettingsCubit', () {
    test('starts from the repository\'s defaults', () {
      final cubit = SettingsCubit(SettingsRepository());
      expect(cubit.state.settings.soundOn, isTrue);
      expect(cubit.state.settings.musicOn, isFalse);
      expect(cubit.state.settings.hapticsOn, isTrue);
    });

    blocTest<SettingsCubit, SettingsState>(
      'success path: each toggle flips its own field and no other',
      build: () => SettingsCubit(SettingsRepository()),
      act: (cubit) => cubit
        ..toggleSound()
        ..toggleMusic()
        ..toggleHaptics(),
      expect: () => [
        isA<SettingsLoaded>()
            .having((state) => state.settings.soundOn, 'soundOn', isFalse)
            .having((state) => state.settings.musicOn, 'musicOn', isFalse)
            .having((state) => state.settings.hapticsOn, 'hapticsOn', isTrue),
        isA<SettingsLoaded>()
            .having((state) => state.settings.soundOn, 'soundOn', isFalse)
            .having((state) => state.settings.musicOn, 'musicOn', isTrue)
            .having((state) => state.settings.hapticsOn, 'hapticsOn', isTrue),
        isA<SettingsLoaded>()
            .having((state) => state.settings.soundOn, 'soundOn', isFalse)
            .having((state) => state.settings.musicOn, 'musicOn', isTrue)
            .having((state) => state.settings.hapticsOn, 'hapticsOn', isFalse),
      ],
    );
  });
}
