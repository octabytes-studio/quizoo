import 'package:quizoo/core/models/difficulty_tier.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the ladder's two config tables — `difficulty_tiers` and the single
/// `boss_level_interval` row of `app_settings` — over Postgrest.
class LadderConfigApi {
  LadderConfigApi(this._client);

  final SupabaseClient _client;

  Future<List<DifficultyTier>> fetchTiers({
    required int defaultQuestionsPerLevel,
  }) async {
    try {
      final rows = await _client
          .from('difficulty_tiers')
          .select()
          .order('sort_order');
      return [
        for (final row in rows)
          DifficultyTier(
            code: row['code'] as String,
            label: row['label'] as String,
            secondsPerQuestion: row['seconds_per_question'] as int,
            levelStart: row['level_start'] as int,
            levelEnd: row['level_end'] as int,
            questionsPerLevel:
                (row['override_questions_per_level'] as int?) ??
                defaultQuestionsPerLevel,
          ),
      ];
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// Every Nth level is a boss level. Falls back to 10 (the seeded default)
  /// if the row is ever missing.
  Future<int> fetchBossLevelInterval() async {
    try {
      final row = await _client
          .from('app_settings')
          .select('value')
          .eq('key', 'boss_level_interval')
          .maybeSingle();
      final value = row?['value'];
      return value is num ? value.toInt() : 10;
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// The global fallback questions-per-level, used by any tier with no
  /// `override_questions_per_level`. Falls back to 20 (the seeded default)
  /// if the row is ever missing.
  Future<int> fetchDefaultQuestionsPerLevel() async {
    try {
      final row = await _client
          .from('app_settings')
          .select('value')
          .eq('key', 'questions_per_level')
          .maybeSingle();
      final value = row?['value'];
      return value is num ? value.toInt() : 20;
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }
}
