/// A small seam over the concrete TTS implementation so `QuizPlayCubit` stays
/// pure Dart and testable without a plugin channel or a network call —
/// `bloc_test`/`fake_async` supply a fake that completes synchronously or on
/// a controlled delay (CLAUDE.md §11, mirroring this Cubit's own
/// `Timer`-not-`Ticker` reasoning).
abstract class TtsService {
  /// Attempts to switch the voice to [languageCode]. [voiceId] is the
  /// ElevenLabs voice configured for this language in the `languages` table
  /// (plan 010) — `null` when none is configured yet. Returns `false` —
  /// never throws — when [voiceId] is null, so the caller can fall back to
  /// silent mode rather than blocking the question screen (spec §4.1).
  Future<bool> setLanguage(String languageCode, {String? voiceId});

  /// Reads [text] aloud. Completion (or cancellation) fires whichever
  /// callback was last registered via [onComplete].
  Future<void> speak(String text);

  /// Stops the current utterance immediately.
  Future<void> stop();

  /// Registers the callback fired when the current utterance finishes or is
  /// cancelled. Registering again replaces the previous callback.
  void onComplete(void Function() callback);

  /// Releases any native resources this service opened. Safe to call even
  /// if nothing was ever spoken. Mirrors `SoundEffectsService.dispose()`.
  Future<void> dispose();
}
