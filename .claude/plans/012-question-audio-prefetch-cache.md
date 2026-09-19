# Question-Audio Prefetch & Local Cache

> Source spec: provided inline in conversation. The user described a concrete
> UX bug — a level's first question (and any question whose narration hasn't
> finished downloading yet) shows on screen before its audio is ready to
> play, because today's `StoredAudioTtsService` streams straight from the
> Supabase Storage URL with no local cache — and asked for a caching
> mechanism that (a) starts warming the cache during the level's countdown
> screen and (b) keeps a window of ~5 upcoming questions' audio cached ahead
> of the player for the rest of the level.
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation
history. Start by reading it in full. Code may have moved on since it was
written (dated 2026-09-19), so spot-check the referenced files and line
numbers still match before you begin — especially `quiz_play_cubit.dart`,
which is dense and has been touched by three prior plans (007, 010, 011).

## Objective

Eliminate the "audio not ready yet" gap on `quiz_play` by prefetching each
question's narration clip to local disk ahead of when it's needed: the first
handful of questions during the 3-beat countdown (S-10), and a rolling
look-ahead window of upcoming questions as the player advances through the
level. Playback (`StoredAudioTtsService`) plays the local file when it's
already cached and falls back to today's direct network stream when it
isn't — so this is a pure performance improvement with no new failure mode
and no change to the existing fail-open contract (plan 011, Research finding
4).

## Scope

**In scope:**
- A new local disk cache for pre-generated question-narration files
  (`questions.audio_url`), keyed by URL, shared across the whole app session
  (and, since it's a disk cache, across app restarts too).
- A prefetch trigger fired from `QuizPlayCubit.startLevel` (during the S-10
  countdown) for the first N questions, and from `QuizPlayCubit._beginQuestion`
  on every question transition to keep N questions ahead of the current one
  cached.
- Updating `StoredAudioTtsService.speak` to play the cached local file when
  present, falling back to the existing direct-`UrlSource` network path
  otherwise (unchanged behavior in the fallback case).
- One new dependency: `flutter_cache_manager`, which supplies the on-disk
  LRU-style store, download plumbing, and staleness/eviction policy so this
  plan doesn't hand-roll file I/O, path management, or cache invalidation.
- Test coverage for the new prefetch triggering logic in
  `quiz_play_cubit_test.dart`, following this project's existing
  `bloc_test`/fake-collaborator convention (no new dedicated test file for
  the concrete cache-manager-backed service, matching how
  `StoredAudioTtsService`/`AudioplayersSoundEffectsService` are already
  untested at that layer — Research finding 5).

**Out of scope:**
- `daily` and `duel` — confirmed via `grep -rln "TtsService\|audio_url"
  lib/features/daily lib/features/daily` and the same for `duel`: neither
  feature has narration today (`DailyQuestion`, `lib/features/daily/domain/
  daily_question.dart:6-10`, explicitly documents "no media/TTS fields...
  since the daily challenge has... no... narration"). This plan touches only
  `lib/features/quiz_play/`.
- Any backend/Supabase change. `questions.audio_url` and the
  `start_level_attempt` payload already carry everything needed (plan 011);
  this plan is 100% client-side caching of data already in hand.
- Prefetching or caching question **images** (`imageAsset`/`media_url`).
  Flutter's own `Image.network` already has an implicit in-memory decode
  cache and the spec is specifically about audio; not touched.
- Changing what plays when audio is muted, or making the mute toggle
  (`toggleQuestionAudio`) retroactively warm the cache. See Assumptions
  below — deliberately kept out to keep this change small and low-risk.
- A user-facing cache-management UI (e.g. a Settings "clear audio cache"
  action). Nothing currently exists for this and the spec didn't ask for it.
- Tuning/replacing the sound-effect assets (`assets/audio/*.mp3`) — those are
  bundled app assets played via `AudioplayersSoundEffectsService`, already
  local, and unaffected by anything here.

## Research findings

1. **The exact gap this plan fixes.** `StoredAudioTtsService.speak`
   (`lib/features/quiz_play/data/stored_audio_tts_service.dart:22-31`) calls
   `_player.play(UrlSource(audioUrl))` directly — every play is a live
   Supabase Storage GET, with no local cache in front of it. Plan 011 itself
   flagged this exact scenario as a known, deliberately deferred risk
   ("Network-latency regression is not fixed, only relocated... the deferred
   prefetch-during-countdown / local-cache-after-first-play work... is the
   fix" — `011-pregenerated-question-audio.md`, Risks & rollout notes). This
   plan is that deferred follow-up.

2. **The countdown is a real Cubit state with a real time window to exploit.**
   `QuizPlayCubit.startLevel` (`lib/features/quiz_play/presentation/bloc/
   quiz_play_cubit.dart:135-224`) emits `QuizPlayCountdown(run: run, beat: 3)`
   and then ticks `_scheduleNextBeat()` once per second
   (`countdownBeat = Duration(seconds: 1)`, line 75) until "GO" and the first
   `_beginQuestion` call. That's a real (if short — 3 seconds, or instantly
   skippable via `skipCountdown()`/tap, S-10) window in which a prefetch can
   be kicked off with zero UI changes: `CountdownView`
   (`lib/features/quiz_play/presentation/screens/countdown_screen.dart`) is a
   pure view over Cubit state and needs no changes — the prefetch trigger
   belongs entirely in the Cubit, not the widget.

3. **`QuizPlayCubit` already owns everything a look-ahead scheduler needs.**
   `_questions` (the full, already-fetched `List<Question>` for the level —
   20 per level, confirmed via `MockQuestions.questionsPerLevel = 20`,
   `lib/features/quiz_play/data/mock_questions.dart:14`, and
   `QuizPlayApi.fetchLevelQuestions` returning the whole level in one RPC
   call) and `_questionIndex` (the current position, advanced in `next()`,
   line 565) are both already fields on the Cubit
   (`quiz_play_cubit.dart:101-102`). No new state needs to be threaded in —
   the prefetch scheduler is two calls to a new collaborator from code paths
   that already run: once in `startLevel` (right after `_ttsAvailable` is
   resolved, line ~195) and once at the top of `_beginQuestion` (line
   253-264), the same method that already computes `speaksThisQuestion`.

4. **The existing fail-open TTS contract dictates the cache-miss behavior.**
   `_beginQuestion`'s `speaksThisQuestion` gate and `StoredAudioTtsService`'s
   `try/catch`-everything `speak()` (Research finding 1) mean nothing in this
   codebase ever blocks a question on audio being ready — a slow or failed
   fetch just plays late or not at all, never hangs the UI. This plan
   preserves that exactly: prefetching is a pure best-effort optimization.
   If a question's audio isn't cached yet when `_beginQuestion` reaches it,
   `speak()` falls back to exactly today's direct-`UrlSource` network path —
   there is no new blocking wait, no new error state, no new user-visible
   failure mode versus today.

5. **No caching precedent exists anywhere in this codebase yet.** `find . -iname
   "*cache*"` across `lib/`, `pubspec.yaml`, and the whole repo (excluding
   `android/.gradle`, `ios/Pods`, `build/`, `.dart_tool/`) turns up nothing —
   `QuizPlayRepository`'s in-memory `_prefetched` map (`lib/features/
   quiz_play/data/quiz_play_repository.dart:28`) is the closest existing
   thing, and it caches parsed `Question` objects in memory for the run's
   lifetime, not files on disk. This plan is the first place a real disk
   cache is introduced, which is why it reaches for a maintained package
   (`flutter_cache_manager` — see Dependencies) rather than hand-rolling
   file paths, download queuing, and eviction from scratch: CLAUDE.md's
   minimalism principle argues against building a bespoke LRU/staleness
   system when a well-established one-purpose package does exactly this and
   is already the transitive dependency `cached_network_image`-style
   packages in the Flutter ecosystem build on.

6. **Neither `StoredAudioTtsService` nor `ElevenLabsTtsService` before it has
   a dedicated unit test** (`find test -iname "*tts*"` returns only
   `quiz_play_cubit_test.dart`'s hand-written `_FakeTtsService` — confirmed
   again for this plan, mirroring plan 011's own Research finding 7). The
   concrete cache-manager-backed service this plan adds follows the same
   established convention: exercised indirectly via the Cubit's fakes, not a
   standalone test file.

7. **`QuizPlayCubit`'s constructor already takes five collaborators
   positionally** (`_repository, _settingsRepository,
   _contentLanguageRepository, _ttsService, _soundEffects` —
   `quiz_play_cubit.dart:57-63`), and `quiz_play_screen.dart:74-90`
   constructs every concrete implementation inline at the `BlocProvider`
   site (`StoredAudioTtsService()`, `AudioplayersSoundEffectsService()`) —
   none of these go through `app.dart`'s `MultiRepositoryProvider`. The new
   audio-cache collaborator follows the exact same pattern: a sixth
   positional constructor argument, constructed inline in
   `quiz_play_screen.dart`, not registered app-wide. This is safe specifically
   *because* the underlying `flutter_cache_manager` store is disk-backed and
   internally deduplicates via its own singleton `CacheManager` subclass
   (the package's own documented pattern — see Design overview) — so a fresh
   Dart-level wrapper object on every screen build still shares the same
   physical cache, unlike `QuizPlayRepository`, which needs app-root scope
   because *its* cache is in-memory only (`quiz_play_repository.dart:17-22`'s
   own doc comment explains exactly this distinction for that class).

## Assumptions & open questions

- **Look-ahead window size: 5 questions**, taken directly from the user's own
  suggestion. With 20 questions per level (Research finding 3) and each
  pre-generated narration clip being a short spoken sentence (~54 characters
  average per plan 011's own cost analysis) encoded as `mp3_44100_128`, five
  clips is on the order of a few hundred KB total — a small, safe burst even
  on a slow connection, while comfortably covering the 3-second countdown
  plus several questions' worth of the per-question answer window as slack
  time for the rest to land. The number is a single named constant
  (`QuizPlayCubit.audioPrefetchWindow`), trivially tunable later without
  touching the scheduling logic itself.
- **Prefetching is gated on `_ttsAvailable`, not recomputed for mute
  toggles.** `_ttsAvailable` is already `false` for the whole run whenever
  the player started the level muted (`quiz_play_cubit.dart:185-195`:
  `_ttsAvailable = false` in the `else` branch, without even checking
  whether the language has a voice pack). That means a player who starts a
  level muted and then un-mutes mid-level via the HUD speaker
  (`toggleQuestionAudio`, line 322) gets zero prefetch benefit for the rest
  of that level — they fall back to exactly today's direct-network play for
  every remaining question, no worse than the status quo. Fixing this would
  mean calling `_contentLanguageRepository.voiceIdFor` (a real network call,
  confirmed via `content_language_repository.dart:51-57`) unconditionally on
  every level start regardless of mute state, which is a real behavioral and
  cost change to an already-tested code path for a secondary scenario the
  user didn't ask about. Flagging this as an explicit, deliberate scope cut
  — if the user wants the toggle-back-on path to also benefit, that's a
  small follow-up (recompute `_ttsAvailable`'s underlying voice-pack check
  independent of mute), not part of this plan.
- **`flutter_cache_manager` is the right dependency**, not a hand-rolled
  `dart:io` + `path_provider` implementation. Justification is Research
  finding 5. If the user would rather avoid a new third-party dependency for
  such a small feature, the hand-rolled alternative is a bigger, riskier
  diff (own eviction policy, own path management, own staleness rules) for
  no functional benefit — flagging the trade-off here rather than deciding
  it unilaterally, though this plan's Implementation steps assume the
  package.
- **Cache config: `maxNrOfCacheObjects: 500`, `stalePeriod: Duration(days:
  30)`.** Chosen to comfortably hold many recently-played levels'-worth of
  clips (25 levels × 20 questions) without unbounded disk growth, and to
  bound how long a cached clip can outlive a possible future re-generation
  of the same `audio_url` (plan 011's own "Orphaned files" risk note — a
  path is only ever overwritten on regeneration, never invalidated
  server-side, so a 30-day stale period is the mechanism that eventually
  self-heals a stale local copy rather than caching it forever). Both are
  easily tunable constants if the real numbers turn out to want adjusting
  after rollout.
- **No cancellation of in-flight downloads on level-quit or Cubit close.**
  If a player quits mid-level, any downloads already kicked off by the
  prefetch window continue to completion in the background and land in the
  shared disk cache — this is treated as a *feature*, not a bug: it means a
  replayed or retried level (or another level reusing the same question via
  the shared question bank) gets a cache hit it wouldn't otherwise have.
  Nothing needs to actively cancel them, since `flutter_cache_manager`'s
  `downloadFile` calls are independent of the Cubit's own lifecycle.

## Design overview

```
QuizPlayCubit
  ├─ startLevel()      → (._ttsAvailable) → _prefetchWindow(0)      [fires during S-10 countdown]
  └─ _beginQuestion()  → (._ttsAvailable) → _prefetchWindow(index+1) [fires on every question transition]
                                                    │
                                                    ▼
                                    QuestionAudioCacheService.prefetch(urls)
                                                    │
                                                    ▼
                              CacheManagerAudioCacheService (flutter_cache_manager)
                                     ├─ getFileFromCache(url)  → already cached? skip
                                     └─ downloadFile(url)      → not cached? fetch to disk

StoredAudioTtsService.speak(audioUrl)
      │
      ▼
QuestionAudioCacheService.localPathFor(audioUrl)
      │
      ├─ non-null (cache hit)  → AudioPlayer.play(DeviceFileSource(localPath))
      └─ null (cache miss)     → AudioPlayer.play(UrlSource(audioUrl))   [today's unchanged path]
                                  + kick off a background prefetch for next time
```

Two new files carry this: `question_audio_cache_service.dart` (the
abstract seam, mirroring `tts_service.dart`/`sound_effects_service.dart`'s
existing interface-file convention) and
`cache_manager_audio_cache_service.dart` (the concrete
`flutter_cache_manager`-backed implementation, mirroring
`stored_audio_tts_service.dart`/`audioplayers_sound_effects_service.dart`'s
naming convention of `<package>_<seam-name>.dart`).

`StoredAudioTtsService` gains one constructor dependency
(`QuestionAudioCacheService`) and its `speak` method gets a cache-check step
in front of the existing play call — nothing else about it changes. Its
fail-open `try/catch` wraps the whole thing, so a cache lookup failure
(unlikely, but e.g. a corrupted local sqflite index) degrades to the direct
network path exactly like a download failure would.

`QuizPlayCubit` gains one constructor dependency
(`QuestionAudioCacheService`), one new constant
(`audioPrefetchWindow = 5`), and one new private method
(`_prefetchWindow(int fromIndex)`) called from two existing methods. No
existing state, transitions, or public API change.

## Implementation steps

### Phase 1 — Dependency

- [ ] Run `flutter pub add flutter_cache_manager` (resolves the latest
  compatible version — expect `^3.4.x` — rather than hand-pinning a version
  number here that may already be stale by execution time). Confirm
  `pubspec.lock` updates and `flutter pub get` succeeds on all of this
  project's real target platforms (iOS, Android — the primary shipped
  platforms per `google_mobile_ads`/`in_app_purchase`'s presence; `web/`,
  `macos/`, `linux/`, `windows/` folders exist in the repo but nothing in
  `lib/` branches on `kIsWeb` for platform-specific behavior beyond
  `firebase_options.dart`, so this plan does not specifically validate
  desktop/web cache behavior — flag if that turns out to matter).

### Phase 2 — New cache seam

- [ ] **New file** `lib/features/quiz_play/data/question_audio_cache_service.dart`:
  ```dart
  /// A small seam over the on-disk narration-clip cache, mirroring
  /// `TtsService`/`SoundEffectsService`'s own interface-file convention so
  /// `QuizPlayCubit` and `StoredAudioTtsService` stay testable with a fake
  /// rather than a real file-system-backed implementation.
  abstract class QuestionAudioCacheService {
    /// Best-effort: downloads each of [urls] to local disk if not already
    /// cached. Never throws — a failed download for one URL doesn't stop the
    /// rest, and a caller never needs to await this to stay correct (only to
    /// stay fast).
    Future<void> prefetch(List<String> urls);

    /// The local file path already cached for [url], or `null` if it isn't
    /// cached yet. Never triggers a download — this is a fast, local-only
    /// lookup so a playback call site can decide whether to use the cached
    /// file or fall back to streaming from the network.
    Future<String?> localPathFor(String url);
  }
  ```
- [ ] **New file** `lib/features/quiz_play/data/cache_manager_audio_cache_service.dart`:
  ```dart
  import 'dart:async';

  import 'package:flutter_cache_manager/flutter_cache_manager.dart';
  import 'package:quizoo/features/quiz_play/data/question_audio_cache_service.dart';

  /// `flutter_cache_manager`'s own recommended pattern for a
  /// purpose-specific cache: a private singleton `CacheManager` subclass, so
  /// every [CacheManagerAudioCacheService] instance — however many are
  /// constructed across screen rebuilds — reads and writes the same physical
  /// on-disk store and sqflite index.
  class _QuestionAudioCacheManager extends CacheManager {
    static const key = 'questionAudioCache';
    static final _QuestionAudioCacheManager instance =
        _QuestionAudioCacheManager._();
    _QuestionAudioCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 30),
            maxNrOfCacheObjects: 500,
          ),
        );
  }

  /// The real [QuestionAudioCacheService], backed by `flutter_cache_manager`.
  class CacheManagerAudioCacheService implements QuestionAudioCacheService {
    CacheManagerAudioCacheService({BaseCacheManager? cacheManager})
      : _cacheManager = cacheManager ?? _QuestionAudioCacheManager.instance;

    final BaseCacheManager _cacheManager;

    /// Guards against queuing the same URL twice while its first download is
    /// still in flight — the window can ask for the same URL again on every
    /// question transition before the first request has landed.
    final Set<String> _inFlight = {};

    @override
    Future<void> prefetch(List<String> urls) async {
      for (final url in urls) {
        if (_inFlight.contains(url)) continue;
        final cached = await _cacheManager.getFileFromCache(url);
        if (cached != null) continue;
        _inFlight.add(url);
        unawaited(
          _cacheManager
              .downloadFile(url)
              .catchError((_) => null)
              .whenComplete(() => _inFlight.remove(url)),
        );
      }
    }

    @override
    Future<String?> localPathFor(String url) async {
      final info = await _cacheManager.getFileFromCache(url);
      return info?.file.path;
    }
  }
  ```

### Phase 3 — `StoredAudioTtsService` plays from cache first

- [ ] `lib/features/quiz_play/data/stored_audio_tts_service.dart`: add the
  new constructor dependency and cache-check step:
  ```dart
  class StoredAudioTtsService implements TtsService {
    StoredAudioTtsService(this._audioCacheService) {
      _player.onPlayerComplete.listen((_) => _onComplete?.call());
    }

    final QuestionAudioCacheService _audioCacheService;
    final AudioPlayer _player = AudioPlayer(playerId: 'tts_stored_audio');
    void Function()? _onComplete;

    @override
    Future<bool> setLanguage(String languageCode, {String? voiceId}) async =>
        voiceId != null;

    @override
    Future<void> speak(String audioUrl) async {
      try {
        final localPath = await _audioCacheService.localPathFor(audioUrl);
        if (localPath != null) {
          await _player.play(DeviceFileSource(localPath));
        } else {
          // Cache miss: unchanged from today — stream directly, and warm
          // the cache in the background so a retry/replay hits it next time.
          await _player.play(UrlSource(audioUrl));
          unawaited(_audioCacheService.prefetch([audioUrl]));
        }
      } catch (_) {
        // Fail open: never leave the question stuck in the "speaking" phase
        // on a network/playback/cache failure.
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
  Add the `question_audio_cache_service.dart` import; the class-level doc
  comment should note the added local-cache step.

### Phase 4 — `QuizPlayCubit` scheduling

- [ ] `lib/features/quiz_play/presentation/bloc/quiz_play_cubit.dart`:
  - Add the constructor dependency (sixth positional parameter, appended
    after `_soundEffects` to minimize the diff against every existing call
    site):
    ```dart
    QuizPlayCubit(
      this._repository,
      this._settingsRepository,
      this._contentLanguageRepository,
      this._ttsService,
      this._soundEffects,
      this._audioCacheService,
    ) : super(const QuizPlayPreparing());

    final QuestionAudioCacheService _audioCacheService;
    ```
  - Add the window-size constant next to the other named durations (line
    ~74-86):
    ```dart
    /// How many upcoming questions' narration this Cubit tries to keep
    /// cached ahead of the current one (spec: "maintain 5 questions cached
    /// ahead").
    static const int audioPrefetchWindow = 5;
    ```
  - In `startLevel`, right after `_ttsAvailable` is resolved and before
    `_questionIndex = 0` (current line ~196):
    ```dart
    if (_ttsAvailable) unawaited(_prefetchWindow(0));
    ```
  - At the top of `_beginQuestion` (current line ~253), after
    `_questionIndex`/`question` are read:
    ```dart
    if (_ttsAvailable) unawaited(_prefetchWindow(_questionIndex + 1));
    ```
  - New private method, placed near the other countdown/question helpers:
    ```dart
    /// Kicks off caching for up to [audioPrefetchWindow] questions starting
    /// at [fromIndex], skipping any that don't need audio at all
    /// (`ttsExcluded`, or no `audioUrl` yet). Best-effort and fire-and-forget
    /// at every call site — a slow or failed prefetch never blocks gameplay
    /// (spec §Design overview).
    Future<void> _prefetchWindow(int fromIndex) async {
      if (fromIndex >= _questions.length) return;
      final end = (fromIndex + audioPrefetchWindow).clamp(0, _questions.length);
      final urls = [
        for (var i = fromIndex; i < end; i++)
          if (!_questions[i].ttsExcluded && _questions[i].audioUrl != null)
            _questions[i].audioUrl!,
      ];
      if (urls.isEmpty) return;
      await _audioCacheService.prefetch(urls);
    }
    ```
  - Add the `question_audio_cache_service.dart` import.

### Phase 5 — Wiring at the construction site

- [ ] `lib/features/quiz_play/presentation/screens/quiz_play_screen.dart`
  (lines 74-90): construct one `CacheManagerAudioCacheService` and pass it to
  both collaborators that need it:
  ```dart
  Widget build(BuildContext context) {
    final (subcategoryId, _) = MockCatalog.parseLevelId(levelId);
    final subcategory = MockCatalog.subcategories
        .where((candidate) => candidate.id == subcategoryId)
        .firstOrNull;
    final audioCacheService = CacheManagerAudioCacheService();

    return BlocProvider<QuizPlayCubit>(
      create: (_) =>
          QuizPlayCubit(
            context.read<QuizPlayRepository>(),
            context.read<SettingsRepository>(),
            context.read<ContentLanguageRepository>(),
            StoredAudioTtsService(audioCacheService),
            AudioplayersSoundEffectsService(),
            audioCacheService,
          )..startLevel(...),
      child: _QuizPlayView(entry: entry),
    );
  }
  ```
  Swap the `stored_audio_tts_service.dart` import for also importing
  `cache_manager_audio_cache_service.dart`.

### Phase 6 — Tests

- [ ] `test/features/quiz_play/quiz_play_cubit_test.dart`:
  - New fake, matching this file's existing "fake over mocktail `Mock`"
    convention for stateful collaborators (comment at line 29-31 explains
    why for `_FakeTtsService`; the same reasoning applies here — recording
    call arguments in order matters more than stubbing return values):
    ```dart
    class _FakeAudioCacheService implements QuestionAudioCacheService {
      /// Each `prefetch` call's URL list, in call order.
      final List<List<String>> prefetchCalls = [];

      @override
      Future<void> prefetch(List<String> urls) async {
        prefetchCalls.add(urls);
      }

      @override
      Future<String?> localPathFor(String url) async => null;
    }
    ```
  - Add `late _FakeAudioCacheService audioCacheService;`, instantiate it in
    `setUp`, and add it to `buildCubit()`'s `QuizPlayCubit(...)` call as the
    sixth argument.
  - **New test**, `'starting a level with audio available prefetches the
    first audioPrefetchWindow questions during the countdown'`: stub
    `settingsRepository.current` to `soundOn: true` (this suite's existing
    default is `soundOn: false` — see line 110-116 — so this test opts in
    explicitly, matching how the file's other audio-specific tests already
    do), call `start(cubit)`, flush microtasks *before* the countdown's first
    beat elapses, and assert
    `audioCacheService.prefetchCalls.first` equals the first
    `QuizPlayCubit.audioPrefetchWindow` questions' `audioUrl`s from the
    `questions` fixture.
  - **New test**, `'advancing to the next question tops up the prefetch
    window'`: with audio available, skip the countdown, answer/advance a
    few questions via `answer()` + `next()` (mirroring this file's existing
    pattern for driving the run forward — check the existing tests around
    line 200+ for the exact helper shape already in use), and assert a later
    `prefetchCalls` entry includes the newly-in-window question further
    ahead than the initial call covered.
  - Existing tests are unaffected: with the suite's default `soundOn: false`,
    `_ttsAvailable` is `false`, so both new call sites are no-ops and
    `audioCacheService.prefetchCalls` stays empty — no assertions in any
    existing test reference it, so nothing needs updating beyond adding the
    fake to `buildCubit()`.
- [ ] Run `flutter analyze` (zero warnings, CLAUDE.md §8) and the full test
  suite.

## Data model / API changes

N/A — no backend, schema, or RPC changes. This plan is entirely client-side,
caching data (`audioUrl`) the app already receives from `start_level_attempt`
(plan 011).

## Dependencies

- **Add**: `flutter_cache_manager` (latest compatible via `flutter pub add`,
  expected `^3.4.x`) — supplies the on-disk cache store, download queuing,
  and staleness/eviction policy (Research finding 5); no hand-rolled
  file-system code needed.
- **No removals.**

## Testing strategy

Matches this project's existing convention exactly (Research finding 6):
`quiz_play_cubit_test.dart`'s `bloc_test`/`fake_async`-based suite, extended
with a hand-written `_FakeAudioCacheService` and two new cases covering the
prefetch-scheduling behavior. No new test file for
`CacheManagerAudioCacheService` or the updated `StoredAudioTtsService` — real
file-system/network integration isn't unit-tested anywhere in this codebase
today; the Cubit-level fake remains the coverage boundary CLAUDE.md §11 and
this project's own practice rely on.

## Edge cases & error handling

- **A question has no `audioUrl` yet** (not generated): already excluded
  from `_prefetchWindow`'s URL list by the same `audioUrl != null` check
  `_beginQuestion` already applies — no wasted prefetch call, no error.
- **A prefetch download fails** (404, network drop, storage outage):
  swallowed by `CacheManagerAudioCacheService.prefetch`'s `.catchError((_) =>
  null)` — the failed URL simply isn't cached; when `_beginQuestion` reaches
  it, `StoredAudioTtsService.speak` finds no local file and falls back to
  its existing direct-network attempt (which itself fails open per Research
  finding 1's existing `try/catch`). No new error state anywhere.
- **The player starts a level muted, then un-mutes mid-level.** Documented
  as an accepted, deliberate limitation (see Assumptions) — no prefetch
  happened while muted, so the rest of that level's questions play via
  today's direct-network path exactly as they would with no caching at all.
  Not a regression; simply not yet accelerated for this one scenario.
- **The player quits or the level ends mid-prefetch.** In-flight downloads
  (`flutter_cache_manager`'s own internal HTTP calls) are not cancelled and
  run to completion in the background, landing in the shared disk cache for
  next time (Assumptions: treated as a feature, not a bug). No Cubit-level
  cleanup is needed since the cache service has no per-Cubit lifecycle to
  tear down (unlike `_ttsService`/`_soundEffects`, which `close()` already
  disposes at lines 814-825 — `_audioCacheService` is deliberately not added
  to that teardown list, since it's a shared, disk-backed resource with its
  own lifetime independent of any one level).
- **Replaying the same level, or reaching the same question via a different
  level** (shared question bank): a cache hit on the very first `speak()`
  call, since the cache key is the stable, deterministic `audio_url` — no
  special-casing needed, this falls out of keying by URL.
- **Device is low on storage / the cache grows over many sessions**: bounded
  by `Config(maxNrOfCacheObjects: 500, stalePeriod: Duration(days: 30))` —
  `flutter_cache_manager` evicts least-recently-used entries beyond that cap
  and beyond that age automatically; no code in this plan needs to manage
  eviction itself.

## Acceptance criteria

- [ ] Starting a level with audio available kicks off caching for the first
  `QuizPlayCubit.audioPrefetchWindow` (5) questions' narration during the
  S-10 countdown (verified by the new Cubit test, and manually: watch
  network activity begin the instant "3" appears, before "GO").
- [ ] As the player advances through the level, the cache window keeps
  topping up to stay ~5 questions ahead of the current one (verified by the
  new Cubit test).
- [ ] A question whose audio finished caching in time plays from the local
  file, not a fresh network request (manually verified: enable airplane
  mode partway through a level after its early questions have had time to
  cache, confirm those questions still narrate).
- [ ] A question whose audio hasn't cached in time (e.g. countdown skipped
  instantly) still plays correctly via the existing direct-network path —
  no regression, no stuck "speaking" phase.
- [ ] `flutter analyze` is clean (CLAUDE.md §8) and the full test suite,
  including the two new prefetch-scheduling cases, passes.
- [ ] The on-disk cache is bounded by an explicit `Config` (object count and
  staleness), not left to grow unbounded.

## Risks & rollout notes

- **Upfront bandwidth burst.** Every level start now fetches up to 5 small
  audio files concurrently instead of one at a time as each question is
  reached. Given the small clip sizes (Assumptions), this is expected to be
  a non-issue in practice, but is a real, measurable change in early-level
  network behavior worth watching after rollout, especially on constrained
  connections.
- **New third-party dependency.** `flutter_cache_manager` is a widely-used,
  actively maintained package (it underlies `cached_network_image`), but it
  is a new supply-chain dependency this project didn't have before. If a
  security/dependency review flags it, the fallback is the hand-rolled
  `dart:io`/`path_provider` alternative noted in Assumptions — a larger,
  riskier diff, not attempted here.
- **Fully reversible, no migration.** Every change in this plan is additive
  and client-side: reverting the new files, the `StoredAudioTtsService`/
  `QuizPlayCubit`/`quiz_play_screen.dart` edits, and the dependency addition
  fully restores today's direct-network-only behavior. No backend state, no
  data migration, nothing to roll back on the server side.
- **Follow-up not built here**: recomputing narration availability
  independent of the mute toggle, so a mid-level un-mute also benefits from
  prefetching (see Assumptions). Worth a small dedicated follow-up if it
  turns out to matter in practice.
