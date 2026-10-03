import 'package:quizoo/core/network/api_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The client's only line to the `sync-pro-status` Edge Function (plan 023).
///
/// The client asks, never tells (Assumption 10): the function re-reads the
/// customer's real state from RevenueCat's REST API itself and returns the
/// public `profiles.is_pro` flag. A failure here is never fatal — the
/// RevenueCat webhook is the backstop — so callers fire it and move on.
class ProStatusApi {
  ProStatusApi(this._client);

  final SupabaseClient _client;

  static const _functionName = 'sync-pro-status';

  /// Asks the server to re-check this account's Pro status. Returns the
  /// server's answer; throws only if the call itself failed.
  Future<bool> sync() async {
    try {
      final response = await _client.functions.invoke(_functionName);
      if (response.status >= 400) {
        throw ApiException(
          'sync-pro-status failed with ${response.status}',
          kind: ApiErrorKind.server,
          statusCode: response.status,
        );
      }
      final data = response.data;
      return data is Map && data['isPro'] == true;
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }
}
