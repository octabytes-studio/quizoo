import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

/// S-42's GAME-section toggles.
///
/// Purely cosmetic in this phase: nothing plays sound, music or vibrates
/// (plan 002's Scope note), so these record a preference and no more.
/// Defaults match the bible's own stated ones — sound on, music off, haptics
/// on.
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(true) bool soundOn,
    @Default(false) bool musicOn,
    @Default(true) bool hapticsOn,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
