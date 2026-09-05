import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/mock/mock_api.dart';
import 'package:quizoo/core/network/api_exception.dart';

/// A feature's `*_api.dart` written exactly the way plans 002–004 must write
/// theirs, so the convention is exercised rather than only described.
class _ExampleApi extends MockApi {
  _ExampleApi({super.failureRate, super.minLatency, super.maxLatency});

  int calls = 0;

  Future<List<String>> fetchItems() =>
      respond(() => ['first', 'second', 'call ${++calls}']);
}

void main() {
  group('MockApi', () {
    test('returns canned data after a simulated round trip', () async {
      final api = _ExampleApi(failureRate: 0);

      final items = await api.fetchItems();

      expect(items, contains('first'));
      expect(api.calls, 1);
    });

    test('never fails when the failure rate is zero', () async {
      final api = _ExampleApi(
        failureRate: 0,
        minLatency: Duration.zero,
        maxLatency: Duration.zero,
      );

      for (var i = 0; i < 50; i++) {
        await api.fetchItems();
      }

      expect(api.calls, 50);
    });

    test('always fails when the failure rate is one', () async {
      final api = _ExampleApi(
        failureRate: 1,
        minLatency: Duration.zero,
        maxLatency: Duration.zero,
      );

      await expectLater(api.fetchItems(), throwsA(isA<ApiException>()));
    });

    test('failNextRequest throws exactly once, then recovers', () async {
      final api = _ExampleApi(
        failureRate: 0,
        minLatency: Duration.zero,
        maxLatency: Duration.zero,
      )..failNextRequest = true;

      await expectLater(
        api.fetchItems(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.isOffline,
            'isOffline',
            isTrue,
          ),
        ),
      );

      // The one deterministic failure a failure-path bloc_test needs.
      expect(api.failNextRequest, isFalse);
      await expectLater(api.fetchItems(), completes);
    });

    test('the simulated latency stays inside its bounds', () async {
      final api = _ExampleApi(
        failureRate: 0,
        minLatency: const Duration(milliseconds: 20),
        maxLatency: const Duration(milliseconds: 40),
      );

      final stopwatch = Stopwatch()..start();
      await api.fetchItems();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(20));
    });
  });

  group('ApiException', () {
    test('the network constructor is the offline case', () {
      const error = ApiException.network();

      expect(error.kind, ApiErrorKind.network);
      expect(error.isOffline, isTrue);
      expect(error.code, 'ERR_NETWORK');
    });

    test('other kinds are not offline', () {
      const error = ApiException(
        'Not found',
        kind: ApiErrorKind.notFound,
        statusCode: 404,
        code: 'ERR_CONTENT_404',
      );

      expect(error.isOffline, isFalse);
      expect(error.toString(), contains('ERR_CONTENT_404'));
    });
  });
}
