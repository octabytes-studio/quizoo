import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/app/theme_cubit.dart';
import 'package:quizoo/core/models/app_theme_mode.dart';

/// **On the missing failure-path test** (CLAUDE.md §11): that rule presumes a
/// Cubit that calls a repository which can fail. [ThemeCubit] has no
/// repository and performs no IO — it is a pure local toggle, so there is no
/// failure transition to assert. `N/A` is recorded here deliberately rather
/// than the test being skipped. Every other Cubit in this project does get one.
void main() {
  group('ThemeCubit', () {
    test('starts on system', () {
      expect(ThemeCubit().state, const ThemeSystem());
    });

    blocTest<ThemeCubit, ThemeState>(
      'setLight emits ThemeLight',
      build: ThemeCubit.new,
      act: (cubit) => cubit.setLight(),
      expect: () => const [ThemeLight()],
    );

    blocTest<ThemeCubit, ThemeState>(
      'setDark emits ThemeDark',
      build: ThemeCubit.new,
      act: (cubit) => cubit.setDark(),
      expect: () => const [ThemeDark()],
    );

    blocTest<ThemeCubit, ThemeState>(
      'setSystem returns to ThemeSystem from another mode',
      build: ThemeCubit.new,
      act: (cubit) => cubit
        ..setDark()
        ..setSystem(),
      expect: () => const [ThemeDark(), ThemeSystem()],
    );

    blocTest<ThemeCubit, ThemeState>(
      'setMode routes each AppThemeMode to its state',
      build: ThemeCubit.new,
      act: (cubit) => cubit
        ..setMode(AppThemeMode.light)
        ..setMode(AppThemeMode.dark)
        ..setMode(AppThemeMode.system),
      expect: () => const [ThemeLight(), ThemeDark(), ThemeSystem()],
    );

    blocTest<ThemeCubit, ThemeState>(
      'setting the same mode twice emits it only once',
      build: ThemeCubit.new,
      act: (cubit) => cubit
        ..setLight()
        ..setLight(),
      expect: () => const [ThemeLight()],
    );

    test('every state maps to its Flutter ThemeMode', () {
      expect(const ThemeLight().mode.toThemeMode(), ThemeMode.light);
      expect(const ThemeDark().mode.toThemeMode(), ThemeMode.dark);
      expect(const ThemeSystem().mode.toThemeMode(), ThemeMode.system);
    });
  });
}
