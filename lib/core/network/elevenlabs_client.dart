import 'package:dio/dio.dart';

const _elevenLabsApiKey = String.fromEnvironment('ELEVENLABS_API_KEY');

/// The one Dio client every ElevenLabs-facing `*_api.dart` file talks
/// through — mirrors `supabase_client.dart`'s "one shared client" pattern
/// (CLAUDE.md §9), for the first external (non-Supabase) REST API this
/// project calls directly.
final Dio elevenLabsClient = Dio(
  BaseOptions(
    baseUrl: 'https://api.elevenlabs.io',
    headers: {'xi-api-key': _elevenLabsApiKey},
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 12),
  ),
);
