import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:quizoo/core/network/api_exception.dart';

/// The base every feature's mock `*_api.dart` extends while there is no
/// backend.
///
/// ## The convention plans 002–004 follow, verbatim
///
/// ```dart
/// // features/home/data/home_api.dart
/// class HomeApi extends MockApi {
///   Future<HomeDto> fetchHome() => respond(() => const HomeDto(...));
/// }
///
/// // features/home/data/home_repository.dart
/// class HomeRepository {
///   HomeRepository(this._api);
///   final HomeApi _api;
///
///   Future<HomeContent> fetchHome() async {
///     final dto = await _api.fetchHome();
///     return dto.toDomain(); // DTO -> domain model, as a real one would
///   }
/// }
///
/// // features/home/presentation/bloc/home_cubit.dart
/// class HomeCubit extends Cubit<HomeState> {
///   HomeCubit(this._repository) : super(const HomeInitial());
///   final HomeRepository _repository;
///
///   Future<void> load() async {
///     emit(const HomeLoading());
///     try {
///       emit(HomeLoaded(await _repository.fetchHome()));
///     } on ApiException catch (error) {
///       emit(HomeError(error));
///     }
///   }
/// }
/// ```
///
/// Two properties matter, and both are the reason this is a base class rather
/// than a copied `Future.delayed` in twenty files:
///
/// 1. **The signatures are the ones a real client would have.** When a backend
///    lands, only the body of each `*_api.dart` changes — repository, domain
///    and presentation are untouched.
/// 2. **It can fail on purpose.** A mock that always succeeds leaves the
///    failure-path `bloc_test` every Cubit owes (CLAUDE.md §11) with nothing
///    real to assert, and leaves `ErrorStateView` unexercised outside a
///    hand-built state. [failureRate] gives the demo build occasional honest
///    failures; [failNextRequest] gives a test a deterministic one.
///
/// This is a deliberate, temporary deviation from CLAUDE.md §9's literal "Dio
/// calls only" wording — flagged here, and in plan 001's Assumption 1, rather
/// than resolved silently.
abstract class MockApi {
  MockApi({
    this.minLatency = const Duration(milliseconds: 300),
    this.maxLatency = const Duration(milliseconds: 600),
    double? failureRate,
    Random? random,
  }) : failureRate =
           failureRate ??
           failureRateOverride ??
           (kDebugMode ? defaultFailureRate : 0),
       _random = random ?? Random();

  /// Roughly one request in twenty-five fails in a debug build — often enough
  /// that the error states get seen during review, rare enough that the app is
  /// still usable.
  static const double defaultFailureRate = 0.04;

  /// Pins the failure rate of every mock API constructed after it is set.
  ///
  /// Widget tests run in debug mode, so without this every screen that loads
  /// content would fail one run in twenty-five at random — a whole suite made
  /// intermittently red by a fixture. A test sets this to `0` for
  /// deterministic success or `1` to exercise an error state, in `setUp`,
  /// which reaches APIs a screen constructs internally where constructor
  /// injection cannot.
  ///
  /// Null (the default) leaves the debug-build behaviour above untouched, so
  /// nothing about the demo build changes.
  static double? failureRateOverride;

  /// The floor of the simulated round trip.
  final Duration minLatency;

  /// The ceiling of the simulated round trip.
  final Duration maxLatency;

  /// 0…1. Zero never fails, which is the default outside debug builds and the
  /// right setting for a success-path test.
  final double failureRate;

  final Random _random;

  /// Forces the next [respond] call to throw, whatever [failureRate] says.
  ///
  /// This is how a failure-path test gets a deterministic failure without
  /// seeding a random or looping until it gets lucky.
  bool failNextRequest = false;

  /// The failure thrown when one is simulated. Override for a feature that
  /// wants a specific kind.
  ApiException get simulatedFailure => const ApiException.network();

  /// Waits out a plausible round trip, then returns [build]'s value — or
  /// throws [simulatedFailure].
  ///
  /// [build] is called *after* the delay, so a fixture that reads the clock
  /// sees the time the response "arrived".
  ///
  /// [latency] overrides the usual [minLatency]…[maxLatency] spread for one
  /// call. It exists for reads that a real client would serve from local
  /// storage rather than the network — Home's cached first paint, which §01
  /// budgets at effectively zero so Splash → Home stays under 1.2 s.
  @protected
  Future<T> respond<T>(T Function() build, {Duration? latency}) async {
    await Future<void>.delayed(latency ?? _latency);

    if (failNextRequest) {
      failNextRequest = false;
      throw simulatedFailure;
    }
    if (failureRate > 0 && _random.nextDouble() < failureRate) {
      throw simulatedFailure;
    }

    return build();
  }

  Duration get _latency {
    final spread = maxLatency.inMicroseconds - minLatency.inMicroseconds;
    if (spread <= 0) return minLatency;
    return Duration(
      microseconds: minLatency.inMicroseconds + _random.nextInt(spread),
    );
  }
}
