part of 'settings_cubit.dart';

/// S-42's GAME-toggle state (CLAUDE.md §3). [SettingsLoaded] is the only
/// concrete subclass — see the Cubit doc for why there is no loading/error
/// state to model.
sealed class SettingsState extends Equatable {
  const SettingsState(this.settings);

  final AppSettings settings;

  @override
  List<Object?> get props => [settings];
}

final class SettingsLoaded extends SettingsState {
  const SettingsLoaded(super.settings);
}
