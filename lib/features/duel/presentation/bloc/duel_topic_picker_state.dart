part of 'duel_topic_picker_cubit.dart';

/// The topic picker sheet's states (CLAUDE.md §3).
sealed class DuelTopicPickerState extends Equatable {
  const DuelTopicPickerState();

  @override
  List<Object?> get props => const [];
}

/// Loading the duel-able topics.
final class DuelTopicPickerLoading extends DuelTopicPickerState {
  const DuelTopicPickerLoading();
}

/// The topics with enough live questions in the content language, in the
/// server's order (category, then activity, then sub-category). May be empty.
final class DuelTopicPickerLoaded extends DuelTopicPickerState {
  const DuelTopicPickerLoaded(this.topics);

  final List<DuelTopic> topics;

  @override
  List<Object?> get props => [topics];
}

final class DuelTopicPickerFailed extends DuelTopicPickerState {
  const DuelTopicPickerFailed(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.code, error.message];
}
