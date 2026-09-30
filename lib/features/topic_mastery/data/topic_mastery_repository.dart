import 'package:quizoo/features/topic_mastery/data/topic_mastery_api.dart';
import 'package:quizoo/features/topic_mastery/domain/topic_mastery.dart';

/// The only thing that talks to [TopicMasteryApi].
class TopicMasteryRepository {
  TopicMasteryRepository(this._api);

  final TopicMasteryApi _api;

  Future<TopicMastery> fetch({
    required String categoryId,
    required String subcategoryId,
    required String locale,
  }) => _api.fetch(
    categoryId: categoryId,
    subcategoryId: subcategoryId,
    locale: locale,
  );
}
