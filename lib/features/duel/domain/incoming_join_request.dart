import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quizoo/features/duel/domain/duel_player.dart';

part 'incoming_join_request.freezed.dart';
part 'incoming_join_request.g.dart';

/// A join request presented to the challenge's creator — the one at the head
/// of the server-side queue, with a 5-second decision window ending at
/// [expiresAt] (server time). [queuedCount] is how many more are waiting.
@freezed
abstract class IncomingJoinRequest with _$IncomingJoinRequest {
  const factory IncomingJoinRequest({
    required String requestId,
    required String challengeId,
    required DuelPlayer requester,
    required DateTime expiresAt,
    @Default(0) int queuedCount,
  }) = _IncomingJoinRequest;

  factory IncomingJoinRequest.fromJson(Map<String, dynamic> json) =>
      _$IncomingJoinRequestFromJson(json);
}
