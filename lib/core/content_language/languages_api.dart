import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/content_language/language_option.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Every language flipped live, in `sort_order` — shared by onboarding's
/// S-03, S-25's sheet, Edit Profile and Home's language pills (moved to
/// `core/` in plan 021).
class LanguagesApi {
  LanguagesApi(this._client);

  final SupabaseClient _client;

  Future<List<LanguageOption>> fetchActiveLanguages() async {
    try {
      final rows = await _client
          .from('languages')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      return [
        for (final row in rows)
          LanguageOption(
            code: row['code'] as String,
            name: row['name'] as String,
            nativeName: row['native_name'] as String,
            isRtl: row['is_rtl'] as bool,
            sortOrder: row['sort_order'] as int,
          ),
      ];
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }
}
