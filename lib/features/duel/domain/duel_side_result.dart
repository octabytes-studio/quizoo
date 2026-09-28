import 'package:freezed_annotation/freezed_annotation.dart';

part 'duel_side_result.freezed.dart';
part 'duel_side_result.g.dart';

/// What the server settled for one seat of a finished live duel — the `p1` /
/// `p2` objects inside the `duel_end` broadcast.
@freezed
abstract class DuelSideResult with _$DuelSideResult {
  const factory DuelSideResult({
    required int eloBefore,
    required int eloAfter,
    @Default(0) int coins,
    @Default(0) int xp,
    @Default([]) List<String> badgeIds,
  }) = _DuelSideResult;

  factory DuelSideResult.fromJson(Map<String, dynamic> json) =>
      _$DuelSideResultFromJson(json);
}
