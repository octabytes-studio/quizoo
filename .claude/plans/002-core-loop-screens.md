# Quizoo — Core Loop Screens (Onboarding → Home → Browse → Play → Result)

> Source spec: Quizoo Design Bible v1.0, sections 07–10 (S-01…S-26) plus the "core loop,
> timed" table in §01 (Overview). **The full original HTML is saved at
> `.claude/docs/quizoo-design-bible.html` in this repo — that file, not this plan's prose,
> is the ground truth for exact pixel-level UI (see below).**
> Status: Draft — not yet implemented
> Depends on: **001-design-foundation.md** (theme tokens, router skeleton with all 54
> route constants already reserved, `core/widgets/*`, mock-data convention, `core/models/*`)
> must be implemented first. This plan only adds feature folders and fills in bodies for
> routes 001 already stubbed.

## How to use this plan

Self-contained given 001 is done: read this file in full, then re-read 001's "Mock-data
convention" and "Folder skeleton" sections once more before starting, since every feature
here follows that pattern verbatim without repeating its rationale. Re-verify the routes
this plan touches (`AppRoutes.sXX` for S-01 through S-26) still exist with placeholder
bodies in `app/router.dart` before you begin — if 001 hasn't landed yet, stop and implement
that first.

**Before building any screen in this plan, open `.claude/docs/quizoo-design-bible.html` in
a browser and find that screen's frame by its ID** (each screen card has an `id="s-XX"`
anchor and a visible `S-XX` badge in its caption — e.g. search the page for `id="s-11"` to
jump straight to the Question/default frame). The user has explicitly asked for the
Flutter implementation to match this document's screens, components and widgets exactly —
every layout, color, spacing value, corner radius, shadow and animation timing this plan
describes was read directly off that live, rendered page (toggle its light/dark and app-
theme switches to see both states), and this plan's prose is a guide to *finding and
reading* the right part of that page, not a substitute for looking at it. Where this
plan's description of a screen and the HTML file ever seem to disagree, the HTML file
wins — flag the discrepancy rather than silently picking one.

This is plan **2 of 4** (see 001 for the full series map). This plan covers the app's
primary, most-rehearsed path — the "core loop" the design bible's Overview section frames
as the whole product: *pick a topic → survive a timed level → get paid in points, coins,
status → see how far the next level is*.

## Objective

Implement, with mock data, every screen a new player sees from first launch through
completing (or failing) their first level and being offered — but never forced into — an
account: S-01 through S-26. Wire real navigation between them following the bible's own
sequencing table (Splash → Home ≤1.2s; Home → Level map ≤2 taps; Level brief → Play → 20
questions → Result → conditionally Save-progress sheet).

## Scope

**In scope — features and their screens:**
- `features/onboarding/` — S-01 Splash, S-02 Onboarding (3-card carousel), S-03 Language
  picker.
- `features/home/` — S-04 Home (guest, first launch), S-05 Home (signed-in), S-06 Search.
- `features/catalog/` — S-07 Category detail, S-08 Level map, S-09 Level brief sheet.
  (S-10 Countdown ships with `quiz_play` below, since it's really the play surface's first
  beat, not a browse screen.)
- `features/quiz_play/` — S-10 Countdown, S-11 Question (default), S-12 Correct, S-13
  Wrong, S-14 Danger (last 5s), S-15 Question (image), S-16 Question (Urdu/RTL), S-17 Pause
  sheet, S-18 Quit confirmation, S-19 Out of lives.
- `features/quiz_result/` — S-21 Level complete, S-22 Level failed.
- `features/auth/` (mocked — no real OAuth/email backend) — S-24 Save-progress sheet,
  S-25 Profile creation & field errors.
- Badge-unlock (S-23) and league-promotion (S-26) are **cross-referenced but not built
  here** — S-23 belongs to `features/achievements` (plan 003) and S-26 to
  `features/leaderboard` (plan 003). This plan's `quiz_result` Cubit is responsible for
  *deciding* whether they should appear next (given its own mock score data) and
  navigating to their (already-placeholder-stubbed) routes — the actual screen bodies are
  built in plan 003. Note this dependency explicitly: if plan 003 hasn't landed yet, that
  navigation will hit 001's placeholder screen, which is an acceptable, expected state.
- S-20 Question (audio) is explicitly **out of scope for this plan** — see Assumptions.

**Out of scope:**
- Real score/XP/coin math (§19 of the bible) — this plan's mock `QuizPlayCubit` produces
  *plausible-looking* numbers for display (using the bible's own worked formulas so the UI
  is exercised with realistic values) but does not need to be a certified-correct scoring
  engine; that's a future business-logic hardening pass. It should still be internally
  consistent enough that a reviewer clicking through doesn't see nonsense (e.g. speed bonus
  bigger than base score).
- Real sign-in (Google/Apple/email OAuth) — `features/auth` mocks the flow: tapping any
  sign-in button just flips a local mock "signed in" flag and pops the sheet; no token, no
  network call, no real account.
- Haptics/sound playback — the motion *tokens* from 001 are used for animation timing, but
  actual `HapticFeedback`/audio-file playback is not wired (no asset budget/plan for sound
  files in this phase). Note visually where a haptic/sound would fire (e.g. a code comment
  is *not* wanted per project style — instead, just leave it absent and flag here that it's
  a deliberate gap, not an oversight).

## Research findings

(All of the following is transcribed directly from `.claude/docs/quizoo-design-bible.html`,
sections 07–10 and the Overview's core-loop table — open that file if any dimension below
needs double-checking against the live, rendered component.)

**Core loop timing contract** (§01): Splash→Home ≤1.2s (home renders from cache, network
fills the popular rail after — in mock form, this just means Home's Cubit should emit a
"loaded from local fixture" state near-instantly, with a deliberately delayed second mock
fetch simulating "network fills in the popular rail"); Home→Level map ≤6s / 2 taps max;
Level brief sheet shown 3s; Play 5–10 min / 20 questions, no blocking network mid-level
(the whole level's questions are "prefetched" — in mock terms, `QuizPlayCubit` loads all 20
mock questions once before Countdown starts, never mid-level); Level complete payout
sequence ~8s; Save-progress sheet shown **at most once, only after a successful first
level, never after a failure**.

**S-01 Splash**: owl mark scales in with `pop` motion token, then wordmark writes on; hard
capped at 1200ms — if bootstrap (mock: loading fixture data) is still running past that,
go to Home anyway with skeletons rather than block. Background `linear-gradient(178deg,
#7B4DFF, #4B22C4)`, edge-to-edge, white status-bar icons.

**S-02 Onboarding**: 3-card swipeable carousel ("pick a topic", "climb the levels", "beat
your friends" — card 2 of 3 shown in the bible has a gradient circle icon 190×190 with a
large emoji, `dsp` heading, body copy, dot-nav indicator, full-width "Next"/"Skip" button).
Skippable from card one. Shown once ever (persist a "seen onboarding" flag — see
Assumptions on persistence), never shown again after a completed level even if somehow
re-triggered.

**S-03 Language picker**: shown once, list of 5 languages each as a `ListRowTile`
(flag/emoji avatar, native name, live "N quizzes" count, radio-style checkmark on the
selected row), pre-selected from device locale, "Continue" CTA. Per 001's localization
scope, only English is fully wired; selecting Urdu here should still visually work (it's
a UI list, not a real content switch) but only English + the Urdu proof-of-concept subset
from 001 actually re-render text — flag this honestly in the screen rather than pretending
all 5 languages work.

**S-04 Home — guest, first launch**: top bar "Welcome 👋 / Playing as Guest" + search icon;
"Save your progress" info card (non-modal, purely informational, grape gradient); Popular
rail (`pq` cards: gradient bg, optional "HOT" badge, emoji, title, played-count); Categories
section with filter chips (`✨ All / 🌍 General / 🧠 IQ / 🔢 Maths / 🔬 Science`) and a
3-up tile grid showing subcategories with "N levels" (no progress bar yet — nothing
started). No wallet pills (nothing earned yet), no Continue rail (nothing in progress).

**S-05 Home — signed-in**: top bar shows avatar + "Hey, {name}" + streak/level subtitle +
wallet pills (coin, life); order is: Daily Challenge banner → **Continue** rail (only
present with an unfinished level; bible calls this "the highest-converting row on the
screen") → Popular rail → Categories (now with progress bars/level-count per tile).

**S-06 Search**: back + search input (autofocus, grape border while focused); "N RESULTS"
meta label; result rows (subcategory icon, name, "Category › Sub-path · N questions",
"Play" affordance); "TRENDING SEARCHES" chip cloud below. Debounced ~250ms in the real
spec — for mock data this can just filter an in-memory fixture list synchronously with a
tiny artificial delay to prove the loading affordance exists.

**S-07 Category detail** (`features/catalog`): full-bleed colored header (category's own
gradient + large emoji, back + overflow "⋯"), category name (`dsp` 26px), "N topics · N
questions · N players" meta line; below, "Topics" section with a sort control ("Sort:
Popular") and a tile grid of subcategories (locked ones show a 🔒 overlay). Header color/
emoji come from the taxonomy data, not hardcoded per category — model this in the mock
`Category` fixture (already has `colorFrom`/`colorTo` per 001's `core/models/category.dart`).

**S-08 Level map**: subcategory header card (icon plate, name, "N questions · N levels",
thin progress bar with "X/20", then a 3-stat row: best score / stars (X/60) / rank).
Below: a vertical **serpentine** level path (`lvmap`/`lvstep`/`lvlink` pattern in the
bible's CSS — nodes alternate left/right offset, connected by dashed links that turn mint
once cleared), grouped into difficulty **bands** as horizontal dividers ("MEDIUM · 25s PER
QUESTION" etc., the active band highlighted in mango). Node states: `done` (mint, shows
stars earned), `now` (mango, 1.12x scale, pulsing ring, a "YOU'RE HERE" flag), `locked`
(shows a 🔒 badge and its unlock condition as a label — "CLEAR LEVEL 12" / "LOCKED"), boss
levels (every 5th) get a 👑 badge. Screen opens pre-scrolled so the current node sits at
~45% viewport height. Bottom CTA: "Play Level N" with a `sub` line stating difficulty/
question-count/seconds.

**S-09 Level brief sheet**: triggered by tapping the level-map CTA (or a locked-node's
future unlock, N/A here). Bottom sheet: level icon plate + "Level N" + "{Subcategory} ·
{Difficulty}" + a streak-multiplier chip if applicable; a 3-up stat row (Questions / Per-
question seconds / Lives) as flat cards; "POWER-UPS IN HAND" label + a row of owned
power-up tiles (count badges) plus a dimmed "+ SHOP" tile; "Start Level N" CTA. Dismissible
by drag-down. This is also stated as "where the level's 20 questions finish prefetching" —
mock equivalent: `QuizPlayCubit.prepareLevel()` is called when this sheet opens and must
resolve before "Start Level N" is enabled (show the button in a brief loading/disabled
state if the mock fetch hasn't resolved yet, to actually exercise that state rather than
faking instant readiness).

**S-10 Countdown**: full-screen dark-play-surface background, "{SUBCATEGORY} · LEVEL N"
meta label, giant `150px` numeral counting 3→2→1→GO at 1s intervals each numeral scaling
1.6→1.0 with `pop`; skippable by tap; **the gameplay timer does not start until "GO" has
fully left the screen** — this ordering matters and should be a real invariant in
`QuizPlayCubit`, not just visual (the first question's timer must not be already ticking
underneath the countdown).

**S-11..S-20 Gameplay** (`features/quiz_play`, arena background from 001's
`ArenaColors`, always dark regardless of app theme):
- **Chrome present on every question state**: `✕` (quit, opens S-18), 20-dot progress
  strip (`d`=done-correct/mint, `w`=wrong/raspberry, `c`=current/white, empty=upcoming),
  streak badge (🔥 N, dims to 0-opacity style when streak is 0); below that, a meta row
  "Question N of 20" / hearts as ❤️/🖤 glyphs (never a bare number) / "Score N"; centered
  circular timer (SVG ring, stroke color mango→raspberry as time runs low, numeral
  center); question box (`qbox`, rounded translucent card, `text-wrap:balance` question
  text, up to 3 lines); 4 answer options (3 for image questions) via `AnswerOptionTile`
  from 001; power-up dock row (50:50 / +15s / Skip, with count badges) beneath the options.
- **S-11 default**: rest state, all options interactive.
- **S-12 Correct**: wrong options fade to 24% opacity, chosen-correct option turns mint
  with a ✓ tick; a slide-up feedback banner (`fb good`, mint bg) shows "Correct!" + points
  earned + the question's one-sentence **explanation** text (bible: "the single feature
  that turns a quiz into learning" — must always be shown, correct or wrong) + "Next
  question" button; auto-advances after 2.5s if untouched.
- **S-13 Wrong**: chosen option turns raspberry with ✕, correct option still shown mint
  (**always reveal the right answer**, never hide it); streak resets to 0 visually; a 6px/
  120ms screen-shake plays (disabled under reduce-motion — wire this through 001's
  `AppMotion` reduced-motion helper); feedback banner (`fb bad`, raspberry bg) shows "Not
  quite" + "−1 ❤️" + explanation.
- **S-14 Danger (last 5s)**: arena background swaps to the crimson variant
  (`linear-gradient(178deg,#5A1030,#38091F,#1E0512)`), timer ring turns raspberry and
  pulses scale 1.06 once per second, a haptic-tick equivalent (visual pulse only, per
  Scope's haptics note) fires each second; if the player owns a "+15s" power-up its tile
  gets a lemon outline ring as the one deliberate nudge toward using it.
- **S-15 Question (image)**: adds a 132px media plate above the question box (used by
  Visual Knowledge/Flags/Logos/Landmarks categories in the real taxonomy — for mock data,
  tag a handful of fixture questions as "hasImage" with a bundled placeholder asset or a
  solid-color/emoji plate, since no real image CDN exists); timer shrinks to 52px to make
  room; a failed/missing image must degrade to the text-only layout, never a broken-image
  box — build this as a real fallback path (e.g. an `errorBuilder`), not just a note.
- **S-16 Question (Urdu/RTL)**: full mirror — progress dots fill right-to-left, close
  button moves right, option key badges lead from the right, Eastern Arabic numerals,
  Nastaliq font at 2.1 line-height with +4px vertical padding added project-wide for RTL
  (per 001's typography note). This is the second real screen (after Home) that proves
  001's RTL scaffolding; use the same Urdu `.arb` subset.
- **S-17 Pause sheet**: triggered by... (the bible doesn't show an explicit pause button
  in the HUD — treat it as reachable via a system back-gesture/app-background event, or
  add a small pause affordance if none exists; flag this as an open question below).
  Content behind it is blurred+dimmed; timer **freezes the instant the sheet's entrance
  animation begins, not when it finishes landing** (a real timing detail worth getting
  right in `QuizPlayCubit`); sheet offers Resume, Sound/Haptics quick-toggles, Restart
  level, and a raspberry-tinted "Quit — lose progress" line item.
- **S-18 Quit confirmation**: modal dialog (not a sheet) triggered from the ✕ button;
  states the exact cost in the player's own live numbers ("You're 6 questions in with
  1,340 points. Quitting loses this level's score and one life. Your streak survives.");
  destructive action ("Quit level") is visually second and never pre-focused; "Keep
  playing" is first/dominant.
- **S-19 Out of lives**: modal dialog when hearts hit 0 mid-level; states the exact next
  natural-refill clock time (not a relative "in 28 minutes" — compute from the mock
  `PlayerCurrency.heartRefillAt`); 3 stacked actions: gold "Watch an ad for 1 ❤️" (loudest,
  listed first — mock: just grants +1 heart instantly with a brief simulated "ad" delay,
  no real ad SDK), "Refill 5 ❤️ · 300 🪙" (mock: only enabled if mock coin balance ≥ 300,
  deducts and refills), "Back to level map" (abandons the run, same cost as S-18's quit).

**S-21 Level complete** (`features/quiz_result`): mint-gradient wash background; stars
(0–3, animate in with `pop` at 0/200/400ms per star); score card: score counts up over
900ms (`count` token), a breakdown list (correct×100, speed bonus, best-streak bonus,
clean-run bonus if applicable, total — staggered in at 60ms/row), then coins/XP stat pair,
then an XP progress bar toward next player level. Buttons: "Next level →" (primary) and
"Replay for 3 stars" (line) if not already 3-starred. Whole sequence ~2.6s, skippable by
tap. **After this screen**, `QuizResultCubit` must decide, from its own mock inputs,
whether to chain into (in order, each only if applicable): S-23 badge-unlocked
(plan 003's route) if a mock achievement was newly earned this run, then S-24 save-
progress sheet if this is the player's first-ever successful level completion **and**
they're still a guest **and** it hasn't been shown in the last 24h (mock: a simple
in-memory/session flag is enough — no need for real persistence across app restarts in
this phase, flag as a known limitation).

**S-22 Level failed**: raspberry-gradient wash; "😤 So close!" + "You ran out of hearts on
question N"; a 3-up stat row (correct / points / accuracy%); a "YOU MISSED THESE — TAP TO
REVIEW" list (each missed question as a compact row: the question text, "{correct answer}
— you said {player's answer}"); primary CTA "Try again · 1 ❤️" (deducts a heart, restarts
the same level), secondary "Back to map". **No stars shown, no ad/purchase offer of any
kind on this screen** — this is an explicit, bible-stated rule, not a style preference.

**S-24 Save-progress sheet** (`features/auth`, mocked): grape gradient sheet, mascot emoji,
"Don't lose {score} points" headline quoting the player's own live numbers ("You're 82%
through Level 12 with a 12-day streak..."), then 3 sign-in buttons drawn to each vendor's
exact chrome (Google: white/`#DADCE0` border/`#3C4043` label; Apple: black surface/white
label; both 54px with a leading brand slot — **placeholder glyph, not the real vendor
mark**, per 001's Assumption 9) plus a grape "Continue with Email" button, then plain-text
(never disabled/hidden) "Not now — keep playing as guest". Terms/Privacy microcopy below.
Tapping any sign-in option (mock): if Email is chosen, push S-25; if Google/Apple is
chosen, mock-authenticate immediately (flip the mock signed-in flag, pop back to wherever
S-24 was triggered from, show a "Progress saved" `AppSnackbar`).

**S-25 Profile creation & field errors**: avatar (tap "Change avatar" — mock: cycle through
a small fixed emoji set, no real picker/upload), Username field (live availability check —
mock: a fixed denylist of 2–3 taken names, else "✓ available"), Country field (mock: a
short fixed picker list, not a real country database), Email field with **inline
validation only after blur** (bible's exact example: `waleed@` → error "Add the part after
the @ — like gmail.com" — error copy states what to *do*, never "invalid email"). CTA
"Create profile" stays visibly present but disabled (`ChunkyButton`'s `dis` variant) until
all fields validate, rather than disappearing.

**S-20 Question (audio) is explicitly deferred** — see Assumptions below for why.

## Assumptions & open questions

1. **S-20 (audio question) is out of scope for this plan.** It requires a real audio
   asset + a waveform/playback UI with replay-costs-3-seconds logic; building a convincing
   mock of *audio playback specifically* is disproportionate for a design-only pass with no
   sound assets budgeted (001 doesn't add an audio-player package). Recommend deferring it
   to plan 004 or a dedicated follow-up once at least one real short audio fixture exists;
   flagged here rather than silently dropped. If the user wants it included now, it needs
   an `audioplayers`/`just_audio` dependency added to 001 retroactively.
2. **No explicit pause-button affordance is shown in the bible's HUD for S-17.** The
   feasible triggers are: (a) Android hardware/gesture back, (b) the app being backgrounded
   (`AppLifecycleState.paused`), or (c) an icon this plan adds that isn't in the mockup.
   Recommendation: wire it to (a) and (b) both (a `PopScope`/`WillPopScope` handler plus an
   `AppLifecycleListener`), which matches "pause sheet" semantics without inventing new
   chrome. Flagging as a genuine gap in the source spec, not resolving it silently.
3. **Onboarding/language-picker "shown once" persistence.** True cross-session
   persistence would need `shared_preferences` (not added in 001). For this mock-data
   phase, use an in-memory flag that resets on cold start — meaning onboarding will
   actually replay every time the app is relaunched during review. This is acceptable for
   a design review but is flagged explicitly as a known, deliberate gap versus the bible's
   real "shown once" requirement; add `shared_preferences` in a later phase if persistence
   across restarts is wanted before this ships for real.
4. **Mock question bank size.** Per the bible's v1.0 roadmap scope ("6 categories × 5
   subcategories, 20 levels"), and to keep fixture-authoring effort proportionate, this
   plan's mock data needs **at minimum**: 2 categories fully fleshed out (recommend
   Sports/Football, since nearly every one of the bible's own example screens uses it, and
   one more, e.g. Science/Solar System, to prove the "image question" and a second gradient/
   emoji pairing) with a handful of subcategories each, and **one** subcategory (Football)
   with all 20 levels' worth of mock questions (≈least 20 questions, can repeat/shuffle a
   smaller pool of ~20-30 authored mock questions across levels if writing 400 unique ones
   is disproportionate — flagging that reusing a small pool is a deliberate mock-data
   shortcut, not a content-completeness claim). Other subcategories can be "New"/locked
   tiles with no levels behind them yet.
5. **Guest-vs-signed-in state** is tracked by a small mocked `SessionCubit` (or reuse
   `features/auth`'s own Cubit) — global enough (drives Home's two variants, the profile
   tab, leaderboard row text) to justify living as an app-root provider per CLAUDE.md §3's
   "auth session" example. This plan introduces it; plan 003 (profile/leaderboard) and 004
   (settings) consume it.

## Design overview

```
features/
├── onboarding/
│   ├── domain/onboarding_slide.dart
│   ├── data/ (no repository needed — 3 slides are static content, not fetched)
│   └── presentation/
│       ├── screens/splash_screen.dart
│       ├── screens/onboarding_screen.dart
│       ├── screens/language_picker_screen.dart
│       └── widgets/onboarding_slide_card.dart
├── home/
│   ├── data/home_api.dart, home_repository.dart
│   ├── domain/home_content.dart  (freezed: popularQuizzes, continueEntry?, categories,
│   │                              dailyChallengePreview, isSignedIn)
│   └── presentation/
│       ├── bloc/home_cubit.dart, home_state.dart (sealed: Initial/Loading/Loaded/Error)
│       ├── screens/home_screen.dart
│       ├── screens/search_screen.dart
│       └── widgets/popular_quiz_card.dart, continue_row.dart, daily_banner.dart
├── catalog/
│   ├── data/catalog_api.dart, catalog_repository.dart
│   ├── domain/category_detail.dart, level_map.dart (uses core/models Category/Subcategory/Level)
│   └── presentation/
│       ├── bloc/category_detail_cubit.dart (+state), level_map_cubit.dart (+state)
│       ├── screens/category_detail_screen.dart, level_map_screen.dart
│       └── widgets/level_brief_sheet.dart, serpentine_path.dart
├── quiz_play/
│   ├── data/quiz_play_api.dart, quiz_play_repository.dart
│   ├── domain/question.dart, quiz_run.dart (level progress: index, score, streak, hearts)
│   └── presentation/
│       ├── bloc/quiz_play_cubit.dart, quiz_play_state.dart (sealed: Preparing/Countdown/
│       │        InProgress(question, feedback: none|correct|wrong)/Paused/OutOfLives/Ended)
│       ├── screens/countdown_screen.dart, quiz_play_screen.dart
│       └── widgets/timer_ring.dart, quiz_hud.dart, feedback_banner.dart,
│                    quit_confirmation_dialog.dart, out_of_lives_dialog.dart, pause_sheet.dart
├── quiz_result/
│   ├── data/quiz_result_api.dart, quiz_result_repository.dart (mock: computes/records the
│   │        run's final tally + whether it's a "first successful level" + newly-earned
│   │        badge ids, from the QuizRun handed to it)
│   ├── domain/level_result.dart
│   └── presentation/
│       ├── bloc/quiz_result_cubit.dart, quiz_result_state.dart (sealed: Completed/Failed)
│       ├── screens/level_complete_screen.dart, level_failed_screen.dart
│       └── widgets/score_breakdown_card.dart, stars_row.dart, missed_question_row.dart
└── auth/
    ├── data/auth_api.dart, auth_repository.dart (mock sign-in/sign-up, in-memory only)
    ├── domain/auth_user.dart, session.dart
    └── presentation/
        ├── bloc/session_cubit.dart, session_state.dart (sealed: Guest/SignedIn) — app-root
        ├── screens/profile_creation_screen.dart
        └── widgets/save_progress_sheet.dart, vendor_sign_in_button.dart
```

`SessionCubit` is provided at `app/app.dart` root (alongside `ThemeCubit` from 001) since
it's genuinely app-wide per Assumption 5. Every other Cubit above is scoped locally via
`BlocProvider` at its screen per CLAUDE.md §3.

## Implementation steps

- [ ] **Phase A — Onboarding.** Build `SplashScreen` (1200ms hard cap via a `Future.delayed`
  race against mock bootstrap, then `context.go(AppRoutes.home)` or the onboarding route on
  true first-launch), `OnboardingScreen` (3-card `PageView` + dot indicator), 
  `LanguagePickerScreen` (static 5-row list, "Continue" always enabled). Wire into
  `app/router.dart`'s already-reserved S-01/02/03 routes, replacing the placeholders.
- [ ] **Phase B — Home & Search.** `SessionCubit` first (app-root, sealed `Guest`/
  `SignedIn` states, mock `signIn()`/`signOut()` methods). Then `HomeRepository`/`HomeApi`
  mock returning `HomeContent` shaped for both guest and signed-in variants (branch on
  `SessionCubit`'s state, not a duplicate API call). `HomeScreen` renders via `BlocBuilder`
  on `HomeCubit`, switching its layout (not a separate screen) based on `SessionCubit`'s
  state — use `BlocListener`/nested `BlocBuilder` per CLAUDE.md §3, no `context.watch`
  business logic inside `build()`. `SearchScreen` filters the same mock category/
  subcategory fixture list client-side.
- [ ] **Phase C — Catalog.** `CategoryDetailScreen` (header + sort + tile grid),
  `LevelMapScreen` (header stat card + serpentine path — this is the most layout-complex
  widget in the whole plan; budget real time for the alternating-offset/band-divider
  logic), `LevelBriefSheet` (bottom sheet, calls `QuizPlayCubit.prepareLevel()` mock-
  prefetch before enabling "Start Level N").
- [ ] **Phase D — Quiz play.** This is the core of the plan. Build `QuizPlayCubit` as the
  single owner of: current question index, per-question `Ticker`-driven countdown (not a
  widget-level `Timer.periodic`, per 001's architecture note echoed from the bible's §25),
  streak, hearts, running score (using the bible's exact worked formula from §19 — base
  100 + speedBonus + diffMult + streakMult — for realistic mock numbers only, not a
  certified engine per Scope). Model states as a single sealed `QuizPlayState` with the
  question, elapsed/remaining time, and an explicit `feedback` field (none/correct/wrong)
  so the screen can `switch` exhaustively per CLAUDE.md §3 rather than juggling booleans.
  Build `CountdownScreen` → `QuizPlayScreen` (HUD + timer ring `CustomPainter` + question
  box + `AnswerOptionTile`s + feedback banner + power-up dock) → wire `PauseSheet`,
  `QuitConfirmationDialog`, `OutOfLivesDialog` as overlays triggered by Cubit state, never
  by ad hoc `showDialog` calls scattered in the widget tree (drive them from
  `BlocListener`). Implement the danger-state arena swap and screen-shake-on-wrong (with a
  `MediaQuery.disableAnimations` guard) here.
- [ ] **Phase E — Result.** `QuizResultCubit` takes the finished `QuizRun` from
  `QuizPlayCubit` (passed via route `extra` or re-fetched from a short-lived in-memory
  handoff — avoid a second mock network round-trip for data the app already has in
  memory), computes the star count / breakdown / whether this is a first-successful-level
  / any newly-earned badge ids, and emits `Completed` or `Failed`. `LevelCompleteScreen`
  and `LevelFailedScreen` render the sequenced animations described in Research findings.
  Wire the post-completion chain (badge → save-progress sheet) as `context.push` calls
  gated by the Cubit's own booleans, per Scope's "no cross-feature orchestration" rule from
  001 — this Cubit only ever pushes *routes*, it never imports `features/achievements` or
  `features/leaderboard` code directly.
- [ ] **Phase F — Mocked auth.** `SessionCubit.signIn()` mock (no real network); build
  `SaveProgressSheet` (vendor button chrome per Research findings + 001 Assumption 9) and
  `ProfileCreationScreen` (blur-triggered inline validation, disabled-until-valid CTA).
- [ ] **Phase G — Fixtures.** Author the mock question/category/subcategory data per
  Assumption 4's minimum bar, as static Dart const data or bundled fixture JSON parsed
  through `core/models/*`'s freezed `fromJson` — whichever keeps `*_api.dart` files small;
  prefer a `assets/mock/*.json` + `rootBundle.loadString` approach if the data volume makes
  inline Dart constants unwieldy (20+ questions), otherwise inline consts are fine and
  avoid an asset round-trip.

## Data model / API changes

New `core`-shared additions beyond 001 (if any prove genuinely reused 3+ features during
implementation, promote them; otherwise keep local to `features/quiz_play/domain/` etc.):
- `Question` (id, categoryId, subcategoryId, difficulty 1-5, text, options[4 or 3],
  correctIndex, explanation, hasImage, imageAsset?) — kept local to `quiz_play` unless
  plan 003's stats/profile screens end up needing raw question data too (currently they
  only need aggregates, so this likely stays local).
- `QuizRun` (levelId, answers[], score, longestStreak, heartsRemaining, startedAt,
  finishedAt) — local to `quiz_play`, handed to `quiz_result` via route `extra`.

## Dependencies

No new packages beyond 001's list. If S-20 (audio) is pulled into scope later, add
`audioplayers` or `just_audio` at that time — not now.

## Testing strategy

- `SessionCubit`, `HomeCubit`, `CategoryDetailCubit`, `LevelMapCubit`, `QuizPlayCubit`,
  `QuizResultCubit`: each gets a `bloc_test` suite covering initial state, one success path,
  one failure path (the mock API's simulated failure from 001's convention), per CLAUDE.md
  §11.
- `HomeRepository`, `CatalogRepository`, `QuizPlayRepository`, `QuizResultRepository`:
  unit tests with `mocktail`-mocked `*Api` classes, success + one error-mapping path each.
- Widget tests (one per sealed state branch, per CLAUDE.md §11): `HomeScreen` (guest vs.
  signed-in vs. loading vs. error — 4 branches), `QuizPlayScreen` (rest/correct/wrong/
  danger — at least these 4 of its states), `LevelCompleteScreen` vs `LevelFailedScreen`.
- One integration-style widget test walking the golden path: Home → tap a category → tap a
  subcategory → level map → tap current level → brief sheet → Start → countdown → answer
  all 20 mock questions correctly → level complete screen renders with 3 stars. This is the
  single most valuable test in this plan — it's the literal "core loop" the whole document
  is built around.

## Edge cases & error handling

- Timer reaching 0 with no answer selected: must count as a *timeout*, which per the
  bible's rules costs the question but **not** a heart (distinct from a wrong answer) —
  get this branch right in `QuizPlayCubit`, it's easy to conflate with "wrong answer."
  Timeout still needs a feedback banner (bible doesn't show one explicitly for timeout —
  treat it like S-13 Wrong for UI purposes but without decrementing hearts, and flag this
  interpretation here since the bible is silent on the exact timeout visual).
- Answering the exact instant the timer hits the danger threshold (5s): confirm the arena/
  ring swap and the answer-tap feedback don't race visually.
- Quitting (S-18) vs. running out of lives (S-19) vs. genuinely finishing all 20 questions
  must all converge on the same `QuizResultCubit` entry point with different `QuizRun`
  shapes (quit = partial run, marked distinctly from a natural loss) — don't let a quit
  silently look identical to a loss on the result screen (the bible's copy differs: a loss
  says "you ran out of hearts", a quit shouldn't say that).
- Image question (S-15) with a missing/broken asset: must fall back to the text-only
  layout, tested explicitly (this is called out in the bible as a hard requirement, not a
  nice-to-have).
- Save-progress sheet must never appear after S-22 (Level failed) — assert this with a
  test, not just a code comment, since it's an easy accidental regression once both sheets
  exist and share a "just completed a run" trigger point.

## Acceptance criteria

- [ ] Every screen built in this plan (S-01…S-26) has been visually compared, side by side,
  against its frame in `.claude/docs/quizoo-design-bible.html` — not just implemented from
  this plan's prose description — since the user has asked for exact parity with that
  document's screens, components and widgets.
- [ ] A reviewer can go Splash → (optional onboarding) → Home (guest) → tap a category →
  tap a subcategory → Level map → tap the current level → Level brief sheet → Start →
  Countdown → answer 20 mock questions (mixing correct/wrong/timeout) → land on either
  Level complete or Level failed with numbers that are internally consistent (score
  breakdown sums to the total shown).
- [ ] After a first successful level as a guest, the Save-progress sheet appears exactly
  once; mock-signing-in flips Home into its signed-in variant (wallet pills, streak,
  Continue rail).
- [ ] Toggling to Urdu locale and playing S-16's question state shows correct RTL mirroring
  with no overflow, reusing 001's scaffolding without new hacks.
- [ ] Dark/light theme toggling never affects the play-surface arena background.
- [ ] `flutter analyze` zero warnings; every new Cubit has a passing `bloc_test` suite with
  the required 3 cases; the golden-path integration widget test passes.

## Risks & rollout notes

- The serpentine level-map path (S-08) is the single highest-effort layout in this plan —
  budget accordingly; consider building it as its own small isolated widget with a widget
  test asserting node ordering/offsets before wiring it into the full screen.
- The pause-trigger ambiguity (Assumption 2) should be confirmed with the user/design
  owner before or during implementation rather than guessed silently, since it affects a
  visible piece of chrome (or the deliberate absence of one).
- No migration/rollback concerns — greenfield.
