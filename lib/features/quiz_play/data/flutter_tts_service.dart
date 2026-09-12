import 'package:flutter_tts/flutter_tts.dart';
import 'package:quizoo/features/quiz_play/data/tts_service.dart';

/// The real [TtsService], backed by `flutter_tts`.
class FlutterTtsService implements TtsService {
  FlutterTtsService() {
    _tts
      ..setCompletionHandler(() => _onComplete?.call())
      ..setCancelHandler(() => _onComplete?.call())
      ..setErrorHandler((_) => _onComplete?.call());
  }

  final FlutterTts _tts = FlutterTts();
  void Function()? _onComplete;

  @override
  Future<bool> setLanguage(String languageCode) async {
    try {
      final available = await _tts.isLanguageAvailable(languageCode);
      if (available != true) return false;
      await _tts.setLanguage(languageCode);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> speak(String text) => _tts.speak(text);

  @override
  Future<void> stop() => _tts.stop();

  @override
  void onComplete(void Function() callback) => _onComplete = callback;
}
