# Replace `flutter_tts` with ElevenLabs Text-to-Speech

> Source spec: provided inline in conversation (user request to replace `flutter_tts`
> with ElevenLabs' TTS API, plus answers to three clarifying questions asked during
> planning — see "Assumptions & open questions").
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation history.
Start by reading it in full. Code may have moved on since it was written (dated
2026-09-16), so spot-check the referenced files and line numbers still match before
you begin — especially `quiz_play_cubit.dart`, which is dense and actively touched.

## Objective

`QuizPlayCubit` currently reads each quiz question aloud via `flutter_tts`
(on-device, offline, free). Replace it with ElevenLabs' hosted TTS REST API,
keeping the exact same `TtsService` seam so `QuizPlayCubit`'s phase machine
(speaking → revealing → answering) and its existing `bloc_test` suite need no
behavioral changes — only the concrete implementation behind the interface, plus
the small amount of new plumbing ElevenLabs requires that `flutter_tts` didn't
(an API key, a voice per language, network failure handling).

## Scope

**In scope:**
- A new `ElevenLabsTtsService` (implements the existing `TtsService` interface)
  backed by ElevenLabs' `POST /v1/text-to-speech/{voice_id}` endpoint, playing
  the returned audio via `audioplayers` (already a dependency).
- Removing `flutter_tts` entirely (dependency + `FlutterTtsService`).
- A new Dio-based HTTP client in `core/network/`, since this is the first
  feature to call a real external (non-Supabase) REST API — see Research
  finding #1 below for why this departs from how every other feature talks to
  its backend today.
- A new nullable `voice_id` column on the existing `languages` table, so each
  content language's ElevenLabs voice is configured in the database (per your
  answer to the voice-selection question), not hardcoded or dart-defined.
- `ELEVENLABS_API_KEY` delivered via the project's existing `--dart-define`
  convention (per your answer to the API-key question).
- Updating the one existing test file that constructs `QuizPlayCubit`, plus the
  one widget-test support helper that will need a new provider.

**Out of scope (explicitly, per your answers or to avoid scope creep):**
- A Supabase Edge Function proxy to keep the API key fully server-side. You
  chose the client-side dart-define approach for now; the Edge Function
  approach is noted under Risks as a future hardening step, not built here.
- Any admin UI for setting `languages.voice_id` — it's set via a manual SQL
  `update` for now, same as any other one-off content edit in this project.
- Audio prefetching/caching to hide ElevenLabs' network latency behind the
  countdown — noted under Risks as a follow-up, not required for a straight
  replacement.
- ElevenLabs' streaming/WebSocket TTS API — quiz questions are short, single
  sentences; the plain synchronous convert endpoint is sufficient.
- Changing anything in `duel`, `daily`, or any other feature — grep confirmed
  TTS is used only by `quiz_play`.

## Research findings

1. **This project has no Dio anywhere today.** Every real backend call goes
   through `supabase_flutter`'s own client (`core/network/supabase_client.dart`
   → `SupabaseClient get supabase`), invoked from `*_api.dart` files like
   `lib/features/quiz_play/data/quiz_play_api.dart` via `.rpc(...)` /
   `.from(...)`. CLAUDE.md §9 prescribes "one ApiClient (Dio)" — that rule
   predates the project's actual pivot to the Supabase SDK for its own
   backend, and has simply never been exercised. ElevenLabs is a genuinely
   different host, so it's the first real case that rule was written for. This
   plan follows §9's letter for it: one shared, once-configured Dio client in
   `core/network/`, and a typed `ApiException.fromDio(...)` mapping factory
   mirroring the existing `ApiException.fromSupabase(...)` (see
   `lib/core/network/api_exception.dart:80`).

2. **The `TtsService` seam already isolates this cleanly.**
   `lib/features/quiz_play/data/tts_service.dart` is a 4-method abstract class
   (`setLanguage`, `speak`, `stop`, `onComplete`), injected into
   `QuizPlayCubit`'s constructor (`lib/features/quiz_play/presentation/bloc/quiz_play_cubit.dart:58-65`)
   exactly like `SoundEffectsService`. `QuizPlayCubit` never imports
   `flutter_tts` — only `flutter_tts_service.dart` does, and only
   `quiz_play_screen.dart:78` constructs it. `quiz_play_cubit_test.dart`
   already tests the whole phase machine (speaking/revealing/answering,
   completion callback, stop-on-mute) against a hand-written `_FakeTtsService`
   (`test/features/quiz_play/quiz_play_cubit_test.dart:28-48`), not against
   `flutter_tts` — so none of that test coverage or the Cubit's own logic needs
   to change, only the interface's signature (widened, see below) and the
   concrete class swapped at the one construction site.

3. **Graceful degradation already exists and this plan reuses it exactly.**
   `TtsService.setLanguage`'s doc comment (`tts_service.dart:6-10`) states it
   "Returns `false` (never throws) when no voice pack is available... so the
   caller can fall back to silent mode rather than blocking the question
   screen." `QuizPlayCubit.startLevel` (`quiz_play_cubit.dart:182-185`) already
   wires this: `_ttsAvailable = _audioOn ? await _ttsService.setLanguage(languageCode) : false`,
   and `_beginQuestion` (`quiz_play_cubit.dart:250-251`) only speaks when
   `_audioOn && _ttsAvailable && !question.ttsExcluded`. "No `voice_id`
   configured for this language yet" is modeled as exactly this same
   `setLanguage` → `false` path — no new Cubit-level fallback logic is needed.

4. **ElevenLabs' own docs (fetched during planning) explicitly warn against
   shipping the API key client-side** ("Do not share it with others or expose
   it in any client-side code (browsers, apps)"), unlike Supabase's anon key,
   which is designed to be public and is protected by RLS instead. You've
   chosen to proceed with the client-side `--dart-define` approach anyway,
   matching this codebase's only existing secret-handling convention
   (`main.dart:14-15`'s `SUPABASE_URL`/`SUPABASE_ANON_KEY` consts, populated
   via the gitignored `dart_define.json` + `--dart-define-from-file`, wired in
   `.vscode/launch.json`). This is called out under Risks, not re-litigated
   here.

5. **Only `eleven_v3` and `eleven_v3_conversational` support Urdu.** Per
   ElevenLabs' models documentation, `eleven_multilingual_v2` (29 languages)
   and `eleven_flash_v2_5` (32 languages) both omit Urdu; `eleven_v3` and
   `eleven_v3_conversational` cover 70+ languages including it. This app's
   `languages` table (`supabase/migrations/20260910090100_multilingual_content_model.sql:59-75`)
   currently has `en` and `ur` as the only `is_active = true` rows (`hi`,
   `ar`, `fr`, `es` are seeded but inactive) — so Urdu support is a hard
   requirement, not a nice-to-have. You picked `eleven_v3_conversational` for
   its documented ~280ms low-latency, realtime-oriented design, a better fit
   for reading a question aloud under a ticking timer than plain `eleven_v3`
   (narration-focused, latency undocumented).

6. **The `languages` table is the right place for `voice_id`, per your
   answer.** It's `code text primary key, name, native_name, is_rtl,
   is_active, sort_order` (`20260910090100_multilingual_content_model.sql:59-66`),
   already has an open `select`-for-everyone RLS policy
   (`20260910090400_ladder_rls_and_grants_cleanup.sql:28`,
   `using (true)`) — so a new column needs no new RLS policy. It's read today
   by `LanguagesApi.fetchActiveLanguages()`
   (`lib/features/onboarding/data/languages_api.dart`) for the onboarding
   picker (S-03) and by `ContentLanguageApi`/`ContentLanguageRepository`
   (`lib/core/content_language/`) for the persisted content-language pick.
   `LanguageOption`/`LanguagesApi`/`LanguagesRepository` live under
   `features/onboarding/`, which `quiz_play` must not reach into per CLAUDE.md
   §10 ("cross-feature reuse goes through `core/`", and shared files are
   "added to, not restructured" for a single feature's spec — moving
   `LanguageOption` out of onboarding would be exactly that restructuring, and
   is not this plan's job). `ContentLanguageApi`/`Repository` already live in
   `core/` and already query this table — extending them with a `voice_id`
   lookup is additive, in-bounds, and avoids a feature-to-feature dependency.

7. **`ContentLanguageRepository` exists but isn't a `RepositoryProvider`
   today.** `lib/app/app.dart:85-92` constructs it only to feed
   `ContentLanguageCubit`; it's never added to the `MultiRepositoryProvider`
   list at `app.dart:129-144`. `QuizPlayCubit` needs it as a constructor
   dependency (a repository, per CLAUDE.md §3's "Dependencies (repositories)
   are injected via the constructor only" — not another Cubit), so it needs
   registering as a provider too.

8. **Test conventions confirmed from the existing suite:**
   `_api.dart` files are never unit-tested directly in this codebase (no
   `quiz_play_api_test.dart` exists) — only repositories are, with the API
   mocktail-mocked (`test/features/quiz_play/quiz_play_repository_test.dart`,
   `test/core/content_language/content_language_repository_test.dart`). Thin
   plugin-backed service classes (`FlutterTtsService`,
   `AudioplayersSoundEffectsService`) also have no dedicated unit test — they're
   exercised only behind the `TtsService`/`SoundEffectsService` fakes at the
   Cubit level. This plan follows both conventions: no new test file for
   `ElevenLabsTtsApi` or `ElevenLabsTtsService`; the new `voiceIdFor` logic is
   tested at the `ContentLanguageRepository` level (mocking `ContentLanguageApi`),
   and the new "no `voice_id` configured" fallback is tested at the
   `QuizPlayCubit` level (extending `_FakeTtsService`).

9. **Widget-test wiring will break without one addition.**
   `test/support/pump_screen.dart:55-61` already documents that
   `QuizPlayScreen` builds a real TTS service inline and defaults
   `settings.soundOn: false` so it's never exercised in widget tests — that
   protection still holds. But `QuizPlayScreen` will start reading
   `context.read<ContentLanguageRepository>()` to construct `QuizPlayCubit`
   regardless of the sound setting (the read happens at build time, not
   conditionally), so `pump_screen.dart` needs that provider added or every
   `QuizPlayScreen` widget test throws a `ProviderNotFoundException`.

## Assumptions & open questions

- **Model/voice details are sourced from ElevenLabs' public docs pages
  fetched during planning, not a live API call against a real key.** Before
  or during implementation, confirm against `GET https://api.elevenlabs.io/v1/models`
  (once a real key exists) that `eleven_v3_conversational` is: (a) the exact
  literal `model_id` string, and (b) actually enabled on your ElevenLabs
  account/plan — `v3`-family models have historically had narrower access
  than `v2`/`flash` models. If it turns out to be gated, the fallback is
  `eleven_v3` (same language coverage, same account-access question) — there
  is no `v2`-family option that covers Urdu.
- **`languages.voice_id` ships `NULL` for every row in this plan's migration.**
  That means, per Research finding #3, TTS is silently disabled for every
  language immediately after this ships, until someone runs a manual
  `update languages set voice_id = '...' where code = 'en'` (and `'ur'`) with
  real ElevenLabs voice IDs from the Voice Library. This is consistent with
  what you asked for (DB-driven, added "seamlessly" later) but is worth
  stating plainly: **this plan does not make TTS audible on its own** — a
  follow-up manual DB step does.
- **`language_code` sent to ElevenLabs is the app's existing ISO 639-1 `code`
  (`'en'`/`'ur'`) as-is**, assumed to match what ElevenLabs' optional
  `language_code` request field expects. Not independently verified against a
  live call.
- **No retry/backoff** on a failed ElevenLabs call — one attempt per question,
  fail open to silence, matching `setLanguage`'s existing "never throws"
  contract extended to `speak()`. A flaky network drops that one question's
  read-aloud, not the whole level.
- **No audio caching/prefetching.** Each question's audio is fetched exactly
  when `_beginQuestion` starts it, same moment `flutter_tts` used to start
  speaking on-device. Network latency here is new (see Risks).
- **The `voiceIdFor` lookup is not cached** — one extra lightweight Supabase
  query per level start, alongside the `start_level_attempt` RPC that already
  runs at the same moment. Flagged as an easy future optimization if it ever
  shows up as a real cost, not a blocker now.
- If any of the above turns out wrong once you have real API access (model
  gating, language_code behavior, voice quality for Urdu specifically), the
  isolated blast radius is `elevenlabs_tts_api.dart` and the `voice_id`
  column's values — nothing in `QuizPlayCubit` needs to change.

## Design overview

```
QuizPlayScreen
  └─ constructs ElevenLabsTtsService(ElevenLabsTtsApi())
  └─ reads context.read<ContentLanguageRepository>()
       │
       ▼
QuizPlayCubit(repository, settingsRepository, contentLanguageRepository,
              ttsService, soundEffects)
  └─ startLevel(): voiceId = await contentLanguageRepository.voiceIdFor(languageCode)
                    _ttsAvailable = audioOn
                        ? await ttsService.setLanguage(languageCode, voiceId: voiceId)
                        : false
  └─ _beginQuestion(): ttsService.speak(question.text)   // unchanged call site
       │
       ▼
ElevenLabsTtsService implements TtsService
  ├─ setLanguage(code, {voiceId}) → false if voiceId == null, else remembers both
  ├─ speak(text) → ElevenLabsTtsApi.convertTextToSpeech(...) → play bytes via
  │                 audioplayers' AudioPlayer(BytesSource) → onPlayerComplete
  │                 fires the registered onComplete callback; ANY failure
  │                 (network/HTTP/decode) also fires onComplete, never throws
  ├─ stop() → cancels any in-flight request (CancelToken) + AudioPlayer.stop()
  └─ dispose() → AudioPlayer.dispose()  // new interface method, mirrors
                                         // SoundEffectsService.dispose()
       │
       ▼
ElevenLabsTtsApi
  └─ POST {elevenLabsClient.baseUrl}/v1/text-to-speech/{voiceId}
     headers: xi-api-key (set once on the shared client)
     body: {text, model_id: 'eleven_v3_conversational', language_code}
     on failure → throw ApiException.fromDio(error)

core/network/elevenlabs_client.dart
  └─ one Dio instance, base URL https://api.elevenlabs.io,
     xi-api-key from String.fromEnvironment('ELEVENLABS_API_KEY')

languages table (Supabase)
  └─ + voice_id text (nullable) — set manually per language after this ships
```

## Implementation steps

### Phase 1 — Database: add `voice_id` to `languages`

- [ ] New migration `supabase/migrations/20260916120000_add_voice_id_to_languages.sql`:
  ```sql
  begin;

  alter table public.languages
    add column if not exists voice_id text;

  commit;
  ```
  No RLS change needed — `languages_select_all` already covers `select` on
  every column (`using (true)`). Leave every row's `voice_id` `NULL`; it's set
  manually per language after this ships (see Assumptions).

### Phase 2 — Core network layer for ElevenLabs

- [ ] `pubspec.yaml`: add `dio: ^5.7.0` under `dependencies` (verify the
      current latest stable on pub.dev at implementation time — this project
      pins fairly current majors elsewhere, e.g. `go_router: ^16.2.4`). Remove
      `flutter_tts: ^4.2.5` and its "Countdown/TTS read-aloud (plan 007, §4)"
      comment.
- [ ] New `lib/core/network/elevenlabs_client.dart`:
  ```dart
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
  ```
- [ ] `lib/core/network/api_exception.dart`: add a `fromDio` factory alongside
      the existing `fromSupabase` (`api_exception.dart:80-120`), same style:
  ```dart
  factory ApiException.fromDio(Object error) {
    if (error is ApiException) return error;
    if (error is! DioException) return ApiException(error.toString());

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('Request timed out', kind: ApiErrorKind.timeout);
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return ApiException.network();
      case DioExceptionType.cancel:
        return const ApiException('Cancelled', code: 'ERR_TTS_CANCELLED');
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return switch (status) {
          401 || 403 => ApiException(
              'Unauthorized', kind: ApiErrorKind.unauthorized, statusCode: status),
          404 => ApiException(
              'Not found', kind: ApiErrorKind.notFound, statusCode: status),
          429 => ApiException(
              'Rate limited', kind: ApiErrorKind.server, statusCode: status,
              code: 'ERR_TTS_RATE_LIMITED'),
          _ when status != null && status >= 500 => ApiException(
              'Server error', kind: ApiErrorKind.server, statusCode: status),
          _ => ApiException(
              'Request rejected', statusCode: status, code: 'ERR_TTS_INVALID_REQUEST'),
        };
      case DioExceptionType.unknown:
        return error.error is SocketException
            ? ApiException.network()
            : ApiException(error.message ?? error.toString());
    }
  }
  ```
  (Needs `import 'package:dio/dio.dart';` added to this file; `dart:io`'s
  `SocketException` import already present.)

### Phase 3 — Content-language voice lookup (`core/`)

- [ ] `lib/core/content_language/content_language_api.dart`: add
  ```dart
  Future<String?> fetchVoiceId(String code) async {
    try {
      final row = await _client
          .from('languages')
          .select('voice_id')
          .eq('code', code)
          .maybeSingle();
      return row?['voice_id'] as String?;
    } catch (error) {
      throw ApiException.fromSupabase(error);
    }
  }
  ```
- [ ] `lib/core/content_language/content_language_repository.dart`: add
  ```dart
  /// Best-effort, matching `reconcileWithBackend`'s own convention: a lookup
  /// failure disables TTS for this level rather than blocking it from
  /// starting.
  Future<String?> voiceIdFor(String code) async {
    try {
      return await _api.fetchVoiceId(code);
    } on ApiException {
      return null;
    }
  }
  ```
- [ ] `lib/app/app.dart`: add
  `RepositoryProvider<ContentLanguageRepository>.value(value: _contentLanguageRepository)`
  to the `MultiRepositoryProvider.providers` list (`app.dart:129-144`),
  alongside the other five. `_contentLanguageRepository` already exists as a
  field (`app.dart:85-89`) — this just also exposes it, unchanged otherwise.

### Phase 4 — Replace the TTS service

- [ ] `lib/features/quiz_play/data/tts_service.dart`: widen `setLanguage` and
      add `dispose()`:
  ```dart
  abstract class TtsService {
    /// [voiceId] is the ElevenLabs voice configured for this language in the
    /// `languages` table (Assumption: null when none is configured yet).
    /// Returns `false` — never throws — when [voiceId] is null, so the
    /// caller falls back to silent mode exactly as it already does when no
    /// voice pack was available under `flutter_tts`.
    Future<bool> setLanguage(String languageCode, {String? voiceId});

    Future<void> speak(String text);
    Future<void> stop();
    void onComplete(void Function() callback);

    /// Releases any native resources this service opened. Safe to call even
    /// if nothing was ever spoken. Mirrors `SoundEffectsService.dispose()`.
    Future<void> dispose();
  }
  ```
- [ ] Delete `lib/features/quiz_play/data/flutter_tts_service.dart`.
- [ ] New `lib/features/quiz_play/data/elevenlabs_tts_api.dart`:
  ```dart
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
            if (languageCode != null) 'language_code': languageCode,
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
  ```
- [ ] New `lib/features/quiz_play/data/elevenlabs_tts_service.dart`:
  ```dart
  import 'dart:typed_data';

  import 'package:audioplayers/audioplayers.dart';
  import 'package:quizoo/features/quiz_play/data/elevenlabs_tts_api.dart';
  import 'package:quizoo/features/quiz_play/data/tts_service.dart';

  /// The real [TtsService], backed by ElevenLabs' REST API + `audioplayers`
  /// for local playback of the returned audio.
  class ElevenLabsTtsService implements TtsService {
    ElevenLabsTtsService([ElevenLabsTtsApi? api])
        : _api = api ?? ElevenLabsTtsApi() {
      _player.onPlayerComplete.listen((_) => _onComplete?.call());
    }

    final ElevenLabsTtsApi _api;
    final AudioPlayer _player = AudioPlayer(playerId: 'tts_elevenlabs');

    String? _languageCode;
    String? _voiceId;
    CancelToken? _cancelToken;
    void Function()? _onComplete;

    @override
    Future<bool> setLanguage(String languageCode, {String? voiceId}) async {
      _languageCode = languageCode;
      _voiceId = voiceId;
      return voiceId != null;
    }

    @override
    Future<void> speak(String text) async {
      final voiceId = _voiceId;
      if (voiceId == null) {
        _onComplete?.call();
        return;
      }
      _cancelToken = CancelToken();
      try {
        final bytes = await _api.convertTextToSpeech(
          text: text,
          voiceId: voiceId,
          languageCode: _languageCode,
          cancelToken: _cancelToken,
        );
        await _player.play(BytesSource(Uint8List.fromList(bytes)));
      } catch (_) {
        // Fail open: never leave the question stuck in the "speaking" phase
        // on a network/API failure — matches setLanguage's existing
        // never-throws contract, extended to speak().
        _onComplete?.call();
      }
    }

    @override
    Future<void> stop() async {
      _cancelToken?.cancel();
      await _player.stop();
    }

    @override
    void onComplete(void Function() callback) => _onComplete = callback;

    @override
    Future<void> dispose() => _player.dispose();
  }
  ```
  Note: `stop()` deliberately does not itself invoke `_onComplete` for audio
  that's already playing — `audioplayers`' `.stop()` does not emit
  `onPlayerComplete`, and no existing call site depends on it doing so; every
  `stop()` caller in `QuizPlayCubit` already transitions phase itself
  synchronously (see Research finding #3 and `quiz_play_cubit.dart:319-326`).
  A `stop()` called while the HTTP request is still in flight *does* reach
  `_onComplete` via the `CancelToken` throwing inside `speak()`'s `catch`.

### Phase 5 — Wire it into `QuizPlayCubit` / `QuizPlayScreen`

- [ ] `lib/features/quiz_play/presentation/bloc/quiz_play_cubit.dart`:
  - Add `import 'package:quizoo/core/content_language/content_language_repository.dart';`
  - Constructor (`quiz_play_cubit.dart:58-65`) gains a fourth positional
    dependency, `ContentLanguageRepository`, inserted before `_ttsService` to
    match the "repositories first, services after" ordering `SoundEffectsService`
    already establishes:
    ```dart
    QuizPlayCubit(
      this._repository,
      this._settingsRepository,
      this._contentLanguageRepository,
      this._ttsService,
      this._soundEffects,
    ) : super(const QuizPlayPreparing());

    final ContentLanguageRepository _contentLanguageRepository;
    ```
  - `startLevel` (`quiz_play_cubit.dart:182-185`) becomes:
    ```dart
    _audioOn = _settingsRepository.current.soundOn;
    if (_audioOn) {
      final voiceId = await _contentLanguageRepository.voiceIdFor(languageCode);
      if (isClosed) return;
      _ttsAvailable = await _ttsService.setLanguage(languageCode, voiceId: voiceId);
    } else {
      _ttsAvailable = false;
    }
    if (isClosed) return;
    ```
  - `close()` (`quiz_play_cubit.dart:801-810`): add
    `unawaited(_ttsService.dispose());` after the existing
    `unawaited(_ttsService.stop());` at line 808, mirroring
    `unawaited(_soundEffects.dispose())` on the next line.
- [ ] `lib/features/quiz_play/presentation/screens/quiz_play_screen.dart`:
  - Replace the `flutter_tts_service.dart` import with
    `elevenlabs_tts_api.dart` and `elevenlabs_tts_service.dart` imports.
  - In `build()` (`quiz_play_screen.dart:68-83`), replace
    `FlutterTtsService()` with `ElevenLabsTtsService(ElevenLabsTtsApi())`, and
    add `context.read<ContentLanguageRepository>()` as the new third
    constructor argument (matching the Cubit's new parameter order above):
    ```dart
    QuizPlayCubit(
      context.read<QuizPlayRepository>(),
      context.read<SettingsRepository>(),
      context.read<ContentLanguageRepository>(),
      ElevenLabsTtsService(ElevenLabsTtsApi()),
      AudioplayersSoundEffectsService(),
    )..startLevel(...)
    ```
  - Add `import 'package:quizoo/core/content_language/content_language_repository.dart';`
    (the `ContentLanguageCubit` import already there stays, for
    `.state.code`).

### Phase 6 — Tests

- [ ] `test/features/quiz_play/quiz_play_cubit_test.dart`:
  - `_FakeTtsService` (`quiz_play_cubit_test.dart:28-48`): widen `setLanguage`
    and make it behavior-accurate (so cubit tests can actually exercise the
    "no voice configured" path), add `dispose()`:
    ```dart
    @override
    Future<bool> setLanguage(String languageCode, {String? voiceId}) async =>
        voiceId != null && languageAvailable;

    @override
    Future<void> dispose() async {}
    ```
  - Add a mocktail mock: `class _MockContentLanguageRepository extends Mock implements ContentLanguageRepository {}`,
    a `late _MockContentLanguageRepository contentLanguageRepository;` field,
    and in `setUp()`:
    ```dart
    contentLanguageRepository = _MockContentLanguageRepository();
    when(() => contentLanguageRepository.voiceIdFor(any()))
        .thenAnswer((_) async => 'voice-placeholder');
    ```
    (a non-null default keeps every existing `soundOn: true` test's behavior
    unchanged, since `languageAvailable` still gates them the same way it does
    today).
  - Update `buildCubit()` (`quiz_play_cubit_test.dart:114-115`) to pass
    `contentLanguageRepository` as the third constructor argument.
  - The six `soundOn: true` blocks (currently at
    `quiz_play_cubit_test.dart:192, 231, 268, 292, 442, 477`) need no code
    change — they inherit the `setUp()` stub above — but re-confirm each
    still passes once the constructor signature changes; line numbers will
    shift once earlier edits land.
  - Add one new test: with `soundOn: true` and
    `contentLanguageRepository.voiceIdFor(any())` stubbed to return `null`,
    assert the question goes straight to `QuestionPhase.answering` (no
    `speaking` phase) and `ttsService.spoken` stays empty — the "no voice_id
    configured for this language" fallback path.
- [ ] `test/support/pump_screen.dart`:
  - Capture the repository built by `_fakeContentLanguageRepository()` once
    and reuse it for both the `ContentLanguageCubit` and a new provider:
    ```dart
    final contentLanguageRepository =
        contentLanguage == null ? await _fakeContentLanguageRepository() : null;
    final contentLanguageCubit =
        contentLanguage ?? ContentLanguageCubit(contentLanguageRepository!);
    ```
    (adjust to whatever shape keeps a `ContentLanguageRepository` instance
    available either way — the key requirement is a real instance for the new
    provider even when a test passes a custom `contentLanguage` Cubit in).
  - Add `RepositoryProvider<ContentLanguageRepository>.value(value: ...)` to
    the `MultiRepositoryProvider.providers` list at `pump_screen.dart:69-79`.
  - Update the stale comment at `pump_screen.dart:55-61` ("builds a real
    `FlutterTtsService` inline") to reference `ElevenLabsTtsService` instead.
- [ ] `test/core/content_language/content_language_repository_test.dart`: add
      two cases for the new `voiceIdFor` method, mocking `ContentLanguageApi`:
      one where `fetchVoiceId` resolves to a voice id (repository returns it
      unchanged), one where it throws `ApiException` (repository returns
      `null`) — mirroring the existing `reconcileWithBackend` test shape in
      this same file.
- [ ] `flutter analyze` and `flutter test` clean after all of the above —
      per CLAUDE.md §8, zero warnings before this is considered done.

### Phase 7 — Local config (implementer's machine, not committed)

- [ ] Add `"ELEVENLABS_API_KEY": ""` to your local `dart_define.json` (it's
      gitignored — `dart_define*.json` — so this step can't be done by this
      plan or checked into git; every developer running this branch needs
      their own key added locally, same as `SUPABASE_URL`/`SUPABASE_ANON_KEY`
      today).
- [ ] Once you have real ElevenLabs voice IDs, run against your Supabase
      project:
      ```sql
      update languages set voice_id = '<real voice id>' where code = 'en';
      update languages set voice_id = '<real voice id>' where code = 'ur';
      ```

## Data model / API changes

**Database:** `languages` gains one nullable column, `voice_id text` (Phase 1
migration above). No RLS change.

**External API (ElevenLabs, not this project's own):**
- `POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format=mp3_44100_128`
- Header: `xi-api-key: <ELEVENLABS_API_KEY>`
- Body: `{"text": "...", "model_id": "eleven_v3_conversational", "language_code": "en"}`
- Response: `200` with raw audio bytes (`audio/mpeg`), or a JSON error body on
  failure (`401`/`404`/`422`/`429`/`5xx`) — mapped by `ApiException.fromDio`.

## Dependencies

- **Add** `dio` (`^5.7.0` or later stable) — this project's first HTTP client
  for a non-Supabase REST API.
- **Remove** `flutter_tts` (`^4.2.5`) — fully replaced, no remaining
  references after Phase 4.
- `audioplayers` (`^6.8.1`, already present) gains a second use: TTS playback
  via `BytesSource`, alongside its existing sound-effects use.

## Testing strategy

Matches this project's actual conventions (Research finding #8): repositories
get mocktail-mocked-API unit tests (`ContentLanguageRepository`'s new
`voiceIdFor`); the Cubit's phase-machine logic is covered via its existing
hand-written `_FakeTtsService` fake, extended to be voice-id-aware; the
concrete plugin/HTTP-backed service classes (`ElevenLabsTtsApi`,
`ElevenLabsTtsService`) get no dedicated unit test, matching the zero
precedent for `FlutterTtsService`, `AudioplayersSoundEffectsService`, and
`quiz_play_api.dart` today. Widget tests (`quiz_play_screen_test.dart`) keep
passing by construction, since `soundOn: false` in `pump_screen.dart` already
prevents `_ttsService.setLanguage`/`speak` from ever being called — the only
change needed there is the new `ContentLanguageRepository` provider so the
screen's `build()` doesn't crash on the read itself.

## Edge cases & error handling

- **No `voice_id` for the current language** → `setLanguage` returns `false`
  → question skips straight to `answering`, exactly like a `flutter_tts`
  language with no installed voice pack today.
- **Network/API failure mid-`speak()`** (offline, timeout, `401` bad key,
  `429` rate limit, `5xx`) → caught inside `ElevenLabsTtsService.speak()`,
  `onComplete` still fires, the question proceeds without audio. Nothing
  propagates to `QuizPlayCubit` as a `QuizPlayFailed` state — TTS failures are
  not level failures.
- **User mutes or skips while ElevenLabs is still generating audio** →
  `stop()` cancels the in-flight request via `CancelToken`; the resulting
  cancellation is caught in `speak()`'s `catch`, which still calls
  `onComplete` (harmless — `_onSpeechComplete`'s existing phase/question-index
  guards no-op it, since the caller already transitioned phase itself).
- **User mutes or skips while audio is already playing** → `stop()` stops
  playback directly; `onComplete` does not fire from the player itself (no
  existing call site needs it to), and the caller has already transitioned
  phase synchronously.
- **`QuizPlayCubit` closes mid-request** (user backs out of the level) →
  `close()` now calls both `_ttsService.stop()` (cancels/stops) and the new
  `_ttsService.dispose()` (releases the `AudioPlayer`).
- **`ELEVENLABS_API_KEY` left empty** (dart-define never set, e.g. CI or a
  fresh checkout) → every ElevenLabs call fails with a `401`-shaped
  `DioException` → `ApiException.fromDio` maps it → caught in `speak()` →
  fails open to silent, same as no `voice_id` configured. The app never
  crashes or blocks on a missing key.

## Acceptance criteria

- [ ] `flutter_tts` is fully removed from `pubspec.yaml` and the codebase (no
      remaining imports).
- [ ] `dio` is added; `core/network/elevenlabs_client.dart` and
      `ApiException.fromDio` exist and compile.
- [ ] `languages.voice_id` column exists (migration applied); `en`/`ur` rows
      start `NULL`.
- [ ] `ContentLanguageRepository.voiceIdFor(code)` is unit-tested (success +
      failure-returns-null) and `ContentLanguageRepository` is provided at
      app root.
- [ ] `ElevenLabsTtsService` implements `TtsService` and is constructed in
      `quiz_play_screen.dart` in place of `FlutterTtsService`.
- [ ] With a real `ELEVENLABS_API_KEY` and a real `voice_id` set on `en`,
      starting an English level with sound on plays the question aloud via
      ElevenLabs (manually verified — this plan can't script a real network
      call in CI).
- [ ] With `voice_id` left `NULL` for a language (or an invalid API key), a
      level in that language starts and plays normally with no TTS and no
      error surfaced to the player.
- [ ] `quiz_play_cubit_test.dart`'s full suite passes, including the new
      "no `voice_id`" test case.
- [ ] `quiz_play_screen_test.dart` and the rest of the widget-test suite pass
      unchanged (aside from the new provider in `pump_screen.dart`).
- [ ] `flutter analyze` reports zero warnings (CLAUDE.md §8).

## Risks & rollout notes

- **API key ships in the compiled app binary.** Per your explicit choice,
  this plan uses `--dart-define`, consistent with this project's only
  existing secret pattern — but unlike the Supabase anon key, ElevenLabs'
  key is a paid, quota-metered secret with no RLS-equivalent protection.
  Anyone who extracts it from a release build can spend your quota. If usage
  or cost ever becomes a concern, the documented mitigation is proxying
  through a new Supabase Edge Function (not built in this plan) so the real
  key never leaves your backend.
- **New network-latency UX regression.** `flutter_tts` starts speaking
  on-device, near-instantly; ElevenLabs requires a round trip (TLS + queueing
  + generation) before audio starts, on top of whatever the player's network
  conditions are. The "speaking" phase may now visibly pause before audio
  starts, where it previously didn't. Not fixed by this plan (prefetching
  during the countdown is a natural follow-up, called out as out of scope).
- **New per-question cost.** Every question read aloud with sound on is now a
  metered ElevenLabs API call, unlike free on-device synthesis. Worth
  watching usage/cost once this ships, especially since `voice_id` will be
  unset (TTS off) until manually configured — cost only starts accruing after
  that manual step.
- **Rollout is inherently staged by the `voice_id` column being `NULL`.**
  Shipping this plan's code changes alone does not turn TTS on for anyone —
  it stays silently disabled (exactly like "no voice pack available" does
  today) until the manual `update languages set voice_id = ...` step runs.
  This makes rollback trivial too: setting `voice_id` back to `NULL` for a
  language immediately and safely disables ElevenLabs TTS for it again, with
  no code change.
- **No docs currently exist for `dart_define.json`'s required keys** (README
  doesn't mention it at all today). Not this plan's job to fix, but worth
  noting: a `dart_define.example.json` (untracked-value template, checked
  in) would help the next developer discover `ELEVENLABS_API_KEY` is needed
  at all — consider raising that as a separate, small follow-up.
