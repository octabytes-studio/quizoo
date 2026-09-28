import 'package:equatable/equatable.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';

/// A one-shot message the Duel Arena shows as a snackbar (plan 017, Phase 8).
///
/// The Bloc emits these alongside a bumped `noticeSeq`, and the screen's
/// `BlocListener` shows the snackbar and dispatches `NoticeConsumed`.
///
/// Notices that name someone carry the [DuelPlayer] rather than a string:
/// guests are named "Guest 4821" through l10n, which a pure-Dart Bloc cannot
/// reach.
sealed class ArenaNotice extends Equatable {
  const ArenaNotice();

  @override
  List<Object?> get props => const [];
}

/// `challenge_cooldown` — another challenge is allowed in [remaining].
final class CooldownNotice extends ArenaNotice {
  const CooldownNotice(this.remaining);

  final Duration remaining;

  @override
  List<Object?> get props => [remaining];
}

/// `challenge_already_open` — one open challenge per player (A1).
final class AlreadyOpenNotice extends ArenaNotice {
  const AlreadyOpenNotice();
}

/// `challenge_daily_cap`.
final class DailyCapNotice extends ArenaNotice {
  const DailyCapNotice();
}

/// `too_many_requests` — at most [max] outstanding join requests.
final class TooManyRequestsNotice extends ArenaNotice {
  const TooManyRequestsNotice(this.max);

  final int max;

  @override
  List<Object?> get props => [max];
}

/// `rate_limited` / `retry_later` / `challenge_busy`.
final class RateLimitedNotice extends ArenaNotice {
  const RateLimitedNotice();
}

/// The creator stepped off the arena, so the request was dropped (or refused).
final class CreatorAwayNotice extends ArenaNotice {
  const CreatorAwayNotice(this.creator);

  final DuelPlayer creator;

  @override
  List<Object?> get props => [creator];
}

/// The challenge was cancelled, expired or is otherwise gone.
final class ChallengeGoneNotice extends ArenaNotice {
  const ChallengeGoneNotice();
}

/// The creator declined the viewer's request.
final class DeclinedNotice extends ArenaNotice {
  const DeclinedNotice(this.creator);

  final DuelPlayer creator;

  @override
  List<Object?> get props => [creator];
}

/// The creator let the 5-second window lapse.
final class NoResponseNotice extends ArenaNotice {
  const NoResponseNotice(this.creator);

  final DuelPlayer creator;

  @override
  List<Object?> get props => [creator];
}

/// The creator accepted someone else.
final class TakenByOtherNotice extends ArenaNotice {
  const TakenByOtherNotice(this.creator);

  final DuelPlayer creator;

  @override
  List<Object?> get props => [creator];
}

/// `requester_busy` — the requester the viewer accepted is already in a duel.
final class RequesterBusyNotice extends ArenaNotice {
  const RequesterBusyNotice(this.requester);

  final DuelPlayer requester;

  @override
  List<Object?> get props => [requester];
}

/// The viewer's own challenge re-opened because the matched opponent never
/// loaded the duel (the server's no-show abandon).
final class OpponentNoShowNotice extends ArenaNotice {
  const OpponentNoShowNotice();
}

/// `topic_unavailable`.
final class TopicUnavailableNotice extends ArenaNotice {
  const TopicUnavailableNotice();
}

/// A guest tried to create a challenge (Decision 4) — or the server said
/// `guest_cannot_create`.
final class SignInRequiredNotice extends ArenaNotice {
  const SignInRequiredNotice();
}

/// `already_in_duel` — the viewer is already in a duel (the Rejoin banner is
/// the way back into it).
final class AlreadyInDuelNotice extends ArenaNotice {
  const AlreadyInDuelNotice();
}

/// Anything else.
final class GenericErrorNotice extends ArenaNotice {
  const GenericErrorNotice(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.code, error.message];
}
