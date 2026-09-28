import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/skeleton_box.dart';
import 'package:quizoo/features/duel/domain/duel_challenge.dart';
import 'package:quizoo/features/duel/domain/duel_config.dart';
import 'package:quizoo/features/duel/domain/duel_lobby_me.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/domain/incoming_join_request.dart';
import 'package:quizoo/features/duel/presentation/bloc/arena_notice.dart';
import 'package:quizoo/features/duel/presentation/bloc/duel_arena_bloc.dart';
import 'package:quizoo/features/duel/presentation/screens/duel_arena_screen.dart';
import 'package:quizoo/features/duel/presentation/widgets/challenge_card.dart';
import 'package:quizoo/features/duel/presentation/widgets/incoming_request_banner.dart';
import 'package:quizoo/features/duel/presentation/widgets/rejoin_duel_banner.dart';

import '../../support/pump_screen.dart';

class _MockDuelArenaBloc extends MockBloc<DuelArenaEvent, DuelArenaState>
    implements DuelArenaBloc {}

final DateTime _now = DateTime.utc(2026, 9, 27, 12);

const DuelTopic _football = DuelTopic(
  id: 'football',
  name: 'Football',
  emoji: '⚽',
  plateColor: '#DDF1FF',
  categoryName: 'Sports',
  categoryEmoji: '🏅',
);

DuelPlayer _player(String id, String name, {int elo = 1200}) =>
    DuelPlayer(id: id, name: name, avatarEmoji: '🦊', elo: elo);

final DuelPlayer _me = _player('me', 'Me');

DuelChallenge _challenge(
  String id, {
  required DuelPlayer creator,
  int createdSecondsAgo = 0,
  ChallengeStatus status = ChallengeStatus.open,
  bool creatorPresent = true,
  String? opponentName,
}) {
  final createdAt = _now.subtract(Duration(seconds: createdSecondsAgo));
  return DuelChallenge(
    id: id,
    status: status,
    creatorPresent: creatorPresent,
    createdAt: createdAt,
    expiresAt: createdAt.add(const Duration(minutes: 5)),
    creator: creator,
    topic: _football,
    opponentName: opponentName,
  );
}

DuelArenaReady _ready({
  List<DuelChallenge> challenges = const [],
  IncomingJoinRequest? incoming,
  ArenaNotice? notice,
  int noticeSeq = 0,
  String? startDuelId,
  String? activeDuelId,
}) => DuelArenaReady(
  config: const DuelConfig(),
  me: DuelLobbyMe(player: _me),
  challenges: challenges,
  now: _now,
  incoming: incoming,
  onlineCount: 23,
  notice: notice,
  noticeSeq: noticeSeq,
  startDuelId: startDuelId,
  activeDuelId: activeDuelId,
);

void main() {
  late _MockDuelArenaBloc bloc;

  setUp(() => bloc = _MockDuelArenaBloc());

  Future<void> pumpArena(
    WidgetTester tester,
    DuelArenaState state, {
    Stream<DuelArenaState>? states,
  }) async {
    whenListen(
      bloc,
      states ?? const Stream<DuelArenaState>.empty(),
      initialState: state,
    );
    await tester.pumpScreen(DuelArenaScreen(bloc: bloc));
    // Bounded pumps only: skeleton shimmers and countdown rings keep
    // scheduling frames, so this screen never "settles".
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('DuelArenaScreen', () {
    testWidgets('loading: three animated skeleton cards', (tester) async {
      await pumpArena(tester, const DuelArenaLoading());

      expect(find.byType(SkeletonBox), findsNWidgets(3));
      expect(find.text('⚔️ Duel Arena'), findsOneWidget);
      expect(find.text('⚡ QUICK MATCH'), findsOneWidget);
    });

    testWidgets('failed: an error view whose Retry re-loads', (tester) async {
      await pumpArena(tester, const DuelArenaFailed(ApiException.network()));

      expect(find.text('ERR_NETWORK'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const ArenaRetryRequested())).called(1);
    });

    testWidgets('empty feed: the empty block, its CTA and the composer', (
      tester,
    ) async {
      await pumpArena(tester, _ready());

      expect(find.text('No live challenges yet'), findsOneWidget);
      // The empty CTA and the composer both offer creating.
      expect(find.text('Create challenge'), findsNWidgets(2));
      expect(find.byType(ChallengeCard), findsNothing);
      // The head-count pill.
      expect(find.text('23'), findsOneWidget);
    });

    testWidgets('loaded: open, away, in-progress and own cards', (
      tester,
    ) async {
      await pumpArena(
        tester,
        _ready(
          challenges: [
            _challenge(
              'live',
              creator: _player('danish', 'Danish'),
              createdSecondsAgo: 40,
              status: ChallengeStatus.matched,
              opponentName: 'Zara N.',
            ),
            _challenge(
              'away',
              creator: _player('bilal', 'Bilal'),
              createdSecondsAgo: 30,
              creatorPresent: false,
            ),
            _challenge(
              'open',
              creator: _player('ayesha', 'Ayesha K.', elo: 1412),
              createdSecondsAgo: 20,
            ),
            _challenge('mine', creator: _me, createdSecondsAgo: 10),
          ],
        ),
      );

      expect(find.text('LIVE CHALLENGES · 4'), findsOneWidget);
      expect(find.byType(ChallengeCard, skipOffstage: false), findsNWidgets(4));
      expect(find.text('Your challenge', skipOffstage: false), findsOneWidget);
      expect(find.text('Ayesha K.', skipOffstage: false), findsOneWidget);
      expect(find.text('Away', skipOffstage: false), findsOneWidget);
      expect(find.text('LIVE', skipOffstage: false), findsOneWidget);
      // The composer shows the viewer's own open challenge.
      expect(find.text('Your Football challenge · 4:50 left'), findsOneWidget);

      // Newest at the bottom: the own card sits below Ayesha's.
      final ownTop = tester.getTopLeft(find.text('Your challenge')).dy;
      final openTop = tester.getTopLeft(find.text('Ayesha K.')).dy;
      expect(ownTop, greaterThan(openTop));

      // The away card's Join is there too, but disabled.
      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text('Ayesha K.'),
            matching: find.byType(ChallengeCard),
          ),
          matching: find.text('Join'),
        ),
      );
      verify(() => bloc.add(const JoinRequested('open'))).called(1);
      await tester.tap(find.text('Cancel'));
      verify(() => bloc.add(const ChallengeCancelRequested())).called(1);
    });

    testWidgets('incoming request: the banner with Accept / Decline', (
      tester,
    ) async {
      await pumpArena(
        tester,
        _ready(
          challenges: [_challenge('mine', creator: _me)],
          incoming: IncomingJoinRequest(
            requestId: 'req-1',
            challengeId: 'mine',
            requester: _player(
              'danish',
              'Danish M.',
              elo: 1380,
            ).copyWith(league: 'silver', topicLevel: 4),
            expiresAt: _now.add(const Duration(seconds: 3)),
            queuedCount: 2,
          ),
        ),
      );

      expect(find.byType(IncomingRequestBanner), findsOneWidget);
      expect(find.text('Danish M. wants to duel!'), findsOneWidget);
      expect(find.text('🥈 Silver · 1380 ELO · Football Lv 4'), findsOneWidget);
      expect(find.text('3s'), findsOneWidget);
      expect(find.text('+2 waiting'), findsOneWidget);

      await tester.tap(find.text('Accept'));
      verify(() => bloc.add(const IncomingAccepted())).called(1);
      await tester.tap(find.text('Decline'));
      verify(() => bloc.add(const IncomingDeclined())).called(1);
    });

    testWidgets('an active duel pins the Rejoin banner', (tester) async {
      await pumpArena(tester, _ready(activeDuelId: 'duel-7'));

      expect(find.byType(RejoinDuelBanner), findsOneWidget);
      expect(find.text("⚔️ You're in a duel"), findsOneWidget);
      await tester.tap(find.text('Rejoin'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('pushed:/duel/duel-7'), findsOneWidget);
    });

    testWidgets('a notice shows a snackbar and is consumed', (tester) async {
      await pumpArena(
        tester,
        _ready(),
        states: Stream.value(
          _ready(notice: const DailyCapNotice(), noticeSeq: 1),
        ),
      );

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Daily challenge limit reached — try Quick match'),
        findsOneWidget,
      );
      verify(() => bloc.add(const NoticeConsumed())).called(1);
      // Let the snackbar time out so no timer outlives the test.
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(AppSnackbar), findsNothing);
    });

    testWidgets('a started duel pushes the live duel route', (tester) async {
      await pumpArena(
        tester,
        _ready(),
        states: Stream.value(_ready(startDuelId: 'duel-9')),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('pushed:/duel/duel-9'), findsOneWidget);
    });
  });
}
