import 'package:dio/dio.dart';
import 'package:quizoo/core/network/api_exception.dart';
import 'package:quizoo/core/network/elevenlabs_client.dart';

/// The realtime-oriented v3 model — the only ElevenLabs family that covers
/// this app's Urdu content (see plan 010, Research finding #5).
const _modelId = 'eleven_v3_conversational';

/// ElevenLabs' text-to-speech convert endpoint.
class ElevenLabsTtsApi {
  ElevenLabsTtsApi([Dio? client]) : _client = client ?? elevenLabsClient;

  final Dio _client;

  Future<List<int>> convertTextToSpeech({
    required String text,
    required String voiceId,
    String? languageCode,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _client.post<List<int>>(
        '/v1/text-to-speech/$voiceId',
        queryParameters: const {'output_format': 'mp3_44100_128'},
        data: {
          'text': text,
          'model_id': _modelId,
          'language_code': ?languageCode,
        },
        options: Options(responseType: ResponseType.bytes),
        cancelToken: cancelToken,
      );
      return response.data!;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
