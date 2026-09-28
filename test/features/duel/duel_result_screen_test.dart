import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_result.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/presentation/bloc/bot_rematch_cubit.dart';
import 'package:quizoo/features/duel/presentation/bloc/duel_rematch_cubit.dart';
import 'package:quizoo/features/duel/presentation/screens/duel_result_screen.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_topic_picker_sheet.dart';

import '../../support/pump_screen.dart';

class _MockDuelRematchCubit extends MockCubit<DuelRematchState>
    implements DuelRematchCubit {}

class _MockBotRematchCubit extends MockCubit<BotRematchState>
    implements BotRematchCubit {}

const _me = DuelPlayer(
  id: 'user_me',
  name: 'Ayesha',
  avatarEmoji: '🐼',
  elo: 1412,
);

const _opponent = DuelPlayer(
  id: 'user_danish',
  name: 'Danish',
  avatarEmoji: '🐯',
  elo: 1380,
);

const _bot = DuelPlayer(
  id: 'bot_1',
  name: 'Fennec',
  avatarEmoji: '🦊',
  elo: 1400,
  isBot: true,
);

const _topic = DuelTopic(
  id: 'sub_football',
  name: 'Football',
  emoji: '⚽',
  plateColor: '#12C79B',
  categoryName: 'Sports',
  categoryEmoji: '🏅',
);

DuelResult _liveResult({
  int mine = 3,
  int theirs = 2,
  bool isRanked = true,
  int xpEarned = 0,
  DuelEndReason endReason = DuelEndReason.completed,
  DuelTopic? topic = _topic,
}) => DuelResult(
  me: _me,
  opponent: _opponent,
  playerRoundsWon: mine,
  opponentRoundsWon: theirs,
  playerAverageAnswerSeconds: 3.1,
  opponentAverageAnswerSeconds: 4.4,
  eloBefore: 1412,
  eloAfter: isRanked ? 1428 : 1412,
  rewardCoins: 200,
  duelId: 'duel_1',
  isBot: false,
  topic: topic,
  isRanked: isRanked,
  xpEarned: xpEarned,
  endReason: endReason,
);

DuelResult _botResult({DuelTopic? topic = _topic}) => DuelResult(
  me: _me,
  opponent: _bot,
  playerRoundsWon: 2,
  opponentRoundsWon: 3,
  playerAverageAnswerSeconds: 5.2,
  opponentAverageAnswerSeconds: 4.8,
  eloBefore: 1412,
  eloAfter: 1406,
  rewardCoins: 40,
  topic: topic,
);

/// Hosts the result screen one push above a launcher, so `context.canPop()`
/// is true — the way the live duel is stacked over the arena (plan 017, A14).
class _Launcher extends StatelessWidget {
  const _Launcher({required this.screen});

  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => screen)),
        child: const Text('launcher'),
      ),
    );
  }
}

void main() {
  late _MockDuelRematchCubit rematch;
  late _MockBotRematchCubit botRematch;

  setUpAll(() => registerFallbackValue(_topic));

  setUp(() {
    rematch = _MockDuelRematchCubit();
    botRematch = _MockBotRematchCubit();
    when(() => rematch.state).thenReturn(const RematchIdle());
    when(() => rematch.request()).thenAnswer((_) async {});
    when(() => rematch.accept()).thenAnswer((_) async {});
    when(() => botRematch.state).thenReturn(const BotRematchIdle());
    when(() => botRematch.rematch(any())).thenAnswer((_) async {});
  });

  Future<void> pumpLive(WidgetTester tester, DuelResult result) async {
    await tester.pumpScreen(
      DuelResultScreen(result: result, rematchCubit: rematch),
    );
    await tester.pump();
  }

  /// Dismisses the topic picker if one opened — the arena phase's real sheet
  /// replaces today's stub (which completes with null straight away), and
  /// either way the result is "dismissed".
  Future<void> dismissPickerIfShown(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final sheet = find.byType(DuelTopicPickerSheet);
    if (sheet.evaluate().isEmpty) return;
    Navigator.of(tester.element(sheet)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> pumpBot(WidgetTester tester, DuelResult result) async {
    await tester.pumpScreen(
      DuelResultScreen(result: result, botRematchCubit: botRematch),
    );
    await tester.pump();
  }

  group('DuelResultScreen headline and captions', () {
    testWidgets('victory shows both real players and the score', (
      tester,
    ) async {
      await pumpLive(tester, _liveResult());

      expect(find.text('🏆 Victory!'), findsOneWidget);
      expect(find.text('🐼'), findsOneWidget);
      expect(find.text('🐯'), findsOneWidget);
      expect(find.text('Ayesha'), findsOneWidget);
      expect(find.text('Danish'), findsOneWidget);
      expect(find.text('3 – 2'), findsOneWidget);
      expect(find.text('BOT'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('defeat', (tester) async {
      await pumpLive(tester, _liveResult(mine: 1, theirs: 3));

      expect(find.text('Good game'), findsOneWidget);
      expect(find.text('🏆 Victory!'), findsNothing);
    });

    testWidgets('draw', (tester) async {
      await pumpLive(tester, _liveResult(mine: 2, theirs: 2));

      expect(find.text("It's a draw"), findsOneWidget);
      expect(find.text('Good game'), findsNothing);
    });

    testWidgets('an unranked duel says ELO did not move', (tester) async {
      await pumpLive(tester, _liveResult(isRanked: false));

      expect(find.text('Unranked — ELO unchanged'), findsOneWidget);
    });

    testWidgets('a ranked duel has no unranked note', (tester) async {
      await pumpLive(tester, _liveResult());

      expect(find.text('Unranked — ELO unchanged'), findsNothing);
    });

    testWidgets("the opponent's forfeit is captioned", (tester) async {
      await pumpLive(
        tester,
        _liveResult(endReason: DuelEndReason.opponentForfeited),
      );

      expect(
        find.text('Danish left — the remaining questions count for you'),
        findsOneWidget,
      );
    });

    testWidgets("the player's own forfeit is captioned", (tester) async {
      await pumpLive(
        tester,
        _liveResult(mine: 0, theirs: 3, endReason: DuelEndReason.youForfeited),
      );

      expect(find.text('You left the duel'), findsOneWidget);
    });

    testWidgets('earned XP gets its own row', (tester) async {
      await pumpLive(tester, _liveResult(xpEarned: 150));

      expect(find.text('XP'), findsOneWidget);
      expect(find.text('+150'), findsOneWidget);
    });

    testWidgets('no XP row when none was earned', (tester) async {
      await pumpLive(tester, _liveResult());

      expect(find.text('XP'), findsNothing);
    });

    testWidgets('renders in dark theme without throwing', (tester) async {
      await tester.pumpScreen(
        DuelResultScreen(
          result: _liveResult(isRanked: false, xpEarned: 80),
          rematchCubit: rematch,
        ),
        brightness: Brightness.dark,
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('DuelResultScreen live rematch', () {
    testWidgets('idle: Rematch asks for one', (tester) async {
      await pumpLive(tester, _liveResult());

      await tester.tap(find.text('Rematch'));
      await tester.pump();

      verify(() => rematch.request()).called(1);
    });

    testWidgets('waiting: disabled "Waiting for {name}…"', (tester) async {
      when(() => rematch.state).thenReturn(const RematchWaiting());
      await pumpLive(tester, _liveResult());

      expect(find.text('Waiting for Danish…'), findsOneWidget);
      expect(find.text('Rematch'), findsNothing);

      await tester.tap(find.text('Waiting for Danish…'));
      await tester.pump();
      verifyNever(() => rematch.request());
    });

    testWidgets('offered: the opponent asks and Accept starts it', (
      tester,
    ) async {
      when(() => rematch.state).thenReturn(const RematchOffered());
      await pumpLive(tester, _liveResult());

      expect(find.text('Danish wants a rematch!'), findsOneWidget);
      await tester.tap(find.text('Accept rematch'));
      await tester.pump();

      verify(() => rematch.accept()).called(1);
    });

    testWidgets('unavailable: disabled "{name} has left"', (tester) async {
      when(() => rematch.state).thenReturn(const RematchUnavailable());
      await pumpLive(tester, _liveResult());

      expect(find.text('Danish has left'), findsOneWidget);

      await tester.tap(find.text('Danish has left'));
      await tester.pump();
      verifyNever(() => rematch.request());
      verifyNever(() => rematch.accept());
    });

    testWidgets('starting: a spinner, then the new live duel replaces this', (
      tester,
    ) async {
      whenListen(
        rematch,
        Stream<DuelRematchState>.fromIterable(const [
          RematchStarting('duel_2'),
        ]),
        initialState: const RematchIdle(),
      );
      await tester.pumpScreen(
        DuelResultScreen(result: _liveResult(), rematchCubit: rematch),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('pushed:/duel/duel_2'), findsOneWidget);
    });

    testWidgets('starting renders a spinner in place of the button', (
      tester,
    ) async {
      when(() => rematch.state).thenReturn(const RematchStarting('duel_2'));
      await pumpLive(tester, _liveResult());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Rematch'), findsNothing);
    });
  });

  group('DuelResultScreen bot rematch', () {
    testWidgets('labels the bot and deals a new one in the same topic', (
      tester,
    ) async {
      await pumpBot(tester, _botResult());

      expect(find.text('BOT'), findsOneWidget);
      await tester.tap(find.text('Rematch'));
      await tester.pump();

      verify(() => botRematch.rematch(_topic)).called(1);
    });

    testWidgets('a dealt bot replaces this with the bot duel', (tester) async {
      whenListen(
        botRematch,
        Stream<BotRematchState>.fromIterable([
          const BotRematchLoading(),
          BotRematchFound(
            me: _me.copyWith(elo: 1406),
            opponent: _bot,
            topic: _topic,
          ),
        ]),
        initialState: const BotRematchIdle(),
      );
      await pumpBot(tester, _botResult());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('pushed:/duel/bot'), findsOneWidget);
    });

    testWidgets('a failed deal shows a snackbar and keeps Rematch', (
      tester,
    ) async {
      whenListen(
        botRematch,
        Stream<BotRematchState>.fromIterable(const [
          BotRematchLoading(),
          BotRematchFailed(ApiException.network()),
        ]),
        initialState: const BotRematchIdle(),
      );
      await pumpBot(tester, _botResult());
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Something went wrong — please try again'),
        findsOneWidget,
      );
      expect(find.text('Rematch'), findsOneWidget);
    });

    testWidgets('without a topic, a dismissed picker deals nothing', (
      tester,
    ) async {
      await pumpBot(tester, _botResult(topic: null));

      await tester.tap(find.text('Rematch'));
      await dismissPickerIfShown(tester);

      verifyNever(() => botRematch.rematch(any()));
      expect(find.text('Rematch'), findsOneWidget);
    });
  });

  group('DuelResultScreen navigation', () {
    testWidgets('Find a new opponent matchmakes in the same topic', (
      tester,
    ) async {
      await pumpLive(tester, _liveResult());

      await tester.tap(find.text('Find a new opponent'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('pushed:/duel/matchmaking'), findsOneWidget);
    });

    testWidgets('Find a new opponent without a topic stays when the picker '
        'is dismissed', (tester) async {
      await pumpLive(tester, _liveResult(topic: null));

      await tester.tap(find.text('Find a new opponent'));
      await dismissPickerIfShown(tester);

      expect(find.text('pushed:/duel/matchmaking'), findsNothing);
      expect(find.text('Find a new opponent'), findsOneWidget);
    });

    testWidgets('✕ pops back to whatever is underneath', (tester) async {
      await tester.pumpScreen(
        _Launcher(
          screen: DuelResultScreen(
            result: _liveResult(),
            rematchCubit: rematch,
          ),
        ),
      );
      await tester.tap(find.text('launcher'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Find a new opponent'), findsOneWidget);

      await tester.tap(find.text('✕'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Find a new opponent'), findsNothing);
      expect(find.text('launcher'), findsOneWidget);
    });

    testWidgets('a newly earned badge is celebrated after the first frame', (
      tester,
    ) async {
      await tester.pumpScreen(
        DuelResultScreen(
          result: _liveResult().copyWith(newlyEarnedBadgeIds: ['duelist']),
          rematchCubit: rematch,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('pushed:/badge-unlocked/duelist'), findsOneWidget);
    });

    testWidgets('the design-review fallback renders a labelled bot result', (
      tester,
    ) async {
      await tester.pumpScreen(const DuelResultScreen());
      await tester.pump();

      expect(find.text('🏆 Victory!'), findsOneWidget);
      expect(find.text('BOT'), findsOneWidget);
      expect(find.text('Rematch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('✕ with nothing to pop goes home', (tester) async {
      await pumpLive(tester, _liveResult());

      await tester.tap(find.text('✕'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('pushed:/home'), findsOneWidget);
    });
  });
}
