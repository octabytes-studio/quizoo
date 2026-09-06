import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend.freezed.dart';
part 'friend.g.dart';

/// S-31's three row kinds: an incoming request, an online friend (who gets a
/// live duel pill), and an offline one (whose pill is present but dimmed).
enum FriendStatus { pending, online, offline }

/// One row of the Friends screen.
///
/// A small, extra domain model beyond this plan's own Design overview list —
/// flagged here rather than silently added: requests and friends need a
/// shape (`status`, a duel affordance) that neither [LeaderboardEntry] nor
/// [LeagueStanding] carries.
@freezed
abstract class Friend with _$Friend {
  const factory Friend({
    required String id,
    required String name,
    required String avatarEmoji,
    required FriendStatus status,

    /// "Level 22 · Gold League" for a request, "🟢 Playing Cricket now" or
    /// "Last seen 2h ago · 142k pts" for a friend — precomputed by the
    /// fixture, since it is presentation copy over otherwise-identical data.
    required String subtitle,
  }) = _Friend;

  factory Friend.fromJson(Map<String, dynamic> json) => _$FriendFromJson(json);
}
