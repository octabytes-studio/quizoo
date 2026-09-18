# Replace Live ElevenLabs Synthesis with Pre-Generated Question Audio

> Source spec: provided inline in conversation. The user compared two designs for
> question narration — (1) call ElevenLabs live on every question play (today's
> implementation, plan 010) vs. (2) pre-generate one audio file per question,
> store it in Supabase Storage, and have the app just fetch+play it — and chose
> (2) after a cost/performance/security/feasibility comparison grounded in this
> project's actual data (975 questions, 924 `en` / 51 `ur`, one `voice_id` per
> language, ~54-char average question text). This plan covers only the
> consuming side: the Supabase schema/storage/RPC changes and the Flutter app
> changes needed to store and play pre-generated audio.
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation history.
Start by reading it in full. Code may have moved on since it was written (dated
2026-09-17), so spot-check the referenced files and line numbers still match
before you begin — especially `quiz_play_cubit.dart`, which plan 010 already
flagged as dense and actively touched.

## Objective

Stop calling ElevenLabs' TTS API at runtime on every question view. Instead,
consume audio files that already exist in Supabase Storage — produced by a
separate, out-of-scope authoring skill the user is building themselves — by
adding a storage location for them, a way for `questions` rows to point at
them, and a Flutter playback path that fetches and plays a stored URL instead
of synthesizing speech live. This removes ElevenLabs (and its API key) from
the shipped app entirely, and turns question narration into O(unique
questions) cost instead of O(plays).

## Scope

**In scope:**
- `questions.audio_url` column (nullable `text`), mirroring the existing
  `questions.media_url` pattern exactly.
- A new public-read Supabase Storage bucket, `question-audio`, mirroring the
  existing `question-media` bucket's policy shape
  (`supabase/migrations/20260907130000_storage_buckets.sql`).
- Updating `start_level_attempt` (the only RPC that serves `quiz_play`
  questions) to include `audioUrl` in each question's JSON payload.
- Documenting the exact storage-path/column contract the user's separate
  audio-generation skill must conform to when it uploads files and writes
  `audio_url` — this plan builds the consuming side only, not that skill.
- A new `TtsService` implementation that fetches/plays a stored URL via
  `audioplayers`, replacing `ElevenLabsTtsService`.
- Deleting the live-synthesis code path: `ElevenLabsTtsService`,
  `ElevenLabsTtsApi`, `elevenLabsClient`, `ApiException.fromDio`, the `dio`
  dependency, and the `ELEVENLABS_API_KEY` dart-define.
- `QuizPlayCubit`/`Question` changes needed to carry and gate on `audioUrl`,
  keeping the existing fail-open contract (§ Design overview).
- Updating the one existing test file that exercises this path
  (`quiz_play_cubit_test.dart`) and the `.claude/docs/backend/01-...md` storage
  bucket list.

**Out of scope (explicitly, per the user's instructions):**
- The `generate-questions` skill — not touched, not referenced beyond noting
  it's unaffected (it authors question *text*, never audio).
- Building the audio-generation skill itself (the thing that calls ElevenLabs
  offline and uploads files to `question-audio`). This plan defines the
  contract it must satisfy; building it is a separate, later effort owned by
  the user.
- Backfilling `audio_url` for the 975 existing questions — that's what the
  (not-yet-built) audio-generation skill will do. This plan ships with every
  `audio_url` `NULL`, which is safe: see the fail-open contract below.
- Local audio caching / offline playback / prefetching-ahead-of-the-countdown.
  Plan 010 already flagged ElevenLabs' network round-trip as a latency
  regression and explicitly deferred prefetching/caching as "a natural
  follow-up, not required." Switching to a static file doesn't remove that
  network hop — it's now a Supabase Storage GET instead of an ElevenLabs
  POST — so the same deferral applies here; noted again under Risks, not built.
- `duel`, `daily`, or any other feature — grep confirms (see Research finding
  1) `TtsService` is constructed only by `quiz_play_screen.dart`; nothing else
  changes.
- Any admin UI for managing `audio_url` or `question-audio` uploads.

## Research findings

1. **TTS is used only by `quiz_play`, confirmed directly.** `grep -rln
   "TtsService" lib/` returns exactly: `tts_service.dart` (the interface),
   `elevenlabs_tts_service.dart` (the implementation being replaced),
   `sound_effects_service.dart` (an unrelated hit — its doc comment mentions
   `TtsService` by name only), `quiz_play_cubit.dart`, and
   `quiz_play_screen.dart`. `DailyPlayScreen`/`DuelPlayScreen` never construct
   a `TtsService` — they use their own cubits with no narration. This plan's
   changes are fully contained to `quiz_play` + `core/network` +
   `core/content_language` (read-only) + one migration set.

2. **`questions` is already denormalized one row per language — no join table
   needed.** Unlike `question_i18n` (a deprecated, mostly-empty i18n table —
   25 rows, per plan 007's own notes), the live `questions` table
   (975 rows: 924 `en`, 51 `ur`) carries `language_code` directly on each row.
   `questions.media_url` already proves the right pattern for a
   per-question, per-language external asset reference: a single nullable
   `text` column on `questions` itself, consumed directly as a full URL by
   the client with no extra join or lookup
   (`lib/features/quiz_play/presentation/widgets/question_media_plate.dart:33`
   reads `widget.question.imageAsset` — sourced from `media_url` — straight
   into what is effectively `Image.network`). `audio_url` follows the exact
   same shape.

3. **`start_level_attempt` is the single place `Question` JSON is built**, and
   it already went through several narrow, single-purpose migrations rather
   than broad rewrites — most recently
   `supabase/migrations/20260917090000_start_level_attempt_free_to_start.sql`,
   whose own header states "Signature and every other line ... are
   unchanged; this migration only drops the three hearts-related
   statements." This plan's SQL change follows the same discipline: one more
   `create or replace function public.start_level_attempt(...)` migration
   that changes exactly one line in the `jsonb_build_object(...)` at
   (current file) lines 94–105 — adding `'audioUrl', q.audio_url` — and
   nothing else. (Postgres requires the full function body on `create or
   replace`, but the *diff* against the current version is one line.)

4. **The existing fail-open contract is the right shape to extend, not
   replace.** `TtsService.setLanguage` already returns `false` (never
   throws) when no voice is configured
   (`lib/features/quiz_play/data/tts_service.dart:6-12`), and
   `QuizPlayCubit._beginQuestion`
   (`lib/features/quiz_play/presentation/bloc/quiz_play_cubit.dart:253-287`)
   already gates narration on `_audioOn && _ttsAvailable &&
   !question.ttsExcluded` before calling `_ttsService.speak(question.text)`.
   Today that's a *language-level* gate (set once per level, from
   `languages.voice_id`). Pre-generated audio needs a second, *per-question*
   gate too — a specific question can lack `audio_url` (not yet generated by
   the user's future skill) even when its language is otherwise narrated —
   so this plan adds `&& question.audioUrl != null` to the same boolean,
   reusing the identical "just don't speak this one" fallback shape rather
   than inventing new Cubit branching or an error state.

5. **`languages.voice_id` doesn't need a schema change — its meaning just
   shifts.** It's consumed today via
   `ContentLanguageApi.fetchVoiceId`/`ContentLanguageRepository.voiceIdFor`
   (`lib/core/content_language/content_language_api.dart:38-47`,
   `content_language_repository.dart:44-51`) purely to decide "is narration
   available for this language" — `ElevenLabsTtsService.setLanguage` never
   does anything with the actual voice string except store it
   (`elevenlabs_tts_service.dart:35-39`). After this plan, the app still
   only needs the yes/no signal (renamed in intent, not in code: "has
   this language's narration been provisioned" instead of "which live
   ElevenLabs voice to hit") — `voice_id`'s non-null-ness keeps working as
   that signal with **zero changes** to `ContentLanguageApi`/
   `ContentLanguageRepository`. The literal voice ID remains meaningful too:
   it's exactly what the user's separate audio-generation skill will need to
   know which ElevenLabs voice to synthesize with per language — so the
   column's producer-side purpose is unchanged, only its app-side consumer
   changes what it does with the value. Plan 010's rollout mechanism ("set
   `voice_id` back to `NULL` to disable narration for a language, no code
   change") is preserved exactly.

6. **`dio` becomes fully unused once ElevenLabs is removed.** `grep -rln
   "package:dio" lib/` returns exactly three files:
   `core/network/api_exception.dart` (the `ApiException.fromDio` factory,
   added by plan 010 specifically as "the `fromSupabase` of this project's
   first external REST API"), `core/network/elevenlabs_client.dart`, and
   `features/quiz_play/data/elevenlabs_tts_api.dart`. All ElevenLabs call
   sites are deleted by this plan (see Implementation steps), so
   `ApiException.fromDio` (`api_exception.dart:127-180`) has no remaining
   caller and `dio: ^5.7.0` has no remaining import — this plan removes both
   as a direct, in-scope consequence, not speculative cleanup. This also
   restores plan 010 Research finding #1's original observation ("this
   project has no Dio anywhere today") back to true.

7. **No dedicated unit test exists for the concrete TTS implementation
   today**, confirmed via `find test -iname "*elevenlabs*"` (zero results) —
   only `quiz_play_cubit_test.dart`'s hand-written `_FakeTtsService` is
   tested against. The new storage-backed implementation follows the same
   convention: no new test file, `quiz_play_cubit_test.dart`'s existing fake
   and test cases are what get updated/extended.

8. **`ELEVENLABS_API_KEY` lives only in the gitignored `dart_define.json`**
   (confirmed via `git check-ignore -v dart_define.json`) and
   `.vscode/launch.json`'s `--dart-define-from-file=dart_define.json` args
   (which don't name individual keys). No tracked file references the key by
   name outside `.claude/plans/010-...md` itself, so there is no source file
   to edit for its removal — only a manual local step (§ Risks & rollout
   notes).

## Assumptions & open questions

- **`TtsService`'s name and `speak()`'s parameter are kept, not renamed**,
  even though the abstraction is no longer "text-to-speech" at runtime (no
  synthesis happens in the app anymore — it plays a pre-made file). This
  mirrors plan 010's own precedent of widening the interface rather than
  renaming it when the concrete implementation changed
  (`flutter_tts` → ElevenLabs). `speak(String text)` becomes
  `speak(String audioUrl)` — a parameter rename/re-typing, not a new method.
  If a reviewer would rather rename the whole seam (`TtsService` →
  `QuestionAudioService` or similar) now that synthesis is gone for good,
  that's a reasonable call but a bigger diff across `quiz_play_cubit.dart`,
  its test, and the screen — flagging it here rather than deciding it
  unilaterally.
- **`question-audio` is a new bucket, not a prefix inside `question-media`.**
  Keeps independent lifecycle/policy tuning and mirrors the project's
  existing one-bucket-per-asset-type convention (`question-media`,
  `avatars`). If the user's forthcoming audio-generation skill would rather
  reuse `question-media` with an `audio/` prefix, that's a one-line change to
  the bucket migration and the contract doc below — not assumed here.
  Building or extending that skill is explicitly the user's own follow-up.
- **Public-read bucket**, matching `question-media`'s existing policy and
  reasoning. Narration audio isn't more sensitive than question text/images
  already served publicly, and a private bucket would require fetching a
  signed URL through the Supabase SDK before every play — re-adding exactly
  the kind of extra network round-trip this plan exists to remove.
- **No `audio_url` values are backfilled by this plan.** Every question ships
  with `audio_url IS NULL` until the user's separate skill populates it —
  intentional per the fail-open design (Research finding 4), and mirrors
  plan 010's own "rollout inherently staged" precedent for `voice_id`.
- **Storage path convention is `question-audio/<language_code>/<question
  id>.mp3`**, one file per `questions` row (since each row is already
  single-language — Research finding 2), format `mp3` to match what
  `elevenlabs_tts_api.dart` already requested (`output_format:
  mp3_44100_128`) and what `ElevenLabsTtsService` already declared
  (`mimeType: 'audio/mpeg'`) — so any audio already generated under plan 010
  in that format needs no re-encoding if reused. This is the contract the
  user's separate skill must follow; see § Data model / API changes.
- **`tts_excluded` questions are expected to never get an `audio_url`** — the
  audio-generation skill (out of scope here) should skip them, same as the
  live-synthesis path already skips them via
  `!question.ttsExcluded` in `_beginQuestion`. Nothing enforces this in the
  DB (no constraint added); it's a documented expectation for the
  out-of-scope skill, not a rule this plan's schema needs to police.

## Design overview

Today: `QuizPlayCubit` → `TtsService.speak(question.text)` →
`ElevenLabsTtsService` → live `POST /v1/text-to-speech/{voice_id}` →
bytes → temp file → `audioplayers`.

After this plan: `QuizPlayCubit` → `TtsService.speak(question.audioUrl)` →
new `StoredAudioTtsService` → `audioplayers` plays the Supabase Storage URL
directly (`UrlSource`, no download/temp-file step needed — `audioplayers`'
`UrlSource` is a plain `setSourceUrl(isLocal: false)`, which is the
long-standing cross-platform network-playback path; the Darwin
`BytesSource` limitation that forced `ElevenLabsTtsService`'s temp-file
detour never applied to `UrlSource`).

Two independent gates decide whether a question speaks, both fail-open:
- **Language-level** (unchanged mechanism): `languages.voice_id IS NOT NULL`
  → `_ttsAvailable`, set once in `startLevel`.
- **Question-level** (new): `question.audioUrl != null`, checked per question
  in `_beginQuestion` — a question can lack audio even in an otherwise-live
  language, e.g. newly added content the audio-generation skill hasn't
  reached yet.

Data flow for a new question becoming narratable, end to end (only the first
two steps are this plan's responsibility):
1. `generate-questions` skill authors question text → reviewed → inserted
   into `questions` (untouched by this plan).
2. *(Out of scope, user's own future skill)* reads un-narrated questions,
   synthesizes audio via ElevenLabs using `languages.voice_id`, uploads to
   `question-audio/<language_code>/<id>.mp3`, sets `questions.audio_url`.
3. Next time a level containing that question is dealt, `start_level_attempt`
   includes its `audioUrl` in the response; the app plays it.

## Implementation steps

### Phase 1 — Supabase: schema, storage, RPC

- [ ] **New migration** `supabase/migrations/20260917100000_add_audio_url_to_questions.sql`:
  ```sql
  begin;

  alter table public.questions
    add column if not exists audio_url text;

  commit;
  ```
  Mirrors `20260916120000_add_voice_id_to_languages.sql` exactly (same
  `add column if not exists`, same transaction shape).

- [ ] **New migration** `supabase/migrations/20260917100100_question_audio_storage_bucket.sql`:
  create the `question-audio` bucket (public) and its public-read policy,
  mirroring `20260907130000_storage_buckets.sql`'s `question-media` block
  line-for-line:
  ```sql
  insert into storage.buckets (id, name, public)
  values ('question-audio', 'question-audio', true)
  on conflict (id) do nothing;

  drop policy if exists "question-audio public read" on storage.objects;
  create policy "question-audio public read"
    on storage.objects for select
    using (bucket_id = 'question-audio');
  ```
  No insert/update/delete policy is added for `authenticated` — uploads are
  done by the user's separate skill via the service-role key outside the
  app, the same way `question-media`'s own images are populated today (no
  authenticated-upload policy exists for `question-media` either).

- [ ] **New migration** `supabase/migrations/20260917100200_start_level_attempt_audio_url.sql`:
  `create or replace function public.start_level_attempt(...)` with the
  exact body of the current live version
  (`supabase/migrations/20260917090000_start_level_attempt_free_to_start.sql:24-143`),
  changing only the `jsonb_build_object` at the current lines 94–105 to add
  one field:
  ```sql
  select jsonb_build_object(
      'id', q.id,
      'subcategoryId', q.subcategory_id,
      'difficulty', q.difficulty,
      'text', q.prompt,
      'options', q.options,
      'correctIndex', q.correct_index,
      'explanation', q.explanation,
      'hasImage', q.kind = 'image',
      'imageAsset', q.media_url,
      'ttsExcluded', q.tts_excluded,
      'audioUrl', q.audio_url
    ) as row
  ```
  Header comment should state plainly (matching 20260917090000's own style):
  "Signature and every other line of `start_level_attempt` are unchanged;
  this migration only adds `audioUrl` to the per-question JSON payload."
  Re-grant: `grant execute on function public.start_level_attempt(uuid,
  smallint, text) to authenticated;` (unchanged signature, but re-run for
  safety/consistency with prior migrations' own pattern).

- [ ] Apply all three migrations to the connected dev project (this repo's
  established workflow per plan 007/010 — migrations are applied directly,
  confirmed dev-shaped project). Run `get_advisors` afterward, matching plan
  007's own practice of catching RLS/grant gaps post-apply.

### Phase 2 — Flutter: domain + data layer

- [ ] `lib/features/quiz_play/domain/question.dart`: add one field to the
  `@freezed` constructor, near `ttsExcluded` (both are TTS-related and
  optional):
  ```dart
  /// The pre-generated narration clip for this question, or `null` when
  /// none has been generated yet. Sourced from `questions.audio_url`.
  String? audioUrl,
  ```
  Then regenerate: `dart run build_runner build --delete-conflicting-outputs`
  (updates `question.freezed.dart` and `question.g.dart` — both checked in,
  per this repo's existing convention of committing generated files).

- [ ] `lib/features/quiz_play/data/quiz_play_api.dart`: in
  `_questionFromRow` (lines 68-79), add:
  ```dart
  audioUrl: row['audioUrl'] as String?,
  ```
  matching the RPC's new `audioUrl` key exactly (same camelCase convention
  every other field here already follows).

- [ ] `lib/core/content_language/content_language_api.dart:38-47` and
  `content_language_repository.dart:44-51`: **no signature/behavior
  change** — update only the doc comments on `fetchVoiceId`/`voiceIdFor` to
  reflect the shifted meaning (Research finding 5): they now answer "is
  narration provisioned for this language" for the app's purposes, while
  the literal voice ID remains meaningful to the user's separate
  audio-generation skill.

### Phase 3 — Flutter: TTS seam

- [ ] `lib/features/quiz_play/data/tts_service.dart`: widen `speak`'s doc
  comment and signature:
  ```dart
  /// Plays the pre-generated narration clip at [audioUrl]. Completion (or
  /// cancellation) fires whichever callback was last registered via
  /// [onComplete].
  Future<void> speak(String audioUrl);
  ```
  Update the class-level doc comment too — it currently explains why a fake
  is needed for `bloc_test`/`fake_async` (still true, keep that part) but no
  longer needs a network call to synthesize speech, only to fetch/play a
  file; reword accordingly.

- [ ] **New file** `lib/features/quiz_play/data/stored_audio_tts_service.dart`:
  ```dart
  import 'package:audioplayers/audioplayers.dart';
  import 'package:quizoo/features/quiz_play/data/tts_service.dart';

  /// The real [TtsService], playing a pre-generated audio file straight
  /// from its Supabase Storage URL via `audioplayers`. No download/temp-file
  /// step: unlike `BytesSource` (unsupported on Darwin — see the deleted
  /// `ElevenLabsTtsService`'s doc comment), `UrlSource` is a plain
  /// `setSourceUrl(isLocal: false)`, supported on every platform this app
  /// ships to.
  class StoredAudioTtsService implements TtsService {
    StoredAudioTtsService() {
      _player.onPlayerComplete.listen((_) => _onComplete?.call());
    }

    final AudioPlayer _player = AudioPlayer(playerId: 'tts_stored_audio');
    void Function()? _onComplete;

    @override
    Future<bool> setLanguage(String languageCode, {String? voiceId}) async =>
        voiceId != null;

    @override
    Future<void> speak(String audioUrl) async {
      try {
        await _player.play(UrlSource(audioUrl));
      } catch (_) {
        // Fail open: never leave the question stuck in the "speaking"
        // phase on a network/playback failure.
        _onComplete?.call();
      }
    }

    @override
    Future<void> stop() async => _player.stop();

    @override
    void onComplete(void Function() callback) => _onComplete = callback;

    @override
    Future<void> dispose() => _player.dispose();
  }
  ```

- [ ] **Delete** `lib/features/quiz_play/data/elevenlabs_tts_service.dart`,
  `lib/features/quiz_play/data/elevenlabs_tts_api.dart`,
  `lib/core/network/elevenlabs_client.dart`.

- [ ] `lib/core/network/api_exception.dart`: delete the `ApiException.fromDio`
  factory (lines 123-180) and the now-unused `import 'package:dio/dio.dart';`
  (line 4) — no remaining caller after the deletions above (Research
  finding 6).

- [ ] `pubspec.yaml`: remove the `dio: ^5.7.0` dependency (line 51) — no
  remaining import anywhere in `lib/` after the above. Run `flutter pub get`
  and confirm `pubspec.lock` drops it too.

### Phase 4 — Flutter: Cubit + screen wiring

- [ ] `lib/features/quiz_play/presentation/bloc/quiz_play_cubit.dart`,
  `_beginQuestion` (lines 253-287): widen the speak gate and pass the URL
  instead of the text:
  ```dart
  final speaksThisQuestion =
      _audioOn && _ttsAvailable && !question.ttsExcluded &&
      question.audioUrl != null;
  ```
  and
  ```dart
  if (speaksThisQuestion) {
    _ttsService.onComplete(() => _onSpeechComplete(beganAt));
    unawaited(_ttsService.speak(question.audioUrl!));
  } else {
    _startClock();
  }
  ```
  `startLevel` (lines 185-196) is unchanged — it still calls
  `_contentLanguageRepository.voiceIdFor(languageCode)` then
  `_ttsService.setLanguage(languageCode, voiceId: voiceId)`; only what that
  result *means* has shifted (Research finding 5), not the code.

- [ ] `lib/features/quiz_play/presentation/screens/quiz_play_screen.dart`:
  swap the construction site (lines 75-91) —
  ```dart
  StoredAudioTtsService(),
  ```
  replacing `ElevenLabsTtsService(ElevenLabsTtsApi())` — and swap the two
  `elevenlabs_*` imports (lines 23-24) for
  `package:quizoo/features/quiz_play/data/stored_audio_tts_service.dart`.

### Phase 5 — Tests

- [ ] `test/features/quiz_play/quiz_play_cubit_test.dart`:
  - `_FakeTtsService.speak` (line 43): rename the recorded list's intent
    (still `List<String> spoken`, now recording URLs, not text) — no
    structural change needed, just note in a comment that it now captures
    `audioUrl` values.
  - The module-level `questions` fixture (lines 99-102, built from
    `MockQuestions.forLevel(...)`) needs a non-null `audioUrl` on every
    question, since most existing tests assert speaking-phase behavior with
    `soundOn: true` and would otherwise silently fall into the new
    "no audio" branch. Map it once where it's built:
    ```dart
    final questions = MockQuestions.forLevel(
      subcategoryId: MockCatalog.footballId,
      levelNumber: 12,
    ).map((q) => q.copyWith(audioUrl: 'https://cdn.test/audio.mp3')).toList();
    ```
    (`MockQuestions`/`mock_questions.dart` itself is untouched — it's a
    design-review/test fixture pool, confirmed unused by any real play path
    via `grep -rln "MockQuestions" lib/`, whose one production hit,
    `lib/app/router.dart:428`, is an unrelated report-question-sheet demo
    route.)
  - **New test**, mirroring the existing `'a ttsExcluded question skips
    straight to answering, audio or not'` (lines 278-302) exactly in shape:
    ```dart
    test(
      'a question with no audioUrl skips straight to answering, audio or '
      'not',
      () {
        stubQuestions([
          questions.first.copyWith(audioUrl: null),
          ...questions.skip(1),
        ]);
        when(() => settingsRepository.current)
            .thenReturn(const AppSettings(soundOn: true));
        fakeAsync((async) {
          final cubit = buildCubit();
          unawaited(start(cubit));
          async.flushMicrotasks();
          cubit.skipCountdown();

          final state = cubit.state as QuizPlayInProgress;
          expect(state.phase, QuestionPhase.answering);
          expect(ttsService.spoken, isEmpty);

          unawaited(cubit.close());
          async.flushMicrotasks();
        });
      },
    );
    ```
  - Every other existing test in this file keeps passing unmodified once the
    fixture-level `audioUrl` default above is in place — they assert on
    `ttsService.spoken`/phase transitions, not on the literal string
    content, so switching from spoken text to a spoken URL changes nothing
    they check.
- [ ] Confirm no other test references `ElevenLabsTtsService`/
  `ElevenLabsTtsApi`/`elevenLabsClient` (none found via `grep -rln
  "ElevenLabs" test/` during research — re-check at execution time since
  code may have moved).
- [ ] Run `flutter analyze` (zero warnings, CLAUDE.md §8) and the full test
  suite.

### Phase 6 — Docs

- [ ] `.claude/docs/backend/01-supabase-project-setup.md`, "## 5. Storage
  buckets" section (currently lines 115-124): add a third bullet alongside
  `question-media`/`avatars`:
  ```
  - `question-audio` — public read (pre-generated question narration clips
    referenced by `questions.audio_url`). Public, for the same reason as
    `question-media`: no signed-URL round trip needed for playback.
  ```

## Data model / API changes

**`questions` table** — new column:
| Column | Type | Nullable | Notes |
|---|---|---|---|
| `audio_url` | `text` | yes | Full public Storage URL; `NULL` until generated |

**Storage bucket** `question-audio` (public read, no authenticated-write
policy — uploads happen out-of-band via service-role key, matching
`question-media`'s existing precedent).

**Contract for the user's separate audio-generation skill** (documented here
for that future work to conform to; not built by this plan):
- Path: `question-audio/<language_code>/<question id>.mp3` — one file per
  `questions` row (each row is already single-language, so no per-voice
  fan-out is needed).
- Format: `mp3` (matches the `mp3_44100_128` output format and
  `audio/mpeg` mime type the deleted `elevenlabs_tts_api.dart`/
  `elevenlabs_tts_service.dart` already used — any audio already produced
  under plan 010's live path can be reused as-is if captured to storage).
- After upload, set `questions.audio_url` to the full public URL:
  `{SUPABASE_URL}/storage/v1/object/public/question-audio/<language_code>/<question id>.mp3`
  (mirrors `media_url`'s existing full-URL convention — confirmed via
  `question_media_plate.dart` consuming `imageAsset` directly with no URL
  construction in Dart).
- Voice to synthesize with: `languages.voice_id` for that question's
  `language_code` (unchanged column, unchanged meaning for this purpose).
- Questions with `tts_excluded = true` should be skipped (no audio needed —
  mirrors the app's own existing skip behavior).

**`start_level_attempt` RPC response** — each entry in `questions[]` gains one
field: `audioUrl: string | null`.

## Dependencies

- **Remove**: `dio: ^5.7.0` (Phase 3) — no remaining caller after ElevenLabs
  deletion (Research finding 6).
- **No additions**: `audioplayers` (already a dependency, already used for
  `UrlSource`-style network playback elsewhere in this ecosystem) is
  sufficient for the new `StoredAudioTtsService`; no new package needed.

## Testing strategy

Matches this project's existing convention exactly (Research finding 7):
`quiz_play_cubit_test.dart`'s `bloc_test`/`fake_async`-based suite against a
hand-written `_FakeTtsService`, extended with one new case for the
no-`audioUrl` fallback (Phase 5) — no new test file for the concrete
`StoredAudioTtsService` implementation, since no such file exists today for
`ElevenLabsTtsService` either (repository-level integration with real
`audioplayers`/network isn't unit-tested in this codebase; the Cubit-level
fake is the coverage boundary CLAUDE.md §11 and this project's own practice
rely on).

## Edge cases & error handling

- **`audio_url` is `NULL` for a question** (not yet generated): falls back to
  silent mode for that one question only, via the new
  `question.audioUrl != null` gate — same fail-open shape as `ttsExcluded`
  and the language-level "no voice pack" case (Research finding 4).
- **`audio_url` points at a file that 404s or fails to decode** (deleted from
  storage, bad upload): `StoredAudioTtsService.speak`'s `try/catch` calls
  `_onComplete` immediately, matching `ElevenLabsTtsService`'s existing
  never-throws contract — the question silently skips to answering instead
  of hanging in the "speaking" phase.
- **Slow network / the Storage GET is slow**: no different in kind from
  today's ElevenLabs round-trip (already an accepted, documented plan 010
  risk); not solved by this plan (see Risks below and the explicit
  caching/prefetching scope exclusion).
- **A `languages` row has `voice_id` set but zero questions in that language
  have `audio_url` yet** (e.g. a brand-new language, or right after this
  plan ships before the audio-generation skill has run): every question in
  that language falls back to silent narration individually — the level
  still plays normally, just without narration, until the skill catches up.
  No special-casing needed; this is the same per-question gate handling it
  automatically.

## Acceptance criteria

- [ ] `questions.audio_url` column exists; `start_level_attempt` includes
  `audioUrl` in its response for every question.
- [ ] `question-audio` bucket exists, public-read, with a policy mirroring
  `question-media`'s.
- [ ] A question with a real `audio_url` set plays that file via
  `StoredAudioTtsService` during a level (manually verified: set one row's
  `audio_url` to a real uploaded mp3's public URL, play that level with
  sound on).
- [ ] A question with `audio_url IS NULL` skips straight to the answering
  phase with sound on, no error, no stuck "speaking" state.
- [ ] `ElevenLabsTtsService`, `ElevenLabsTtsApi`, `elevenLabsClient`,
  `ApiException.fromDio`, and the `dio` dependency are all removed; `grep
  -rln "elevenlabs\|package:dio" lib/` returns nothing.
- [ ] `flutter analyze` is clean (CLAUDE.md §8) and the full test suite,
  including the new no-`audioUrl` case, passes.
- [ ] `.claude/docs/backend/01-supabase-project-setup.md`'s storage bucket
  list includes `question-audio`.

## Risks & rollout notes

- **This plan alone does not narrate anything.** Every `audio_url` ships
  `NULL` — narration stays silent for every question until the user's
  separate (not-yet-built) audio-generation skill populates them, which is
  intentional (mirrors plan 010's own "rollout inherently staged" note for
  `voice_id`). Nothing breaks in the meantime; it behaves exactly like "TTS
  off," which is today's default whenever `voice_id` is unset.
- **Network-latency regression is not fixed, only relocated.** Plan 010
  flagged ElevenLabs' round-trip as a UX regression versus the old
  on-device `flutter_tts` and explicitly deferred prefetching/caching as a
  follow-up. This plan trades an ElevenLabs POST for a Supabase Storage GET
  — likely faster and more reliable in practice (static file behind
  Supabase's CDN vs. a live generation call), but still a network hop before
  audio starts. If that's still a visible pause, the deferred
  prefetch-during-countdown / local-cache-after-first-play work (out of
  scope here) is the fix.
- **Orphaned files.** If a question is ever deleted or its audio
  regenerated, the old file at its storage path isn't automatically cleaned
  up by anything in this plan (no DB trigger, no lifecycle rule). Same
  file/URL is simply overwritten on regeneration since the path is
  deterministic (`<language_code>/<question id>.mp3`), so regeneration is
  safe; only question *deletion* can strand a file. Not addressed here —
  flagging as a known gap, consistent with this plan's scope boundary
  (the skill that manages these files is out of scope).
- **Manual local cleanup, not code.** `ELEVENLABS_API_KEY` in the
  gitignored `dart_define.json` can be removed locally once this plan ships
  — no tracked file references it by name (Research finding 8), so there's
  nothing for this plan to edit, only a note for whoever runs the app
  locally afterward. If `ELEVENLABS_API_KEY` was ever added to a CI/build
  secrets store outside this repo, that's outside this plan's visibility
  and should be checked separately.
- **Rollback** is as simple as plan 010's own: nothing here is destructive.
  Reverting the three new migrations (drop column, drop bucket/policy,
  restore the prior `start_level_attempt` body) and restoring the deleted
  Flutter files from git history fully reverses this plan if needed.
