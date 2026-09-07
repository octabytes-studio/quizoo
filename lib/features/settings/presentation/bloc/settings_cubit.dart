import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';
import 'package:quizoo/features/settings/domain/app_settings.dart';

part 'settings_state.dart';

/// Owns S-42's GAME-section toggles.
///
/// **On the missing loading/error states and failure-path test** (CLAUDE.md
/// §11): like `ThemeCubit`, this performs no IO — [SettingsRepository] is a
/// synchronous in-memory store, so there is nothing to load and no failure to
/// simulate. `SettingsLoaded` is the only state this Cubit ever emits.
///
/// Theme itself is **not** duplicated here — S-42's segmented control reads
/// and drives `ThemeCubit` directly (plan 004, Research findings), which is
/// what keeps it the one true theme state in the app.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository) : super(SettingsLoaded(_repository.current));

  final SettingsRepository _repository;

  void toggleSound() => emit(
    SettingsLoaded(
      _repository.update(
        state.settings.copyWith(soundOn: !state.settings.soundOn),
      ),
    ),
  );

  void toggleMusic() => emit(
    SettingsLoaded(
      _repository.update(
        state.settings.copyWith(musicOn: !state.settings.musicOn),
      ),
    ),
  );

  void toggleHaptics() => emit(
    SettingsLoaded(
      _repository.update(
        state.settings.copyWith(hapticsOn: !state.settings.hapticsOn),
      ),
    ),
  );
}
