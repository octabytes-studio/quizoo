import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/catalog/domain/level_map.dart';
import 'package:quizoo/features/catalog/presentation/widgets/level_brief_sheet.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_api.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/fake_purchases.dart';
import '../../support/pump_app.dart';

class _MockQuizPlayApi extends Mock implements QuizPlayApi {}

void main() {
  final football = MockCatalog.subcategoryById(MockCatalog.footballId);
  final level = MockCatalog.levelsFor(
    football,
  ).firstWhere((l) => l.number == 12);
  final map = LevelMap(
    category: MockCatalog.categoryById(MockCatalog.sportsId),
    subcategory: football,
    levels: MockCatalog.levelsFor(football),
    rank: 412,
  );

  late _MockQuizPlayApi api;
  late QuizPlayRepository repository;

  setUp(() {
    api = _MockQuizPlayApi();
    repository = QuizPlayRepository(api);
  });

  Future<void> pumpSheet(WidgetTester tester, {bool isPro = false}) {
    // `pumpApp` has no app-root providers, and the brief sheet reads the
    // entitlement for its lives/power-up counts (plan 023).
    final cubit = isPro ? proSubscriptionCubit() : freeSubscriptionCubit();
    addTearDown(cubit.close);
    return tester.pumpApp(
      BlocProvider<SubscriptionCubit>.value(
        value: cubit,
        child: LevelBriefSheet(
          map: map,
          level: level,
          repository: repository,
          languageCode: 'en',
        ),
      ),
    );
  }

  group('LevelBriefSheet', () {
    testWidgets(
      'a failed prefetch explains itself instead of a bare Retry button',
      (tester) async {
        when(
          () => api.fetchLevelQuestions(
            subcategoryId: any(named: 'subcategoryId'),
            levelNumber: any(named: 'levelNumber'),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenThrow(const ApiException.network());

        await pumpSheet(tester);
        await tester.pump();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(LevelBriefSheet)),
        );

        expect(find.text(l10n.contentErrorTitle), findsOneWidget);
        expect(find.text(l10n.contentErrorBody), findsOneWidget);
        expect(find.text(l10n.commonRetry), findsOneWidget);
        expect(find.text(l10n.levelBriefStart(12)), findsNothing);
      },
    );

    testWidgets('a successful prefetch enables Start Level', (tester) async {
      when(
        () => api.fetchLevelQuestions(
          subcategoryId: any(named: 'subcategoryId'),
          levelNumber: any(named: 'levelNumber'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer(
        (_) async => const PreparedLevel(
          attemptId: 'attempt_test',
          questions: [],
          secondsPerQuestion: 20,
          isBoss: false,
        ),
      );

      await pumpSheet(tester);
      await tester.pump();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(LevelBriefSheet)),
      );

      expect(find.text(l10n.levelBriefStart(12)), findsOneWidget);
      expect(find.text(l10n.contentErrorTitle), findsNothing);

      // Level 12 sits in Medium (plan 020: 11-20), which serves 15
      // questions — the sheet must show the level's own count, not a
      // hardcoded 20.
      expect(level.questionCount, 15);
      expect(find.text('15'), findsOneWidget);
    });
  });
}
