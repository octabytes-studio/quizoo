import 'dart:async';

import 'package:quizoo/core/content_language/content_language_repository.dart';
import 'package:quizoo/features/quiz_play/data/audioplayers_sound_effects_service.dart';
import 'package:quizoo/features/quiz_play/data/cache_manager_audio_cache_service.dart';
import 'package:quizoo/features/quiz_play/data/sound_effects_service.dart';
import 'package:quizoo/features/quiz_play/data/stored_audio_tts_service.dart';
import 'package:quizoo/features/quiz_play/data/tts_service.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';

/// Read-aloud and sound effects for a duel's rounds — the same pre-generated
/// narration clips and the same tick / correct / wrong / next chimes play
/// mode uses, behind the same persisted speaker toggle
/// (`AppSettings.soundOn`), so a player who muted play mode is muted here too.
///
/// One difference from play mode, by necessity: a duel's clock belongs to
/// the server and is shared by both players, so it can't wait for the
/// narration to finish — the question is read aloud *while* its clock runs,
/// and each player can mute it for themselves.
///
/// Reuses `quiz_play`'s [TtsService] / [SoundEffectsService] seams (a
/// cross-feature import, like the duel screens' `TimerRing`; moving the
/// audio seams to `core/` is a separate cleanup). Blocs/Cubits take this
/// class through their constructor, so tests substitute a mock.
class DuelAudio {
  DuelAudio(this._tts, this._effects, this._settings, this._languages);

  /// The real device audio — the same narration player, clip cache and
  /// chime players play mode builds.
  factory DuelAudio.device({
    required SettingsRepository settings,
    required ContentLanguageRepository languages,
  }) => DuelAudio(
    StoredAudioTtsService(CacheManagerAudioCacheService()),
    AudioplayersSoundEffectsService(),
    settings,
    languages,
  );

  final TtsService _tts;
  final SoundEffectsService _effects;
  final SettingsRepository _settings;
  final ContentLanguageRepository _languages;

  bool _voiceAvailable = false;
  bool _ticking = false;

  /// The persisted speaker preference.
  bool get isOn => _settings.current.soundOn;

  /// Checks once whether [languageCode] has a narration voice; without one,
  /// questions stay silent but the chimes still play.
  Future<void> prepare(String languageCode) async {
    try {
      final voiceId = await _languages.voiceIdFor(languageCode);
      _voiceAvailable = await _tts.setLanguage(languageCode, voiceId: voiceId);
    } on Object {
      _voiceAvailable = false;
    }
  }

  /// A question just appeared: read it aloud (when it has a clip and isn't
  /// excluded) and start the clock tick.
  void questionShown({String? audioUrl, bool ttsExcluded = false}) {
    if (!isOn) return;
    if (_voiceAvailable && !ttsExcluded && audioUrl != null) {
      unawaited(_tts.speak(audioUrl));
    }
    _startTick();
  }

  /// This player locked an answer (or timed out): their clock is done.
  void answerLocked() {
    _stopTick();
    unawaited(_tts.stop());
  }

  /// The round's verdict is on screen.
  void revealed({required bool correct}) {
    answerLocked();
    if (!isOn) return;
    unawaited(correct ? _effects.playCorrect() : _effects.playWrong());
  }

  /// The next question is about to appear.
  void nextQuestion() {
    if (isOn) unawaited(_effects.playNextQuestion());
  }

  /// Flips and persists the speaker preference; returns the new value.
  /// Muting silences the narration and tick at once; un-muting restarts
  /// the tick only if the player is still answering ([clockRunning]).
  bool toggle({required bool clockRunning}) {
    final current = _settings.current;
    final on = !current.soundOn;
    _settings.update(current.copyWith(soundOn: on));
    if (!on) {
      answerLocked();
    } else if (clockRunning) {
      _startTick();
    }
    return on;
  }

  /// Silences everything (screen closing, duel over).
  void stopAll() => answerLocked();

  Future<void> dispose() async {
    stopAll();
    await _tts.dispose();
    await _effects.dispose();
  }

  void _startTick() {
    if (_ticking) return;
    _ticking = true;
    unawaited(_effects.startTicking());
  }

  void _stopTick() {
    if (!_ticking) return;
    _ticking = false;
    unawaited(_effects.stopTicking());
  }
}
