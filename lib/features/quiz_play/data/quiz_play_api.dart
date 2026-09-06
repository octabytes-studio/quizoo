import 'package:quizoo/core/mock/mock_api.dart';
import 'package:quizoo/features/quiz_play/data/mock_questions.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';

/// The play surface's mocked endpoint.
class QuizPlayApi extends MockApi {
  QuizPlayApi({
    super.minLatency,
    super.maxLatency,
    super.failureRate,
    super.random,
  });

  /// The whole level's questions, in one call.
  ///
  /// One call is the point: §01's contract is "no blocking network mid-level",
  /// so a level is fetched once, before the countdown, and never again.
  Future<List<Question>> fetchLevelQuestions({
    required String subcategoryId,
    required int levelNumber,
    required String languageCode,
  }) => respond(
    () => MockQuestions.forLevel(
      subcategoryId: subcategoryId,
      levelNumber: levelNumber,
      languageCode: languageCode,
    ),
  );
}
