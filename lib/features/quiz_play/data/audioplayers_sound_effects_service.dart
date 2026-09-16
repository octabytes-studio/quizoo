import 'package:audioplayers/audioplayers.dart';
import 'package:quizoo/features/quiz_play/data/sound_effects_service.dart';

/// The real [SoundEffectsService], backed by `audioplayers`.
///
/// Each sound gets its own [AudioPlayer] rather than sharing one, so a quick
/// manual "Next" tap can layer the next-question chime over a still-ringing
/// correct/wrong chime without cutting either off, and so the looping tick
/// never fights a one-shot for the same native player.
///
/// Every player is created lazily, on its first actual play call.
/// Constructing an [AudioPlayer] opens a platform channel immediately
/// (`audioplayers`' own `_create()`), which would fire even while sound
/// effects are off — the default, and the only case exercised in widget
/// tests (`pump_screen.dart` seeds `settings.soundOn: false`).
class AudioplayersSoundEffectsService implements SoundEffectsService {
  AudioPlayer? _tick;
  AudioPlayer? _correct;
  AudioPlayer? _wrong;
  AudioPlayer? _next;

  static final _tickAsset = AssetSource('audio/clock_ticking.mp3');
  static final _correctAsset = AssetSource('audio/right_answer.mp3');
  static final _wrongAsset = AssetSource('audio/wrong_answer.mp3');
  static final _nextAsset = AssetSource('audio/next_question.mp3');

  @override
  Future<void> startTicking() async {
    final player = _tick ??= AudioPlayer(playerId: 'sfx_tick');
    await player.setReleaseMode(ReleaseMode.loop);
    await player.stop();
    await player.play(_tickAsset);
  }

  @override
  Future<void> stopTicking() async {
    await _tick?.stop();
  }

  @override
  Future<void> playCorrect() async {
    final player = _correct ??= AudioPlayer(playerId: 'sfx_correct');
    await player.stop();
    await player.play(_correctAsset, mode: PlayerMode.lowLatency);
  }

  @override
  Future<void> playWrong() async {
    final player = _wrong ??= AudioPlayer(playerId: 'sfx_wrong');
    await player.stop();
    await player.play(_wrongAsset, mode: PlayerMode.lowLatency);
  }

  @override
  Future<void> playNextQuestion() async {
    final player = _next ??= AudioPlayer(playerId: 'sfx_next');
    await player.stop();
    await player.play(_nextAsset, mode: PlayerMode.lowLatency);
  }

  @override
  Future<void> dispose() async {
    await _tick?.dispose();
    await _correct?.dispose();
    await _wrong?.dispose();
    await _next?.dispose();
  }
}
