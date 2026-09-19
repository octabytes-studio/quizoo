import 'package:quizoo/features/quiz_play/data/quiz_play_api.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';

/// The prefetch cache that makes a level playable with no network mid-run.
///
/// S-09 states that the level brief sheet "is also where the level's 20
/// questions finish prefetching", and §01 requires no blocking network once
/// play starts. Both are the same requirement, and this is where it lives:
/// [prepareLevel] fetches and caches, [questionsFor] reads the cache.
///
/// Caches a [PreparedLevel] (questions **and** the server-issued attempt id
/// `submit_level_attempt` needs back) rather than a bare question list — the
/// one place plan 005 changes this class's shape rather than just its
/// `*_api.dart` body, since a real backend also hands back an id a mock
/// single-player run never needed.
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

  final Map<String, PreparedLevel> _prefetched = {};

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
    return _prefetched[_key(levelId, languageCode)]?.questions ?? const [];
  }

  /// The attempt id `submit_level_attempt` needs back, for the same prepared
  /// level [questionsFor] just resolved.
  String? attemptIdFor(String levelId, {String languageCode = 'en'}) =>
      _prefetched[_key(levelId, languageCode)]?.attemptId;

  /// The server-authoritative clock for this level, from the same
  /// `start_level_attempt` response [questionsFor] resolved — replaces
  /// `MockCatalog.secondsFor(levelNumber)`.
  int? secondsPerQuestionFor(String levelId, {String languageCode = 'en'}) =>
      _prefetched[_key(levelId, languageCode)]?.secondsPerQuestion;

  /// Whether this level is a boss level, from the same server response —
  /// replaces `levelNumber % 5 == 0`.
  bool? isBossFor(String levelId, {String languageCode = 'en'}) =>
      _prefetched[_key(levelId, languageCode)]?.isBoss;

  /// Drops a level's cache so a replay re-deals it. Called when a run ends.
  void forget(String levelId) =>
      _prefetched.removeWhere((key, _) => key.startsWith('$levelId@'));

  /// Today's real ten daily-challenge questions — never cached, since there
  /// is exactly one attempt per day per player and nothing to prefetch
  /// ahead of.
  Future<DailyQuestionSession> questionsForDaily({
    required String languageCode,
  }) => _api.fetchDailyQuestions(languageCode: languageCode);

  static String _key(String levelId, String languageCode) =>
      '$levelId@$languageCode';
}
