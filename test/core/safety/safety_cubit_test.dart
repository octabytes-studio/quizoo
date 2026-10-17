import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/safety/domain/player_report_reason.dart';
import 'package:quizoo/core/safety/safety_cubit.dart';
import 'package:quizoo/core/safety/safety_repository.dart';

class _MockSafetyRepository extends Mock implements SafetyRepository {}

void main() {
  late _MockSafetyRepository repository;

  setUp(() {
    repository = _MockSafetyRepository();
  });

  SafetyCubit buildCubit({bool isBlocked = false}) =>
      SafetyCubit(repository, playerId: 'user_a', isBlocked: isBlocked);

  blocTest<SafetyCubit, SafetyState>(
    'success path: blocking emits Busy then Done(blocked) and flips isBlocked',
    setUp: () {
      when(() => repository.block('user_a')).thenAnswer((_) async {});
    },
    build: buildCubit,
    act: (cubit) => cubit.toggleBlock(),
    expect: () => [
      isA<SafetyBusy>(),
      isA<SafetyDone>().having(
        (state) => state.outcome,
        'outcome',
        SafetyOutcome.blocked,
      ),
    ],
    verify: (cubit) {
      verify(() => repository.block('user_a')).called(1);
      expect(cubit.isBlocked, isTrue);
    },
  );

  blocTest<SafetyCubit, SafetyState>(
    'success path: unblocking a blocked player emits Done(unblocked) and '
    'clears isBlocked',
    setUp: () {
      when(() => repository.unblock('user_a')).thenAnswer((_) async {});
    },
    build: () => buildCubit(isBlocked: true),
    act: (cubit) => cubit.toggleBlock(),
    expect: () => [
      isA<SafetyBusy>(),
      isA<SafetyDone>().having(
        (state) => state.outcome,
        'outcome',
        SafetyOutcome.unblocked,
      ),
    ],
    verify: (cubit) {
      verify(() => repository.unblock('user_a')).called(1);
      expect(cubit.isBlocked, isFalse);
    },
  );

  blocTest<SafetyCubit, SafetyState>(
    'success path: reporting emits Done(reported) with the reason code',
    setUp: () {
      when(
        () => repository.reportPlayer(
          playerId: any(named: 'playerId'),
          reason: any(named: 'reason'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async {});
    },
    build: buildCubit,
    act: (cubit) => cubit.report(PlayerReportReason.harassment),
    expect: () => [
      isA<SafetyBusy>(),
      isA<SafetyDone>().having(
        (state) => state.outcome,
        'outcome',
        SafetyOutcome.reported,
      ),
    ],
    verify: (_) {
      verify(
        () => repository.reportPlayer(
          playerId: 'user_a',
          reason: 'harassment',
          note: null,
        ),
      ).called(1);
    },
  );

  blocTest<SafetyCubit, SafetyState>(
    'failure path: a failed block emits Failed and leaves isBlocked alone',
    setUp: () {
      when(
        () => repository.block('user_a'),
      ).thenThrow(const ApiException.network());
    },
    build: buildCubit,
    act: (cubit) => cubit.toggleBlock(),
    expect: () => [
      isA<SafetyBusy>(),
      isA<SafetyFailed>().having(
        (state) => state.error.kind,
        'error kind',
        ApiErrorKind.network,
      ),
    ],
    verify: (cubit) => expect(cubit.isBlocked, isFalse),
  );
}
