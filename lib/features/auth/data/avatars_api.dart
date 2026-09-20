import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/auth/domain/avatar_option.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// S-25's real endpoint: every active avatar, in the order the picker
/// should list them.
class AvatarsApi {
  AvatarsApi(this._client);

  final SupabaseClient _client;

  Future<List<AvatarOption>> fetchActiveAvatars() async {
    try {
      final rows = await _client
          .from('avatar_options')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      return [
        for (final row in rows)
          AvatarOption(
            id: row['id'] as String,
            emoji: row['emoji'] as String,
            sortOrder: row['sort_order'] as int,
          ),
      ];
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }
}
