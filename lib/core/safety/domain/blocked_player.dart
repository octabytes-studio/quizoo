/// One row of Privacy → Blocked players (plan 025).
class BlockedPlayer {
  const BlockedPlayer({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.blockedAt,
  });

  final String id;
  final String name;
  final String avatarEmoji;
  final DateTime blockedAt;
}
