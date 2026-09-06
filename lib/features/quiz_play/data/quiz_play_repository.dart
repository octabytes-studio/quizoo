import 'package:quizoo/features/quiz_play/data/quiz_play_api.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';

/// The prefetch cache that makes a level playable with no network mid-run.
///
/// S-09 states that the level brief sheet "is also where the level's 20
/// questions finish prefetching", and §01 requires no blocking network once
/// play starts. Both are the same requirement, and this is where it lives:
/// [prepareLevel] fetches and caches, [questionsFor] reads the cache.
///
/// **Why this instance is provided at the app root** rather than scoped to a
/// screen: the sheet that warms the cache (S-09) and the screen that reads it
/// (S-11) are different routes. A repository scoped to either one would be
/// disposed between them, and the prefetch would be a fetch that happened
/// twice. The bible's real design has the same shape — a `QuestionRepository`
/// reading local storage first (§25).
class QuizPlayRepository {
  QuizPlayRepository(this._api);

  final QuizPlayApi _api;

  final Map<String, List<Question>> _prefetched = {};

  /// True once [prepareLevel] has resolved for this level and language.
  bool isPrepared(String levelId, {String languageCode = 'en'}) =>
      _prefetched.containsKey(_key(levelId, languageCode));

  /// Fetches and caches a level's twenty questions.
  ///
  /// Idempotent: calling it for an already-prepared level is free, so
  /// reopening the brief sheet does not re-fetch.
  Future<void> prepareLevel({
    required String levelId,
    required String subcategoryId,
    required int levelNumber,
    String languageCode = 'en',
  }) async {
    final key = _key(levelId, languageCode);
    if (_prefetched.containsKey(key)) return;

    _prefetched[key] = await _api.fetchLevelQuestions(
      subcategoryId: subcategoryId,
      levelNumber: levelNumber,
      languageCode: languageCode,
    );
  }

  /// The prepared questions, fetching them first if the sheet was skipped —
  /// which is what happens when a level is deep-linked rather than entered
  /// through S-09.
  Future<List<Question>> questionsFor({
    required String levelId,
    required String subcategoryId,
    required int levelNumber,
    String languageCode = 'en',
  }) async {
    await prepareLevel(
      levelId: levelId,
      subcategoryId: subcategoryId,
      levelNumber: levelNumber,
      languageCode: languageCode,
    );
    return _prefetched[_key(levelId, languageCode)] ?? const [];
  }

  /// Drops a level's cache so a replay re-deals it. Called when a run ends.
  void forget(String levelId) =>
      _prefetched.removeWhere((key, _) => key.startsWith('$levelId@'));

  static String _key(String levelId, String languageCode) =>
      '$levelId@$languageCode';
}
