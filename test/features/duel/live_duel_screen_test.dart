import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/widgets/answer_option.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_question.dart';
import 'package:quizoo/features/duel/domain/duel_result.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/presentation/bloc/live_duel_bloc.dart';
import 'package:quizoo/features/duel/presentation/widgets/vs_header.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_status_chip.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_audio_button.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/features/duel/presentation/screens/live_duel_screen.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_round_view.dart';
import 'package:quizoo/features/duel/presentation/widgets/match_intro_view.dart';
import 'package:quizoo/l10n/app_localizations.dart';

import '../../support/pump_screen.dart';

class _MockLiveDuelBloc extends MockBloc<LiveDuelEvent, LiveDuelState>
    implements LiveDuelBloc {}

const _me = DuelPlayer(
  id: 'user_me',
  name: 'Waleed',
  avatarEmoji: '🐼',
  elo: 1310,
  league: 'silver',
);
const _opponent = DuelPlayer(
  id: 'user_opp',
  name: 'Danish',
  avatarEmoji: '🐯',
  elo: 1380,
  league: 'gold',
);
const _topic = DuelTopic(
  id: 'sub_football',
  name: 'Football',
  emoji: '⚽',
  plateColor: '#DDF1FF',
  categoryName: 'Sports',
  categoryEmoji: '🏅',
);
const _question = DuelQuestion(
  text: 'Who won the 2022 World Cup?',
  options: ['Argentina', 'France', 'Brazil', 'Croatia'],
);
final _now = DateTime.utc(2026, 9, 27, 12);

LiveDuelIntro _intro({DateTime? startsAt}) => LiveDuelIntro(
  me: _me,
  opponent: _opponent,
  topic: _topic,
  isRanked: true,
  startsAt: startsAt,
  now: _now,
);

LiveDuelRound _round({
  DuelQuestion? question = _question,
  bool opponentOnline = true,
}) => LiveDuelRound(
  me: _me,
  opponent: _opponent,
  topic: _topic,
  isRanked: true,
  roundNumber: 2,
  totalRounds: 5,
  question: question,
  secondsRemaining: 11,
  secondsTotal: 15,
  myScore: 1,
  opponentScore: 0,
  history: const [],
  opponentLocked: true,
  opponentSeconds: 4,
  opponentOnline: opponentOnline,
  opponentReconnectSeconds: opponentOnline ? null : 7,
);

const _result = DuelResult(
  me: _me,
  opponent: _opponent,
  playerRoundsWon: 3,
  opponentRoundsWon: 2,
  playerAverageAnswerSeconds: 3,
  opponentAverageAnswerSeconds: 5,
  eloBefore: 1310,
  eloAfter: 1326,
  rewardCoins: 200,
  duelId: 'duel_1',
  isBot: false,
);

void main() {
  late _MockLiveDuelBloc bloc;

  setUp(() {
    bloc = _MockLiveDuelBloc();
    when(() => bloc.isClosed).thenReturn(false);
  });

  Future<AppLocalizations> pumpWith(
    WidgetTester tester,
    LiveDuelState state, {
    Stream<LiveDuelState>? stream,
  }) async {
    whenListen(
      bloc,
      stream ?? const Stream<LiveDuelState>.empty(),
      initialState: state,
    );
    await tester.pumpScreen(LiveDuelScreen(duelId: 'duel_1', bloc: bloc));
    await tester.pump();
    return AppLocalizations.of(tester.element(find.byType(LiveDuelScreen)));
  }

  group('LiveDuelScreen', () {
    testWidgets("the joiner's side (p2) shows their own avatar left and the "
        "challenger's right — never swapped", (tester) async {
      const guestJoiner = DuelPlayer(
        id: 'guest_joiner',
        name: null,
        avatarEmoji: '🐼',
        elo: 1169,
        isGuest: true,
        guestTag: '5447',
      );
      const challenger = DuelPlayer(
        id: 'creator',
        name: 'OctaBytes',
        avatarEmoji: '🦋',
        elo: 1231,
        league: 'silver',
      );
      final round = LiveDuelRound(
        me: guestJoiner,
        opponent: challenger,
        topic: _topic,
        isRanked: true,
        roundNumber: 1,
        totalRounds: 10,
        question: _question,
        secondsRemaining: 12,
        secondsTotal: 15,
        myScore: 0,
        opponentScore: 0,
        history: const [],
      );
      await pumpWith(tester, round);

      final header = tester.widget<VsHeader>(find.byType(VsHeader));
      expect(header.leftAvatarEmoji, '🐼');
      expect(header.rightAvatarEmoji, '🦋');
      expect(header.rightName, 'OctaBytes');
      final chips = tester
          .widgetList<DuelStatusChip>(find.byType(DuelStatusChip))
          .map((chip) => chip.emoji)
          .toList();
      expect(chips, ['🐼', '🦋']);
    });

    testWidgets('after the reveal each pick carries its own player\'s avatar', (
      tester,
    ) async {
      await pumpWith(
        tester,
        _round().copyWith(
          myLocked: true,
          myChoice: 1,
          mySeconds: 3,
          isRevealed: true,
          correctIndex: 0,
          opponentChoice: 0,
        ),
      );
      // Options 0 (opponent's pick) and 1 (mine) each show one marker,
      // plus both avatars in the header and the status chips.
      expect(find.text('🐯'), findsNWidgets(3));
      expect(find.text('🐼'), findsNWidgets(3));
    });

    testWidgets('the speaker toggle shows 🔊 and dispatches the toggle', (
      tester,
    ) async {
      await pumpWith(tester, _round().copyWith(isAudioOn: true));
      expect(find.text('🔊'), findsOneWidget);
      await tester.tap(find.byType(DuelAudioButton));
      await tester.pump();
      verify(() => bloc.add(const LiveDuelAudioToggled())).called(1);
    });

    testWidgets('the last seconds wash the arena red', (tester) async {
      await pumpWith(tester, _round().copyWith(secondsRemaining: 4));
      await tester.pump(const Duration(milliseconds: 400));
      final washed = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(LiveDuelScreen),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final gradient =
          (washed.decoration! as BoxDecoration).gradient! as LinearGradient;
      expect(gradient.colors, const ArenaColors().danger.colors);
    });

    testWidgets('connecting shows a spinner', (tester) async {
      await pumpWith(tester, const LiveDuelConnecting());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(MatchIntroView), findsNothing);
    });

    testWidgets('the intro names both players and waits for the opponent', (
      tester,
    ) async {
      final l10n = await pumpWith(tester, _intro());
      expect(find.byType(MatchIntroView), findsOneWidget);
      expect(find.text('Waleed'), findsOneWidget);
      expect(find.text('Danish'), findsOneWidget);
      expect(find.text('Football'), findsOneWidget);
      expect(find.text(l10n.duelIntroRanked), findsOneWidget);
      expect(find.text(l10n.duelWaitingFor('Danish')), findsOneWidget);
    });

    testWidgets('the intro counts down to round 1 once it is scheduled', (
      tester,
    ) async {
      final l10n = await pumpWith(
        tester,
        _intro(startsAt: _now.add(const Duration(milliseconds: 2400))),
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.text(l10n.duelWaitingFor('Danish')), findsNothing);
    });

    testWidgets('a round shows the question; tapping an option answers it', (
      tester,
    ) async {
      final l10n = await pumpWith(tester, _round());
      expect(find.byType(DuelRoundView), findsOneWidget);
      expect(find.text(_question.text), findsOneWidget);
      expect(find.byType(AnswerOption), findsNWidgets(4));
      expect(find.text(l10n.duelRoundLabel(2, 5)), findsOneWidget);
      expect(find.text(l10n.duelAnsweredIn(4)), findsOneWidget);
      expect(find.text(l10n.duelThinking), findsOneWidget);

      await tester.tap(find.text('France'));
      await tester.pump();
      verify(() => bloc.add(const LiveDuelAnswerSelected(1))).called(1);
    });

    testWidgets('a round whose question is still loading says "Get ready…"', (
      tester,
    ) async {
      final l10n = await pumpWith(tester, _round(question: null));
      expect(find.text(l10n.duelGetReady), findsOneWidget);
      expect(find.byType(AnswerOption), findsNothing);
    });

    testWidgets('an opponent who dropped off shows the reconnecting chip', (
      tester,
    ) async {
      final l10n = await pumpWith(tester, _round(opponentOnline: false));
      expect(
        find.text(l10n.duelOpponentReconnecting('Danish', 7)),
        findsOneWidget,
      );
    });

    testWidgets('✕ asks first, and "Leave" confirms the quit', (tester) async {
      final l10n = await pumpWith(tester, _round());
      await tester.tap(find.bySemanticsLabel(l10n.duelQuitLabel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(l10n.duelQuitTitle), findsOneWidget);
      verifyNever(() => bloc.add(const LiveDuelQuitConfirmed()));

      await tester.tap(find.text(l10n.duelQuitConfirm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      verify(() => bloc.add(const LiveDuelQuitConfirmed())).called(1);
    });

    testWidgets('ended replaces the screen with the result', (tester) async {
      await pumpWith(
        tester,
        _round(),
        stream: Stream.value(const LiveDuelEnded(_result)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('pushed:/duel/duel_1/result'), findsOneWidget);
    });

    testWidgets('abandoned tells the player the opponent never showed and '
        'leaves', (tester) async {
      final l10n = await pumpWith(
        tester,
        _intro(),
        stream: Stream.value(const LiveDuelAbandoned('no_show')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(l10n.duelNoticeOpponentNoShow), findsOneWidget);
      expect(find.text('pushed:/home'), findsOneWidget);
    });

    testWidgets('failed shows the error view with a way back', (tester) async {
      final l10n = await pumpWith(
        tester,
        const LiveDuelFailed(
          ApiException('not_a_participant', code: 'not_a_participant'),
        ),
      );
      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text(l10n.commonBack), findsOneWidget);
      expect(find.text('not_a_participant'), findsOneWidget);
    });
  });
}
