/// One thing a `DuelRealtime` topic stream delivers — the transport-level
/// shape, before a repository decodes it into a feature event.
sealed class DuelBroadcast {
  const DuelBroadcast();
}

/// A database-sent broadcast (`realtime.send`) on the topic.
final class BroadcastMessage extends DuelBroadcast {
  const BroadcastMessage({required this.event, required this.payload});

  final String event;
  final Map<String, dynamic> payload;
}

/// The channel subscribed (`true`) or dropped/errored/closed (`false`).
final class BroadcastStatus extends DuelBroadcast {
  const BroadcastStatus({required this.isLive});

  final bool isLive;
}

/// The channel's Presence state synced — the user ids currently tracked.
final class BroadcastPresence extends DuelBroadcast {
  const BroadcastPresence(this.userIds);

  final Set<String> userIds;
}
