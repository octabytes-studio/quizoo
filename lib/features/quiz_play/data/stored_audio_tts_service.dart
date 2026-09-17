import 'package:audioplayers/audioplayers.dart';
import 'package:quizoo/features/quiz_play/data/tts_service.dart';

/// The real [TtsService], playing a pre-generated audio file straight
/// from its Supabase Storage URL via `audioplayers`. No download/temp-file
/// step: unlike `BytesSource` (unsupported on Darwin — see the deleted
/// `ElevenLabsTtsService`'s doc comment), `UrlSource` is a plain
/// `setSourceUrl(isLocal: false)`, supported on every platform this app
/// ships to.
class StoredAudioTtsService implements TtsService {
  StoredAudioTtsService() {
    _player.onPlayerComplete.listen((_) => _onComplete?.call());
  }

  final AudioPlayer _player = AudioPlayer(playerId: 'tts_stored_audio');
  void Function()? _onComplete;

  @override
  Future<bool> setLanguage(String languageCode, {String? voiceId}) async =>
      voiceId != null;

  @override
  Future<void> speak(String audioUrl) async {
    try {
      await _player.play(UrlSource(audioUrl));
    } catch (_) {
      // Fail open: never leave the question stuck in the "speaking" phase
      // on a network/playback failure.
      _onComplete?.call();
    }
  }

  @override
  Future<void> stop() async => _player.stop();

  @override
  void onComplete(void Function() callback) => _onComplete = callback;

  @override
  Future<void> dispose() => _player.dispose();
}
