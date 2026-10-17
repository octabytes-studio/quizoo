import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/breakpoints.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/theme/app_theme.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/report_question_sheet.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/features/quiz_play/domain/report_question_args.dart';
import 'package:quizoo/features/quiz_play/presentation/bloc/report_question_cubit.dart';
import 'package:quizoo/features/quiz_play/presentation/screens/report_question_screen.dart';
import 'package:quizoo/l10n/app_localizations.dart';

class _MockQuizPlayRepository extends Mock implements QuizPlayRepository {}

const _args = ReportQuestionArgs(
  questionId: 'q_42',
  questionText: 'Which club has won the most titles?',
  topicLabel: 'Football · Level 12',
  languageCode: 'en',
);

/// Pumps a host app whose second route is the real report screen, so
/// "success closes the sheet" is observable: the host's button reappears.
/// With [withPayload] false the route mimics a stale deep link that arrives
/// without a [ReportQuestionArgs].
Future<void> pumpReporter(
  WidgetTester tester,
  QuizPlayRepository repository, {
  bool withPayload = true,
}) async {
  tester.view
    ..physicalSize = const Size(
      Breakpoints.designWidth,
      Breakpoints.designHeight,
    )
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => context.push('/report'),
                child: const Text('open reporter'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) =>
            ReportQuestionScreen(args: withPayload ? _args : null),
      ),
    ],
  );

  await tester.pumpWidget(
    RepositoryProvider<QuizPlayRepository>.value(
      value: repository,
      child: ScreenUtilInit(
        designSize: const Size(
          Breakpoints.designWidth,
          Breakpoints.designHeight,
        ),
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.light,
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.text('open reporter'));
  await tester.pumpAndSettle();
}

void main() {
  late _MockQuizPlayRepository repository;

  setUp(() {
    repository = _MockQuizPlayRepository();
  });

  void stubReport({Object? error}) {
    when(
      () => repository.reportQuestion(
        questionId: any(named: 'questionId'),
        reasonCode: any(named: 'reasonCode'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {
      if (error != null) throw error;
    });
  }

  testWidgets('selecting a reason enables Submit', (tester) async {
    stubReport();
    await pumpReporter(tester, repository);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ReportQuestionScreen)),
    );
    final submit = find.widgetWithText(ChunkyButton, l10n.reportQuestionSubmit);
    expect(tester.widget<ChunkyButton>(submit).onPressed, isNull);

    await tester.tap(find.text(l10n.reportReasonWrong));
    await tester.pump();

    expect(tester.widget<ChunkyButton>(submit).onPressed, isNotNull);
  });

  testWidgets('a successful report confirms and closes the sheet', (
    tester,
  ) async {
    stubReport();
    await pumpReporter(tester, repository);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ReportQuestionScreen)),
    );
    await tester.tap(find.text(l10n.reportReasonTranslation));
    await tester.pump();
    await tester.tap(
      find.widgetWithText(ChunkyButton, l10n.reportQuestionSubmit),
    );
    await tester.pumpAndSettle();

    verify(
      () => repository.reportQuestion(
        questionId: 'q_42',
        reasonCode: 'translation',
        locale: 'en',
      ),
    ).called(1);
    expect(find.text(l10n.reportQuestionSent), findsOneWidget);
    // Closed: the host's own button is visible again.
    expect(find.text('open reporter'), findsOneWidget);
  });

  testWidgets('a failed report shows the error and keeps the sheet open', (
    tester,
  ) async {
    stubReport(error: const ApiException.network());
    await pumpReporter(tester, repository);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ReportQuestionScreen)),
    );
    await tester.tap(find.text(l10n.reportReasonOffensive));
    await tester.pump();
    await tester.tap(
      find.widgetWithText(ChunkyButton, l10n.reportQuestionSubmit),
    );
    await tester.pumpAndSettle();

    verify(
      () => repository.reportQuestion(
        questionId: 'q_42',
        reasonCode: 'offensive',
        locale: 'en',
      ),
    ).called(1);
    expect(
      tester
          .element(find.byType(ReportQuestionSheet))
          .read<ReportQuestionCubit>()
          .state,
      isA<ReportQuestionFailed>(),
    );
    // The sheet's route stays on top here (a plain opaque MaterialPage in
    // this host, vs the real app's transparent sheet page), so the snackbar
    // renders in the host Scaffold beneath it — and `find` skips offstage
    // subtrees by default.
    expect(
      find.text(l10n.reportQuestionError, skipOffstage: false),
      findsOneWidget,
    );
    // Still open, with the reason still selected for a one-tap retry.
    expect(find.text(l10n.reportQuestionTitle), findsOneWidget);
    final submit = find.widgetWithText(ChunkyButton, l10n.reportQuestionSubmit);
    expect(tester.widget<ChunkyButton>(submit).onPressed, isNotNull);
  });

  testWidgets('a route with no payload shows the unavailable state, never '
      'a fixture question (plan 025)', (tester) async {
    await pumpReporter(tester, repository, withPayload: false);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ReportQuestionScreen)),
    );
    expect(find.text(l10n.reportQuestionUnavailableBody), findsOneWidget);
    expect(find.textContaining('Which club'), findsNothing);
  });
}
