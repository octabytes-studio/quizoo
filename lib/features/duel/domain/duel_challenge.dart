import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';

part 'duel_challenge.freezed.dart';
part 'duel_challenge.g.dart';

/// Where a challenge is in its server-side lifecycle (plan 017, "Challenge
/// lifecycle"). A challenge that is cancelled, expires, or whose duel ends is
/// deleted from the live table but kept for 7 days in `duel_challenge_history`
/// as `ended` — the only status a `recentlyEnded` card ever carries.
enum ChallengeStatus { open, matched, ended }

/// One card in the Duel Arena's feed — either the server's
/// `_duel_challenge_card` snapshot (live, in `DuelLobbySnapshot.challenges`)
/// or its `_duel_challenge_history_card` counterpart (in
/// `DuelLobbySnapshot.recentlyEnded`, [status] always [ChallengeStatus.ended]
/// with [endReason]/[endedAt] set). Needs no joins to render either way.
@freezed
abstract class DuelChallenge with _$DuelChallenge {
  const factory DuelChallenge({
    required String id,
    required ChallengeStatus status,
    required bool creatorPresent,
    required DateTime createdAt,
    required DateTime expiresAt,
    required DuelPlayer creator,
    required DuelTopic topic,
    String? opponentName,
    String? opponentGuestTag,
    String? duelId,

    /// Why an `ended` card ended: `cancelled`, `expired`, `completed` or
    /// `abandoned`. Null for a live card.
    String? endReason,

    /// When an `ended` card was archived. Null for a live card.
    DateTime? endedAt,
  }) = _DuelChallenge;

  factory DuelChallenge.fromJson(Map<String, dynamic> json) =>
      _$DuelChallengeFromJson(json);
}
