import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/mock/mock_catalog.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/catalog/domain/level_map.dart';
import 'package:quizoo/features/catalog/presentation/widgets/level_brief_sheet.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_api.dart';
import 'package:quizoo/features/quiz_play/data/quiz_play_repository.dart';
import 'package:quizoo/l10n/app_localizations.dart';

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

  Future<void> pumpSheet(WidgetTester tester) => tester.pumpApp(
    LevelBriefSheet(
      map: map,
      level: level,
      repository: repository,
      languageCode: 'en',
    ),
  );

  group('LevelBriefSheet', () {
    testWidgets(
      'start_level_attempt out_of_hearts shows the hearts explanation, '
      'not the generic content-error copy',
      (tester) async {
        when(
          () => api.fetchLevelQuestions(
            subcategoryId: any(named: 'subcategoryId'),
            levelNumber: any(named: 'levelNumber'),
            languageCode: any(named: 'languageCode'),
          ),
        ).thenThrow(
          const ApiException(
            'out_of_hearts',
            kind: ApiErrorKind.server,
            code: 'out_of_hearts',
          ),
        );

        await pumpSheet(tester);
        await tester.pump();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(LevelBriefSheet)),
        );

        expect(
          find.text('💔 ${l10n.startBlockedOutOfHeartsTitle}'),
          findsOneWidget,
        );
        expect(find.text(l10n.startBlockedOutOfHeartsBody), findsOneWidget);
        expect(find.text(l10n.contentErrorTitle), findsNothing);
        expect(find.text(l10n.commonRetry), findsOneWidget);
        expect(find.text(l10n.levelBriefStart(12)), findsNothing);
      },
    );

    testWidgets('any other failure keeps the generic content-error copy', (
      tester,
    ) async {
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
      expect(find.text(l10n.startBlockedOutOfHeartsTitle), findsNothing);
    });
  });
}
