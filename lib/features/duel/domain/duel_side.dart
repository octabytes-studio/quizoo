/// Which seat of a live duel a player occupies — the server stores both
/// players' data as `p1_*`/`p2_*` columns and every room broadcast keeps that
/// shape; clients map it to "me"/"opponent" with their own side (plan 017).
enum DuelSide {
  p1,
  p2;

  /// The other seat.
  DuelSide get other => this == p1 ? p2 : p1;
}
