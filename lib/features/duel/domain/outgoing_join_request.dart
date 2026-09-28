import 'package:freezed_annotation/freezed_annotation.dart';

part 'outgoing_join_request.freezed.dart';
part 'outgoing_join_request.g.dart';

/// Where one of the player's own join requests stands.
///
/// [unavailable] is client-side only: it is what any status the server adds
/// later decodes to, so an older build degrades to "not joinable" rather than
/// failing to parse.
enum JoinRequestStatus {
  queued,
  pending,
  accepted,
  declined,
  expired,
  withdrawn,
  unavailable,
}

/// The player's own request to join someone else's challenge — the server's
/// `join_request_status` payload.
///
/// [position] is 1-based while [JoinRequestStatus.queued]; [expiresAt] is the
/// creator's decision deadline while [JoinRequestStatus.pending]; and
/// [retryAfter] is when a declined/expired request may be sent again.
@freezed
abstract class OutgoingJoinRequest with _$OutgoingJoinRequest {
  const factory OutgoingJoinRequest({
    required String requestId,
    required String challengeId,
    @JsonKey(unknownEnumValue: JoinRequestStatus.unavailable)
    required JoinRequestStatus status,
    int? position,
    DateTime? expiresAt,
    DateTime? retryAfter,
    String? reason,
  }) = _OutgoingJoinRequest;

  const OutgoingJoinRequest._();

  factory OutgoingJoinRequest.fromJson(Map<String, dynamic> json) =>
      _$OutgoingJoinRequestFromJson(json);

  /// Still waiting on the creator — queued or being decided.
  bool get isActive =>
      status == JoinRequestStatus.queued || status == JoinRequestStatus.pending;
}
