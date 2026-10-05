import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:quizoo/features/quiz_play/data/question_audio_cache_service.dart';
import 'package:quizoo/features/quiz_play/data/tts_service.dart';

/// The real [TtsService], playing a pre-generated audio file straight
/// from its Supabase Storage URL via `audioplayers`. No download/temp-file
/// step: unlike `BytesSource` (unsupported on Darwin — see the deleted
/// `ElevenLabsTtsService`'s doc comment), `UrlSource` is a plain
/// `setSourceUrl(isLocal: false)`, supported on every platform this app
/// ships to.
///
/// Plays from [QuestionAudioCacheService]'s local disk cache when the
/// clip's already there, falling back to the direct network stream — and
/// warming the cache for next time — on a cache miss.
class StoredAudioTtsService implements TtsService {
  StoredAudioTtsService(this._audioCacheService) {
    _player.onPlayerComplete.listen((_) => _onComplete?.call());
  }

  final QuestionAudioCacheService _audioCacheService;
  final AudioPlayer _player = AudioPlayer(playerId: 'tts_stored_audio');
  void Function()? _onComplete;

  @override
  Future<void> speak(String audioUrl) async {
    try {
      final localPath = await _audioCacheService.localPathFor(audioUrl);
      if (localPath != null) {
        await _player.play(DeviceFileSource(localPath));
      } else {
        // Cache miss: unchanged from today — stream directly, and warm
        // the cache in the background so a retry/replay hits it next time.
        await _player.play(UrlSource(audioUrl));
        unawaited(_audioCacheService.prefetch([audioUrl]));
      }
    } catch (_) {
      // Fail open: never leave the question stuck in the "speaking" phase
      // on a network/playback/cache failure.
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
