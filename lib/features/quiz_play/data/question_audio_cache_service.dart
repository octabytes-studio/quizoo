/// A small seam over the on-disk narration-clip cache, mirroring
/// `TtsService`/`SoundEffectsService`'s own interface-file convention so
/// `QuizPlayCubit` and `StoredAudioTtsService` stay testable with a fake
/// rather than a real file-system-backed implementation.
abstract class QuestionAudioCacheService {
  /// Best-effort: downloads each of [urls] to local disk if not already
  /// cached. Never throws — a failed download for one URL doesn't stop the
  /// rest, and a caller never needs to await this to stay correct (only to
  /// stay fast).
  Future<void> prefetch(List<String> urls);

  /// The local file path already cached for [url], or `null` if it isn't
  /// cached yet. Never triggers a download — this is a fast, local-only
  /// lookup so a playback call site can decide whether to use the cached
  /// file or fall back to streaming from the network.
  Future<String?> localPathFor(String url);
}
