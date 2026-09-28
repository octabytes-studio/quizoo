import 'package:quizoo/core/network/api_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The duel APIs' shared RPC plumbing: every call maps its failure through
/// [ApiException.fromSupabase], so a `raise exception 'challenge_cooldown'`
/// reaches the Bloc as `ApiException.code == 'challenge_cooldown'`.
extension DuelRpc on SupabaseClient {
  /// An RPC returning a JSON object.
  Future<Map<String, dynamic>> rpcObject(
    String function, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      final response = await rpc<dynamic>(function, params: params);
      if (response is Map) return Map<String, dynamic>.from(response);
      throw ApiException(
        '$function returned ${response.runtimeType}, expected an object',
        kind: ApiErrorKind.parsing,
      );
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// An RPC returning a JSON array.
  Future<List<dynamic>> rpcList(
    String function, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      final response = await rpc<dynamic>(function, params: params);
      if (response == null) return const [];
      if (response is List) return response;
      throw ApiException(
        '$function returned ${response.runtimeType}, expected an array',
        kind: ApiErrorKind.parsing,
      );
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// An RPC returning nothing.
  Future<void> rpcVoid(String function, [Map<String, dynamic>? params]) async {
    try {
      await rpc<dynamic>(function, params: params);
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }
}

/// Runs a JSON → domain [build], turning any decode failure into a parsing
/// [ApiException] so a malformed payload surfaces as the feature's ordinary
/// error state rather than an uncaught `TypeError`.
T decodeDuelJson<T>(T Function() build) {
  try {
    return build();
  } on ApiException {
    rethrow;
  } on Object catch (error) {
    throw ApiException(
      'Could not decode duel payload: $error',
      kind: ApiErrorKind.parsing,
      code: 'ERR_PARSE',
    );
  }
}
