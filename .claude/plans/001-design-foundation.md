# Quizoo — Design Foundation (tokens, shell, mock-data pattern)

> Source spec: Quizoo Design Bible v1.0 — the full, original HTML document is saved at
> `.claude/docs/quizoo-design-bible.html` in this repo (also originally published as
> artifact `3f18beb5-ee6d-4da1-a741-dfa5d66e02a6`, in case the local copy ever needs
> re-verifying against the source). This plan transcribes every token/value it uses from
> that document, but **the HTML file is the ground truth for pixel-level UI fidelity, not
> this plan's prose** — see the mandatory instruction below.
> Status: Draft — not yet implemented
> Depends on: nothing (this is the base plan). Plans 002, 003, 004 all depend on this one being implemented first.

## How to use this plan

This plan is self-contained: executing it needs no prior conversation history. Start by
reading it in full, then **open `.claude/docs/quizoo-design-bible.html` directly (in a
browser, or by reading the file's markup/inline CSS) and read sections 01–06** (Overview,
Information architecture, Color, Typography, Space/shape/motion, Component library) —
render it in a browser to see the actual component gallery (buttons, answer options,
pills, cards, tiles, snackbars, skeletons, power-up dock) exactly as designed, in both its
light/dark theme toggle and its app-theme toggle (the page has working `☀️/🌙` and
`Light/Dark/Auto` switches in §06 — use them). **The user has explicitly asked for pixel-
parity with this document: every color, radius, shadow, spacing value, font, and motion
timing implemented in this plan (and in plans 002–004) must match the HTML file exactly,
not an approximation.** Where this plan's prose gives a hex value, class name, or pixel
number, that value was read directly from the HTML/CSS in that file — if anything here
ever looks ambiguous or you need a value this plan didn't transcribe, go back to the HTML
file itself (search it for the relevant `.sw`/`.type-row`/`.compo`/screen-id anchor, e.g.
`id="s-11"`) rather than guessing. Code may have moved on since this was written —
`lib/main.dart` is currently still the stock `flutter create` counter app; verify that's
still true before you begin.

This is plan **1 of 4**:
- **001 (this file)** — design tokens, folder skeleton, app shell/routing, shared core
  widgets, the mock-data pattern every later feature will follow, dependency setup.
- **002** — Onboarding, Home, Browse/Level-map, Quiz Play, Result & sign-in-prompt screens
  (the core loop).
- **003** — Daily challenge, Leaderboard & Friends, Profile/Achievements/Stats.
- **004** — Shop/Economy, 1v1 Duel, Settings & RTL, system states (loading/empty/offline/
  error) and overlay screens (report, delete account, share, force update, notification
  pre-prompt).

Plans 002–004 each assume this plan's folder layout, theme tokens, router constants, core
widgets and mock-data convention already exist — they do not redefine them.

## Objective

Stand up everything that is shared by every screen in the app — design tokens (color,
type, spacing, shape, motion), the five-tab + FAB navigation shell, the routing skeleton
(every route this app will ever need, wired to placeholder screens so the app runs and
navigates end-to-end from step one), the reusable component library called out in the
design bible's §06, and — because this phase is explicitly "design with mock data, no
backend" — a repeatable pattern for feeding Cubits from fake data instead of a live API,
so plans 002–004 can follow one convention instead of inventing their own each time.

No business logic, scoring math, backend, or real network call is in scope anywhere in
this plan or its three siblings. Everything here is `main.dart` → app shell → routes →
screens → Cubits → mock repositories → static/generated fixture data.

## Scope

**In scope:**
- `pubspec.yaml` dependency additions (state mgmt, routing, sizing, fonts, animation, mock
  data generation, testing).
- `core/theme/*` — `AppColors` (light + dark), a `QuizooColors` `ThemeExtension` for the
  shell chrome, a separate fixed `ArenaColors` extension for the play surface (dark in both
  themes per the design bible), `AppTypography` (`TextTheme` for both modes), `AppSpacing`,
  shape/radius constants, motion-curve/duration constants.
- `core/widgets/*` — the component-library widgets from §06: `ChunkyButton` (the 4px hard-
  shadow ledge used by buttons/options/level nodes), `AnswerOption`, wallet `CurrencyPill`,
  `AppChip`/`SegmentedTabs`, `ListRowTile` (content/player/self row), `CategoryTile`/
  `LevelNode`, `AppSnackbar`, `SkeletonBox`, `PowerUpDock` tile, `EmptyStateView`,
  `ErrorStateView`, bottom sheet/dialog scaffolding (`AppBottomSheet`, `AppDialog`).
- `core/models/*` — the small set of domain models genuinely reused by 3+ features
  (`Category`, `Subcategory`, `Level`, `PlayerCurrency`, `Badge`, plus enums like
  `AppThemeMode`), justified per-model in "Design overview" below.
- `core/breakpoints.dart`, `core/router/app_routes.dart` (route path constants only — see
  below), `app/router.dart` (the actual `GoRouter` + `ShellRoute`), `app/app.dart`
  (`ScreenUtilInit` + `MaterialApp.router` + both `ThemeData`s), `app/theme_cubit.dart`
  (app-root `ThemeCubit`, the one legitimately global Cubit this phase needs).
- `lib/l10n/` scaffolding: `flutter_localizations` + `gen-l10n` wired for **English**
  (complete) and **Urdu** (a small proof-of-concept subset — see Assumptions) so the RTL
  mirroring called out in §04/§05/§16 can actually be exercised on at least one real screen.
- A documented, example-backed **mock-data convention** (`data/<feature>_api.dart` returns
  canned DTOs via `Future.delayed` instead of a Dio call; `data/<feature>_repository.dart`
  maps DTOs → domain models exactly as CLAUDE.md §9 describes) that plans 002–004 must
  follow verbatim.
- A placeholder screen + route for **every one of the 54 screen IDs** (S-01…S-54) in the
  design bible, wired into `app/router.dart`, so the whole app is navigable (even if most
  bodies just say "S-23 Badge unlocked — see plan 004") from the moment this plan lands.
  This is what lets 002/003/004 be built and reviewed independently and in any order.

**Out of scope:**
- Any real screen body beyond a placeholder (all 54 screens are fleshed out in 002–004).
- Supabase/Firebase, `ApiClient`/Dio wiring, push notifications, IAP, ads, analytics.
- Real translations beyond the English + Urdu proof-of-concept subset; Arabic, Hindi,
  Spanish are content work, not design-system work, and are explicitly deferred (see
  Assumptions).
- Scoring/XP/streak/economy math (§19–20 of the bible) — those are business-logic
  specs for a future "make it real" phase, not the mock-data design phase.
- `very_good_analysis` migration — `analysis_options.yaml` stays on `flutter_lints` as
  currently configured; swapping lint bases is an infra decision outside a single spec's
  scope per CLAUDE.md §10.

## Research findings

- **The repo is a brand-new `flutter create` scaffold.** `lib/main.dart` is still the stock
  counter-app template, `pubspec.yaml` has only `cupertino_icons` + `flutter_lints`, and
  there is no `lib/{app,core,features,l10n,gen}` structure yet. There are no existing
  conventions to mirror — this plan **establishes** them, per CLAUDE.md §2.
- **Flutter 3.44.6 / Dart 3.12.2**, stable channel (confirmed via `flutter --version`).
  `pubspec.yaml` currently pins `sdk: ^3.12.2`.
- **CLAUDE.md is exhaustive and must be followed literally** — feature-first folders,
  Cubit-first state (Bloc only for multi-trigger state machines), sealed-class states with
  exhaustive `switch`, go_router with `AppRoutes` constants, `core/theme` tokens only (no
  raw colors/text styles/spacing), `flutter_screenutil` for all sizing, `bloc_test` per
  Cubit, `mocktail` for repository tests. Every plan in this series follows these without
  exception; anywhere the mock-data premise pulls against a CLAUDE.md rule (see
  Assumptions) it is called out explicitly rather than silently resolved.
- **Design bible key facts, transcribed exactly from `.claude/docs/quizoo-design-bible.html`**
  (open this file — ideally rendered in a browser — for the live component gallery, the
  working light/dark and app-theme toggles, and to verify any value below against the
  actual CSS custom properties and markup rather than this summary alone):

  **Fonts** — `Baloo 2` (500/600/700/800) for display/headings/buttons/scores, `Plus Jakarta
  Sans` (400/500/600/700/800) for body/UI text, `JetBrains Mono` (400/500/700) for meta/mono
  labels, `Noto Nastaliq Urdu` (400/700) for Urdu question/UI text. The bible explicitly
  warns against `google_fonts` at runtime ("a cold-start network dependency you do not want
  on the splash screen") — **bundle all four as local font assets** in `pubspec.yaml`.

  **Color tokens — light / dark** (hex, from §03):
  | Token | Role | Light | Dark |
  |---|---|---|---|
  | `s0` | app background | `#F3F0FC` | `#120D25` |
  | `s1` | card/sheet surface | `#FFFFFF` | `#201941` |
  | `s2` | raised/selected | `#F8F6FE` | `#2A2154` |
  | `s3` | sunken/track | `#EDE8FA` | `#181233` |
  | `tx` | primary text | `#1B1438` | `#F2EEFF` |
  | `tx2` | secondary text | `#6E668C` | `#ADA4CC` |
  | `tx3` | tertiary/meta | `#9E97B8` | `#7B7399` |
  | `ln` | hairline border | `#E7E2F5` | `#332968` |
  | `p` (mango) | primary CTA/timer/FAB | `#FF8A24` | `#FF9A3D` |
  | `p-d`/`p-sh` (mango pressed/ledge) | | `#F06E00`/`#C85800` | `#FF8A24`/`#B85F00` |
  | `g` (grape) | brand/XP/active tab/links | `#7B4DFF` | `#9A78FF` |
  | `g-sh` | grape ledge | `#5A2CD8` | `#6A45D6` |
  | `ok` (mint) | correct/success | `#12C79B` | `#22D6AA` |
  | `ok-sh`/`ok-bg` | | `#0A9A77`/`#E2F9F2` | `#0E9C79`/`#0E3B33` |
  | `bad` (raspberry) | wrong/destructive | `#FF3D6E` | `#FF5C84` |
  | `bad-sh`/`bad-bg` | | `#D31C4C`/`#FFE8EE` | `#C92253`/`#40122A` |
  | `info` (sky) | gems/duels/info | `#2BB3FF` | `#57C4FF` |
  | `gold` (lemon) | coins/stars/1st place | `#FFC61A` | `#FFD34D` |
  | `gold-sh` | | `#D19A00` | `#B98700` |
  | `ov` | scrim | `rgba(27,20,56,.5)` | `rgba(4,2,12,.66)` |

  **Elevation** — `sh: 0 1px 2px rgba(27,20,56,.06), 0 8px 20px -10px rgba(27,20,56,.22)`
  (light) / `0 1px 2px rgba(0,0,0,.36), 0 10px 24px -12px rgba(0,0,0,.7)` (dark);
  `sh-lg` for sheets/dialogs is the same recipe with `-6y/34blur` and a larger spread.

  **Play-surface arena** (§09: "the one place the app commits to a single look" — same in
  both themes): base gradient `linear-gradient(178deg, #2A1B5E 0%, #160E36 62%, #0E0824
  100%)`; danger/last-5s variant `linear-gradient(178deg, #5A1030 0%, #38091F 60%, #1E0512
  100%)`. This is the `ArenaColors` extension — it must **not** repaint on `Theme.of(context)
  .brightness`.

  **Typography scale** (§04, family / weight / size-line-height / letter-spacing):
  Display XL 56/56 −3% (Baloo 800, scores); Display L 28/32 −2% (Baloo 800, "Level
  complete!"); Title 22/26 (Baloo 800, screen headers); Section 17/22 (Baloo 800, section
  headers); Question 19/24 balance (Baloo 700, question text — hard 3-line cap, drop to
  17px before ever truncating); Button 17.5/1 +1% (Baloo 800); Answer 15/20 (Jakarta 700);
  Body 14/20 (Jakarta 400); Label 11.5/14 (Jakarta 800); Meta 10.5/13 +4% (Jakarta 700,
  never below 10.5px anywhere); Urdu question 17/36 (Nastaliq 400, ~2.1 line-height).
  Numbers that stack (scores/ranks/timers/leaderboard points) use tabular figures.

  **Spacing scale** (4pt base, §05): `space.1=4, .2=8, .3=12, .4=16, .5=20 (screen margin,
  invariant on every screen without exception, incl. inside sheets), .6=24, .7=32`.

  **Shape/elevation** (§05): bottom sheet radius 28 (top only); dialog 26; card/tile 18–20;
  button 18 with a **hard, unblurred 4px bottom shadow, no blur** (this is the "signature"
  — every pressable surface sits on a solid ledge in a darker shade of its own color and
  translates down 4px on press); answer option 18, same hard-shadow treatment; icon button
  12; pill/chip 999.

  **Motion tokens** (§05): `press` 90ms easeOut (button/option depress); `pop` 340ms
  elasticOut(0.9) (stars, badge unlock, coin burst); `slide` 260ms easeOutCubic (question
  card transitions); `sheet` 300ms easeOutQuint (bottom sheets, 200ms scrim fade); `count`
  900ms easeOutExpo (score roll-up, XP fill, coin counter); `tick` 1000ms linear loop
  (timer ring sweep; last-5s adds a 1.06 scale pulse per second). Respect
  `MediaQuery.disableAnimations` / reduced motion everywhere (screen-shake on wrong answer
  is explicitly disabled under reduce-motion in the bible).

  **Edge-to-edge** (§05): every screen's own background must run behind the status bar —
  transparent `statusBarColor`, `SystemUiMode.edgeToEdge`, no `SafeArea` around the
  *background* layer (only the content layer takes `MediaQuery.padding.top`). Status-bar
  icon brightness is set per-route from the color underneath it. Same at the bottom: the
  tab bar/bottom CTA sits above `MediaQuery.padding.bottom` and is pinned via Scaffold's
  `bottomNavigationBar` slot, never as the last Column child.

  **Design size**: the bible is authored at **390×844 logical px** (iPhone 14/Pixel class)
  — this is the `ScreenUtilInit designSize` to use, confirmed explicitly in §25 "Flutter
  build notes".

  **Information architecture** (§02) — 5 tabs + 1 modal play surface, identical for guest
  and signed-in:
  ```
  Tab 1 Home        → popular rail, continue rail, category chips, subcategory grid, daily banner
  Tab 2 Ranks        → Global/Country/Friends segmented, Weekly/Monthly/All-time chips, per-category boards
  Tab 3 Play (FAB)   → action sheet: Quick Play, Daily Challenge, 1v1 Duel
  Tab 4 Daily        → today's challenge, streak calendar, milestones
  Tab 5 You          → profile header, stats, achievements grid, friends, settings
  ```
  The play surface is a full-screen route pushed over the shell with the tab bar hidden;
  exiting always returns to the screen that launched it, never to Home.

  **Component library** (§06) — exact widgets to build: buttons (54px tall, radius 18,
  variants: primary/`g`/`ok`/`gold`/`ghost`/`line`/`dis`/pressed); answer option (5 states:
  rest, selected-with-lemon-ring, correct, wrong, eliminated/"gone" at 24% opacity — color
  is always doubled with a ✓/✕ glyph, never color alone, because "roughly 1 in 12 male
  players cannot separate [mint/raspberry] by hue alone"); wallet pills (coin/gem/life,
  each with a colored token disc); segmented control (4px-inset sunken track); list row (3
  configs: content, player, self — self row gets a permanent 2px grape border); category
  tile + level node (done/now/locked/boss-crown states); snackbar (4 intents, 16px above
  tab bar, 3.2s auto-dismiss or 5s with an action, never stacks); skeleton (shape-matched,
  1.4s shimmer, only after 300ms of waiting); power-up dock tile (56×52, count badge,
  zero-count drops to 40% opacity and opens shop on tap).

  **All 54 screen IDs**, grouped exactly as the bible groups them (this is the basis for
  the placeholder-route list and for how plans 002–004 split the work):
  - Entry & home: S-01 Splash, S-02 Onboarding, S-03 Language picker, S-04 Home (guest),
    S-05 Home (signed-in), S-06 Search
  - Browse & level map: S-07 Category detail, S-08 Level map, S-09 Level brief sheet,
    S-10 Countdown
  - Gameplay: S-11 Question (default), S-12 Correct, S-13 Wrong, S-14 Danger (last 5s),
    S-15 Question (image), S-16 Question (Urdu/RTL), S-17 Pause sheet, S-18 Quit
    confirmation, S-19 Out of lives, S-20 Question (audio)
  - Results & progression: S-21 Level complete, S-22 Level failed, S-23 Badge unlocked,
    S-24 Save-progress sheet, S-25 Profile creation, S-26 League promotion
  - Daily: S-27 Daily tab, S-28 Daily result
  - Leaderboards & social: S-29 Global leaderboard, S-30 Category leaderboard, S-31 Friends
  - Profile: S-32 Profile, S-33 Achievements grid, S-34 Badge detail dialog, S-35 Stats
  - Shop: S-36 Shop, S-37 Rewarded ad prompt
  - Duel: S-38 Play sheet (FAB), S-39 Matchmaking, S-40 Duel in play, S-41 Duel result
  - Settings: S-42 Settings, S-43 Home (Urdu/RTL), S-44 Notifications
  - System states: S-45 Home loading, S-46 Offline, S-47 Empty state, S-48 Content error
  - Overlays: S-49 Snackbar in place, S-50 Force update, S-51 Report a question, S-52
    Delete account, S-53 Share sheet, S-54 Notification permission

## Assumptions & open questions

These are places where the mock-data/design-only premise genuinely pulls against a literal
CLAUDE.md rule or an unstated bible detail. Flagging per the project's own instruction
("flag the conflict instead of silently deviating") rather than resolving silently:

1. **`data/<feature>_api.dart` will not call Dio.** CLAUDE.md §9 says this file is "Dio
   calls only, returns DTOs", but there is no backend to call in this phase. Resolution:
   each `*_api.dart` returns `Future<List<XDto>>` (etc.) via `Future.delayed(const
   Duration(milliseconds: 300..600))` wrapping canned/generated DTOs, keeping the exact
   same method signatures a real Dio implementation would have. When a backend lands,
   only this file's body changes — repository, domain, and presentation are untouched.
   This is a deliberate, temporary deviation from the literal "Dio calls only" wording,
   not a silent one — flagging it here per project instruction.
2. **No `core/network/api_client.dart` / Dio dependency added in this phase.** Since no
   `*_api.dart` performs a real call, wiring a real `Dio` client would be dead
   infrastructure. It is deferred to the "make it real" phase, at which point it slots in
   exactly where §9 describes. `dio` is not added to `pubspec.yaml` here.
3. **Shared domain models live in `core/models/`.** CLAUDE.md §2 says core/ is for
   "reused-by-3+-features" code only. `Category`/`Subcategory`/`Level` are consumed by
   Home, Browse, Shop, Profile-stats and Leaderboard (5 features) — they qualify. Each
   feature still owns its *own* narrower models (e.g. `features/quiz_play/domain/
   question.dart`, `features/duel/domain/duel_round.dart`) that are not shared.
4. **No DI/service-locator package.** CLAUDE.md only requires constructor injection for
   Cubits; it doesn't mandate `get_it`/`injectable`. To keep this phase simple, each
   `BlocProvider` constructs its own repository (and the repository its own mock api)
   inline at the point of use, e.g. `BlocProvider(create: (_) => HomeCubit(HomeRepository
   (HomeApi())))`. If a later phase wants a service locator, that's a separate, explicit
   infra task per CLAUDE.md §10 — flagging so nobody is surprised it's absent.
5. **Localization scope is deliberately narrow.** The bible targets 5 languages; building
   real translation content for all 5 is content/localization work, not UI design. This
   phase ships `gen-l10n` scaffolding with English complete and a small Urdu subset (just
   enough strings to reproduce S-16/S-43's RTL mirroring for review) via `.arb` files.
   Arabic/Hindi/Spanish `.arb` files are **not** created — flagged as a v1.1+ item per the
   bible's own roadmap (§26).
6. **`ShareSheet` (S-53) is promoted to `core/widgets/` despite being used by only 2
   features** (quiz_result in plan 002, daily in plan 003) rather than the usual 3+
   threshold, because it is pure, parameterized UI chrome with zero business logic
   (matches the spirit of "generic buttons/loaders" already named in CLAUDE.md §2). Noted
   as a judgment call for the user/reviewer to veto if they'd rather duplicate it.
   `ReportQuestionSheet` (S-51) similarly lives in `core/widgets/` for the same reason (used
   from quiz_play and quiz_result).
7. **No automatic cross-feature orchestration.** Real triggers like "show the notification
   pre-prompt after the player's 3rd completed level" or "detect real offline and switch
   Home into offline mode" require app-wide event plumbing that's a business-logic concern,
   not a UI concern. For this phase: (a) sequential screens whose *next step* is knowable
   locally (e.g., quiz_result's own Cubit knows the mock score, so it can decide "show
   badge-unlock next" or "show sign-in sheet next" itself and the widget just navigates in
   order) are wired for real; (b) screens that would need real external state (offline
   detection, "3rd level" tracking across sessions) get a manual toggle for demo purposes
   — see plan 004's system-states section for the concrete mechanism (a debug-only
   "Simulate offline" switch in Settings).
8. **Every one of the 54 screens gets a placeholder route now, fleshed out later.** This
   is what makes 002/003/004 independently buildable. The placeholder body is a `Scaffold`
   with the screen's ID/name and a "not yet implemented — see plan 00X" message; this file
   still must define `AppRoutes.sXX` constants for all 54 upfront so later plans only add
   bodies, never new route constants (keeping `app/router.dart` — a frequently-touched
   shared file per CLAUDE.md §10 — edited by exactly one plan's worth of "add a route
   constant" churn instead of four).
9. **Google/Apple sign-in button chrome is drawn per the bible's spec but without the
   vendor-supplied logo assets** (the bible explicitly says these must be the official
   Google/Apple marks, not redrawn ones, and requires separate light/dark variants). Since
   there is no real auth in this phase, plan 002 draws the buttons with the exact colors/
   borders/typography specified but a placeholder glyph (`G`/`` icon) in the brand slot,
   flagged inline in that plan as "swap for the official asset before shipping."

## Design overview

### Folder skeleton this plan creates

```
lib/
├── app/
│   ├── app.dart                 # ScreenUtilInit + MaterialApp.router + both ThemeData
│   ├── router.dart              # GoRouter + ShellRoute, imports AppRoutes from core
│   └── theme_cubit.dart         # global ThemeCubit (light/dark/system) — the one
│                                 # legitimately app-root Cubit per CLAUDE.md §3
├── core/
│   ├── theme/
│   │   ├── app_colors.dart          # AppColors (light/dark ColorScheme seeds)
│   │   ├── quizoo_colors.dart        # ThemeExtension<QuizooColors> — s0..s3,tx..tx3,ln,
│   │   │                             # p/p-d/p-sh, g/g-sh, ok/ok-sh/ok-bg, bad/bad-sh/
│   │   │                             # bad-bg, info, gold/gold-sh, ov, sh, sh-lg
│   │   ├── arena_colors.dart         # ThemeExtension<ArenaColors> — fixed dark palette,
│   │   │                             # does not vary with brightness
│   │   ├── app_typography.dart       # TextTheme builder (light + dark), font family consts
│   │   ├── app_spacing.dart          # AppSpacing.xs/sm/md/lg/xl (4/8/12/16/20/24/32 — see
│   │   │                             # note below on naming vs the bible's space.1..7)
│   │   ├── app_radius.dart           # radius constants (sheet 28, dialog 26, card 18-20,
│   │   │                             # button 18, icon-button 12, pill 999)
│   │   ├── app_motion.dart           # Durations + Curves: press/pop/slide/sheet/count/tick
│   │   └── app_theme.dart            # assembles light/dark ThemeData from the above
│   ├── breakpoints.dart              # Breakpoints.tablet etc. (used with LayoutBuilder only)
│   ├── router/
│   │   └── app_routes.dart           # AppRoutes class — path const per screen, all 54
│   ├── models/
│   │   ├── category.dart             # freezed: id, name, emoji/imageUrl, colorFrom,
│   │   │                             # colorTo, order, subcategoryCount, questionCount,
│   │   │                             # isNew, isLocked
│   │   ├── subcategory.dart          # freezed: id, categoryId, name, emoji, questionCount,
│   │   │                             # levelsCleared, bestScore, starsEarned
│   │   ├── level.dart                # freezed: number, difficultyBand, secondsPerQuestion,
│   │   │                             # isBoss, status (locked/current/done), starsEarned
│   │   ├── player_currency.dart      # freezed: coins, gems, hearts, heartRefillAt
│   │   ├── badge.dart                # freezed: id, name, emoji, gradientFrom/To, isLocked,
│   │   │                             # rarityPercent, unlockedAt
│   │   └── app_theme_mode.dart       # enum: light/dark/system (if not reusing Flutter's)
│   └── widgets/
│       ├── chunky_button.dart        # ChunkyButton — the 4px-ledge press widget; variants
│       │                             # primary/secondary(g)/success(ok)/gold/ghost/line/
│       │                             # disabled, `sm` size, `sub` second line
│       ├── answer_option.dart        # AnswerOptionTile — 5 visual states
│       ├── currency_pill.dart        # CurrencyPill (coin/gem/life)
│       ├── app_chip.dart             # AppChip (category/filter chip, on/off)
│       ├── segmented_tabs.dart       # SegmentedTabs (Global/Country/Friends etc.)
│       ├── list_row_tile.dart        # ListRowTile (content/player/self configs)
│       ├── category_tile.dart        # CategoryTile (subcategory grid cell)
│       ├── level_node.dart           # LevelNode (done/now/locked/boss)
│       ├── app_snackbar.dart         # AppSnackbar.show(context, ...) — 4 intents
│       ├── skeleton_box.dart         # SkeletonBox — shimmer, shape-matched
│       ├── power_up_tile.dart        # PowerUpTile (dock + brief-sheet variants)
│       ├── empty_state_view.dart     # EmptyStateView (icon, title, body, actions)
│       ├── error_state_view.dart     # ErrorStateView (icon, title, body, error code, actions)
│       ├── app_bottom_sheet.dart     # AppBottomSheet.show(...) — grab handle, radius 28
│       ├── app_dialog.dart           # AppDialog.show(...) — radius 26, icon plate
│       ├── share_sheet.dart          # ShareSheet — see Assumption 6
│       └── report_question_sheet.dart # ReportQuestionSheet — see Assumption 6
├── l10n/
│   ├── app_en.arb                    # complete
│   └── app_ur.arb                    # proof-of-concept subset (see Assumption 5)
├── features/
│   └── shell/
│       ├── presentation/
│       │   ├── screens/app_shell_screen.dart   # the ShellRoute's child: Scaffold with
│       │   │                                    # bottomNavigationBar = AppTabBar
│       │   └── widgets/
│       │       ├── app_tab_bar.dart             # 5-tab bar + centre FAB
│       │       └── play_launcher_sheet.dart     # S-38's sheet (Quick Play/Daily/Duel/
│       │                                        # Challenge a friend) — stateless, routes
│       │                                        # out via go_router
│       └── (no bloc — this feature is pure navigation chrome, intentionally stateless)
└── main.dart                         # replaces the counter-app boilerplate; runApp(App())
```

**Note on `AppSpacing` naming**: CLAUDE.md §5 mandates an `xs/sm/md/lg/xl` scale; the bible
uses `space.1..7` (4/8/12/16/20/24/32). Map them as `xs=4, sm=8, md=12, base=16, lg=20,
xl=24, xxl=32` — i.e. CLAUDE.md's naming convention wins (per its own precedence rule),
with the bible's 7 raw values all still present just under different names. Document this
mapping in a comment at the top of `app_spacing.dart` so nobody has to re-derive it.

### Router skeleton

`app/router.dart` defines one `GoRouter` with:
- A top-level `ShellRoute` wrapping `AppShellScreen`, containing the 5 tab branches (Home,
  Ranks, Daily, You use `StatefulShellRoute.indexedStack`; the centre "Play" tab has no
  page of its own — tapping it opens `PlayLauncherSheet` via `showModalBottomSheet`, it
  does not push a route).
- Every other screen (S-01/02/03 onboarding, S-06 search, S-07/08/09/10 browse, S-11..20
  play surface, S-21..26 results, S-36/37 shop, S-38..41 duel, S-42/44 settings, S-45..54
  system/overlay screens where they're full routes rather than dialogs) as top-level
  routes **outside** the shell (`parentNavigatorKey` pointing at the root navigator), so
  they cover the tab bar per the bible's "play surface hides the tab bar" rule.
- All paths as `AppRoutes.sXX` constants (`core/router/app_routes.dart`), e.g.
  `AppRoutes.home = '/home'`, `AppRoutes.levelMap = '/category/:categoryId/subcategory/
  :subcategoryId/levels'`, `AppRoutes.quizPlay = '/play/:levelId'`. Exact param shape is
  finalized per-screen in plans 002–004, but the constant names for all 54 screens are
  reserved here so later plans never touch this file's *shape*, only fill in a builder.

### Mock-data convention (the pattern 002–004 must copy)

```dart
// features/<feature>/data/<feature>_api.dart
class HomeApi {
  Future<HomeDto> fetchHome() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return HomeDto(...); // canned data, or built from core/models fixtures
  }
}

// features/<feature>/data/<feature>_repository.dart
class HomeRepository {
  HomeRepository(this._api);
  final HomeApi _api;

  Future<HomeContent> fetchHome() async {
    final dto = await _api.fetchHome();
    return HomeContent(...); // DTO -> domain model, same as a real repository
  }
}

// features/<feature>/presentation/bloc/home_cubit.dart
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository) : super(const HomeState.initial());
  final HomeRepository _repository;

  Future<void> load() async {
    emit(const HomeState.loading());
    try {
      final content = await _repository.fetchHome();
      emit(HomeState.loaded(content));
    } catch (e) {
      emit(HomeState.error(e.toString()));
    }
  }
}
```
Every feature's mock `*_api.dart` throws a simulated failure sometimes (e.g. a debug flag
or a fixed 1-in-N chance) purely so the required `bloc_test` failure-path test (CLAUDE.md
§11) has something real to assert against, and so the `ErrorStateView` this plan builds
gets exercised somewhere real rather than only in a widget test's hand-built state.

## Implementation steps

- [ ] **Dependencies.** Add to `pubspec.yaml` (dev + regular as appropriate): `flutter_bloc`,
  `equatable`, `go_router`, `flutter_screenutil`, `freezed_annotation` + `freezed` +
  `build_runner` + `json_annotation`/`json_serializable` (for DTOs), `flutter_animate`,
  `intl` + `flutter_localizations` (SDK) for `gen-l10n`, and dev-only `bloc_test`,
  `mocktail`. Do **not** add `dio`, `supabase_flutter`, `firebase_*`, `rive`, `confetti`,
  `google_mobile_ads`, `in_app_purchase` yet — those are named in the bible's §25 package
  shortlist for the real-backend phase, out of scope here (Assumption 2). Enable `generate:
  true` under `flutter:` in `pubspec.yaml` for `gen-l10n`, add an `l10n.yaml` at the repo
  root pointing at `lib/l10n/`.
- [ ] **Fonts.** Download/obtain Baloo 2, Plus Jakarta Sans, JetBrains Mono, Noto Nastaliq
  Urdu (all on Google Fonts, OFL-licensed) as static `.ttf`/`.otf` files under
  `assets/fonts/`, register each family + its weights in `pubspec.yaml`'s `fonts:` section.
- [ ] **Theme tokens** — build `core/theme/*` exactly as listed in Design overview, using
  the hex values transcribed in Research findings verbatim for both light and dark. Verify
  contrast pairs match the bible's own stated ratios (tx on s1: 15.6:1 light / 15.1:1 dark;
  tx2: 5.4:1 / 6.1:1) as a sanity check, not a new requirement.
- [ ] **`AppSpacing`/`AppRadius`/`AppMotion`/`Breakpoints`** per Design overview.
- [ ] **`app/theme_cubit.dart`** — sealed state or simple `Cubit<ThemeMode>`? Per CLAUDE.md
  §3 every Cubit state must be a sealed class — model as `sealed class ThemeState` with
  `ThemeLight`/`ThemeDark`/`ThemeSystem` subclasses (not Flutter's raw `ThemeMode` enum
  directly as the emitted state, to satisfy the sealed-class rule), plus a thin mapper to
  Flutter's `ThemeMode` at the point `MaterialApp.router` consumes it. Persist the choice
  with `shared_preferences`? — **not added in this phase**; it resets on app restart, which
  is acceptable for a design review build (note this as a known limitation, not a bug, in
  the PR description when this plan is executed).
- [ ] **`core/models/*`** — build the five shared freezed models per Design overview, with
  `fromJson`/`toJson` (even though nothing calls a real API yet, DTOs will still parse
  fixture JSON payloads through the same freezed models in some features — keep the
  pattern consistent).
- [ ] **`core/widgets/*`** — build each widget per the exact spec in Research findings
  (dimensions, radii, the 4px hard-shadow ledge behavior, the 5 answer-option states, the
  4-intent snackbar, etc.). Each widget gets a small widget test asserting it renders in
  both light and dark `ThemeData` without throwing (full interaction/golden testing is out
  of scope for this foundation pass; deeper per-screen widget tests land in 002–004 per
  CLAUDE.md §11's "non-trivial conditional rendering" bar).
- [ ] **`core/router/app_routes.dart`** — reserve all 54 `AppRoutes.sXX` constants now
  (see the full ID list in Research findings), plus the 5 tab-branch constants
  (`AppRoutes.home`, `.ranks`, `.daily`, `.you`) and any nested dynamic-segment routes
  plans 002–004 will need (level map, quiz play, category detail, etc.) — exact path
  templates can be refined by the plan that first implements that screen, but the constant
  *name* must not change afterward.
- [ ] **`app/router.dart`** — build the `GoRouter` + `ShellRoute`/`StatefulShellRoute`
  skeleton, with every route pointing at a trivial placeholder `Scaffold` (screen ID + name
  + "see plan 00X" text) except the 5 shell tabs, which render minimal real placeholder
  bodies too (so the app is genuinely navigable end-to-end from tab to tab and into at
  least one pushed route, proving the shell + routing works before any real screen exists).
- [ ] **`features/shell/`** — build `AppShellScreen`, `AppTabBar` (5 tabs + centre FAB per
  the exact spec: FAB rotates 45° into a close icon when `PlayLauncherSheet` is open), and
  `PlayLauncherSheet` (S-38) as a real, finished screen (it's simple enough — 4 static rows
  — to finish now rather than defer to plan 004, and doing so proves the FAB/sheet
  interaction end-to-end immediately).
- [ ] **`l10n/app_en.arb` + `app_ur.arb`** — seed with the handful of strings needed to
  reproduce S-04/S-05 Home and S-11 Question in Urdu (per Assumption 5), wire
  `flutter_localizations` + `AppLocalizations.delegate` into `MaterialApp.router`, verify
  `Directionality` flips correctly for `ur` (RTL) vs `en` (LTR) by toggling the device
  locale or a debug-only locale switch in the placeholder Settings screen.
- [ ] **`main.dart`** — replace the counter-app boilerplate with `runApp(const
  QuizooApp())`; `app/app.dart` wraps `ScreenUtilInit(designSize: Size(390, 844), builder:
  ... MaterialApp.router(...))` with `BlocProvider<ThemeCubit>` at the root (the one
  legitimately global provider per CLAUDE.md §3).
- [ ] **Remove** `test/widget_test.dart`'s counter-app test (it will fail immediately once
  `main.dart` changes) and replace with a minimal smoke test that pumps `QuizooApp` and
  asserts the Home tab renders.

## Data model / API changes

N/A — no real API in this phase. The five `core/models/` domain models above are the only
"data model" surface, and they exist purely to be populated by each feature's mock
`*_api.dart`/`*_repository.dart` per the convention in Design overview.

## Dependencies

| Package | Why |
|---|---|
| `flutter_bloc`, `equatable` | state management, mandated by CLAUDE.md §3 |
| `go_router` | routing, mandated by CLAUDE.md §4 |
| `flutter_screenutil` | sizing, mandated by CLAUDE.md §6 |
| `freezed` + `freezed_annotation` + `build_runner` | immutable domain models/DTOs |
| `json_annotation` + `json_serializable` | DTO (de)serialization |
| `flutter_animate` | the `pop`/`slide`/`count` motion tokens without hand-rolling every `AnimationController` |
| `intl`, `flutter_localizations` (SDK) | `gen-l10n`, RTL |
| `bloc_test` (dev) | required per-Cubit tests, CLAUDE.md §11 |
| `mocktail` (dev) | repository tests, CLAUDE.md §11 |

## Testing strategy

- Every `core/widgets/*` widget: one widget test per widget rendering under both light and
  dark `ThemeData` (smoke-level — asserts no exception, key sub-elements present).
- `ThemeCubit`: `bloc_test` covering initial state, `setLight`/`setDark`/`setSystem`
  transitions (no real failure path exists for a pure local toggle — note `N/A` for the
  failure-path requirement here with a one-line justification in the test file, since
  CLAUDE.md's rule presumes a repository call that can fail and this Cubit has none).
  This is the intentional single exception to "every Cubit needs a failure-path test" in
  this whole plan series, and it is *because* there is no repository/IO involved, not
  because testing is being skipped.
- `app/router.dart`: one test that pumps `QuizooApp`, navigates to 2–3 representative
  routes (a shell tab, a pushed placeholder route) and asserts the expected screen renders
  — a smoke test for the routing skeleton, not exhaustive per-route coverage (that
  happens naturally as 002–004 add real screens and their own tests).
- `PlayLauncherSheet`: widget test with one case per row tapped, asserting the expected
  `go_router` navigation call (via a mocked/observed `GoRouter`).

## Edge cases & error handling

- Locale toggled to Urdu mid-session: verify no layout overflow on Home's title/wallet row
  (Nastaliq needs taller line-height — this is exactly why the RTL proof-of-concept exists
  now rather than being bolted on in plan 004).
- Dark mode + Arena colors: confirm the play-surface placeholder screen does NOT read
  `Theme.of(context).brightness` for its background — regression-test this explicitly,
  since it's the one deliberate exception to "colors come from theme" and it's easy to get
  backwards.
- Reduced-motion (`MediaQuery.disableAnimations`): every `AppMotion` duration/curve helper
  should have a reduced-motion short-circuit path exercised by at least one widget test.

## Acceptance criteria

- [ ] Every color, radius, shadow, spacing and type value implemented in
  `core/theme/*` has been checked side-by-side against `.claude/docs/quizoo-design-bible.
  html` rendered in a browser (both its light/dark toggle and its app-theme toggle) — not
  just against this plan's transcription — since the user has asked for exact pixel
  parity with that document.
- [ ] App builds and runs (`flutter run`) showing the 5-tab shell with a working centre FAB
  that opens `PlayLauncherSheet`.
- [ ] All 54 `AppRoutes.sXX` constants exist in `core/router/app_routes.dart` and are wired
  to a route in `app/router.dart`, each reachable by direct navigation (deep-link or a
  temporary debug list) even before their real bodies exist.
- [ ] `flutter analyze` passes with zero warnings; `dart format` has been run on every new
  file.
- [ ] Toggling `ThemeCubit` between light/dark/system visibly re-themes the whole shell,
  including every `core/widgets/*` component, with no hardcoded colors anywhere in
  `features/shell/` or `core/widgets/`.
- [ ] Switching the device/debug locale to Urdu flips Home and Question (S-11) into RTL
  with Nastaliq type and no overflow.
- [ ] Every `core/widgets/*` widget has a passing widget test; `ThemeCubit` has a passing
  `bloc_test` suite; the router skeleton has a passing smoke test.
- [ ] Plans 002, 003 and 004 can each be hand-read and executed by a fresh session using
  only this plan's folder layout, token names, and route constants — no additional
  guessing required.

## Risks & rollout notes

- **Font licensing/bundling weight**: 4 font families × several weights adds meaningful app
  size. Acceptable for a design-review build; revisit variable-font versions (fewer files
  per family) when this moves past the mock-data phase.
- **Reserving all 54 routes upfront** is deliberate scope-spreading *of routing only* (not
  of screen bodies) so 002/003/004 can proceed in parallel or any order without merge
  conflicts in `app/router.dart`. If the user would rather each plan add its own routes as
  it goes (smaller, more isolated diffs per plan, at the cost of the three later plans
  needing to touch the shared router file each), that's a reasonable alternative — flagged
  here as a judgment call, not a re-litigated decision.
- No migration/rollback concerns — this is a greenfield app with no production data.
