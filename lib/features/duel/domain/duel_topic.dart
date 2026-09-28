import 'package:freezed_annotation/freezed_annotation.dart';

part 'duel_topic.freezed.dart';
part 'duel_topic.g.dart';

/// A sub-category a duel is fought in (plan 017) — picking one is required
/// both to create a challenge and to matchmake.
///
/// Keys match the server's `_duel_topic_json`, plus `list_duel_topics`'
/// activity counts. A challenge card's embedded topic carries no
/// [categoryId] or counts, hence their defaults.
@freezed
abstract class DuelTopic with _$DuelTopic {
  const factory DuelTopic({
    required String id,
    required String name,
    required String emoji,
    required String plateColor,
    required String categoryName,
    required String categoryEmoji,
    @Default('') String categoryId,
    @Default(0) int myTopicLevel,
    @Default(0) int openChallenges,
    @Default(0) int searching,
  }) = _DuelTopic;

  const DuelTopic._();

  factory DuelTopic.fromJson(Map<String, dynamic> json) =>
      _$DuelTopicFromJson(json);

  /// True when anyone is searching or has an open challenge here right now.
  bool get hasActivity => openChallenges + searching > 0;
}
