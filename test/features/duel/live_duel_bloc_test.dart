import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_audio.dart';
import 'package:quizoo/features/duel/data/live_duel_repository.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/domain/duel_config.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_question.dart';
import 'package:quizoo/features/duel/domain/duel_result.dart';
import 'package:quizoo/features/duel/domain/duel_room_event.dart';
import 'package:quizoo/features/duel/domain/duel_round.dart';
import 'package:quizoo/features/duel/domain/duel_side.dart';
import 'package:quizoo/features/duel/domain/duel_side_result.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/domain/live_duel_outcome.dart';
import 'package:quizoo/features/duel/domain/live_duel_round_state.dart';
import 'package:quizoo/features/duel/domain/live_duel_snapshot.dart';
import 'package:quizoo/features/duel/presentation/bloc/live_duel_bloc.dart';

class _MockLiveDuelRepository extends Mock implements LiveDuelRepository {}

class _MockDuelAudio extends Mock implements DuelAudio {}

const _duelId = 'duel_1';

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
  league: 'silver',
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

/// Every test's server (and local) clock starts here.
final _start = DateTime.utc(2026, 9, 27, 12);

/// Round 1 of the scripted duel starts 3 s in (the server's intro).
final _round1StartsAt = _start.add(const Duration(seconds: 3));
final _round1Deadline = _round1StartsAt.add(
  const Duration(seconds: 15, milliseconds: 1500),
);

LiveDuelSnapshot _snapshot({
  LiveDuelStatus status = LiveDuelStatus.pending,
  DuelSide mySide = DuelSide.p1,
  LiveDuelRoundState? round,
  List<DuelRoundRecord> history = const [],
  int myScore = 0,
  int opponentScore = 0,
}) => LiveDuelSnapshot(
  serverNow: _start,
  duelId: _duelId,
  status: status,
  mySide: mySide,
  isRanked: true,
  origin: 'matchmaking',
  topic: _topic,
  me: _me,
  opponent: _opponent,
  config: DuelConfig.fallback,
  currentRound: round?.number ?? 0,
  history: history,
  myScore: myScore,
  opponentScore: opponentScore,
  round: round,
);

RoundScheduled _scheduled(int round, DateTime startsAt) => RoundScheduled(
  round: round,
  startsAt: startsAt,
  deadline: startsAt.add(const Duration(seconds: 15, milliseconds: 1500)),
  roundSeconds: 15,
  totalRounds: 5,
);

DuelFinished _finished({String? forfeitedBy}) => DuelFinished(
  reason: forfeitedBy == null ? 'completed' : 'forfeit',
  isRanked: true,
  winnerId: 'user_me',
  forfeitedBy: forfeitedBy,
  p1Rounds: 3,
  p2Rounds: 2,
  p1AvgMs: 3000,
  p2AvgMs: 5000,
  p1: const DuelSideResult(
    eloBefore: 1310,
    eloAfter: 1326,
    coins: 200,
    xp: 150,
    badgeIds: ['badge_duelist'],
  ),
  p2: const DuelSideResult(eloBefore: 1380, eloAfter: 1364, coins: 40, xp: 80),
);

/// One running duel inside `fakeAsync`: the Bloc, its room channel, and
/// every state it emitted.
class _Duel {
  _Duel(this.async, this.bloc, this.room, this.states);

  final FakeAsync async;
  final LiveDuelBloc bloc;
  final StreamController<DuelRoomEvent> room;
  final List<LiveDuelState> states;

  LiveDuelState get state => bloc.state;

  LiveDuelRound get round => bloc.state as LiveDuelRound;

  void push(DuelRoomEvent event) {
    room.add(event);
    async.flushMicrotasks();
  }

  void add(LiveDuelEvent event) {
    bloc.add(event);
    async.flushMicrotasks();
  }

  void elapse(Duration duration) => async.elapse(duration);

  /// Schedules round 1 at [_round1StartsAt] and runs the clock to the
  /// moment its question is fetched and shown (300 ms before the start).
  void playIntoRound1() {
    push(_scheduled(1, _round1StartsAt));
    elapse(const Duration(milliseconds: 2700));
  }
}

void main() {
  late _MockLiveDuelRepository repository;

  setUp(() {
    repository = _MockLiveDuelRepository();
    when(
      () => repository.markReady(any()),
    ).thenAnswer((_) async => LiveDuelStatus.pending);
    when(() => repository.heartbeat(any())).thenAnswer((_) async => null);
    when(() => repository.fetchRound(any(), any())).thenAnswer(
      (invocation) async => (
        round: invocation.positionalArguments[1] as int,
        startsAt: _round1StartsAt,
        deadline: _round1Deadline,
        question: _question,
      ),
    );
    when(
      () => repository.submitAnswer(
        any(),
        round: any(named: 'round'),
        choice: any(named: 'choice'),
        clientMs: any(named: 'clientMs'),
      ),
    ).thenAnswer((_) async {});
    when(() => repository.claimTimeout(any(), any())).thenAnswer((_) async {});
    when(() => repository.leave(any())).thenAnswer((_) async {});
  });

  /// Starts a Bloc on [initial] inside `fakeAsync`, runs [body], then closes
  /// everything down.
  void runDuel(
    LiveDuelSnapshot initial,
    void Function(_Duel duel) body, {
    DuelAudio? audio,
  }) {
    fakeAsync((async) {
      when(() => repository.fetchState(any())).thenAnswer((_) async => initial);
      final room = StreamController<DuelRoomEvent>.broadcast();
      when(
        () =>
            repository.roomEvents(any(), opponentId: any(named: 'opponentId')),
      ).thenAnswer((_) => room.stream);
      final bloc = LiveDuelBloc(
        repository,
        ServerClock(localNow: () => _start.add(async.elapsed)),
        duelId: _duelId,
        audio: audio,
        languageCode: 'en',
      );
      final states = <LiveDuelState>[];
      final subscription = bloc.stream.listen(states.add);
      bloc.add(const LiveDuelStarted());
      async.flushMicrotasks();

      body(_Duel(async, bloc, room, states));

      unawaited(subscription.cancel());
      unawaited(bloc.close());
      unawaited(room.close());
      async.flushMicrotasks();
    });
  }

  group('LiveDuelBloc sound', () {
    late _MockDuelAudio audio;
    const narrated = DuelQuestion(
      text: 'Who won the 2022 World Cup?',
      options: ['Argentina', 'France', 'Brazil', 'Croatia'],
      audioUrl: 'https://cdn.example/q1.mp3',
    );

    setUp(() {
      audio = _MockDuelAudio();
      when(() => audio.isOn).thenReturn(true);
      when(() => audio.dispose()).thenAnswer((_) async {});
      when(() => repository.fetchRound(any(), any())).thenAnswer(
        (_) async => (
          round: 1,
          startsAt: _round1StartsAt,
          deadline: _round1Deadline,
          question: narrated,
        ),
      );
    });

    test('the question is read aloud as it appears, the answer stops the '
        'tick, and the reveal plays the verdict chime', () {
      runDuel(_snapshot(), (duel) {
        duel.playIntoRound1();
        verify(
          () => audio.questionShown(
            audioUrl: narrated.audioUrl,
            ttsExcluded: false,
          ),
        ).called(1);
        expect(duel.round.isAudioOn, isTrue);

        duel.add(const LiveDuelAnswerSelected(0));
        verify(() => audio.answerLocked()).called(1);

        duel.push(
          const RoundResolved(
            round: 1,
            outcome: RoundSideOutcome.draw,
            correctIndex: 0,
            p1Choice: 0,
            p2Choice: 0,
            p1Ms: 3000,
            p2Ms: 2400,
            p1Rounds: 1,
            p2Rounds: 1,
          ),
        );
        verify(() => audio.revealed(correct: true)).called(1);
        // Both answered correctly: both scored, whoever was faster.
        expect(duel.round.myScore, 1);
        expect(duel.round.opponentScore, 1);
      }, audio: audio);
    });

    test('the speaker toggle flips the preference while answering', () {
      when(
        () => audio.toggle(clockRunning: any(named: 'clockRunning')),
      ).thenReturn(false);
      runDuel(_snapshot(), (duel) {
        duel.playIntoRound1();
        duel.add(const LiveDuelAudioToggled());
        verify(() => audio.toggle(clockRunning: true)).called(1);
        expect(duel.round.isAudioOn, isFalse);
      }, audio: audio);
    });

    test('the last five seconds are the danger zone', () {
      runDuel(_snapshot(), (duel) {
        duel.playIntoRound1();
        expect(duel.round.isDanger, isFalse);
        duel.elapse(const Duration(seconds: 11));
        expect(duel.round.secondsRemaining, lessThanOrEqualTo(5));
        expect(duel.round.isDanger, isTrue);
        duel.add(const LiveDuelAnswerSelected(1));
        expect(duel.round.isDanger, isFalse);
      }, audio: audio);
    });
  });

  group('LiveDuelBloc', () {
    test('starts connecting', () {
      final bloc = LiveDuelBloc(repository, ServerClock(), duelId: _duelId);
      expect(bloc.state, const LiveDuelConnecting());
      unawaited(bloc.close());
    });

    blocTest<LiveDuelBloc, LiveDuelState>(
      'success path: a pending duel opens on the VS intro, waiting for the '
      'opponent, and marks this player ready',
      setUp: () {
        when(
          () => repository.fetchState(_duelId),
        ).thenAnswer((_) async => _snapshot());
        when(
          () => repository.roomEvents(
            any(),
            opponentId: any(named: 'opponentId'),
          ),
        ).thenAnswer((_) => const Stream.empty());
      },
      build: () => LiveDuelBloc(repository, ServerClock(), duelId: _duelId),
      act: (bloc) => bloc.add(const LiveDuelStarted()),
      expect: () => [
        isA<LiveDuelIntro>()
            .having((intro) => intro.me, 'me', _me)
            .having((intro) => intro.opponent, 'opponent', _opponent)
            .having((intro) => intro.topic, 'topic', _topic)
            .having((intro) => intro.isRanked, 'isRanked', isTrue)
            .having((intro) => intro.startsAt, 'startsAt', isNull),
      ],
      verify: (_) {
        verify(
          () => repository.roomEvents(_duelId, opponentId: _opponent.id),
        ).called(1);
        verify(() => repository.markReady(_duelId)).called(1);
      },
    );

    blocTest<LiveDuelBloc, LiveDuelState>(
      'failure path: a snapshot that fails to load ends in LiveDuelFailed',
      setUp: () => when(() => repository.fetchState(_duelId)).thenThrow(
        const ApiException('not_a_participant', code: 'not_a_participant'),
      ),
      build: () => LiveDuelBloc(repository, ServerClock(), duelId: _duelId),
      act: (bloc) => bloc.add(const LiveDuelStarted()),
      expect: () => [
        isA<LiveDuelFailed>().having(
          (failed) => failed.error.code,
          'code',
          'not_a_participant',
        ),
      ],
      verify: (_) => verifyNever(() => repository.markReady(any())),
    );

    test('round_start → the intro counts down, then the question is fetched '
        'just before the start and the round is shown', () {
      runDuel(_snapshot(), (duel) {
        duel.push(_scheduled(1, _round1StartsAt));
        final intro = duel.state as LiveDuelIntro;
        expect(intro.startsAt, _round1StartsAt);
        expect(intro.secondsToStart, 3);

        duel.elapse(const Duration(seconds: 1));
        expect((duel.state as LiveDuelIntro).secondsToStart, 2);
        verifyNever(() => repository.fetchRound(any(), any()));

        // 300 ms before the server start.
        duel.elapse(const Duration(milliseconds: 1700));
        verify(() => repository.fetchRound(_duelId, 1)).called(1);
        final round = duel.round;
        expect(round.roundNumber, 1);
        expect(round.totalRounds, 5);
        expect(round.question, _question);
        expect(round.secondsRemaining, 15);
        expect(round.myLocked, isFalse);
      });
    });

    test('a too_early question fetch is retried after 250 ms', () {
      var calls = 0;
      when(() => repository.fetchRound(any(), any())).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          throw const ApiException('too_early', code: 'too_early');
        }
        return (
          round: 1,
          startsAt: _round1StartsAt,
          deadline: _round1Deadline,
          question: _question,
        );
      });
      runDuel(_snapshot(), (duel) {
        duel.playIntoRound1();
        expect(duel.round.question, isNull);

        duel.elapse(const Duration(milliseconds: 300));
        expect(calls, 2);
        expect(duel.round.question, _question);
      });
    });

    test('answering locks it locally and submits the choice with the '
        'player\'s own time since the question appeared', () {
      runDuel(_snapshot(), (duel) {
        duel.playIntoRound1();
        duel.elapse(const Duration(milliseconds: 3200));

        duel.add(const LiveDuelAnswerSelected(1));
        final round = duel.round;
        expect(round.myLocked, isTrue);
        expect(round.myChoice, 1);
        expect(round.mySeconds, 3);
        expect(round.isRevealed, isFalse);
        verify(
          () => repository.submitAnswer(
            _duelId,
            round: 1,
            choice: 1,
            clientMs: 3200,
          ),
        ).called(1);

        // A second tap is ignored.
        duel.add(const LiveDuelAnswerSelected(2));
        expect(duel.round.myChoice, 1);
        verifyNever(
          () => repository.submitAnswer(
            any(),
            round: any(named: 'round'),
            choice: 2,
            clientMs: any(named: 'clientMs'),
          ),
        );
      });
    });

    test('a network error on submit is retried, while the round is open', () {
      var calls = 0;
      when(
        () => repository.submitAnswer(
          any(),
          round: any(named: 'round'),
          choice: any(named: 'choice'),
          clientMs: any(named: 'clientMs'),
        ),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw const ApiException.network();
      });
      runDuel(_snapshot(), (duel) {
        duel.playIntoRound1();
        duel.add(const LiveDuelAnswerSelected(0));
        duel.elapse(const Duration(milliseconds: 300));
        expect(calls, 2);
        expect(duel.round.myLocked, isTrue);
      });
    });

    test('the opponent\'s answer_locked shows their timing, never their '
        'choice; this player\'s own lock is ignored', () {
      runDuel(_snapshot(), (duel) {
        duel.playIntoRound1();

        duel.push(const AnswerLocked(userId: 'user_me', round: 1, ms: 900));
        expect(duel.round.opponentLocked, isFalse);

        duel.push(const AnswerLocked(userId: 'user_opp', round: 1, ms: 4100));
        final round = duel.round;
        expect(round.opponentLocked, isTrue);
        expect(round.opponentSeconds, 4);
        expect(round.opponentChoice, isNull);
        expect(round.correctIndex, isNull);
        expect(round.isRevealed, isFalse);
      });
    });

    test('withheld-correctness invariant: no state before round_result '
        'carries the correct index or the opponent\'s choice', () {
      runDuel(_snapshot(), (duel) {
        duel.playIntoRound1();
        duel.elapse(const Duration(seconds: 2));
        duel.push(const AnswerLocked(userId: 'user_opp', round: 1, ms: 2400));
        duel.elapse(const Duration(seconds: 1));
        duel.add(const LiveDuelAnswerSelected(0));
        duel.elapse(const Duration(seconds: 1));

        final beforeResult = List<LiveDuelState>.of(duel.states);
        final rounds = beforeResult.whereType<LiveDuelRound>().toList();
        // Not vacuous: the round was really on screen, question and all,
        // with both players locked in.
        expect(rounds.where((round) => round.question != null), isNotEmpty);
        expect(rounds.last.myLocked && rounds.last.opponentLocked, isTrue);
        for (final round in rounds) {
          expect(round.correctIndex, isNull, reason: 'correct index leaked');
          expect(round.opponentChoice, isNull, reason: 'choice leaked');
          expect(round.isRevealed, isFalse);
        }

        duel.push(
          const RoundResolved(
            round: 1,
            outcome: RoundSideOutcome.p1,
            correctIndex: 0,
            p1Choice: 0,
            p2Choice: 2,
            p1Ms: 3000,
            p2Ms: 2400,
            p1Rounds: 1,
            p2Rounds: 0,
          ),
        );
        expect(duel.round.correctIndex, 0);
        expect(duel.round.opponentChoice, 2);
      });
    });

    test('round_result reveals the round and moves the score; the reveal '
        'stays up until the next round starts, which is fetched afresh', () {
      runDuel(_snapshot(), (duel) {
        duel.playIntoRound1();
        duel.add(const LiveDuelAnswerSelected(0));

        duel.push(
          const RoundResolved(
            round: 1,
            outcome: RoundSideOutcome.p1,
            correctIndex: 0,
            p1Choice: 0,
            p2Choice: 2,
            p1Ms: 3200,
            p2Ms: 4100,
            p1Rounds: 1,
            p2Rounds: 0,
          ),
        );
        final revealed = duel.round;
        expect(revealed.isRevealed, isTrue);
        expect(revealed.correctIndex, 0);
        expect(revealed.opponentChoice, 2);
        expect(revealed.myChoice, 0);
        expect(revealed.opponentLocked, isTrue);
        expect(revealed.opponentSeconds, 4);
        expect(revealed.myScore, 1);
        expect(revealed.opponentScore, 0);
        expect(revealed.history.single.outcome, RoundOutcome.playerWon);
        expect(revealed.history.single.playerCorrect, isTrue);

        final round2StartsAt = _start.add(const Duration(seconds: 6));
        duel.push(_scheduled(2, round2StartsAt));
        expect(duel.round.roundNumber, 1);
        expect(duel.round.isRevealed, isTrue);
        expect(duel.round.nextRoundAt, round2StartsAt);

        // Until 300 ms before round 2: 6 s − 0.3 s − 2.7 s already elapsed.
        duel.elapse(const Duration(milliseconds: 3000));
        verify(() => repository.fetchRound(_duelId, 2)).called(1);
        final next = duel.round;
        expect(next.roundNumber, 2);
        expect(next.isRevealed, isFalse);
        expect(next.correctIndex, isNull);
        expect(next.opponentChoice, isNull);
        expect(next.myLocked, isFalse);
        expect(next.myScore, 1);
        expect(next.nextRoundAt, isNull);
      });
    });

    test('the round clock runs out → a timeout is submitted, and after the '
        'deadline the round is claimed', () {
      runDuel(_snapshot(), (duel) {
        duel.playIntoRound1();
        duel.elapse(const Duration(seconds: 15));

        final round = duel.round;
        expect(round.secondsRemaining, 0);
        expect(round.myLocked, isTrue);
        expect(round.myChoice, isNull);
        expect(round.mySeconds, 15);
        verify(
          () => repository.submitAnswer(
            _duelId,
            round: 1,
            choice: null,
            clientMs: 15000,
          ),
        ).called(1);
        verifyNever(() => repository.claimTimeout(any(), any()));

        // Deadline (start + 16.5 s) + 1 s grace.
        duel.elapse(const Duration(seconds: 3));
        verify(() => repository.claimTimeout(_duelId, 1)).called(1);
      });
    });

    for (final side in DuelSide.values) {
      test('duel_end builds the result from this player\'s seat '
          '(${side.name})', () {
        runDuel(_snapshot(mySide: side), (duel) {
          duel.push(_finished());

          final result = (duel.state as LiveDuelEnded).result;
          final isP1 = side == DuelSide.p1;
          expect(result.me, _me);
          expect(result.opponent, _opponent);
          expect(result.playerRoundsWon, isP1 ? 3 : 2);
          expect(result.opponentRoundsWon, isP1 ? 2 : 3);
          expect(result.playerAverageAnswerSeconds, isP1 ? 3.0 : 5.0);
          expect(result.opponentAverageAnswerSeconds, isP1 ? 5.0 : 3.0);
          expect(result.eloBefore, isP1 ? 1310 : 1380);
          expect(result.eloAfter, isP1 ? 1326 : 1364);
          expect(result.rewardCoins, isP1 ? 200 : 40);
          expect(result.xpEarned, isP1 ? 150 : 80);
          expect(
            result.newlyEarnedBadgeIds,
            isP1 ? ['badge_duelist'] : isEmpty,
          );
          expect(result.duelId, _duelId);
          expect(result.isBot, isFalse);
          expect(result.topic, _topic);
          expect(result.isRanked, isTrue);
          expect(result.endReason, DuelEndReason.completed);
        });
      });
    }

    test('a duel_end right after the last reveal lets the reveal stay up '
        'for its beat before ending', () {
      runDuel(_snapshot(), (duel) {
        duel.playIntoRound1();
        duel.push(
          const RoundResolved(
            round: 1,
            outcome: RoundSideOutcome.draw,
            correctIndex: 3,
            p1Rounds: 3,
            p2Rounds: 2,
          ),
        );
        duel.push(_finished());
        expect(duel.round.isRevealed, isTrue);

        // `DuelConfig.fallback.revealSeconds` is 2.
        duel.elapse(const Duration(milliseconds: 2100));
        expect(duel.state, isA<LiveDuelEnded>());
      });
    });

    test('a forfeit by the opponent is told apart from this player\'s own', () {
      runDuel(_snapshot(), (duel) {
        duel.push(_finished(forfeitedBy: 'user_opp'));
        expect(
          (duel.state as LiveDuelEnded).result.endReason,
          DuelEndReason.opponentForfeited,
        );
      });
    });

    test('an abandoned duel_end (no-show) ends in LiveDuelAbandoned', () {
      runDuel(_snapshot(), (duel) {
        duel.push(
          const DuelFinished(
            reason: 'abandoned',
            cause: 'no_show',
            isRanked: false,
            p1Rounds: 0,
            p2Rounds: 0,
          ),
        );
        expect(duel.state, const LiveDuelAbandoned('no_show'));
      });
    });

    test('a resumed snapshot rebuilds the round against the real server '
        'clock, and a channel drop → re-subscribe refetches it', () {
      final round2StartsAt = _start.subtract(const Duration(seconds: 4));
      final resumed = _snapshot(
        status: LiveDuelStatus.active,
        round: LiveDuelRoundState(
          number: 2,
          startsAt: round2StartsAt,
          deadline: round2StartsAt.add(
            const Duration(seconds: 15, milliseconds: 1500),
          ),
          opponentLocked: true,
          opponentMs: 2000,
          question: _question,
        ),
        history: [
          DuelRoundRecord.live(
            roundNumber: 1,
            outcome: RoundOutcome.opponentWon,
            correctIndex: 1,
            roundSeconds: 15,
            playerChoice: 3,
            opponentChoice: 1,
            playerMs: 5000,
            opponentMs: 2000,
          ),
        ],
        opponentScore: 1,
      );
      runDuel(resumed, (duel) {
        final round = duel.round;
        expect(round.roundNumber, 2);
        expect(round.question, _question);
        // Four seconds of round 2 were already gone (plan 017, A4).
        expect(round.secondsRemaining, 11);
        expect(round.opponentLocked, isTrue);
        expect(round.opponentSeconds, 2);
        expect(round.opponentScore, 1);
        expect(round.history, hasLength(1));
        verify(() => repository.fetchState(_duelId)).called(1);

        // The first subscribe is not a reconnect.
        duel.push(const RoomChannelStatusChanged(isLive: true));
        verifyNever(() => repository.fetchState(any()));

        duel.push(const RoomChannelStatusChanged(isLive: false));
        duel.push(const RoomChannelStatusChanged(isLive: true));
        verify(() => repository.fetchState(_duelId)).called(1);
        expect(duel.round.roundNumber, 2);
      });
    });

    test('the app resuming refetches the snapshot', () {
      runDuel(_snapshot(), (duel) {
        verify(() => repository.fetchState(_duelId)).called(1);
        duel.add(const LiveDuelResumed());
        verify(() => repository.fetchState(_duelId)).called(1);
      });
    });

    test('the opponent dropping off shows a reconnecting timer', () {
      runDuel(_snapshot(), (duel) {
        duel.playIntoRound1();
        duel.push(const OpponentPresenceChanged(online: false));
        expect(duel.round.opponentOnline, isFalse);
        expect(duel.round.opponentOfflineSince, isNotNull);

        duel.elapse(const Duration(seconds: 3));
        expect(duel.round.opponentReconnectSeconds, 3);

        duel.push(const OpponentPresenceChanged(online: true));
        expect(duel.round.opponentOnline, isTrue);
        expect(duel.round.opponentOfflineSince, isNull);
      });
    });

    test('quitting calls leave; the forfeit duel_end then ends the duel', () {
      runDuel(_snapshot(), (duel) {
        duel.playIntoRound1();
        duel.add(const LiveDuelQuitConfirmed());
        verify(() => repository.leave(_duelId)).called(1);

        duel.push(_finished(forfeitedBy: 'user_me'));
        expect(
          (duel.state as LiveDuelEnded).result.endReason,
          DuelEndReason.youForfeited,
        );
      });
    });

    test('quitting before round 1 abandons it — by this player, so no '
        '"no-show" notice', () {
      runDuel(_snapshot(), (duel) {
        duel.add(const LiveDuelQuitConfirmed());
        verify(() => repository.leave(_duelId)).called(1);
        duel.push(
          const DuelFinished(
            reason: 'abandoned',
            cause: 'left_before_start',
            isRanked: false,
            p1Rounds: 0,
            p2Rounds: 0,
          ),
        );
        expect(
          duel.state,
          const LiveDuelAbandoned('left_before_start', byMe: true),
        );
      });
    });

    test(
      'if duel_end never arrives after leaving, the snapshot settles it',
      () {
        runDuel(_snapshot(), (duel) {
          duel.playIntoRound1();
          when(() => repository.fetchState(any())).thenAnswer(
            (_) async => _snapshot(status: LiveDuelStatus.complete).copyWith(
              opponentScore: 5,
              result: const LiveDuelOutcome(
                reason: 'forfeit',
                eloBefore: 1310,
                eloAfter: 1298,
                youForfeited: true,
              ),
            ),
          );
          duel.add(const LiveDuelQuitConfirmed());
          expect(duel.state, isA<LiveDuelRound>());

          duel.elapse(const Duration(seconds: 4));
          final result = (duel.state as LiveDuelEnded).result;
          expect(result.endReason, DuelEndReason.youForfeited);
          expect(result.opponentRoundsWon, 5);
          expect(result.eloAfter, 1298);
        });
      },
    );
  });
}
