import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/features/quiz_play/domain/question.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The server's hand-dealt copy of a level: the attempt id
/// `submit_level_attempt` needs back, the questions themselves, and the
/// server-authoritative ladder values for this level — so the play surface
/// never re-derives them from a hardcoded client-side ladder.
class PreparedLevel {
  const PreparedLevel({
    required this.attemptId,
    required this.questions,
    required this.secondsPerQuestion,
    required this.isBoss,
  });

  final String attemptId;
  final List<Question> questions;
  final int secondsPerQuestion;
  final bool isBoss;
}

/// The play surface's real endpoint.
class QuizPlayApi {
  QuizPlayApi(this._client);

  final SupabaseClient _client;

  /// The whole level's questions, in one call, via `start_level_attempt`
  /// (functions migration) — one Postgres function call is what keeps §01's
  /// "no blocking network mid-level" contract, the same way the mock's single
  /// `fetchLevelQuestions` call did.
  ///
  /// Spends one account heart server-side; throws an [ApiException] with
  /// `code: 'out_of_hearts'` when the caller has none left to spend — a
  /// "can't even start" failure, distinct from `QuizPlayOutOfLives`'s
  /// mid-run wall.
  Future<PreparedLevel> fetchLevelQuestions({
    required String subcategoryId,
    required int levelNumber,
    required String languageCode,
  }) async {
    try {
      final response = await _client.rpc<Map<String, dynamic>>(
        'start_level_attempt',
        params: {
          'p_subcategory_id': subcategoryId,
          'p_level': levelNumber,
          'p_locale': languageCode,
        },
      );

      final questions = [
        for (final row in response['questions'] as List)
          _questionFromRow(row as Map<String, dynamic>),
      ];
      return PreparedLevel(
        attemptId: response['attemptId'] as String,
        questions: questions,
        secondsPerQuestion: response['secondsPerQuestion'] as int,
        isBoss: response['isBoss'] as bool,
      );
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  /// Today's real questions to answer — `get_daily_challenge_questions`
  /// (`get_daily_challenge_questions_full_shape` migration), shaped exactly
  /// like [fetchLevelQuestions]'s so the daily challenge can play through the
  /// same [Question]-driven arena a level does (`QuizPlayCubit.startDaily`).
  ///
  /// Throws with `code: 'already_played_today'` when the caller already has
  /// a `daily_attempts` row for today, and `code: 'no_challenge_today'` if
  /// nothing was generated for this date/language yet — both raised by the
  /// RPC itself, not derived here.
  Future<DailyQuestionSession> fetchDailyQuestions({
    required String languageCode,
  }) async {
    try {
      final response = await _client.rpc<Map<String, dynamic>>(
        'get_daily_challenge_questions',
        params: {'p_language_code': languageCode},
      );

      final questions = [
        for (final row in response['questions'] as List)
          _questionFromRow(row as Map<String, dynamic>),
      ];
      return DailyQuestionSession(
        questions: questions,
        secondsPerQuestion: response['secondsPerQuestion'] as int,
      );
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }

  static Question _questionFromRow(Map<String, dynamic> row) => Question(
    id: row['id'] as String,
    subcategoryId: row['subcategoryId'] as String,
    difficulty: row['difficulty'] as int,
    text: row['text'] as String,
    options: (row['options'] as List).cast<String>(),
    correctIndex: row['correctIndex'] as int,
    explanation: row['explanation'] as String,
    hasImage: row['hasImage'] as bool? ?? false,
    mediaUrl: row['mediaUrl'] as String?,
    figureSvg: row['figureSvg'] as String?,
    ttsExcluded: row['ttsExcluded'] as bool? ?? false,
    audioUrl: row['audioUrl'] as String?,
  );
}

/// Today's real questions plus the clock to answer them under — what
/// [QuizPlayRepository.questionsForDaily] hands [QuizPlayCubit.startDaily].
class DailyQuestionSession {
  const DailyQuestionSession({
    required this.questions,
    required this.secondsPerQuestion,
  });

  final List<Question> questions;
  final int secondsPerQuestion;
}
