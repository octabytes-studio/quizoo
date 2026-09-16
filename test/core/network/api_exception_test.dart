import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ApiException.fromSupabase', () {
    test('a raised exception surfaces its message as code, not the shared '
        'P0001 SQLSTATE every raise exception comes back with', () {
      const error = PostgrestException(message: 'out_of_hearts', code: 'P0001');

      final result = ApiException.fromSupabase(error);

      expect(result.code, 'out_of_hearts');
      expect(result.kind, ApiErrorKind.server);
    });

    test('a real Postgres error code is kept as-is', () {
      const error = PostgrestException(
        message: 'duplicate key value violates unique constraint',
        code: '23505',
      );

      final result = ApiException.fromSupabase(error);

      expect(result.code, '23505');
    });

    test('PGRST116 still maps to the content-not-found shape', () {
      const error = PostgrestException(message: 'no rows', code: 'PGRST116');

      final result = ApiException.fromSupabase(error);

      expect(result.code, 'ERR_CONTENT_404');
      expect(result.kind, ApiErrorKind.notFound);
    });
  });
}
