import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/presentation/bloc/matchmaking_cubit.dart';
import 'package:quizoo/features/duel/presentation/screens/matchmaking_screen.dart';
import 'package:quizoo/features/duel/presentation/widgets/matchmaking_bot_offer.dart';
import 'package:quizoo/features/duel/presentation/widgets/vs_header.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/pump_screen.dart';

class _MockMatchmakingCubit extends MockCubit<MatchmakingState>
    implements MatchmakingCubit {}

void main() {
  const topic = DuelTopic(
    id: 'sub_football',
    name: 'Football',
    emoji: '⚽',
    plateColor: '#FF8A24',
    categoryName: 'Sports',
    categoryEmoji: '🏅',
  );
  const me = DuelPlayer(
    id: 'user_me',
    name: 'Waleed',
    avatarEmoji: '🐼',
    elo: 1240,
    league: 'silver',
  );
  const bot = DuelPlayer(
    id: 'bot_fox',
    name: 'Fox',
    avatarEmoji: '🦊',
    elo: 1230,
    isBot: true,
  );

  MatchmakingSearching searching({bool botAvailable = false}) =>
      MatchmakingSearching(
        me: me,
        topic: topic,
        elapsedSeconds: botAvailable ? 31 : 12,
        bandMin: 1140,
        bandMax: 1340,
        secondsToNextWiden: 3,
        botAvailable: botAvailable,
      );

  late _MockMatchmakingCubit cubit;

  setUp(() {
    cubit = _MockMatchmakingCubit();
    when(() => cubit.start()).thenAnswer((_) async {});
    when(() => cubit.cancel()).thenAnswer((_) async {});
    when(() => cubit.playBot()).thenAnswer((_) async {});
  });

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first));

  /// Pumps the screen on [initial], then replays [later] through the
  /// Cubit's stream. Bounded pumps only — the spinner never settles.
  Future<void> pumpWith(
    WidgetTester tester,
    MatchmakingState initial, {
    List<MatchmakingState> later = const [],
  }) async {
    whenListen(
      cubit,
      Stream<MatchmakingState>.fromIterable(later),
      initialState: initial,
    );
    await tester.pumpScreen(MatchmakingScreen(topic: topic, cubit: cubit));
    await tester.pump();
  }

  group('MatchmakingScreen', () {
    testWidgets('Joining: an animating spinner under the title', (
      tester,
    ) async {
      await pumpWith(tester, const MatchmakingJoining());

      final l10n = l10nOf(tester);
      expect(find.text(l10n.duelMatchmakingTitle), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(VsHeader), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Searching: the real me, the topic chip, the band and the '
        'status line — and no bot offer yet', (tester) async {
      await pumpWith(tester, searching());

      final l10n = l10nOf(tester);
      expect(find.text('⚽ Football'), findsOneWidget);
      expect(find.text('🐼'), findsOneWidget);
      expect(
        find.text(l10n.duelLeagueEloCaption('🥈 Silver', '1,240')),
        findsOneWidget,
      );
      expect(find.text(l10n.duelSearchingBand(1140, 1340)), findsOneWidget);
      expect(find.text(l10n.duelSearchingStatus(12, 3)), findsOneWidget);
      expect(find.byType(MatchmakingBotOffer), findsNothing);
      // The plan-004 "Cancel — play a bot instead" button is gone (plan 017).
      expect(find.text('Cancel — play a bot instead'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Searching with the bot offer: labelled BOT, and both '
        'buttons reach the Cubit', (tester) async {
      await pumpWith(tester, searching(botAvailable: true));
      await tester.pump(const Duration(milliseconds: 400));

      final l10n = l10nOf(tester);
      expect(find.byType(MatchmakingBotOffer), findsOneWidget);
      expect(find.text(l10n.duelBotOfferTitle('⚽ Football')), findsOneWidget);
      expect(find.text(l10n.duelBotBadge), findsOneWidget);

      await tester.tap(find.text(l10n.duelBotOfferPlay));
      await tester.pump();
      verify(() => cubit.playBot()).called(1);

      await tester.tap(find.text(l10n.duelKeepSearching));
      await tester.pump();
      verify(() => cubit.keepSearching()).called(1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Found: replaces the route with the live duel', (tester) async {
      await pumpWith(
        tester,
        searching(),
        later: [const MatchmakingFound('duel_1')],
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('pushed:${AppRoutes.duelPlayPath('duel_1')}'),
        findsOneWidget,
      );
    });

    testWidgets('BotReady: replaces the route with the labelled bot duel', (
      tester,
    ) async {
      await pumpWith(
        tester,
        searching(botAvailable: true),
        later: [const MatchmakingBotReady(me: me, opponent: bot, topic: topic)],
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('pushed:${AppRoutes.duelBot}'), findsOneWidget);
    });

    testWidgets('Failed: an error view whose Retry restarts the search', (
      tester,
    ) async {
      await pumpWith(
        tester,
        const MatchmakingFailed(
          ApiException(
            'topic_unavailable',
            kind: ApiErrorKind.server,
            code: 'topic_unavailable',
          ),
        ),
      );

      final l10n = l10nOf(tester);
      expect(find.text(l10n.contentErrorTitle), findsOneWidget);
      expect(find.text(l10n.duelNoticeTopicUnavailable), findsOneWidget);
      expect(find.text('topic_unavailable'), findsOneWidget);
      expect(find.text(l10n.commonBack), findsOneWidget);

      await tester.tap(find.text(l10n.commonRetry));
      await tester.pump();
      verify(() => cubit.start()).called(1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the ✕ leaves the queue', (tester) async {
      await pumpWith(tester, searching());

      final l10n = l10nOf(tester);
      await tester.tap(find.bySemanticsLabel(l10n.duelLeaveQueueLabel));
      await tester.pump();

      verify(() => cubit.cancel()).called(1);
    });
  });
}
