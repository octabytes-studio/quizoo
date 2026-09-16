import 'package:quizoo/core/network/api_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads and writes the signed-in user's `profiles.locale` — the backend leg
/// of the content-language pick. A guest with no session simply has nothing
/// to attach it to yet, so both methods no-op/return null rather than throw.
class ContentLanguageApi {
  ContentLanguageApi(this._client);

  final SupabaseClient _client;

  Future<void> updateProfileLocale(String code) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from('profiles').update({'locale': code}).eq('id', userId);
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  Future<String?> fetchProfileLocale() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final row = await _client
          .from('profiles')
          .select('locale')
          .eq('id', userId)
          .maybeSingle();
      return row?['locale'] as String?;
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// The ElevenLabs voice configured for [code] in the `languages` table,
  /// or `null` when none has been set yet (plan 010).
  Future<String?> fetchVoiceId(String code) async {
    try {
      final row = await _client
          .from('languages')
          .select('voice_id')
          .eq('code', code)
          .maybeSingle();
      return row?['voice_id'] as String?;
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }
}
