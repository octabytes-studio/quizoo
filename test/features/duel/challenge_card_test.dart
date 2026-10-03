import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/features/duel/domain/duel_challenge.dart';
import 'package:quizoo/features/duel/domain/duel_config.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/presentation/bloc/challenge_card_state.dart';
import 'package:quizoo/features/duel/presentation/bloc/fairness.dart';
import 'package:quizoo/features/duel/presentation/widgets/challenge_card.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizoo/app/subscription_cubit.dart';
import 'package:quizoo/features/auth/data/auth_repository.dart';
import 'package:quizoo/features/auth/presentation/bloc/session_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_purchases.dart';
import '../../support/pump_app.dart';
import '../../support/pump_screen.dart';

final DateTime _now = DateTime.utc(2026, 9, 27, 12);

final DuelChallenge _challenge = DuelChallenge(
  id: 'c1',
  status: ChallengeStatus.open,
  creatorPresent: true,
  createdAt: _now.subtract(const Duration(seconds: 48)),
  // 4:12 left.
  expiresAt: _now.add(const Duration(minutes: 4, seconds: 12)),
  creator: const DuelPlayer(
    id: 'ayesha',
    name: 'Ayesha K.',
    avatarEmoji: '🦊',
    elo: 1412,
    league: 'gold',
    topicLevel: 7,
  ),
  topic: const DuelTopic(
    id: 'football',
    name: 'Football',
    emoji: '⚽',
    plateColor: '#DDF1FF',
    categoryName: 'Sports',
    categoryEmoji: '🏅',
  ),
);

void main() {
  /// `ChallengeCard` reads the app-root `SessionCubit`/`SubscriptionCubit`
  /// to decide the Pro tick (plan 023), so those two — and only those two —
  /// sit above it. `pumpApp` keeps the test's original layout and pump
  /// semantics.
  Future<void> pumpCard(
    WidgetTester tester,
    ChallengeCardState cardState, {
    DuelChallenge? challenge,
    Fairness fairness = Fairness.even,
    VoidCallback? onJoin,
    VoidCallback? onWithdraw,
    VoidCallback? onCancel,
  }) async {
    final authApi = FakeAuthApi();
    when(
      () => authApi.authStateChanges,
    ).thenAnswer((_) => const Stream.empty());
    final session = SessionCubit(
      AuthRepository(authApi, await SharedPreferences.getInstance()),
    );
    final subscription = freeSubscriptionCubit();
    addTearDown(session.close);
    addTearDown(subscription.close);

    await tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<SubscriptionCubit>.value(value: subscription),
        ],
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ChallengeCard(
            challenge: challenge ?? _challenge,
            cardState: cardState,
            fairness: fairness,
            now: _now,
            config: const DuelConfig(),
            onJoin: onJoin,
            onWithdraw: onWithdraw,
            onCancel: onCancel,
          ),
        ),
      ),
    );
  }

  ChunkyButton buttonLabelled(WidgetTester tester, String label) => tester
      .widget<ChunkyButton>(find.widgetWithText(ChunkyButton, label).first);

  group('ChallengeCard', () {
    testWidgets('open: creator, rating, topic, time, fairness and Join', (
      tester,
    ) async {
      var joined = false;
      await pumpCard(
        tester,
        const ChallengeCardOpen(),
        onJoin: () => joined = true,
      );

      expect(find.text('Ayesha K.'), findsOneWidget);
      expect(find.text('🥇 1,412 · Lv 7'), findsOneWidget);
      expect(find.text('Football · Sports'), findsOneWidget);
      expect(find.text('4:12'), findsOneWidget);
      expect(find.text('Even match'), findsOneWidget);
      expect(find.text('10 questions · winner +200 🪙'), findsOneWidget);

      await tester.tap(find.text('Join'));
      expect(joined, isTrue);
    });

    testWidgets('carries one semantics label for the whole card', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpCard(tester, const ChallengeCardOpen(), onJoin: () {});

      // The card's label leads; the Join button merges into the same node,
      // so a screen reader hears one card with one action.
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'^Challenge from Ayesha K\., Gold, 1412 ELO, Football, '
            r'4:12 left',
          ),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('fairness hints: tough and favourable', (tester) async {
      await pumpCard(
        tester,
        const ChallengeCardOpen(),
        fairness: Fairness.tough,
      );
      expect(find.text('Tough one'), findsOneWidget);

      await pumpCard(
        tester,
        const ChallengeCardOpen(),
        fairness: Fairness.favourable,
      );
      expect(find.text('Favourable'), findsOneWidget);
    });

    testWidgets('queued: "Request sent · N ahead" and a withdraw ✕', (
      tester,
    ) async {
      var withdrew = false;
      await pumpCard(
        tester,
        const ChallengeCardQueued(position: 2),
        onWithdraw: () => withdrew = true,
      );

      expect(find.text('Request sent · 2 ahead'), findsOneWidget);
      expect(find.text('Join'), findsNothing);
      await tester.tap(find.text('✕'));
      expect(withdrew, isTrue);
    });

    testWidgets('queued without a position yet: "Request sent"', (
      tester,
    ) async {
      await pumpCard(tester, const ChallengeCardQueued());
      expect(find.text('Request sent'), findsOneWidget);
    });

    testWidgets('pending: "{name} is deciding…" with its window bar', (
      tester,
    ) async {
      await pumpCard(
        tester,
        ChallengeCardPending(expiresAt: _now.add(const Duration(seconds: 3))),
      );

      expect(find.text('Ayesha K. is deciding…'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(0.6, 0.001));
    });

    testWidgets('cooling: "Not this time" first, then a disabled retry', (
      tester,
    ) async {
      final retryAt = _now.add(const Duration(seconds: 13));
      await pumpCard(
        tester,
        ChallengeCardCooling(retryAt: retryAt, justResolved: true),
      );
      expect(find.text('Not this time'), findsOneWidget);
      expect(buttonLabelled(tester, 'Not this time').onPressed, isNull);

      await pumpCard(tester, ChallengeCardCooling(retryAt: retryAt));
      expect(find.text('Try again in 13s'), findsOneWidget);
      expect(buttonLabelled(tester, 'Try again in 13s').onPressed, isNull);
    });

    testWidgets('away: dimmed, "Away" chip, Join disabled', (tester) async {
      await pumpCard(tester, const ChallengeCardAway(), onJoin: () {});

      expect(find.text('Away'), findsOneWidget);
      expect(buttonLabelled(tester, 'Join').onPressed, isNull);
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('Away'), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, ChallengeCard.awayOpacity);
    });

    testWidgets('in progress: "LIVE" and who is playing, no Join', (
      tester,
    ) async {
      await pumpCard(
        tester,
        const ChallengeCardInProgress(opponentName: 'Zara N.'),
        challenge: _challenge.copyWith(status: ChallengeStatus.matched),
      );

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('Football · In progress · vs Zara N.'), findsOneWidget);
      expect(find.byType(ChunkyButton), findsNothing);
    });

    testWidgets('in progress against a guest names them "Guest ####"', (
      tester,
    ) async {
      await pumpCard(
        tester,
        const ChallengeCardInProgress(opponentGuestTag: '4821'),
        challenge: _challenge.copyWith(status: ChallengeStatus.matched),
      );
      expect(
        find.text('Football · In progress · vs Guest 4821'),
        findsOneWidget,
      );
    });

    testWidgets('own: end-aligned, waiting, and Cancel', (tester) async {
      var cancelled = false;
      await pumpCard(
        tester,
        const ChallengeCardOwn(),
        onCancel: () => cancelled = true,
      );

      expect(find.text('Your challenge'), findsOneWidget);
      expect(find.text('Waiting for a challenger…'), findsOneWidget);
      expect(find.text('Join'), findsNothing);
      expect(
        tester.widget<Align>(
          find.ancestor(
            of: find.text('Your challenge'),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Align &&
                  widget.alignment == AlignmentDirectional.centerEnd,
            ),
          ),
        ),
        isNotNull,
      );

      await tester.tap(find.text('Cancel'));
      expect(cancelled, isTrue);
    });

    testWidgets('own while away: "Paused while you\'re away"', (tester) async {
      await pumpCard(tester, const ChallengeCardOwn(paused: true));
      expect(find.text("💤 Paused while you're away"), findsOneWidget);
    });

    testWidgets('ended: dimmed, reason chip, no Join/Cancel', (tester) async {
      await pumpCard(
        tester,
        const ChallengeCardEnded(endReason: 'completed'),
        challenge: _challenge.copyWith(status: ChallengeStatus.ended),
        onJoin: () {},
        onCancel: () {},
      );

      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Ayesha K.'), findsOneWidget);
      expect(find.text('Football · Sports'), findsOneWidget);
      expect(find.text('Join'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.text('Completed'),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, ChallengeCard.awayOpacity);
    });

    testWidgets('ended reasons map to their own labels', (tester) async {
      final challenge = _challenge.copyWith(status: ChallengeStatus.ended);

      await pumpCard(
        tester,
        const ChallengeCardEnded(endReason: 'cancelled'),
        challenge: challenge,
      );
      expect(find.text('Cancelled'), findsOneWidget);

      await pumpCard(
        tester,
        const ChallengeCardEnded(endReason: 'expired'),
        challenge: challenge,
      );
      expect(find.text('Expired'), findsOneWidget);

      await pumpCard(
        tester,
        const ChallengeCardEnded(endReason: 'abandoned'),
        challenge: challenge,
      );
      expect(find.text('Abandoned'), findsOneWidget);

      await pumpCard(tester, const ChallengeCardEnded(), challenge: challenge);
      expect(find.text('Ended'), findsOneWidget);
    });

    testWidgets('ended card has its own semantics label, no time-left', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpCard(
        tester,
        const ChallengeCardEnded(endReason: 'completed'),
        challenge: _challenge.copyWith(status: ChallengeStatus.ended),
      );

      expect(
        find.bySemanticsLabel('Ended challenge from Ayesha K., Football'),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });
}
