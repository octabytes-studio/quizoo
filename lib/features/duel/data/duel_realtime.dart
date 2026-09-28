import 'dart:async';

import 'package:quizoo/features/duel/data/duel_broadcast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The duel feature's one door onto Supabase Realtime (plan 017).
///
/// Holds **one private channel per topic, ref-counted**: the arena,
/// matchmaking and live-duel screens are stacked routes that all listen to
/// the same `duel-user:<uid>` inbox, and joining that topic twice would
/// duplicate every event. The first [watch] of a topic opens the channel;
/// the last cancel removes it.
///
/// Clients only ever *receive* broadcasts and *track* presence — every
/// broadcast is sent by the database, and `realtime.messages` RLS refuses
/// client publishes (plan 017, Phase 2).
class DuelRealtime {
  DuelRealtime(this._client);

  final SupabaseClient _client;
  final Map<String, _TopicHandle> _topics = {};

  // ------------------------------------------------------------ topics

  /// The arena feed for one content language.
  static String lobby(String languageCode) => 'duel-lobby:$languageCode';

  /// One player's personal inbox.
  static String inbox(String userId) => 'duel-user:$userId';

  /// One live duel's room.
  static String room(String duelId) => 'duel:$duelId';

  // ------------------------------------------------------------ events
  // Mirrors the event names the SQL sends (plan 017, "Broadcast events").

  static const String challengeUpsert = 'challenge_upsert';
  static const String challengeRemove = 'challenge_remove';
  static const String joinRequest = 'join_request';
  static const String joinRequestCleared = 'join_request_cleared';
  static const String joinRequestStatus = 'join_request_status';
  static const String duelStart = 'duel_start';
  static const String roundStart = 'round_start';
  static const String answerLocked = 'answer_locked';
  static const String roundResult = 'round_result';
  static const String duelEnd = 'duel_end';
  static const String rematch = 'rematch';

  static const List<String> lobbyEvents = [challengeUpsert, challengeRemove];

  static const List<String> inboxEvents = [
    joinRequest,
    joinRequestCleared,
    joinRequestStatus,
    duelStart,
  ];

  static const List<String> roomEvents = [
    roundStart,
    answerLocked,
    roundResult,
    duelEnd,
    rematch,
  ];

  /// The signed-in (possibly anonymous guest) user, or null with no session.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Every broadcast named in [events] on [topic], plus the channel's
  /// subscribe status and (when [trackPresence]) its Presence roster.
  ///
  /// A late listener to an already-open topic immediately receives the last
  /// known status and presence, so it never waits for the next change.
  Stream<DuelBroadcast> watch(
    String topic, {
    required List<String> events,
    bool trackPresence = false,
  }) {
    final wanted = events.toSet();
    StreamSubscription<DuelBroadcast>? subscription;
    late final StreamController<DuelBroadcast> controller;
    controller = StreamController<DuelBroadcast>(
      onListen: () {
        final handle = _acquire(topic, wanted, trackPresence: trackPresence);
        final lastStatus = handle.lastStatus;
        if (lastStatus != null) controller.add(lastStatus);
        final lastPresence = handle.lastPresence;
        if (lastPresence != null) controller.add(lastPresence);
        subscription = handle.controller.stream.listen((broadcast) {
          if (broadcast is BroadcastMessage &&
              !wanted.contains(broadcast.event)) {
            return;
          }
          controller.add(broadcast);
        });
      },
      onCancel: () async {
        await subscription?.cancel();
        await _release(topic);
      },
    );
    return controller.stream;
  }

  _TopicHandle _acquire(
    String topic,
    Set<String> events, {
    required bool trackPresence,
  }) {
    final existing = _topics[topic];
    if (existing != null) {
      existing.listeners++;
      _bindEvents(existing, events);
      if (trackPresence && !existing.tracksPresence) {
        existing.tracksPresence = true;
        if (existing.lastStatus?.isLive ?? false) unawaited(_track(existing));
      }
      return existing;
    }

    final channel = _client.channel(
      topic,
      opts: RealtimeChannelConfig(private: true, key: currentUserId ?? ''),
    );
    final handle = _TopicHandle(
      channel: channel,
      controller: StreamController<DuelBroadcast>.broadcast(),
      tracksPresence: trackPresence,
    );
    _topics[topic] = handle;
    _bindEvents(handle, events);
    channel
      ..onPresenceSync((_) {
        final roster = BroadcastPresence({
          for (final entry in channel.presenceState()) entry.key,
        });
        handle
          ..lastPresence = roster
          ..emit(roster);
      })
      ..subscribe((status, _) {
        final isLive = status == RealtimeSubscribeStatus.subscribed;
        final update = BroadcastStatus(isLive: isLive);
        handle
          ..lastStatus = update
          ..emit(update);
        if (isLive && handle.tracksPresence) unawaited(_track(handle));
      });
    return handle;
  }

  void _bindEvents(_TopicHandle handle, Set<String> events) {
    for (final event in events.difference(handle.boundEvents)) {
      handle.boundEvents.add(event);
      handle.channel.onBroadcast(
        event: event,
        callback: (message) => handle.emit(
          BroadcastMessage(event: event, payload: _innerPayload(message)),
        ),
      );
    }
  }

  Future<void> _track(_TopicHandle handle) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await handle.channel.track({'userId': userId});
    } on Object {
      // Presence is a UI nicety (plan 017, A10) — a failed track never
      // breaks the feature.
    }
  }

  Future<void> _release(String topic) async {
    final handle = _topics[topic];
    if (handle == null) return;
    handle.listeners--;
    if (handle.listeners > 0) return;
    _topics.remove(topic);
    await handle.controller.close();
    try {
      await _client.removeChannel(handle.channel);
    } on Object {
      // Already gone — nothing left to clean up.
    }
  }

  /// A broadcast callback receives the whole message
  /// (`{type, event, payload}`); the database's JSON is under `payload`.
  static Map<String, dynamic> _innerPayload(Map<String, dynamic> message) {
    final inner = message['payload'];
    if (inner is Map) return Map<String, dynamic>.from(inner);
    return message;
  }
}

class _TopicHandle {
  _TopicHandle({
    required this.channel,
    required this.controller,
    required this.tracksPresence,
  });

  final RealtimeChannel channel;
  final StreamController<DuelBroadcast> controller;
  final Set<String> boundEvents = {};
  bool tracksPresence;
  int listeners = 1;
  BroadcastStatus? lastStatus;
  BroadcastPresence? lastPresence;

  void emit(DuelBroadcast broadcast) {
    if (!controller.isClosed) controller.add(broadcast);
  }
}
