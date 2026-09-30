part of 'topic_mastery_cubit.dart';

/// The Topic Mastered screen's states (CLAUDE.md §3).
sealed class TopicMasteryState extends Equatable {
  const TopicMasteryState();

  @override
  List<Object?> get props => const [];
}

final class TopicMasteryLoading extends TopicMasteryState {
  const TopicMasteryLoading();
}

final class TopicMasteryLoaded extends TopicMasteryState {
  const TopicMasteryLoaded(this.mastery);

  final TopicMastery mastery;

  @override
  List<Object?> get props => [mastery];
}

final class TopicMasteryError extends TopicMasteryState {
  const TopicMasteryError(this.error);

  final ApiException error;

  @override
  List<Object?> get props => [error.kind, error.message];
}
