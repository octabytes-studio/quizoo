import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';

void main() {
  final start = DateTime.utc(2026, 9, 27, 12);

  late DateTime local;
  late ServerClock clock;

  setUp(() {
    local = start;
    clock = ServerClock(localNow: () => local);
  });

  /// One RPC round trip starting at [sentAt] and lasting [roundTrip], whose
  /// server stamp is [serverNow].
  void sample({
    required DateTime sentAt,
    required Duration roundTrip,
    required DateTime serverNow,
  }) =>
      clock.sync(serverNow, sentAt: sentAt, receivedAt: sentAt.add(roundTrip));

  group('ServerClock', () {
    test('starts with no offset: now() is the local clock', () {
      expect(clock.offset, Duration.zero);
      expect(clock.now(), start);
      expect(clock.localNow(), start);
    });

    test('derives the offset from a sample', () {
      // Zero round trip: the server stamp maps straight onto sentAt.
      sample(
        sentAt: start,
        roundTrip: Duration.zero,
        serverNow: start.add(const Duration(seconds: 5)),
      );

      expect(clock.offset, const Duration(seconds: 5));
      expect(clock.now(), start.add(const Duration(seconds: 5)));

      local = start.add(const Duration(seconds: 10));
      expect(clock.now(), start.add(const Duration(seconds: 15)));
    });

    test('adds half the round trip (the server stamped mid-flight)', () {
      sample(
        sentAt: start,
        roundTrip: const Duration(milliseconds: 400),
        serverNow: start.add(const Duration(seconds: 10)),
      );

      // Midpoint is start + 200 ms, so the server is 9.8 s ahead.
      expect(clock.offset, const Duration(milliseconds: 9800));
    });

    test('a server behind the device yields a negative offset', () {
      sample(
        sentAt: start,
        roundTrip: const Duration(milliseconds: 100),
        serverNow: start.subtract(const Duration(seconds: 3)),
      );

      expect(clock.offset, const Duration(milliseconds: -3050));
      expect(clock.now(), start.subtract(const Duration(milliseconds: 3050)));
    });

    group('min-RTT smoothing', () {
      test('a slower later sample within 60 s does not replace a faster '
          'one', () {
        sample(
          sentAt: start,
          roundTrip: const Duration(milliseconds: 100),
          serverNow: start.add(const Duration(milliseconds: 2050)),
        );
        expect(clock.offset, const Duration(seconds: 2));

        final later = start.add(const Duration(seconds: 30));
        sample(
          sentAt: later,
          roundTrip: const Duration(milliseconds: 900),
          serverNow: later.add(const Duration(seconds: 7)),
        );

        expect(clock.offset, const Duration(seconds: 2));
      });

      test('a faster later sample replaces the current one', () {
        sample(
          sentAt: start,
          roundTrip: const Duration(milliseconds: 600),
          serverNow: start.add(const Duration(milliseconds: 2300)),
        );
        expect(clock.offset, const Duration(seconds: 2));

        final later = start.add(const Duration(seconds: 10));
        sample(
          sentAt: later,
          roundTrip: const Duration(milliseconds: 40),
          serverNow: later.add(const Duration(milliseconds: 1520)),
        );

        expect(clock.offset, const Duration(milliseconds: 1500));
      });

      test('an equally fast later sample replaces the current one', () {
        sample(
          sentAt: start,
          roundTrip: const Duration(milliseconds: 100),
          serverNow: start.add(const Duration(milliseconds: 1050)),
        );

        final later = start.add(const Duration(seconds: 20));
        sample(
          sentAt: later,
          roundTrip: const Duration(milliseconds: 100),
          serverNow: later.add(const Duration(milliseconds: 1250)),
        );

        expect(clock.offset, const Duration(milliseconds: 1200));
      });

      test('a sample exactly 60 s old still wins over a slower one', () {
        sample(
          sentAt: start,
          roundTrip: Duration.zero,
          serverNow: start.add(const Duration(seconds: 2)),
        );

        // Received exactly 60 s after the best sample was taken.
        final later = start.add(const Duration(seconds: 59, milliseconds: 500));
        sample(
          sentAt: later,
          roundTrip: const Duration(milliseconds: 500),
          serverNow: later.add(const Duration(seconds: 9)),
        );

        expect(clock.offset, const Duration(seconds: 2));
      });

      test('any sample replaces one older than 60 s, even a slower one', () {
        sample(
          sentAt: start,
          roundTrip: const Duration(milliseconds: 50),
          serverNow: start.add(const Duration(milliseconds: 2025)),
        );
        expect(clock.offset, const Duration(seconds: 2));

        final later = start.add(const Duration(seconds: 61));
        sample(
          sentAt: later,
          roundTrip: const Duration(seconds: 2),
          serverNow: later.add(const Duration(seconds: 5)),
        );

        expect(clock.offset, const Duration(seconds: 4));
      });

      test('the replacement then becomes the sample to beat', () {
        sample(
          sentAt: start,
          roundTrip: const Duration(milliseconds: 50),
          serverNow: start.add(const Duration(milliseconds: 2025)),
        );

        final stale = start.add(const Duration(seconds: 61));
        sample(
          sentAt: stale,
          roundTrip: const Duration(milliseconds: 800),
          serverNow: stale.add(const Duration(milliseconds: 3400)),
        );
        expect(clock.offset, const Duration(seconds: 3));

        // Slower than the 800 ms replacement, within its 60 s: ignored.
        final next = stale.add(const Duration(seconds: 5));
        sample(
          sentAt: next,
          roundTrip: const Duration(milliseconds: 900),
          serverNow: next.add(const Duration(seconds: 8)),
        );
        expect(clock.offset, const Duration(seconds: 3));
      });
    });

    test('ignores a sample whose round trip is negative', () {
      clock.sync(
        start.add(const Duration(seconds: 30)),
        sentAt: start.add(const Duration(seconds: 1)),
        receivedAt: start,
      );

      expect(clock.offset, Duration.zero);
    });

    group('until', () {
      test('counts down to a future server instant', () {
        sample(
          sentAt: start,
          roundTrip: Duration.zero,
          serverNow: start.add(const Duration(seconds: 5)),
        );

        // Server now = start + 5 s; the instant is 10 s later.
        expect(
          clock.until(start.add(const Duration(seconds: 15))),
          const Duration(seconds: 10),
        );

        local = start.add(const Duration(seconds: 4));
        expect(
          clock.until(start.add(const Duration(seconds: 15))),
          const Duration(seconds: 6),
        );
      });

      test('clamps at zero once the instant has passed', () {
        sample(
          sentAt: start,
          roundTrip: Duration.zero,
          serverNow: start.add(const Duration(seconds: 5)),
        );

        expect(
          clock.until(start.add(const Duration(seconds: 5))),
          Duration.zero,
        );
        expect(clock.until(start), Duration.zero);
        expect(
          clock.until(start.subtract(const Duration(hours: 1))),
          Duration.zero,
        );
      });
    });

    group('timed', () {
      test('syncs from the response\'s serverNow, stamping both sides of the '
          'call, and passes the response through', () async {
        final response = <String, dynamic>{
          'serverNow': '2026-09-27T12:00:05.100000+00:00',
          'status': 'active',
        };

        final result = await clock.timed(() async {
          local = local.add(const Duration(milliseconds: 200));
          return response;
        });

        expect(result, same(response));
        // Midpoint start + 100 ms; server stamp start + 5.1 s.
        expect(clock.offset, const Duration(seconds: 5));
      });

      test(
        'leaves the offset alone when the response has no serverNow',
        () async {
          final response = <String, dynamic>{'accepted': true};

          final result = await clock.timed(() async => response);

          expect(result, same(response));
          expect(clock.offset, Duration.zero);
        },
      );

      test(
        'leaves the offset alone when serverNow is not a timestamp',
        () async {
          await clock.timed(() async => <String, dynamic>{'serverNow': 'soon'});
          await clock.timed(() async => <String, dynamic>{'serverNow': 12345});

          expect(clock.offset, Duration.zero);
        },
      );

      test(
        'rethrows the call\'s ApiException unchanged, offset intact',
        () async {
          const error = ApiException('boom', code: 'too_early');

          await expectLater(
            clock.timed(() async => throw error),
            throwsA(same(error)),
          );
          expect(clock.offset, Duration.zero);
        },
      );
    });
  });
}
