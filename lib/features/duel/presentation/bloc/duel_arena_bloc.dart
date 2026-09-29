import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/data/duel_arena_repository.dart';
import 'package:quizoo/features/duel/data/server_clock.dart';
import 'package:quizoo/features/duel/domain/duel_challenge.dart';
import 'package:quizoo/features/duel/domain/duel_config.dart';
import 'package:quizoo/features/duel/domain/duel_lobby_me.dart';
import 'package:quizoo/features/duel/domain/duel_lobby_snapshot.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';
import 'package:quizoo/features/duel/domain/incoming_join_request.dart';
import 'package:quizoo/features/duel/domain/lobby_event.dart';
import 'package:quizoo/features/duel/domain/outgoing_join_request.dart';
import 'package:quizoo/features/duel/presentation/bloc/arena_notice.dart';
import 'package:quizoo/features/duel/presentation/bloc/challenge_card_state.dart';
import 'package:quizoo/features/duel/presentation/bloc/composer_state.dart';
import 'package:quizoo/features/duel/presentation/bloc/fairness.dart';

part 'duel_arena_event.dart';
part 'duel_arena_state.dart';

/// S-38 — the Duel Arena's state machine (plan 017, Phase 8).
///
/// Snapshot + deltas: [ArenaOpened] loads `get_duel_lobby`, then applies the
/// lobby and inbox broadcasts on top, and re-fetches the snapshot whenever
/// the channels (re-)subscribe so a missed message self-heals. A 1-second
/// ticker drives every countdown from the shared [ServerClock], and a lobby
/// heartbeat keeps the viewer's own challenge "Live" and their requests
/// alive — only while the arena is visible and there is something to keep
/// alive (A10).
///
/// Pure Dart (CLAUDE.md §3): visibility comes in as [ArenaVisibilityChanged]
/// from the screen's route/lifecycle plumbing, and navigation happens in the
/// screen's `BlocListener` off [DuelArenaReady.startDuelId].
class DuelArenaBloc extends Bloc<DuelArenaEvent, DuelArenaState> {
  DuelArenaBloc(this._repository, this._clock, {required this.languageCode})
    : super(const DuelArenaLoading()) {
    on<ArenaOpened>(_onOpened);
    on<ArenaRetryRequested>(_onRetryRequested);
    on<ArenaVisibilityChanged>(_onVisibilityChanged);
    on<ArenaServerEvent>(_onServerEvent);
    on<ArenaTicked>(_onTicked);
    on<ChallengeCreateRequested>(_onCreateRequested);
    on<ChallengeCancelRequested>(_onCancelRequested);
    on<JoinRequested>(_onJoinRequested);
    on<JoinWithdrawn>(_onJoinWithdrawn);
    on<IncomingAccepted>(_onIncomingAccepted);
    on<IncomingDeclined>(_onIncomingDeclined);
    on<IncomingTimedOut>(_onIncomingTimedOut);
    on<NoticeConsumed>(_onNoticeConsumed);
  }

  /// The feed shows at most this many challenges, dropping the oldest (A11).
  /// Mirrors the server's `lobby_feed_limit`, which the lobby config does not
  /// expose.
  static const int feedLimit = 50;

  /// Mirrors the server's `join_max_outstanding` default (Q2), for the
  /// "up to {max} challenges at once" notice.
  static const int maxOutstandingRequests = 3;

  /// How long a declined/lapsed request's card says "Not this time" before
  /// switching to the retry countdown.
  static const Duration notThisTimeFor = Duration(seconds: 2);

  static const Duration tickInterval = Duration(seconds: 1);

  final DuelArenaRepository _repository;
  final ServerClock _clock;

  /// The content language the arena was opened in. Read once: the arena is a
  /// full-screen route, so it can't change underneath it.
  final String languageCode;

  StreamSubscription<LobbyEvent>? _events;
  Timer? _ticker;
  Timer? _heartbeat;

  /// Whether the arena is the visible, foreground route.
  bool _visible = true;

  /// The channels have been live at least once since the arena opened.
  bool _everLive = false;

  /// They dropped after having been live, so the next "live" means
  /// messages may have been missed.
  bool _droppedSinceLive = false;

  /// Incoming requests already answered (or timed out) — each is answered
  /// exactly once.
  final Set<String> _respondedRequestIds = {};

  /// Incoming requests whose timeout was already dispatched.
  final Set<String> _timeoutDispatched = {};

  /// Challenges withdrawn while their join request was still in flight.
  final Set<String> _withdrawOnArrival = {};

  /// Every creator seen, by challenge id — so a notice can still name them
  /// after their card has gone.
  final Map<String, DuelPlayer> _knownCreators = {};

  // ------------------------------------------------------------ lifecycle

  Future<void> _onOpened(
    ArenaOpened event,
    Emitter<DuelArenaState> emit,
  ) async {
    _visible = true;
    await _load(emit);
  }

  Future<void> _onRetryRequested(
    ArenaRetryRequested event,
    Emitter<DuelArenaState> emit,
  ) async {
    if (state is! DuelArenaFailed) return;
    emit(const DuelArenaLoading());
    await _load(emit);
  }

  Future<void> _load(Emitter<DuelArenaState> emit) async {
    final DuelLobbySnapshot snapshot;
    try {
      snapshot = await _repository.fetchLobby(languageCode);
    } on ApiException catch (error) {
      emit(DuelArenaFailed(error));
      return;
    }
    final ready = _fromSnapshot(snapshot);
    emit(ready);
    _startLive(ready.config);
    unawaited(_setPresence(present: true));
  }

  void _startLive(DuelConfig config) {
    _events ??= _repository
        .events(languageCode, trackPresence: config.presenceEnabled)
        .listen((event) {
          if (!isClosed) add(ArenaServerEvent(event));
        });
    _ticker ??= Timer.periodic(tickInterval, (_) {
      if (!isClosed) add(const ArenaTicked());
    });
    _startHeartbeat(config);
  }

  void _startHeartbeat(DuelConfig config) {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(
      Duration(seconds: max(1, config.lobbyHeartbeatSeconds)),
      (_) => _beat(),
    );
  }

  void _beat() {
    final current = state;
    if (_visible && current is DuelArenaReady && current.needsHeartbeat) {
      unawaited(_setPresence(present: true));
    }
  }

  Future<void> _setPresence({required bool present}) async {
    try {
      await _repository.setPresence(present: present);
    } on ApiException {
      // Best-effort: the next heartbeat, or the server's sweeper, corrects it.
    }
  }

  Future<void> _onVisibilityChanged(
    ArenaVisibilityChanged event,
    Emitter<DuelArenaState> emit,
  ) async {
    if (event.visible == _visible) return;
    _visible = event.visible;
    final current = state;

    if (!event.visible) {
      _heartbeat?.cancel();
      _heartbeat = null;
      unawaited(_setPresence(present: false));
      // Going away withdraws the viewer's requests server-side; mirror it.
      if (current is DuelArenaReady) {
        emit(
          current.copyWith(
            outgoing: const {},
            notThisTimeUntil: const {},
            clearIncoming: true,
          ),
        );
      }
      return;
    }

    unawaited(_setPresence(present: true));
    if (current is DuelArenaReady) {
      _startHeartbeat(current.config);
      await _refresh(emit);
    }
  }

  /// Re-fetches the snapshot over the current [DuelArenaReady], keeping the
  /// local-only fields. A failure keeps what is on screen.
  Future<void> _refresh(Emitter<DuelArenaState> emit) async {
    try {
      final snapshot = await _repository.fetchLobby(languageCode);
      final current = state;
      if (current is! DuelArenaReady) return;
      emit(_fromSnapshot(snapshot, previous: current));
    } on ApiException {
      // The next re-subscribe or visibility change tries again.
    }
  }

  DuelArenaReady _fromSnapshot(
    DuelLobbySnapshot snapshot, {
    DuelArenaReady? previous,
  }) {
    for (final challenge in snapshot.challenges) {
      _knownCreators[challenge.id] = challenge.creator;
    }

    final outgoing = <String, OutgoingJoinRequest>{};
    for (final request in snapshot.myRequests) {
      final existing = outgoing[request.challengeId];
      if (existing == null || !existing.isActive) {
        outgoing[request.challengeId] = request;
      }
    }
    // Keep requests still in flight — the server may not have them yet.
    previous?.outgoing.forEach((challengeId, request) {
      if (request.requestId.isEmpty) {
        outgoing.putIfAbsent(challengeId, () => request);
      }
    });

    final incoming = snapshot.incoming;
    final unanswered =
        incoming != null && !_respondedRequestIds.contains(incoming.requestId)
        ? incoming
        : null;

    return DuelArenaReady(
      config: snapshot.config,
      me: snapshot.me,
      challenges: _ordered(snapshot.challenges, snapshot.me.player.id),
      recentlyEnded: snapshot.recentlyEnded.take(feedLimit).toList(),
      outgoing: outgoing,
      incoming: unanswered,
      now: _clock.now(),
      activeDuelId: snapshot.me.activeDuelId,
      onlineCount: previous?.onlineCount ?? 0,
      isLive: previous?.isLive ?? true,
      isBusy: previous?.isBusy ?? false,
      notice: previous?.notice,
      noticeSeq: previous?.noticeSeq ?? 0,
      startDuelId: previous?.startDuelId,
      notThisTimeUntil: {
        for (final entry
            in (previous?.notThisTimeUntil ?? const <String, DateTime>{})
                .entries)
          if (outgoing.containsKey(entry.key)) entry.key: entry.value,
      },
    );
  }

  /// Oldest first, capped at [feedLimit] by dropping the oldest — never the
  /// viewer's own challenge.
  static List<DuelChallenge> _ordered(
    Iterable<DuelChallenge> challenges,
    String myId,
  ) {
    final sorted = challenges.toList()
      ..sort((a, b) {
        final byTime = a.createdAt.compareTo(b.createdAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    var overflow = sorted.length - feedLimit;
    if (overflow <= 0) return sorted;
    final kept = <DuelChallenge>[];
    for (final challenge in sorted) {
      if (overflow > 0 && challenge.creator.id != myId) {
        overflow--;
        continue;
      }
      kept.add(challenge);
    }
    return kept;
  }

  // ------------------------------------------------------- server events

  Future<void> _onServerEvent(
    ArenaServerEvent event,
    Emitter<DuelArenaState> emit,
  ) async {
    final current = state;
    if (current is! DuelArenaReady) return;

    switch (event.event) {
      case ChallengeUpserted(:final challenge):
        _upsert(current, challenge, emit);
      case ChallengeRemoved(:final challengeId):
        _remove(current, challengeId, emit);
      case IncomingRequestPresented(:final request):
        if (_respondedRequestIds.contains(request.requestId)) return;
        emit(current.copyWith(incoming: request));
      case IncomingRequestCleared(:final requestId):
        if (current.incoming?.requestId == requestId) {
          emit(current.copyWith(clearIncoming: true));
        }
      case OutgoingRequestChanged(:final request):
        _applyOutgoing(current, request, emit);
      case DuelStarted(:final duelId):
        // Only the visible arena opens the duel: when matchmaking or a duel
        // is stacked on top, that screen handles its own inbox (and the
        // snapshot re-fetched on return shows the Rejoin banner if needed).
        if (_visible) {
          emit(current.copyWith(startDuelId: duelId, clearIncoming: true));
        }
      case LobbyChannelStatusChanged(:final isLive):
        // The combined status reports `false` while the two channels are
        // still joining, then `true` once both are. Only a drop *after* that
        // first `true` is a real reconnect: show "Reconnecting…" for it, and
        // heal whatever it missed by re-fetching once live again.
        final healsDrop = isLive && _droppedSinceLive;
        if (isLive) {
          _everLive = true;
          _droppedSinceLive = false;
        } else if (_everLive) {
          _droppedSinceLive = true;
        }
        emit(current.copyWith(isLive: isLive || !_everLive));
        if (healsDrop) await _refresh(emit);
      case LobbyPresenceChanged(:final count):
        emit(current.copyWith(onlineCount: count));
    }
  }

  void _upsert(
    DuelArenaReady current,
    DuelChallenge challenge,
    Emitter<DuelArenaState> emit,
  ) {
    _knownCreators[challenge.id] = challenge.creator;
    final previous = current.challenges
        .where((c) => c.id == challenge.id)
        .firstOrNull;
    final myId = current.me.player.id;
    final isMine = challenge.creator.id == myId;

    var next = current.copyWith(
      challenges: _ordered([
        for (final c in current.challenges)
          if (c.id != challenge.id) c,
        challenge,
      ], myId),
    );
    if (isMine && challenge.status == ChallengeStatus.open) {
      next = next.copyWith(me: next.me.copyWith(openChallengeId: challenge.id));
    }
    // Matched → open again on the viewer's own challenge means the server
    // abandoned the duel because the opponent never showed up.
    if (isMine &&
        previous?.status == ChallengeStatus.matched &&
        challenge.status == ChallengeStatus.open) {
      next = _withNotice(next, const OpponentNoShowNotice());
    }
    emit(next);
  }

  void _remove(
    DuelArenaReady current,
    String challengeId,
    Emitter<DuelArenaState> emit,
  ) {
    final removed = current.challenges
        .where((c) => c.id == challengeId)
        .firstOrNull;
    if (removed == null) return;

    final isMineOpen = current.me.openChallengeId == challengeId;
    // Optimistic: the card lingers as "ended" using what is already known
    // about it, reconciled by the next snapshot fetch (which has the
    // server's actual endReason).
    final endedEntry = removed.copyWith(
      status: ChallengeStatus.ended,
      endedAt: _clock.now(),
    );
    emit(
      current.copyWith(
        challenges: [
          for (final c in current.challenges)
            if (c.id != challengeId) c,
        ],
        recentlyEnded: [
          endedEntry,
          for (final c in current.recentlyEnded)
            if (c.id != challengeId) c,
        ].take(feedLimit).toList(),
        outgoing: Map.of(current.outgoing)..remove(challengeId),
        notThisTimeUntil: Map.of(current.notThisTimeUntil)..remove(challengeId),
        me: isMineOpen
            ? current.me.copyWith(openChallengeId: null)
            : current.me,
        clearIncoming: current.incoming?.challengeId == challengeId,
      ),
    );
  }

  void _applyOutgoing(
    DuelArenaReady current,
    OutgoingJoinRequest request,
    Emitter<DuelArenaState> emit,
  ) {
    final challengeId = request.challengeId;
    final existing = current.outgoing[challengeId];
    // A late terminal update for an older request must not clobber a newer,
    // still-active one on the same challenge.
    if (existing != null &&
        existing.isActive &&
        existing.requestId.isNotEmpty &&
        existing.requestId != request.requestId &&
        !request.isActive) {
      return;
    }

    final now = _clock.now();
    final outgoing = Map.of(current.outgoing);
    final notThisTime = Map.of(current.notThisTimeUntil);
    ArenaNotice? notice;

    switch (request.status) {
      case JoinRequestStatus.queued || JoinRequestStatus.pending:
        outgoing[challengeId] = request;
        notThisTime.remove(challengeId);
      case JoinRequestStatus.accepted:
        // `duel_start` follows and opens the duel.
        outgoing.remove(challengeId);
        notThisTime.remove(challengeId);
      case JoinRequestStatus.declined ||
          JoinRequestStatus.expired ||
          JoinRequestStatus.withdrawn ||
          JoinRequestStatus.unavailable:
        notice = _noticeForResolved(request);
        final retryAfter = request.retryAfter;
        if (retryAfter != null && retryAfter.isAfter(now)) {
          outgoing[challengeId] = request;
          notThisTime[challengeId] = now.add(notThisTimeFor);
        } else {
          outgoing.remove(challengeId);
          notThisTime.remove(challengeId);
        }
    }

    final next = current.copyWith(
      outgoing: outgoing,
      notThisTimeUntil: notThisTime,
    );
    emit(notice == null ? next : _withNotice(next, notice));
  }

  /// The snackbar for one of the viewer's requests ending, by the server's
  /// `join_request_status` reason first and its status second. Null when
  /// there is nothing to say (the viewer withdrew, left the arena, or is
  /// already in another duel).
  ///
  /// A decline that lands at or after the 5 s window is recorded as status
  /// `expired` with reason `no_response`, so the reason decides.
  ArenaNotice? _noticeForResolved(OutgoingJoinRequest request) {
    final creator = _knownCreators[request.challengeId];
    switch (request.reason) {
      case 'declined':
        return creator == null ? null : DeclinedNotice(creator);
      case 'no_response':
        return creator == null ? null : NoResponseNotice(creator);
      case 'taken':
        return creator == null
            ? const ChallengeGoneNotice()
            : TakenByOtherNotice(creator);
      case 'creator_away':
        return creator == null
            ? const ChallengeGoneNotice()
            : CreatorAwayNotice(creator);
      case 'challenge_gone' || 'expired':
        return const ChallengeGoneNotice();
      case 'withdrawn' || 'requester_left' || 'in_duel' || 'accepted':
        return null;
    }
    return switch (request.status) {
      JoinRequestStatus.declined =>
        creator == null ? null : DeclinedNotice(creator),
      JoinRequestStatus.expired =>
        creator == null ? null : NoResponseNotice(creator),
      JoinRequestStatus.unavailable => const ChallengeGoneNotice(),
      _ => null,
    };
  }

  // ---------------------------------------------------------------- ticker

  void _onTicked(ArenaTicked event, Emitter<DuelArenaState> emit) {
    final current = state;
    if (current is! DuelArenaReady) return;
    final now = _clock.now();

    // The server deletes expired challenges too; this just doesn't wait.
    final challenges = [
      for (final c in current.challenges)
        if (c.status != ChallengeStatus.open || c.expiresAt.isAfter(now)) c,
    ];
    final liveIds = {for (final c in challenges) c.id};
    final outgoing = Map.of(current.outgoing)
      ..removeWhere((challengeId, request) {
        if (!liveIds.contains(challengeId)) return true;
        if (request.isActive) return false;
        final retryAfter = request.retryAfter;
        return retryAfter == null || !retryAfter.isAfter(now);
      });
    final notThisTime = Map.of(current.notThisTimeUntil)
      ..removeWhere((challengeId, until) => !until.isAfter(now));
    final openId = current.me.openChallengeId;

    emit(
      current.copyWith(
        now: now,
        challenges: challenges.length == current.challenges.length
            ? current.challenges
            : challenges,
        outgoing: outgoing,
        notThisTimeUntil: notThisTime,
        me: openId != null && !liveIds.contains(openId)
            ? current.me.copyWith(openChallengeId: null)
            : current.me,
      ),
    );

    // The creator's client auto-declines at 0 s; the sweeper is only the
    // backstop.
    final incoming = current.incoming;
    if (incoming != null &&
        !incoming.expiresAt.isAfter(now) &&
        !_respondedRequestIds.contains(incoming.requestId) &&
        _timeoutDispatched.add(incoming.requestId)) {
      add(const IncomingTimedOut());
    }
  }

  // --------------------------------------------------------- own challenge

  Future<void> _onCreateRequested(
    ChallengeCreateRequested event,
    Emitter<DuelArenaState> emit,
  ) async {
    final current = state;
    if (current is! DuelArenaReady || current.isBusy) return;
    if (current.isGuest) {
      emit(_withNotice(current, const SignInRequiredNotice()));
      return;
    }

    emit(current.copyWith(isBusy: true));
    try {
      final result = await _repository.createChallenge(event.topic.id);
      final latest = state;
      if (latest is! DuelArenaReady) return;
      final challenge = result.challenge;
      _knownCreators[challenge.id] = challenge.creator;
      emit(
        latest.copyWith(
          isBusy: false,
          challenges: _ordered([
            for (final c in latest.challenges)
              if (c.id != challenge.id) c,
            challenge,
          ], latest.me.player.id),
          me: latest.me.copyWith(
            openChallengeId: challenge.id,
            cooldownEndsAt: result.cooldownEndsAt ?? latest.me.cooldownEndsAt,
          ),
        ),
      );
    } on ApiException catch (error) {
      final code = error.code;
      final resyncs =
          code == 'challenge_cooldown' ||
          code == 'challenge_already_open' ||
          code == '23505' ||
          code == 'already_in_duel';
      if (resyncs) await _refresh(emit);
      final latest = state;
      if (latest is! DuelArenaReady) return;
      final notice = switch (code) {
        'challenge_cooldown' => CooldownNotice(_cooldownRemaining(latest)),
        // The partial unique index is the last line of defence against a
        // double-tap race.
        'challenge_already_open' || '23505' => const AlreadyOpenNotice(),
        'challenge_daily_cap' => const DailyCapNotice(),
        'topic_unavailable' => const TopicUnavailableNotice(),
        'guest_cannot_create' => const SignInRequiredNotice(),
        'already_in_duel' => const AlreadyInDuelNotice(),
        _ => GenericErrorNotice(error),
      };
      emit(_withNotice(latest.copyWith(isBusy: false), notice));
    }
  }

  Duration _cooldownRemaining(DuelArenaReady ready) {
    final endsAt = ready.me.cooldownEndsAt;
    if (endsAt != null && endsAt.isAfter(_clock.now())) {
      return _clock.until(endsAt);
    }
    // Unknown locally (a race with another device): the configured cool-off
    // is the upper bound.
    return Duration(seconds: ready.config.cooldownSeconds);
  }

  Future<void> _onCancelRequested(
    ChallengeCancelRequested event,
    Emitter<DuelArenaState> emit,
  ) async {
    final current = state;
    if (current is! DuelArenaReady || current.isBusy) return;
    final own = current.ownOpenChallenge;
    if (own == null) return;

    emit(current.copyWith(isBusy: true));
    try {
      await _repository.cancelChallenge(own.id);
    } on ApiException catch (error) {
      if (error.code != 'challenge_not_found') {
        final latest = state;
        if (latest is DuelArenaReady) {
          emit(
            _withNotice(
              latest.copyWith(isBusy: false),
              GenericErrorNotice(error),
            ),
          );
        }
        return;
      }
      // Already gone server-side — same outcome as a cancel.
    }
    final latest = state;
    if (latest is! DuelArenaReady) return;
    emit(
      latest.copyWith(
        isBusy: false,
        challenges: [
          for (final c in latest.challenges)
            if (c.id != own.id) c,
        ],
        recentlyEnded: [
          own.copyWith(
            status: ChallengeStatus.ended,
            endReason: 'cancelled',
            endedAt: _clock.now(),
          ),
          for (final c in latest.recentlyEnded)
            if (c.id != own.id) c,
        ].take(feedLimit).toList(),
        me: latest.me.copyWith(openChallengeId: null),
        clearIncoming: latest.incoming?.challengeId == own.id,
      ),
    );
  }

  // ---------------------------------------------------- outgoing requests

  Future<void> _onJoinRequested(
    JoinRequested event,
    Emitter<DuelArenaState> emit,
  ) async {
    final current = state;
    if (current is! DuelArenaReady) return;
    final challengeId = event.challengeId;
    final challenge = current.challenges
        .where((c) => c.id == challengeId)
        .firstOrNull;
    if (challenge == null ||
        current.cardStateFor(challenge) is! ChallengeCardOpen) {
      return;
    }

    // Joining someone's challenge needs an account: a guest sees Join, and
    // tapping it opens the sign-in sheet instead (no RPC — the server
    // refuses guests with `guest_cannot_join` too).
    if (current.me.isGuest) {
      emit(_withNotice(current, const SignInRequiredNotice()));
      return;
    }

    // Optimistic: the card flips to "Request sent" before the round trip.
    emit(
      current.copyWith(
        outgoing: {
          ...current.outgoing,
          challengeId: OutgoingJoinRequest(
            requestId: '',
            challengeId: challengeId,
            status: JoinRequestStatus.queued,
          ),
        },
      ),
    );

    try {
      final request = await _repository.requestJoin(challengeId);
      final latest = state;
      if (latest is! DuelArenaReady) return;

      if (_withdrawOnArrival.remove(challengeId)) {
        emit(
          latest.copyWith(
            outgoing: Map.of(latest.outgoing)..remove(challengeId),
          ),
        );
        await _withdraw(request.requestId, emit);
        return;
      }

      // A status broadcast for this same request may have landed first;
      // it is at least as fresh as this response.
      final existing = latest.outgoing[challengeId];
      if (existing != null && existing.requestId == request.requestId) return;
      emit(
        latest.copyWith(outgoing: {...latest.outgoing, challengeId: request}),
      );
    } on ApiException catch (error) {
      _withdrawOnArrival.remove(challengeId);
      if (error.code == 'already_requested') await _refresh(emit);
      final latest = state;
      if (latest is! DuelArenaReady) return;
      final outgoing = Map.of(latest.outgoing);
      if (outgoing[challengeId]?.requestId.isEmpty ?? false) {
        outgoing.remove(challengeId);
      }
      final notice = switch (error.code) {
        'retry_later' ||
        'rate_limited' ||
        'challenge_busy' => const RateLimitedNotice(),
        'too_many_requests' => const TooManyRequestsNotice(
          maxOutstandingRequests,
        ),
        'creator_away' => CreatorAwayNotice(challenge.creator),
        'challenge_unavailable' => const ChallengeGoneNotice(),
        'already_in_duel' => const AlreadyInDuelNotice(),
        'guest_cannot_join' => const SignInRequiredNotice(),
        'already_requested' || 'own_challenge' => null,
        _ => GenericErrorNotice(error),
      };
      final next = latest.copyWith(outgoing: outgoing);
      emit(notice == null ? next : _withNotice(next, notice));
    }
  }

  Future<void> _onJoinWithdrawn(
    JoinWithdrawn event,
    Emitter<DuelArenaState> emit,
  ) async {
    final current = state;
    if (current is! DuelArenaReady) return;
    final request = current.outgoing[event.challengeId];
    if (request == null || !request.isActive) return;

    emit(
      current.copyWith(
        outgoing: Map.of(current.outgoing)..remove(event.challengeId),
      ),
    );
    if (request.requestId.isEmpty) {
      // Still in flight: withdraw as soon as the server hands back its id.
      _withdrawOnArrival.add(event.challengeId);
      return;
    }
    await _withdraw(request.requestId, emit);
  }

  Future<void> _withdraw(String requestId, Emitter<DuelArenaState> emit) async {
    try {
      await _repository.withdrawJoin(requestId);
    } on ApiException catch (error) {
      if (error.code == 'request_not_found') return;
      final latest = state;
      if (latest is DuelArenaReady) {
        emit(_withNotice(latest, GenericErrorNotice(error)));
      }
    }
  }

  // ---------------------------------------------------- incoming request

  Future<void> _onIncomingAccepted(
    IncomingAccepted event,
    Emitter<DuelArenaState> emit,
  ) async {
    final current = state;
    if (current is! DuelArenaReady || current.isBusy) return;
    final incoming = current.incoming;
    if (incoming == null || !_respondedRequestIds.add(incoming.requestId)) {
      return;
    }

    emit(current.copyWith(isBusy: true));
    try {
      final duelId = await _repository.respondJoin(
        incoming.requestId,
        accept: true,
      );
      final latest = state;
      if (latest is! DuelArenaReady) return;
      emit(
        latest.copyWith(
          isBusy: false,
          startDuelId: duelId,
          clearIncoming: latest.incoming?.requestId == incoming.requestId,
        ),
      );
    } on ApiException catch (error) {
      final latest = state;
      if (latest is! DuelArenaReady) return;
      final notice = switch (error.code) {
        'requester_busy' => RequesterBusyNotice(incoming.requester),
        'already_in_duel' => const AlreadyInDuelNotice(),
        'topic_unavailable' => const TopicUnavailableNotice(),
        _ => GenericErrorNotice(error),
      };
      // The server presents the next request in line on its own.
      emit(
        _withNotice(
          latest.copyWith(
            isBusy: false,
            clearIncoming: latest.incoming?.requestId == incoming.requestId,
          ),
          notice,
        ),
      );
    }
  }

  Future<void> _onIncomingDeclined(
    IncomingDeclined event,
    Emitter<DuelArenaState> emit,
  ) => _decline(emit);

  Future<void> _onIncomingTimedOut(
    IncomingTimedOut event,
    Emitter<DuelArenaState> emit,
  ) => _decline(emit);

  Future<void> _decline(Emitter<DuelArenaState> emit) async {
    final current = state;
    if (current is! DuelArenaReady) return;
    final incoming = current.incoming;
    if (incoming == null || !_respondedRequestIds.add(incoming.requestId)) {
      return;
    }

    emit(current.copyWith(clearIncoming: true));
    try {
      await _repository.respondJoin(incoming.requestId, accept: false);
    } on ApiException catch (error) {
      // Already lapsed server-side — which is what a decline wanted anyway.
      if (error.code == 'request_expired' ||
          error.code == 'request_not_found') {
        return;
      }
      final latest = state;
      if (latest is DuelArenaReady) {
        emit(_withNotice(latest, GenericErrorNotice(error)));
      }
    }
  }

  // ---------------------------------------------------------------- notices

  void _onNoticeConsumed(NoticeConsumed event, Emitter<DuelArenaState> emit) {
    final current = state;
    if (current is DuelArenaReady && current.notice != null) {
      emit(current.copyWith(clearNotice: true));
    }
  }

  static DuelArenaReady _withNotice(DuelArenaReady ready, ArenaNotice notice) =>
      ready.copyWith(notice: notice, noticeSeq: ready.noticeSeq + 1);

  @override
  Future<void> close() async {
    _ticker?.cancel();
    _heartbeat?.cancel();
    await _events?.cancel();
    unawaited(_setPresence(present: false));
    return super.close();
  }
}
