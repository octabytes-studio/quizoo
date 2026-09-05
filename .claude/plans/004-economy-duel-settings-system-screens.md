# Quizoo — Shop/Economy, 1v1 Duel, Settings & RTL, System & Overlay Screens

> Source spec: Quizoo Design Bible v1.0, sections 14–18 (S-36…S-54). **The full original
> HTML is saved at `.claude/docs/quizoo-design-bible.html` in this repo — that file is the
> ground truth for exact pixel-level UI, not this plan's prose (see below).**
> Status: Draft — not yet implemented
> Depends on: **001-design-foundation.md** (theme, router skeleton, core widgets, mock-data
> convention). Benefits from **002** (`SessionCubit`, `features/quiz_play`'s power-up
> concept) and **003** (`SessionCubit` consumers, `ShareSheet` precedent) existing first,
> but its four feature areas are largely independent of 002/003's internals — only route
> constants are shared, per CLAUDE.md §10's "no feature touches another feature's files"
> rule, enforced throughout this plan too.

## How to use this plan

Self-contained given 001 is done. Read 001's mock-data convention and folder skeleton
again before starting. This plan is the largest of the three "screens" plans in scope
(19 screen IDs across 4 fairly independent feature areas), so it is written in four mostly
self-contained phases — a fresh session could pick up any one phase without the others
having landed, as long as 001 is in place.

**Before building any screen in this plan, open `.claude/docs/quizoo-design-bible.html` in
a browser and find that screen's frame by its `id="s-XX"` anchor** (e.g. `id="s-40"` for
duel-in-play). The user has asked for the Flutter implementation to match this document's
screens, components and widgets exactly — read the shop rows, the duel VS header, the
settings groups, the force-update/report/delete-account overlays, etc. directly off the
live rendered page (toggle its light/dark and app-theme switches) rather than assembling
them purely from this plan's prose. Where this plan's description and the HTML file ever
seem to disagree, the HTML file wins — flag the discrepancy rather than silently picking
one.

This is plan **4 of 4** (see 001 for the full series map). After this plan, all 54 screens
in the design bible have a real implementation and the placeholder-route scaffolding from
001 is fully retired.

## Objective

Implement, with mock data: the shop/power-up economy (S-36/37), the 1v1 duel flow
(S-38…S-41 — S-38 was actually already built in plan 001 as part of the shell's FAB, see
note below), settings including the RTL/notifications screens (S-42/43/44), the loading/
empty/offline/error system-state patterns (S-45…S-48), and the remaining overlay screens
(S-49…S-54: in-place snackbar demo, force update, report question, delete account, share
sheet — already built in 001/003 — and notification permission pre-prompt).

## Scope

**In scope — features and their screens:**
- `features/shop/` — S-36 Shop, S-37 Rewarded ad prompt.
- `features/duel/` — S-39 Matchmaking, S-40 Duel in play, S-41 Duel result. (S-38's
  `PlayLauncherSheet` was already built in plan 001, Phase concerning `features/shell/` —
  this plan only needs to make sure its "1v1 Duel" row actually routes into this feature's
  matchmaking screen instead of 001's generic placeholder.)
- `features/settings/` — S-42 Settings, S-43 Home (Urdu/RTL) *(this is a state of
  `features/home`, built in plan 002 — this plan's job is only to make sure the language
  toggle in Settings actually drives it; no new screen file here)*, S-44 Notifications,
  S-52 Delete account, S-54 Notification permission pre-prompt.
- System states, demonstrated as real reachable states rather than one-off mockups: S-45
  Home loading (already a natural state of `HomeCubit` from plan 002 — this plan verifies/
  polishes it, doesn't rebuild it), S-46 Offline (a new state, driven by a debug-only
  "Simulate offline" toggle added to Settings per 001's Assumption 7), S-47 Empty state
  (already demonstrated in plan 003's Friends screen — this plan adds `core/widgets/
  empty_state_view.dart` polish if needed and confirms 1 more real usage, e.g. an empty
  achievements filter, to prove it's truly generic and not accidentally Friends-specific),
  S-48 Content error (demonstrated on the level map screen from plan 002 — simulated via
  the same mock-failure convention from 001, triggered on demand rather than randomly, so
  it's reviewable on request).
- Overlays: S-49 Snackbar in place *(already built as `core/widgets/app_snackbar.dart` in
  001 — this plan adds one clearly-labelled demo trigger point if none of 002/003 already
  show one organically, e.g. after mock-signing-in)*, S-50 Force update (new, simple, its
  own full-bleed screen), S-51 Report a question (new — `core/widgets/
  report_question_sheet.dart` was reserved in 001, this plan builds its actual content and
  wires it from `features/quiz_play`'s question ⋯ menu, added retroactively as a small
  addition to that plan-002 feature per CLAUDE.md §10's "shared files may only be added to"
  — this is adding a menu item to an existing quiz_play screen, not restructuring it), S-53
  Share sheet *(already built + used in plan 003 — no new work here beyond confirming it's
  genuinely shared, not duplicated)*.

**Out of scope:**
- Real ads SDK / IAP — `features/shop`'s coin packs and "remove ads" tile, and S-37's
  rewarded-ad prompt, are all mock: tapping "Watch now" simulates a 1-2s delay then grants
  the stated mock coin amount; tapping a coin pack or "remove ads" shows an `AppSnackbar`
  ("mock — payments not wired") rather than opening a real store sheet.
- Real duel networking — `features/duel` uses a scripted mock opponent (a small fixed
  "bot" answer-timing script) rather than a real matchmaking server or realtime channel;
  the bible's own §24 (duel architecture, server-resolved rounds) is explicitly a backend
  concern deferred everywhere in this series per 001's Scope.
- Real push notification permission plumbing — S-54 shows the *pre-prompt* UI and, on
  accept, can optionally call the real OS `permission_handler`/`firebase_messaging`
  request (out of scope, no such package added) or simply mock-flip a "reminders on" flag
  and dismiss; recommend the latter to stay consistent with "no real backend/services"
  everywhere else in this series.
- Real account deletion — S-52's confirmation flow is fully interactive (typed-username
  gate, disabled-until-match button) but "Delete permanently" on a mock account just
  mock-signs-out (`SessionCubit` back to Guest) and shows a snackbar; no real data erasure
  exists to perform.

## Research findings

**S-36 Shop** (`features/shop`): top bar "Shop" + wallet pills (coin, gem); a gold/mango
gradient "Free coins" card ("Watch a 30s ad · N left today" / "+50 🪙" affordance — sits
**above** paid options, deliberately, per the bible: "Free coins sit above paid coins,
deliberately"); "Power-ups" section as rows (50:50/+15s/Skip priced in coins, Freeze priced
in gems — each row shows what the power-up does as a one-line description, matching
`features/quiz_play`'s power-up domain concept from plan 002, so this feature should reuse
whatever power-up enum/model plan 002 defined rather than inventing a second one — if
plan 002 kept it local/non-shared, promote it to `core/models/` now since it's now used by
2 features, following 001's same reused-by-3+ spirit loosely, or duplicate deliberately if
promoting mid-series feels disruptive — flag this as a live judgment call, see
Assumptions); "Coin packs" 3-up tile grid ($0.99/$4.99 middle-highlighted/$9.99, with
"+20%"/"+50%" bonus badges); a "Remove ads forever" row explicitly promising rewarded ads
stay available (bible: "the commonest complaint about that purchase is losing the free-
coin route" — the mock version should carry this exact copy, since it's a real product
decision the design bible is encoding, not incidental).

**S-37 Rewarded ad prompt**: modal dialog, TV emoji icon, "Watch to earn" / "A 30-second
ad gets you {N} coins. You have {x} of {y} daily rewards left."; a before→after balance
chip pair (current balance → projected balance, connected by an arrow, projected balance
outlined in mint); actions "▶ Watch now" (gold, primary) / "No thanks" (line). Mock:
"Watch now" runs a short simulated delay (standing in for ad playback) then credits the
mock coin balance and closes with a success `AppSnackbar`; **ad load failure must fall back
to a toast, never a dead/unresponsive button** — build a deliberate, occasionally-
triggered mock "ad failed to load" path (reuse 001's mock-failure convention) so this
required fallback is actually exercised, not just described.

**S-38 Play sheet — already built in plan 001.** No new work; this plan only verifies its
"1v1 Duel" row's route target once `features/duel` exists.

**S-39 Matchmaking** (`features/duel`): dark arena background (reuse `ArenaColors` from
001 — this screen is explicitly gameplay-adjacent even though it's pre-game); "Finding an
opponent" title, a VS row (player's own avatar/ELO on one side, a shimmering "❓ Searching…"
skeleton avatar + ELO-band text on the other, "VS" centered), a spinner, a status line
"Searching for {n}s · widening range in {m}s" (mock: a simple count-up timer with the ELO
band widening every 6s, as specified); after ~20s (per bible), auto-offer an explicitly-
labeled bot opponent — "**never a secret bot**" is a hard bible requirement, the mock bot
must always show as a bot, never pretend to be a human; "Cancel — play a bot instead"
button available throughout, not just after the 20s mark (bible shows it present
immediately in the mockup — read that as "always offered," not "offered only after
timeout" — flag this reading since the surrounding prose emphasizes 20s but the button is
visible from frame one).

**S-40 Duel — in play**: dark arena; a VS header row (each side: avatar + running round-
score, not points — duels are best-of-5 rounds); center: timer ring (56px) + "ROUND N/5"
label; a status-chip pair below ("🐼 answered in {t}s" once the player has locked an
answer / "🦊 thinking…" for the opponent, live); the shared question box + 4 options exactly
like solo play but **the chosen option shows an hourglass icon and stays visually "locked"
rather than immediately revealing correct/wrong — correctness is withheld until both
players have answered**, which is a specific, important behavioral rule (prevents the
faster player's UI from leaking the answer to what would, in a real multiplayer session,
be visible to the opponent — even though in this mock-only version there's no real second
client, implement the *rule* faithfully since it's the whole architectural point the bible
is making in its duel-design callout). Mock the opponent (bot) answering after a scripted
delay drawn from a small fixed timing table per "ELO band," per Scope's mock-opponent note.

**S-41 Duel result**: victory variant shown in Research findings (mint gradient, "🏆
Victory!", VS score row with the winner's avatar ringed in gold, a stat card: rounds won,
average answer time comparison, ELO before→after, reward); "Rematch" primary (white button
on the colored ground) / "Find a new opponent" secondary. **Defeat variant**: "identical in
structure with a raspberry ground, 'Good game' headline, and the same reward card showing
the smaller consolation payout" — build both from one parameterized screen/widget (an
`isVictory` flag driving background gradient + headline + reward numbers), not two
separate files, matching the bible's own framing of them as one screen with two states.

**S-42 Settings** (`features/settings`): grouped list — "APPEARANCE" (theme segmented
Light/Dark/System, driving 001's `ThemeCubit` directly — this screen is the first *real*
consumer of that Cubit beyond a debug toggle); "GAME" (Language row → S-3-style picker or a
simpler inline picker, reusing `features/onboarding`'s language list rather than
duplicating it; Sound effects / Music / Haptics toggles — bible's stated defaults are sound
on, music off, haptics on — these can be purely cosmetic mock toggles since no audio/haptic
playback is wired per plan 002's Scope note); "ACCOUNT" (Notifications → S-44,
Privacy/leaderboard visibility → a stub row is acceptable if not otherwise specified, Delete
account → S-52, styled in raspberry text); footer version string. **This screen also hosts
the debug-only "Simulate offline" toggle** from 001's Assumption 7 — place it in a clearly
labeled section (e.g. a "DEVELOPER" group) so a reviewer understands it's a demo aid, not a
real settings item the design bible specifies.

**S-43 Home — Urdu (RTL)**: not a new screen — confirm/polish that plan 002's
`HomeScreen` fully mirrors under `Directionality.rtl`: avatar/wallet swap sides, rails
scroll right-to-left, gradients flip angle (150deg → mirrored), the "hot"/emoji badge on
popular cards moves to the opposite corner, tab bar *order* stays visually the same (icons
carry meaning, not text position) — the bible is explicit that the tab bar itself doesn't
mirror even though everything else does. If plan 002 already handled this correctly via
001's `EdgeInsetsDirectional`/`start`/`end` discipline, this phase is verification + a
regression test, not new screen code.

**S-44 Notifications**: back + "Notifications" + "Mark all read"; a list of rows, unread
ones washed in a light grape tint; **actionable notifications embed their action inline**
(the bible's explicit example: a duel-challenge notification has an "Accept" pill right in
the row — "accepting a duel from here must never require a second screen"); other rows are
purely informational (streak-ending warning, league-rank-drop, new-content, reward-claimed).
Mock: a fixed list of 5 rows matching the bible's own examples; "Accept" on the duel-
challenge row navigates straight into `features/duel`'s matchmaking/duel screen (or, more
correctly per the bible's own duel description, straight into a duel already found — since
this is a friend challenge, not matchmaking; render it as directly entering S-40 with a
pre-filled opponent, skipping S-39 entirely, which is a reasonable reading of "must never
require a second screen").

**S-45 Home loading**: not new — plan 002's `HomeCubit` already has a natural loading
state; this plan's job is confirming the skeleton treatment matches the bible exactly
(chrome — top bar avatar/title/wallet and the tab bar — renders instantly, never as
skeletons; only the popular rail / category tiles / section headers skeleton, and only if
the cache is "genuinely cold" — mock: only show this state on true cold start / after an
explicit "reset app state" debug action, not on every navigation to Home).

**S-46 Offline**: a new Home variant — top bar subtitle changes to "Offline mode"; an
inline warning card ("📡 No connection. You can still play N downloaded topics. Scores
sync when you're back."); "Available offline" tile grid (a fixed subset of categories
flagged as "downloaded" in mock data); a dimmed "NEEDS CONNECTION" strip listing what
doesn't work (Duels · Leaderboards · Daily challenge). Driven entirely by the debug
"Simulate offline" toggle from Settings (a simple app-root `ConnectivityCubit` or a field
on `SessionCubit` — pick whichever fits better once 002's `SessionCubit` shape is visible;
this plan does not require a real `connectivity_plus` package, per Scope).

**S-47 Empty state**: `core/widgets/empty_state_view.dart` was already built in 001 and
demonstrated in plan 003's Friends screen — this plan's job is a second real usage (e.g.
an achievements filter chip with zero matches, or a subcategory with no levels played yet)
to prove genericity, plus a direct widget test.

**S-48 Content error**: back + category name; icon 🧩, "Couldn't load this level" /
"The questions didn't finish downloading. Your progress is safe."; a monospace error-code
chip ("ERR_CONTENT_FETCH · 504" — mock: any stable fake code is fine); "Try again" +
"Play a different topic". Demonstrated on plan 002's level-map/level-brief flow, triggered
via 001's mock-failure convention on demand (e.g. a debug button, or simply whenever the
mock API's simulated-failure branch fires) rather than randomly during normal review.

**S-49 Snackbar in place** — already built (001), needs one clean demonstration point if
none exists yet: recommend firing it after `SessionCubit.signIn()` succeeds ("Progress
saved to your account / Synced across all your devices") since that's the bible's own
literal example and a natural, real trigger already in the app (from plan 002).

**S-50 Force update**: full-bleed grape gradient, 🚀 emoji, "Time to update" / "Version 1.4
adds 1v1 duels and 12 new topics. This version can no longer connect." + a single gold
"Update Quizoo" button. **Blocking** (no back/dismiss) — bible: "used only for a genuine
protocol break," soft updates get a dismissible Home banner instead (a soft-update banner
is *not* separately specified anywhere else in the bible, so is not built here — flag that
only the hard/blocking variant is in scope). Reach this screen via a debug entry point
only (there's no real version-check service in this mock phase) — e.g. a Settings row
"Preview: force update screen".

**S-51 Report a question**: bottom sheet, radio-style single-select list (The answer is
wrong / Question is unclear / Bad translation / Offensive content / Image doesn't load),
"Send report" CTA. Mock: on send, shows an `AppSnackbar` confirmation and pops; no real
moderation-queue backend (bible's `questionId`/auto-suspend-after-3-reports mechanism is
explicitly backend/content-moderation infrastructure, out of scope everywhere in this
series). Wired from a new "⋯" overflow affordance added to `features/quiz_play`'s question
HUD (a small, additive change to an existing plan-002 screen, not a restructure).

**S-52 Delete account**: modal dialog, 🗑️ icon, states exactly what's destroyed in the
player's own live mock numbers (points/badges/streak — pull from `SessionCubit`/`profile`
mock state, don't hardcode the bible's literal example numbers), a text field gated
confirmation (must type the current mock username exactly), "Keep my account" (dominant,
`ghost` style) vs. a `dis`-styled "Delete permanently" that only enables once the typed
text matches. Mock delete = sign out to Guest + snackbar, per Scope.

**S-53 Share sheet** — already built + demonstrated in plan 003; this plan does not modify
it, only confirms `features/duel`'s victory screen and `features/shop` do **not** need it
(neither screen in this plan actually calls for a share moment per the bible — don't add
one that wasn't specified).

**S-54 Notification permission**: modal dialog, 🔔 icon, "Keep your streak alive?" / "We'll
send one reminder a day at a time you choose. Nothing else — no marketing, no 'we miss
you'."; a time-picker row (mock: a fixed default "8:30 PM," tapping it can open a simple
`showTimePicker` — this is genuinely easy to make real since it's a built-in Flutter
widget, no reason to mock it); actions "Turn on reminders" / "Not now". Bible states this
fires "after the third completed level, never on first launch" — per 001's Assumption 7,
real cross-session trigger tracking is out of scope; reach this screen via a debug entry
point in Settings for review purposes, and optionally (nice-to-have, not required) wire a
simple in-memory "levels completed this session" counter on `SessionCubit`/similar that
triggers it for real after 3 mock level completions within one running session — flagged
as optional because it's a small enough addition to be worth attempting if time allows,
but not an acceptance-blocking requirement.

## Assumptions & open questions

1. **Power-up model ownership (Shop vs. quiz_play).** Flagged inline in Research
   findings — recommend promoting whatever power-up enum/model plan 002 built to
   `core/models/` once this plan needs it too, rather than duplicating; this is a small
   retroactive addition to 001/002's territory, allowed under CLAUDE.md §10's "shared
   files may only be added to" (adding a model to `core/models/` is an addition, not a
   restructure).
2. **Duel's "always-visible bot fallback button" reading** — flagged inline in S-39's
   findings; if the user intends the button to appear *only* after the 20s timeout, that's
   a one-line change to `MatchmakingCubit`'s state, not a structural change to this plan.
3. **Notification-permission real trigger (S-54) is optional/best-effort**, not
   acceptance-blocking, per Research findings — flagging explicitly so it isn't mistaken
   for a dropped requirement if it's left as debug-only.
4. **"Privacy & leaderboard visibility" settings row** has no corresponding screen anywhere
   in the 54-screen inventory — the bible lists it as a settings row with a "›" affordance
   but never mockups its destination. Recommend a stub screen (a simple on/off list: "Show
   my rank on leaderboards," "Show my activity to friends") reasonably inferred from the
   row's own label, flagged here as an inferred addition rather than bible-specified.
5. **`ConnectivityCubit` vs. extending `SessionCubit`** for the offline toggle — left as an
   implementation-time judgment call once 002's actual `SessionCubit` shape is visible;
   either is consistent with CLAUDE.md (a small, genuinely app-wide piece of state either
   way).

## Design overview

```
features/
├── shop/
│   ├── data/shop_api.dart, shop_repository.dart
│   ├── domain/power_up_offer.dart, coin_pack.dart  (or import core/models power-up if promoted)
│   └── presentation/
│       ├── bloc/shop_cubit.dart (+state), rewarded_ad_cubit.dart (+state)
│       ├── screens/shop_screen.dart
│       └── widgets/coin_pack_tile.dart, rewarded_ad_dialog.dart
├── duel/
│   ├── data/duel_api.dart, duel_repository.dart
│   ├── domain/duel_opponent.dart, duel_round.dart, duel_result.dart
│   └── presentation/
│       ├── bloc/matchmaking_cubit.dart (+state: Searching/BotOffered/Found),
│       │        duel_play_cubit.dart (+state, mirrors quiz_play_cubit's shape where
│       │        sensible but is its own Cubit — a duel is not just solo play with a
│       │        second avatar bolted on, per the withheld-correctness rule)
│       ├── screens/matchmaking_screen.dart, duel_play_screen.dart, duel_result_screen.dart
│       └── widgets/vs_header.dart, duel_status_chip.dart
├── settings/
│   ├── data/settings_api.dart, settings_repository.dart (mock: reads/writes an in-memory
│   │        SettingsState — sound/music/haptics/theme-passthrough/simulate-offline)
│   ├── domain/app_settings.dart
│   └── presentation/
│       ├── bloc/settings_cubit.dart (+state), notifications_cubit.dart (+state)
│       ├── screens/settings_screen.dart, notifications_screen.dart,
│       │        delete_account_screen.dart (or dialog-only, see impl notes),
│       │        notification_permission_screen.dart (dialog), force_update_screen.dart,
│       │        privacy_settings_screen.dart (Assumption 4 stub)
│       └── widgets/settings_row.dart, settings_toggle_row.dart
└── (system-state polish lands inside features/home, features/catalog, features/
    achievements from plans 002/003 — no new feature folder for S-45..48)

core/widgets/  (additions in this plan)
└── report_question_sheet.dart  (content filled in; file itself reserved by 001)
```

## Implementation steps

- [ ] **Phase A — Shop.** Resolve the power-up model question (Assumption 1) before
  writing `ShopRepository`. Build `ShopScreen` per Research findings; `RewardedAdDialog` +
  `RewardedAdCubit` with the before→after balance chip and the deliberate occasional
  simulated ad-failure path (reusing 001's convention).
- [ ] **Phase B — Duel.** `MatchmakingScreen` + `MatchmakingCubit` (mock ELO-band widening
  every 6s via a `Ticker`/timer, auto-offers bot per Assumption 2's chosen reading).
  `DuelPlayCubit` implementing the withheld-correctness rule explicitly (do not reveal
  correct/wrong to the UI until both "players" — the real one and the scripted bot — have
  answered; model this as a real state transition, not a UI-level delay hack). Script the
  bot's answer timing from a small fixed table keyed by ELO band. `DuelResultScreen` as one
  parameterized widget for both victory/defeat per Research findings. Update `features/
  shell`'s `PlayLauncherSheet` (built in 001) so its "1v1 Duel" row's route now resolves
  here instead of 001's placeholder — this is the one small edit to a plan-001 file this
  plan needs to make.
- [ ] **Phase C — Settings core.** `SettingsCubit` (theme passthrough calling 001's
  `ThemeCubit`, sound/music/haptics toggles, the debug "Simulate offline" flag).
  `SettingsScreen` with all three grouped sections plus the labeled DEVELOPER section.
  `NotificationsScreen` with the 5 fixed rows and the inline "Accept" duel action wired
  into Phase B's duel screens per Research findings (skip matchmaking, enter duel-in-play
  directly with a pre-set friend opponent).
- [ ] **Phase D — Settings overlays.** `DeleteAccountScreen`/dialog (typed-confirmation
  gate), `NotificationPermissionScreen` (real `showTimePicker`, mock accept/decline),
  `ForceUpdateScreen` (blocking, debug-reachable only), `PrivacySettingsScreen` (Assumption
  4 stub).
- [ ] **Phase E — System-state verification pass.** Walk S-45 (Home loading), S-46
  (Offline — new, wire the debug toggle from Phase C through to `HomeScreen`'s offline
  variant), S-47 (Empty state — add the second usage per Research findings), S-48 (Content
  error — verify it's triggerable on demand on the level-map screen). This phase touches
  `features/home` and `features/catalog` (from plan 002) and `features/achievements` (from
  plan 003) additively — new states/branches on existing sealed unions, not restructuring
  — consistent with CLAUDE.md §10.
- [ ] **Phase F — Report question.** Fill in `core/widgets/report_question_sheet.dart`'s
  content (radio list + send), add the "⋯" menu affordance to `features/quiz_play`'s HUD
  (plan 002) that opens it, mock the "Send report" confirmation snackbar.
- [ ] **Phase G — Retire the placeholder scaffolding.** Once every one of the 54 routes
  has a real screen behind it (across all 4 plans), delete 001's generic placeholder
  `Scaffold` builder from `app/router.dart` — there should be nothing left pointing at it.
  Grep for any leftover reference before considering this plan done.

## Data model / API changes

- `core/models/power_up.dart` (promoted per Assumption 1, if that's the resolution
  reached) — enum or small class: `type` (fiftyFifty/extraTime/skip/freeze), `count`,
  `costCoins`/`costGems`.
- Feature-local: `DuelOpponent` (id, name, avatarEmoji, elo), `DuelRound` (questionId,
  playerAnswerIndex?, playerAnswerTime?, opponentAnswerIndex?, opponentAnswerTime?,
  resolved bool), `AppSettings` (soundOn, musicOn, hapticsOn, simulateOffline).

## Dependencies

No new packages beyond 001's list. `showTimePicker` (S-54) is Flutter SDK, no add needed.

## Testing strategy

- `ShopCubit`, `RewardedAdCubit`, `MatchmakingCubit`, `DuelPlayCubit`, `SettingsCubit`,
  `NotificationsCubit`: `bloc_test` suites, initial/success/failure, per CLAUDE.md §11
  (the "failure" case for `DuelPlayCubit` can be the mock ad-equivalent or a connection-
  drop simulation — pick whichever is more natural once the Cubit is drafted, but it must
  be a real distinct branch, not a reuse of the success test with different assertions).
- Repository unit tests with `mocktail` for `ShopRepository`, `DuelRepository`,
  `SettingsRepository`.
- Widget test specifically asserting `DuelPlayCubit` never exposes correctness to the UI
  before both sides have answered — this is the single most important behavioral test in
  this plan, since it's easy to accidentally leak the answer via a shared state field.
- Widget test for `DeleteAccountScreen`'s button-enable-only-on-exact-match gate.
- A full grep-based check (not a Dart test, a build-time verification step) confirming no
  route in `app/router.dart` still points at 001's placeholder builder — this is Phase G's
  own acceptance gate.

## Edge cases & error handling

- Rewarded-ad "load failure" must show a toast and leave the dialog in a retryable state,
  never a permanently-dead button — test this explicitly.
- Duel opponent (bot) disconnecting mid-round is out of scope (no real disconnect concept
  exists without real networking) — the bot always completes all 5 rounds; don't build a
  disconn­ect-handling path that has nothing real to simulate.
- Force-update screen must have **no** back-navigation, system-back, or gesture-dismiss
  path — verify with a test that `PopScope`/equivalent actually blocks it, since this is
  the one screen in the entire app that's intentionally non-dismissible.
- Delete-account confirmation must be case-sensitive exact match against the mock
  username (bible shows the literal typed value must equal the account's username) — don't
  accept a trimmed/case-insensitive match, that would weaken the deliberate friction.

## Acceptance criteria

- [ ] Every screen built in this plan (S-36…S-54) has been visually compared, side by
  side, against its frame in `.claude/docs/quizoo-design-bible.html`, not just implemented
  from this plan's prose description, since the user has asked for exact parity with that
  document.
- [ ] Every one of the 54 `AppRoutes.sXX` constants reserved in plan 001 now points at a
  real, finished screen; 001's placeholder builder is deleted and nothing references it.
- [ ] A duel can be played start-to-finish against the scripted bot without the UI ever
  revealing correctness before both sides answer, ending on the correctly-parameterized
  victory or defeat result screen.
- [ ] Settings' theme toggle drives the same `ThemeCubit` used everywhere else in the app
  (no second, disconnected theme state); the "Simulate offline" toggle visibly flips
  Home into its offline variant and back.
- [ ] Report-question, delete-account, and notification-permission flows are each reachable
  and functionally complete per their mock rules (send confirmation / typed-match gate /
  real time picker) even though none of them touch a real backend.
- [ ] `flutter analyze` zero warnings across the whole repo (this plan is the last one —
  it's the first point at which "zero warnings across the whole repo" is a meaningful,
  final check rather than a per-plan one).

## Risks & rollout notes

- This plan touches the most already-built files from prior plans (Phases B, E, F all add
  to existing screens/widgets) — review each addition against CLAUDE.md §10's "add, don't
  restructure" rule before merging, since it's the easiest rule to violate by accident
  when four plans' worth of work all converge on the same shared files near the end.
- Recommend Phase G (placeholder retirement + full-repo lint pass) as a deliberate final
  step done once, after the other phases, rather than incrementally — it's the natural
  "is the whole 54-screen build actually done" checkpoint for this entire 4-plan series.
- No migration/rollback concerns — greenfield, mock data only.
