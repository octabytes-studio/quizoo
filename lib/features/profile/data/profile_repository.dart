import 'package:quizoo/features/profile/data/profile_api.dart';
import 'package:quizoo/features/profile/domain/profile_summary.dart';
import 'package:quizoo/features/profile/domain/stats_summary.dart';

/// The only thing that talks to [ProfileApi].
class ProfileRepository {
  ProfileRepository(this._api);

  final ProfileApi _api;

  Future<ProfileSummary> fetchSummary() => _api.fetchSummary();

  Future<StatsSummary> fetchStats() => _api.fetchStats();
}
