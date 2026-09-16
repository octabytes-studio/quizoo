import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:quizoo/features/quiz_play/data/elevenlabs_tts_api.dart';
import 'package:quizoo/features/quiz_play/data/tts_service.dart';

/// The real [TtsService], backed by ElevenLabs' REST API + `audioplayers`
/// for local playback of the returned audio.
class ElevenLabsTtsService implements TtsService {
  ElevenLabsTtsService([ElevenLabsTtsApi? api])
    : _api = api ?? ElevenLabsTtsApi() {
    _player.onPlayerComplete.listen((_) => _onComplete?.call());
  }

  final ElevenLabsTtsApi _api;
  final AudioPlayer _player = AudioPlayer(playerId: 'tts_elevenlabs');

  String? _languageCode;
  String? _voiceId;
  CancelToken? _cancelToken;
  void Function()? _onComplete;

  @override
  Future<bool> setLanguage(String languageCode, {String? voiceId}) async {
    _languageCode = languageCode;
    _voiceId = voiceId;
    return voiceId != null;
  }

  @override
  Future<void> speak(String text) async {
    final voiceId = _voiceId;
    if (voiceId == null) {
      _onComplete?.call();
      return;
    }
    _cancelToken = CancelToken();
    try {
      final bytes = await _api.convertTextToSpeech(
        text: text,
        voiceId: voiceId,
        languageCode: _languageCode,
        cancelToken: _cancelToken,
      );
      await _player.play(BytesSource(Uint8List.fromList(bytes)));
    } catch (_) {
      // Fail open: never leave the question stuck in the "speaking" phase
      // on a network/API failure — matches setLanguage's existing
      // never-throws contract, extended to speak().
      _onComplete?.call();
    }
  }

  @override
  Future<void> stop() async {
    _cancelToken?.cancel();
    await _player.stop();
  }

  @override
  void onComplete(void Function() callback) => _onComplete = callback;

  @override
  Future<void> dispose() => _player.dispose();
}
