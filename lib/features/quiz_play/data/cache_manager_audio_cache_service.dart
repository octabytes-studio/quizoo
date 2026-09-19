import 'dart:async';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:quizoo/features/quiz_play/data/question_audio_cache_service.dart';

/// `flutter_cache_manager`'s own recommended pattern for a
/// purpose-specific cache: a private singleton `CacheManager` subclass, so
/// every [CacheManagerAudioCacheService] instance — however many are
/// constructed across screen rebuilds — reads and writes the same physical
/// on-disk store and sqflite index.
class _QuestionAudioCacheManager extends CacheManager {
  static const key = 'questionAudioCache';
  static final _QuestionAudioCacheManager instance =
      _QuestionAudioCacheManager._();
  _QuestionAudioCacheManager._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 500,
        ),
      );
}

/// The real [QuestionAudioCacheService], backed by `flutter_cache_manager`.
class CacheManagerAudioCacheService implements QuestionAudioCacheService {
  CacheManagerAudioCacheService({BaseCacheManager? cacheManager})
    : _cacheManager = cacheManager ?? _QuestionAudioCacheManager.instance;

  final BaseCacheManager _cacheManager;

  /// Guards against queuing the same URL twice while its first download is
  /// still in flight — the window can ask for the same URL again on every
  /// question transition before the first request has landed.
  final Set<String> _inFlight = {};

  @override
  Future<void> prefetch(List<String> urls) async {
    for (final url in urls) {
      if (_inFlight.contains(url)) continue;
      final cached = await _cacheManager.getFileFromCache(url);
      if (cached != null) continue;
      _inFlight.add(url);
      unawaited(_downloadInBackground(url));
    }
  }

  /// Downloads [url] to disk, swallowing any failure — a failed download
  /// simply leaves the URL uncached for next time (Research finding 4: the
  /// fail-open contract).
  Future<void> _downloadInBackground(String url) async {
    try {
      await _cacheManager.downloadFile(url);
    } catch (_) {
      // Best-effort: nothing to do here, playback falls back to streaming.
    } finally {
      _inFlight.remove(url);
    }
  }

  @override
  Future<String?> localPathFor(String url) async {
    final info = await _cacheManager.getFileFromCache(url);
    return info?.file.path;
  }
}
