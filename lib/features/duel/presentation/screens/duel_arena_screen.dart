import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quizoo/app/content_language_cubit.dart';
import 'package:quizoo/core/network/supabase_client.dart';
import 'package:quizoo/core/router/app_route_observer.dart';
import 'package:quizoo/core/router/app_routes.dart';
import 'package:quizoo/core/theme/app_spacing.dart';
import 'package:quizoo/core/theme/arena_colors.dart';
import 'package:quizoo/core/widgets/app_snackbar.dart';
import 'package:quizoo/core/widgets/chunky_button.dart';
import 'package:quizoo/core/widgets/error_state_view.dart';
import 'package:quizoo/features/duel/data/duel_arena_api.dart';
import 'package:quizoo/features/duel/data/duel_arena_repository.dart';
import 'package:quizoo/features/duel/data/duel_realtime.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/presentation/bloc/arena_notice.dart';
import 'package:quizoo/features/duel/presentation/bloc/duel_arena_bloc.dart';
import 'package:quizoo/features/duel/presentation/widgets/arena_top_bar.dart';
import 'package:quizoo/features/duel/presentation/widgets/challenge_composer_bar.dart';
import 'package:quizoo/features/duel/presentation/widgets/challenge_feed.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_clock_label.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_player_label.dart';
import 'package:quizoo/features/duel/presentation/widgets/duel_topic_picker_sheet.dart';
import 'package:quizoo/features/duel/presentation/widgets/incoming_request_banner.dart';
import 'package:quizoo/features/duel/presentation/widgets/quick_match_card.dart';
import 'package:quizoo/features/duel/presentation/widgets/rejoin_duel_banner.dart';
import 'package:quizoo/features/settings/data/settings_repository.dart';
import 'package:quizoo/l10n/app_localizations.dart';

/// S-38 — the Duel Arena (plan 017): a live, chat-style feed of challenges,
/// Quick match, and the composer to post your own. Full-screen over the
/// shell, on the invariant grape `arena.lite` gradient (Decision 5).
class DuelArenaScreen extends StatelessWidget {
  const DuelArenaScreen({super.key, this.bloc});

  /// A pre-built Bloc for widget tests; the app always builds its own.
  @visibleForTesting
  final DuelArenaBloc? bloc;

  @override
  Widget build(BuildContext context) {
    final injected = bloc;
    if (injected != null) {
      return BlocProvider<DuelArenaBloc>.value(
        value: injected,
        child: const _DuelArenaView(),
      );
    }
    return BlocProvider<DuelArenaBloc>(
      create: (context) {
        final clock = context.read<ServerClock>();
        return DuelArenaBloc(
          DuelArenaRepository(
            DuelArenaApi(supabase, context.read<DuelRealtime>()),
            clock,
          ),
          clock,
          languageCode: context.read<ContentLanguageCubit>().state.code,
        )..add(const ArenaOpened());
      },
      child: const _DuelArenaView(),
    );
  }
}

/// Stateful **only** to host [RouteAware] and [WidgetsBindingObserver]: the
/// arena is "visible" while it is the top route and the app is in the
/// foreground, and the Bloc needs to know when that changes (presence,
/// heartbeat, re-fetch). Ephemeral plumbing, not business state.
class _DuelArenaView extends StatefulWidget {
  const _DuelArenaView();

  @override
  State<_DuelArenaView> createState() => _DuelArenaViewState();
}

class _DuelArenaViewState extends State<_DuelArenaView>
    with RouteAware, WidgetsBindingObserver {
  bool _covered = false;
  bool _foreground = true;
  bool _reportedVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    _covered = true;
    _reportVisibility();
  }

  @override
  void didPopNext() {
    _covered = false;
    _reportVisibility();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
      case AppLifecycleState.hidden ||
          AppLifecycleState.paused ||
          AppLifecycleState.detached:
        _foreground = false;
      case AppLifecycleState.inactive:
        // A notification shade or an OS dialog — still on the arena.
        return;
    }
    _reportVisibility();
  }

  void _reportVisibility() {
    final visible = !_covered && _foreground;
    if (visible == _reportedVisible || !mounted) return;
    _reportedVisible = visible;
    context.read<DuelArenaBloc>().add(ArenaVisibilityChanged(visible: visible));
  }

  Future<void> _onQuickMatch() async {
    final topic = await DuelTopicPickerSheet.show(
      context,
      purpose: DuelTopicPurpose.matchmake,
    );
    if (topic == null || !mounted) return;
    await context.push(AppRoutes.duelMatchmaking, extra: topic);
  }

  Future<void> _onCreate() async {
    final bloc = context.read<DuelArenaBloc>();
    final topic = await DuelTopicPickerSheet.show(
      context,
      purpose: DuelTopicPurpose.create,
    );
    if (topic == null || bloc.isClosed) return;
    bloc.add(ChallengeCreateRequested(topic));
  }

  void _onSignIn() => context.push(AppRoutes.saveProgress);

  void _onNotice(BuildContext context, DuelArenaReady state) {
    final notice = state.notice;
    if (notice == null) return;
    context.read<DuelArenaBloc>().add(const NoticeConsumed());
    // A guest tapping Join / Create gets the sign-in sheet itself, not a
    // snackbar about it.
    if (notice is SignInRequiredNotice) {
      _onSignIn();
      return;
    }
    final (title, intent) = _noticeCopy(AppLocalizations.of(context), notice);
    AppSnackbar.show(context, title: title, intent: intent);
  }

  void _onIncoming() {
    if (context.read<SettingsRepository>().current.hapticsOn) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final arena = context.arena;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: MultiBlocListener(
        listeners: [
          BlocListener<DuelArenaBloc, DuelArenaState>(
            listenWhen: (previous, current) =>
                current is DuelArenaReady &&
                current.startDuelId != null &&
                (previous is! DuelArenaReady ||
                    previous.startDuelId != current.startDuelId),
            listener: (context, state) {
              final duelId = (state as DuelArenaReady).startDuelId;
              if (duelId != null) {
                context.push(AppRoutes.duelPlayPath(duelId));
              }
            },
          ),
          BlocListener<DuelArenaBloc, DuelArenaState>(
            listenWhen: (previous, current) =>
                current is DuelArenaReady &&
                current.notice != null &&
                (previous is! DuelArenaReady ||
                    previous.noticeSeq != current.noticeSeq),
            listener: (context, state) =>
                _onNotice(context, state as DuelArenaReady),
          ),
          BlocListener<DuelArenaBloc, DuelArenaState>(
            listenWhen: (previous, current) =>
                current is DuelArenaReady &&
                current.incoming != null &&
                (previous is! DuelArenaReady ||
                    previous.incoming?.requestId !=
                        current.incoming?.requestId),
            listener: (context, state) => _onIncoming(),
          ),
        ],
        child: Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: arena.lite),
            child: SafeArea(
              bottom: false,
              child: BlocBuilder<DuelArenaBloc, DuelArenaState>(
                builder: (context, state) => _ArenaLayout(
                  state: state,
                  onQuickMatch: _onQuickMatch,
                  onCreate: _onCreate,
                  onSignIn: _onSignIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The arena's column: top bar, Quick match, the incoming banner, the feed,
/// the Rejoin banner and the composer.
class _ArenaLayout extends StatelessWidget {
  const _ArenaLayout({
    required this.state,
    required this.onQuickMatch,
    required this.onCreate,
    required this.onSignIn,
  });

  final DuelArenaState state;
  final VoidCallback onQuickMatch;
  final VoidCallback onCreate;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DuelArenaBloc>();
    final current = state;
    final ready = current is DuelArenaReady ? current : null;
    final activeDuelId = ready?.activeDuelId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ArenaTopBar(
          onClose: () => context.pop(),
          isLive: ready?.isLive ?? true,
          onlineCount: ready != null && ready.config.presenceEnabled
              ? ready.onlineCount
              : null,
        ),
        QuickMatchCard(onFind: onQuickMatch),
        if (ready != null)
          IncomingRequestBanner(
            request: ready.incoming,
            now: ready.now,
            window: Duration(seconds: ready.config.joinWindowSeconds),
            topicName: _incomingTopicName(ready),
            isBusy: ready.isBusy,
            onAccept: () => bloc.add(const IncomingAccepted()),
            onDecline: () => bloc.add(const IncomingDeclined()),
          ),
        Expanded(
          child: switch (current) {
            DuelArenaLoading() => const ChallengeFeed.loading(),
            DuelArenaFailed(:final error) => _ArenaError(
              errorCode: error.code,
              onRetry: () => bloc.add(const ArenaRetryRequested()),
            ),
            DuelArenaReady() => ChallengeFeed(
              ready: current,
              onJoin: (id) => bloc.add(JoinRequested(id)),
              onWithdraw: (id) => bloc.add(JoinWithdrawn(id)),
              onCancel: () => bloc.add(const ChallengeCancelRequested()),
              onCreate: onCreate,
            ),
          },
        ),
        if (activeDuelId != null)
          RejoinDuelBanner(
            onRejoin: () => context.push(AppRoutes.duelPlayPath(activeDuelId)),
          ),
        if (ready != null)
          ChallengeComposerBar(
            composer: ready.composerState,
            now: ready.now,
            config: ready.config,
            isBusy: ready.isBusy,
            onCreate: onCreate,
            onSignIn: onSignIn,
          )
        else
          SafeArea(top: false, child: SizedBox(height: AppSpacing.md.h)),
      ],
    );
  }

  static String _incomingTopicName(DuelArenaReady ready) {
    final challengeId = ready.incoming?.challengeId;
    for (final challenge in ready.challenges) {
      if (challenge.id == challengeId) return challenge.topic.name;
    }
    return '';
  }
}

class _ArenaError extends StatelessWidget {
  const _ArenaError({required this.errorCode, required this.onRetry});

  final String? errorCode;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ErrorStateView(
      title: l10n.contentErrorTitle,
      emoji: '⚔️',
      message: l10n.contentErrorBody,
      errorCode: errorCode,
      action: ChunkyButton.ghost(label: l10n.commonRetry, onPressed: onRetry),
    );
  }
}

/// A notice's snackbar copy and intent.
(String, SnackbarIntent) _noticeCopy(
  AppLocalizations l10n,
  ArenaNotice notice,
) => switch (notice) {
  CooldownNotice(:final remaining) => (
    l10n.duelNoticeCooldown(remaining.clockLabel(l10n.localeName)),
    SnackbarIntent.warning,
  ),
  AlreadyOpenNotice() => (l10n.duelNoticeAlreadyOpen, SnackbarIntent.warning),
  DailyCapNotice() => (l10n.duelNoticeDailyCap, SnackbarIntent.warning),
  TooManyRequestsNotice(:final max) => (
    l10n.duelNoticeTooManyRequests(max),
    SnackbarIntent.warning,
  ),
  RateLimitedNotice() => (l10n.duelNoticeRateLimited, SnackbarIntent.warning),
  CreatorAwayNotice(:final creator) => (
    l10n.duelNoticeCreatorAway(creator.displayName(l10n)),
    SnackbarIntent.info,
  ),
  ChallengeGoneNotice() => (l10n.duelNoticeChallengeGone, SnackbarIntent.info),
  DeclinedNotice(:final creator) => (
    l10n.duelNoticeDeclined(creator.displayName(l10n)),
    SnackbarIntent.info,
  ),
  NoResponseNotice(:final creator) => (
    l10n.duelNoticeNoResponse(creator.displayName(l10n)),
    SnackbarIntent.info,
  ),
  TakenByOtherNotice(:final creator) => (
    l10n.duelNoticeTakenByOther(creator.displayName(l10n)),
    SnackbarIntent.info,
  ),
  RequesterBusyNotice(:final requester) => (
    l10n.duelNoticeRequesterBusy(requester.displayName(l10n)),
    SnackbarIntent.info,
  ),
  OpponentNoShowNotice() => (
    l10n.duelNoticeOpponentNoShow,
    SnackbarIntent.info,
  ),
  TopicUnavailableNotice() => (
    l10n.duelNoticeTopicUnavailable,
    SnackbarIntent.warning,
  ),
  SignInRequiredNotice() => (
    l10n.duelNoticeSignInRequired,
    SnackbarIntent.info,
  ),
  AlreadyInDuelNotice() => (l10n.duelComposerInDuel, SnackbarIntent.info),
  GenericErrorNotice() => (l10n.duelNoticeGeneric, SnackbarIntent.error),
};
