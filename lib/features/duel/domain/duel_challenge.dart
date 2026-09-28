import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';
import 'package:quizoo/features/duel/domain/duel_topic.dart';

part 'duel_challenge.freezed.dart';
part 'duel_challenge.g.dart';

/// Where a challenge is in its server-side lifecycle (plan 017, "Challenge
/// lifecycle"). Expired, cancelled and finished challenges are deleted, not
/// given a status, so these are the only two a client ever sees.
enum ChallengeStatus { open, matched }

/// One card in the Duel Arena's live feed — the server's
/// `_duel_challenge_card` snapshot, needing no joins to render.
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
  }) = _DuelChallenge;

  factory DuelChallenge.fromJson(Map<String, dynamic> json) =>
      _$DuelChallengeFromJson(json);
}
