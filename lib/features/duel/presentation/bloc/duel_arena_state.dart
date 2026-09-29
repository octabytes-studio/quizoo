part of 'duel_arena_bloc.dart';

/// S-38's states (CLAUDE.md §3).
sealed class DuelArenaState extends Equatable {
  const DuelArenaState();

  @override
  List<Object?> get props => const [];
}

/// Loading the lobby snapshot.
final class DuelArenaLoading extends DuelArenaState {
  const DuelArenaLoading();
}

/// The lobby snapshot could not be loaded.
final class DuelArenaFailed extends DuelArenaState {
  const DuelArenaFailed(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.code, error.message];
}

/// The live arena: the snapshot with Realtime deltas applied on top.
final class DuelArenaReady extends DuelArenaState {
  const DuelArenaReady({
    required this.config,
    required this.me,
    required this.challenges,
    required this.now,
    this.recentlyEnded = const [],
    this.outgoing = const {},
    this.incoming,
    this.onlineCount = 0,
    this.isLive = true,
    this.isBusy = false,
    this.notice,
    this.noticeSeq = 0,
    this.startDuelId,
    this.activeDuelId,
    this.notThisTimeUntil = const {},
  });

  final DuelConfig config;
  final DuelLobbyMe me;

  /// Oldest first — the chat-style feed renders the newest at the bottom.
  final List<DuelChallenge> challenges;

  /// Cancelled, expired or finished within the last 7 days, newest-ended
  /// first. Only ever refreshed by re-fetching the snapshot (no Realtime
  /// deltas), except for the optimistic entry [_remove] adds the moment a
  /// live card disappears.
  final List<DuelChallenge> recentlyEnded;

  /// The viewer's own join requests, by challenge id.
  final Map<String, OutgoingJoinRequest> outgoing;

  /// The request presented on the viewer's own challenge, if any.
  final IncomingJoinRequest? incoming;

  /// Players on the arena right now (Realtime Presence).
  final int onlineCount;

  /// False after the lobby/inbox channels dropped, until they re-subscribe.
  final bool isLive;

  /// Server time as of the last tick.
  final DateTime now;

  /// A create/cancel/respond call is in flight.
  final bool isBusy;

  /// The snackbar to show, paired with [noticeSeq] so the same notice twice
  /// in a row still shows twice.
  final ArenaNotice? notice;
  final int noticeSeq;

  /// Set once a duel with the viewer in it starts: the screen opens it.
  final String? startDuelId;

  /// A duel the viewer is still in (the Rejoin banner).
  final String? activeDuelId;

  /// Challenge id → when its card stops saying "Not this time" and starts
  /// the retry countdown (local, 2 s after the decline/expiry arrived).
  final Map<String, DateTime> notThisTimeUntil;

  bool get isGuest => me.isGuest || me.player.isGuest;

  bool _isMine(DuelChallenge challenge) => challenge.creator.id == me.player.id;

  /// The viewer's own open challenge, if one is in the feed.
  DuelChallenge? get ownOpenChallenge {
    for (final challenge in challenges) {
      if (_isMine(challenge) && challenge.status == ChallengeStatus.open) {
        return challenge;
      }
    }
    return null;
  }

  /// Anything that needs the lobby heartbeat (A10): an own open challenge or
  /// a request still waiting on a creator.
  bool get needsHeartbeat =>
      ownOpenChallenge != null || outgoing.values.any((r) => r.isActive);

  /// [challenges] plus [recentlyEnded], oldest first — the feed's single
  /// chronological timeline. Ended cards render further back (dimmed,
  /// non-interactive) rather than in their own section.
  List<DuelChallenge> get feedItems {
    if (recentlyEnded.isEmpty) return challenges;
    final combined = [...recentlyEnded, ...challenges]
      ..sort((a, b) {
        final byTime = a.createdAt.compareTo(b.createdAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    return combined;
  }

  /// The card state for [challenge] (plan 017's card-state table).
  ChallengeCardState cardStateFor(DuelChallenge challenge) {
    if (challenge.status == ChallengeStatus.ended) {
      return ChallengeCardEnded(endReason: challenge.endReason);
    }
    if (_isMine(challenge)) {
      return ChallengeCardOwn(paused: !challenge.creatorPresent);
    }
    if (challenge.status == ChallengeStatus.matched) {
      return ChallengeCardInProgress(
        opponentName: challenge.opponentName,
        opponentGuestTag: challenge.opponentGuestTag,
      );
    }
    final request = outgoing[challenge.id];
    if (request != null && request.isActive) {
      return switch (request.status) {
        JoinRequestStatus.pending => ChallengeCardPending(
          expiresAt: request.expiresAt ?? now,
        ),
        _ => ChallengeCardQueued(position: request.position),
      };
    }
    if (!challenge.creatorPresent) return const ChallengeCardAway();
    final retryAt = request?.retryAfter;
    if (retryAt != null && retryAt.isAfter(now)) {
      final shoutUntil = notThisTimeUntil[challenge.id];
      return ChallengeCardCooling(
        retryAt: retryAt,
        justResolved: shoutUntil != null && shoutUntil.isAfter(now),
      );
    }
    return const ChallengeCardOpen();
  }

  /// The fairness hint: |Δelo| ≤ 100 even, creator ≥ +150 tough, ≤ −150
  /// favourable, and even in the grey zone between.
  Fairness fairnessFor(DuelChallenge challenge) {
    final delta = challenge.creator.elo - me.player.elo;
    if (delta.abs() <= 100) return Fairness.even;
    if (delta >= 150) return Fairness.tough;
    if (delta <= -150) return Fairness.favourable;
    return Fairness.even;
  }

  /// What the composer bar offers.
  ComposerState get composerState {
    final duelId = activeDuelId;
    if (duelId != null) return ComposerInDuel(duelId);
    if (isGuest) return const ComposerSignIn();
    final own = ownOpenChallenge;
    if (own != null) return ComposerOwnOpen(own);
    final cooldownEndsAt = me.cooldownEndsAt;
    if (cooldownEndsAt != null && cooldownEndsAt.isAfter(now)) {
      return ComposerCooldown(cooldownEndsAt);
    }
    return const ComposerCreate();
  }

  DuelArenaReady copyWith({
    DuelConfig? config,
    DuelLobbyMe? me,
    List<DuelChallenge>? challenges,
    List<DuelChallenge>? recentlyEnded,
    Map<String, OutgoingJoinRequest>? outgoing,
    IncomingJoinRequest? incoming,
    bool clearIncoming = false,
    int? onlineCount,
    bool? isLive,
    DateTime? now,
    bool? isBusy,
    ArenaNotice? notice,
    bool clearNotice = false,
    int? noticeSeq,
    String? startDuelId,
    String? activeDuelId,
    bool clearActiveDuelId = false,
    Map<String, DateTime>? notThisTimeUntil,
  }) => DuelArenaReady(
    config: config ?? this.config,
    me: me ?? this.me,
    challenges: challenges ?? this.challenges,
    recentlyEnded: recentlyEnded ?? this.recentlyEnded,
    outgoing: outgoing ?? this.outgoing,
    incoming: clearIncoming ? null : (incoming ?? this.incoming),
    onlineCount: onlineCount ?? this.onlineCount,
    isLive: isLive ?? this.isLive,
    now: now ?? this.now,
    isBusy: isBusy ?? this.isBusy,
    notice: clearNotice ? null : (notice ?? this.notice),
    noticeSeq: noticeSeq ?? this.noticeSeq,
    startDuelId: startDuelId ?? this.startDuelId,
    activeDuelId: clearActiveDuelId
        ? null
        : (activeDuelId ?? this.activeDuelId),
    notThisTimeUntil: notThisTimeUntil ?? this.notThisTimeUntil,
  );

  @override
  List<Object?> get props => [
    config,
    me,
    challenges,
    recentlyEnded,
    outgoing,
    incoming,
    onlineCount,
    isLive,
    now,
    isBusy,
    notice,
    noticeSeq,
    startDuelId,
    activeDuelId,
    notThisTimeUntil,
  ];
}
