import 'package:quizoo/features/achievements/data/achievements_api.dart';
import 'package:quizoo/features/achievements/domain/badge_progress.dart';

/// The only thing that talks to [AchievementsApi].
///
/// Also the fixture `features/profile` reuses for its recent-badges rail —
/// see [fetchAll]'s doc — rather than duplicating badge data in a second
/// mock source (plan 003, Phase D).
class AchievementsRepository {
  AchievementsRepository(this._api);

  final AchievementsApi _api;

  Future<List<BadgeProgress>> fetchAll() => _api.fetchAll();

  Future<BadgeProgress> fetchById(String badgeId) => _api.fetchById(badgeId);
}
