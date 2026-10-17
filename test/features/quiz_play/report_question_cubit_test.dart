import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/features/quiz_play/domain/report_question_args.dart';
import 'package:quizoo/features/quiz_play/domain/report_reason.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/report_question_cubit.dart';

class _MockQuizPlayRepository extends Mock implements QuizPlayRepository {}

void main() {
  late _MockQuizPlayRepository repository;

  const args = ReportQuestionArgs(
    questionId: 'q_1',
    questionText: 'Which club has won the most titles?',
    topicLabel: 'Football · Level 12',
    languageCode: 'en',
  );

  setUp(() {
    repository = _MockQuizPlayRepository();
  });

  ReportQuestionCubit buildCubit() =>
      ReportQuestionCubit(repository, args: args);

  blocTest<ReportQuestionCubit, ReportQuestionState>(
    'success path: sending emits Sending then Sent, with the actual '
    'question id, reason code and locale on the wire',
    setUp: () {
      when(
        () => repository.reportQuestion(
          questionId: any(named: 'questionId'),
          reasonCode: any(named: 'reasonCode'),
          locale: any(named: 'locale'),
        ),
      ).thenAnswer((_) async {});
    },
    build: buildCubit,
    act: (cubit) => cubit.submit(ReportReason.wrong),
    expect: () => [isA<ReportQuestionSending>(), isA<ReportQuestionSent>()],
    verify: (_) {
      verify(
        () => repository.reportQuestion(
          questionId: 'q_1',
          reasonCode: 'wrong',
          locale: 'en',
        ),
      ).called(1);
    },
  );

  blocTest<ReportQuestionCubit, ReportQuestionState>(
    'failure path: a failed insert emits Failed carrying the mapped error',
    setUp: () {
      when(
        () => repository.reportQuestion(
          questionId: any(named: 'questionId'),
          reasonCode: any(named: 'reasonCode'),
          locale: any(named: 'locale'),
        ),
      ).thenThrow(const ApiException.network());
    },
    build: buildCubit,
    act: (cubit) => cubit.submit(ReportReason.unclear),
    expect: () => [
      isA<ReportQuestionSending>(),
      isA<ReportQuestionFailed>().having(
        (state) => state.error.kind,
        'error kind',
        ApiErrorKind.network,
      ),
    ],
  );

  test('a second submit while the first is in flight does not '
      'double-insert', () async {
    final completer = Completer<void>();
    when(
      () => repository.reportQuestion(
        questionId: any(named: 'questionId'),
        reasonCode: any(named: 'reasonCode'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) => completer.future);

    final cubit = buildCubit();
    final first = cubit.submit(ReportReason.wrong);
    // The state is already Sending — this one must fall on the floor.
    await cubit.submit(ReportReason.image);
    completer.complete();
    await first;

    verify(
      () => repository.reportQuestion(
        questionId: any(named: 'questionId'),
        reasonCode: any(named: 'reasonCode'),
        locale: any(named: 'locale'),
      ),
    ).called(1);
    expect(cubit.state, isA<ReportQuestionSent>());
  });
}
