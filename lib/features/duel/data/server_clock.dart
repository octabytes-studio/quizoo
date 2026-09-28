/// The one shared estimate of the server's clock (plan 017, "Server time is
/// the only time").
///
/// Every duel RPC returns `serverNow`; repositories feed it here with the
/// local times either side of the call, and every countdown on the arena,
/// matchmaking and live-duel screens reads [now]/[until] so that two devices
/// agree on when a challenge expires or a round starts regardless of their
/// own clock skew. Provided once at the app root, so stacked duel screens
/// share one offset.
///
/// Pure Dart. [localNow] is injectable so `fake_async` tests can drive it
/// (`ServerClock(localNow: () => start.add(async.elapsed))`).
class ServerClock {
  ServerClock({DateTime Function()? localNow})
    : _localNow = localNow ?? DateTime.now;

  final DateTime Function() _localNow;

  /// How long a sample stays authoritative before any newer one — even a
  /// slower one — may replace it.
  static const Duration sampleLifetime = Duration(seconds: 60);

  Duration _offset = Duration.zero;
  _Sample? _best;

  /// The current server-minus-local offset.
  Duration get offset => _offset;

  /// The local clock this estimate is built on — what callers stamp
  /// `sentAt`/`receivedAt` with, so tests can fake both sides consistently.
  DateTime localNow() => _localNow();

  /// Folds in one `serverNow` sample.
  ///
  /// The server stamped [serverNow] roughly half-way through the round trip
  /// between [sentAt] and [receivedAt]. The sample with the smallest round
  /// trip seen in the last [sampleLifetime] wins, so one slow response does
  /// not jerk every countdown on screen.
  void sync(
    DateTime serverNow, {
    required DateTime sentAt,
    required DateTime receivedAt,
  }) {
    final roundTrip = receivedAt.difference(sentAt);
    if (roundTrip.isNegative) return;
    final localMidpoint = sentAt.add(roundTrip ~/ 2);
    final sampleOffset = serverNow.difference(localMidpoint);

    final best = _best;
    final isStale =
        best == null || receivedAt.difference(best.takenAt) > sampleLifetime;
    if (isStale || roundTrip <= best.roundTrip) {
      _best = _Sample(
        offset: sampleOffset,
        roundTrip: roundTrip,
        takenAt: receivedAt,
      );
      _offset = sampleOffset;
    }
  }

  /// Runs [call] (an RPC returning a JSON object) and folds the `serverNow`
  /// it carries into the offset, stamping the local times either side.
  Future<Map<String, dynamic>> timed(
    Future<Map<String, dynamic>> Function() call,
  ) async {
    final sentAt = localNow();
    final response = await call();
    final receivedAt = localNow();
    final serverNow = response['serverNow'];
    if (serverNow is String) {
      final parsed = DateTime.tryParse(serverNow);
      if (parsed != null) sync(parsed, sentAt: sentAt, receivedAt: receivedAt);
    }
    return response;
  }

  /// The best estimate of the server's current time.
  DateTime now() => _localNow().add(_offset);

  /// How long until [serverInstant], clamped at zero once it has passed.
  Duration until(DateTime serverInstant) {
    final remaining = serverInstant.difference(now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

class _Sample {
  const _Sample({
    required this.offset,
    required this.roundTrip,
    required this.takenAt,
  });

  final Duration offset;
  final Duration roundTrip;
  final DateTime takenAt;
}
