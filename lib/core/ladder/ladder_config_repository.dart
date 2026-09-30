import 'dart:math';

import 'package:quizoo/core/ladder/ladder_config_api.dart';
import 'package:quizoo/core/models/difficulty_tier.dart';

/// The app-wide ladder config: `difficulty_tiers` plus the boss-level
/// interval, fetched once and held for the process lifetime.
///
/// Replaces `MockCatalog.bandFor`/`secondsFor` and every hardcoded
/// `% 5 == 0` boss check in `features/catalog` — a fetched, cached table
/// instead of a value mirrored between Dart and SQL (plan 007, Research
/// findings). Not a Cubit: this is static-for-the-session reference data,
/// not UI state, the same shape as `QuizPlayRepository._prefetched`.
class LadderConfigRepository {
  LadderConfigRepository(this._api);

  final LadderConfigApi _api;

  List<DifficultyTier> _tiers = const [];
  int _bossLevelInterval = 10;
  Future<void>? _loading;

  /// Fetches once; every later call awaits the same in-flight or completed
  /// fetch rather than re-hitting the network.
  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final defaultQuestionsPerLevel = await _api
          .fetchDefaultQuestionsPerLevel();
      _tiers = await _api.fetchTiers(
        defaultQuestionsPerLevel: defaultQuestionsPerLevel,
      );
      _bossLevelInterval = await _api.fetchBossLevelInterval();
    } catch (_) {
      // Don't cache a failed fetch forever — the next caller (a fresh
      // catalog screen open, most likely) gets to try again instead of
      // being permanently stuck on whatever failed once at boot.
      _loading = null;
      rethrow;
    }
  }

  /// The tier covering [level]. Falls back to the widest-reaching tier if
  /// [ensureLoaded] hasn't resolved yet or a level falls outside every tier's
  /// range, so a caller mid-boot never crashes on a null lookup.
  DifficultyTier tierFor(int level) {
    if (_tiers.isEmpty) return _fallbackTier;
    return _tiers.firstWhere(
      (tier) => level >= tier.levelStart && level <= tier.levelEnd,
      orElse: () => _tiers.last,
    );
  }

  int secondsFor(int level) => tierFor(level).secondsPerQuestion;

  int questionsFor(int level) => tierFor(level).questionsPerLevel;

  bool isBoss(int level) =>
      _bossLevelInterval > 0 && level % _bossLevelInterval == 0;

  /// The top of the ladder — the highest `levelEnd` across every tier.
  /// Falls back to [fallbackTotalLevels] before [ensureLoaded] resolves.
  int get totalLevels => _tiers.isEmpty
      ? fallbackTotalLevels
      : _tiers.map((tier) => tier.levelEnd).reduce(max);

  /// Mirrors the seeded 30-level ladder. Used before [ensureLoaded] resolves
  /// and by display sites that don't have this repository (Home tiles,
  /// Profile, Leaderboard).
  static const int fallbackTotalLevels = 30;

  static const _fallbackTier = DifficultyTier(
    code: 'easy',
    label: 'Easy',
    secondsPerQuestion: 20,
    levelStart: 1,
    levelEnd: 30,
    questionsPerLevel: 10,
  );
}
