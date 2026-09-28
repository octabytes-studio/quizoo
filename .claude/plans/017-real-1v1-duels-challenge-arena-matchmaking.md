# Real 1v1 Duels — Challenge Arena, Matchmaking & Live Play

> Source spec: provided inline in conversation ("1v1 Duel - Full integration" —
> remove the centre-FAB bottom sheet, open a realtime Challenge screen instead,
> challenge cards + 5-second join prompt, 5-minute challenge lifetime, 2-minute
> creation cool-off, backend anti-spam, sub-category picker, auto-matchmaking by
> closest skill with a bot after 30 s, all matchmaking/challenge logic in the
> backend). Clarifying answers from the product owner are recorded under
> "Assumptions & open questions → Decisions already made".
> Status: Implemented 2026-09-28 (Flutter complete, tests green). Migrations
> 20260927120000–120600 dry-run verified and applied to the live project.

## How to use this plan

This plan is self-contained: executing it needs no prior conversation history.
Read it in full first. Code may have moved on since it was written (27 Sep 2026),
so spot-check the referenced files still match before you begin — Phase 0 lists
the exact checks.

The work is large, so it is split into **12 phases** that are meant to be
executed and reviewed in order. Phases 1–6 are backend only (SQL migrations,
applied to the live Supabase project the same way plans 007/008/016 were).
Phases 7–12 are Flutter. Every phase ends in a state where `dart analyze` is
clean and the existing test suite passes, so the work can pause between phases.

Hard project rules that bind every phase (from `CLAUDE.md`): Cubit/Bloc state is
a `sealed class` switched exhaustively; no `setState` for business data; no
hardcoded colors/text styles/spacing/route strings; `flutter_screenutil` for all
sizes; relative imports inside the feature, package imports across features;
every new Cubit/Bloc gets a `bloc_test` file; **never run the app** — static
verification only (`dart analyze`, `dart format`, `flutter test`), and finish
with a "To verify:" list for the developer.

## Objective

Replace today's bot-only "duel" (a client-side simulation that never meets a
real person) with real player-vs-player duels. The centre tab-bar button opens a
full-screen **Duel Arena**: a live, chat-style feed of challenges other players
are posting, a **Quick match** option that auto-pairs you with a similarly
skilled player in a chosen topic (a labelled bot after 30 s if nobody is found),
and a composer to post your own challenge. When someone taps your challenge you
get a 5-second Accept/Decline prompt; on accept, both players drop into a
synchronised, server-refereed best-of-5 duel. **All of this is run by the
backend**: matchmaking, the challenge lifecycle (creation limits, expiry,
deletion), join-request queuing, round timing and scoring, ELO, payouts, and
disconnect handling. Supabase Postgres RPCs, `pg_cron` and Realtime Broadcast do
the work, and no Edge Functions are needed.

## Scope

**In scope:**
- Remove the centre-FAB `PlayLauncherSheet` (and its Quick Play / Daily
  entries). The FAB pushes the new Duel Arena screen instead.
- **Duel Arena screen** (new): chat-style challenge feed (newest at the bottom),
  a Quick match hero card at the top, a sticky composer to create a challenge
  (with cool-off countdown), the creator's incoming-request banner, a "● N in the
  arena" presence pill and a rejoin banner for an interrupted duel.
- **Topic picker bottom sheet** (new): picking a sub-category is required for
  both creating a challenge and matchmaking. It only lists topics with enough live
  questions in the player's content language, with live "N searching / N open"
  activity counts.
- **Challenges backend**: create (1 open per user, 2-min cool-off, daily cap,
  guests cannot create), cancel, 5-minute TTL, presence-based "Away" pause,
  join requests with a **one-at-a-time queue** and 5-second decision window,
  per-user rate limits, automatic deletion of expired, cancelled and completed
  challenges, and Realtime broadcast of every change.
- **Matchmaking backend**: queue per (sub-category, language), pairing on
  ELO with a widening band plus topic level as a secondary weight, heartbeat-based
  liveness, and a bot offer at 30 s.
- **Live duel backend**: server-created duels, per-round question delivery
  (never early), server-authoritative timing (latency-tolerant, cheat-bounded),
  withheld correctness until both answer, round and duel resolution, ELO (K=32),
  payouts, a ranked **anti-farming cap** (same pair: ELO counts for the first 3
  duels per 24 h), disconnect forfeit after 30 s, explicit quit, and rematch.
- Flutter data/domain/presentation for all of the above in `features/duel/`,
  including a rewrite of `MatchmakingCubit` and a new `LiveDuelBloc`. The
  existing bot duel is kept, but its questions now come from the chosen topic
  and its screen shares the round view with live duels.
- Real player identity in duel screens (replacing `MockPlayer.avatarEmoji` and
  the hardcoded `1240` ELO).
- Fixing the two latent backend defects found while researching (draw payouts,
  Duelist badge counting bot wins only) — see Research findings.
- Tests: `bloc_test` for every new/rewritten Cubit/Bloc, repository tests with
  `mocktail`, widget tests per sealed-state branch of the new screens, and a
  SQL smoke-test script run through the Supabase MCP inside rolled-back
  transactions.

**Out of scope:**
- Push notifications (FCM) for join requests while the app is backgrounded. The
  "pause while away" design makes this unnecessary for v1, and FCM isn't wired
  anywhere yet (`fcm_tokens` has 0 rows).
- Direct friend-to-friend challenges (S-31/S-44's "Challenge a friend" and the
  `app_notifications.kind = 'duelChallenge'` path). The notifications screen's
  fake "accept duel" shortcut is re-pointed to the arena (Phase 12) and nothing
  more.
- Coin wagers, spectating, duel-specific leaderboards, seasons.
- Server-graded level play and hiding `questions.correct_index` from clients
  (see Assumption A9 — a separate hardening plan).
- A real "Quick Play" feature (the removed sheet's Quick Play pointed at a
  placeholder `demo` level).
- Content authoring. Only English has enough questions today (see Research
  findings); non-English players see an honest empty picker.

## Research findings

### Governance that applies (`CLAUDE.md`)
- §1–3: Presentation → Repository → API; sealed states with an exhaustive `switch`,
  no default branch; Cubit by default, and a **Bloc with a sealed Event class when
  one state machine has several trigger sources**. The arena (realtime lobby
  events + inbox events + user taps + a clock) and the live duel (server events +
  answer taps + a clock + presence) both qualify, so they are Blocs. Matchmaking
  stays a Cubit.
- §3: navigation, snackbars and dialogs go in `BlocListener`, never in a
  `BlocBuilder`. `BlocProvider` sits directly above the screen.
- §4: routes only in `app/router.dart`, paths as constants in
  `lib/core/router/app_routes.dart` (`AppRoutes`), no raw path strings.
- §5/§6: colors from `context.quizoo` / `context.arena` / `AppColors`, text from
  `Theme.of(context).textTheme` / `AppTypography`, spacing from `AppSpacing`, and
  all sizes via `.w/.h/.r/.sp`. New tokens are added to `core/theme`.
- §9: one shared client. Plan 005 reinterpreted "Dio `ApiClient`" as the
  singleton `supabase` getter in `lib/core/network/supabase_client.dart`. All
  errors go through `ApiException.fromSupabase`, and repositories are the only
  place JSON becomes domain models.
- §10: new work shouldn't modify other features' files, and `app/router.dart` /
  `core/theme` are add-only. **This spec forces two exceptions**, flagged in
  Assumptions: removing the play-launcher route and re-pointing
  `features/settings/.../notifications_screen.dart`.
- §11: `bloc_test` (initial, success, failure) for each Cubit/Bloc; `mocktail`
  repository tests; one widget test per sealed-state branch.
- §13: never run the app.

### Current FAB / shell (to be changed)
- `lib/features/shell/presentation/screens/app_shell_screen.dart`:
  `_openPlaySheet()` calls `PlayLauncherSheet.show(context)` and tracks
  `_isPlaySheetOpen` with `setState`.
- `lib/features/shell/presentation/widgets/app_tab_bar.dart`: `_PlayFab` takes
  `isOpen`, rotates 45° into `✕`, and uses `l10n.playSheetClose` / `l10n.tabPlay`.
  The `⚔️` glyph is already the FAB's resting icon.
- `lib/features/shell/presentation/widgets/play_launcher_sheet.dart`: three rows:
  Duel → `AppRoutes.duelMatchmaking`, Quick Play → `quizPlayPath('demo')`
  (placeholder), Daily → `AppRoutes.daily` (already a shell tab).
- `lib/app/router.dart` ~L276-282: `GoRoute(path: AppRoutes.playLauncher, …
  _sheetPage(state, const PlayLauncherSheet()))`. `_sheetPage` is also used by
  3 other routes, so keep it.
- `lib/core/router/app_routes.dart`: `playLauncher = '/play-launcher'`,
  `duelMatchmaking = '/duel/matchmaking'`, `duelPlay = '/duel/:duelId'`,
  `duelResult = '/duel/:duelId/result'`, `s38 = playLauncher`, and the
  `kScreenIndex` S-38 entry.
- Test: `test/features/shell/play_launcher_sheet_test.dart`.
- l10n keys used only by the sheet/FAB: `playSheetTitle, playSheetSubtitle,
  playSheetDuel, playSheetDuelMeta, playSheetQuickPlay, playSheetQuickPlayMeta,
  playSheetDaily, playSheetDailyMeta, playSheetGo, playSheetClose,
  playSheetFriend, playSheetFriendMeta` (the last two are already unused).

### Current duel feature (bot-only)
Files under `lib/features/duel/` (read in full):
- `data/duel_api.dart`: `fetchBotOpponent({playerElo})` (6-name roster, ±120
  ELO), `fetchRoundQuestions({languageCode})` (**hardcoded to the `football`
  slug**, direct `from('questions')` select incl. `correct_index`),
  `submitBotDuel(...)` → RPC `submit_bot_duel`. `BotDuelRecord` is defined in the
  same file.
- `data/duel_repository.dart`: pass-through of the three methods.
- `domain/duel_opponent.dart`: `DuelOpponent{id,name,avatarEmoji,elo,isBot=true}`
  + `DuelEloBand` enum + `DuelBotTiming` extension (bot answer time/accuracy).
- `domain/duel_round.dart`: `RoundOutcome{playerWon,opponentWon,draw}` +
  `DuelRoundRecord`. `domain/duel_result.dart`: `DuelResult` (opponent, rounds,
  avg seconds, eloBefore/After, rewardCoins, newlyEarnedBadgeIds).
- `presentation/bloc/matchmaking_cubit.dart`: 1 s ticker; auto-bot at **20 s**;
  `playBotInstead()` from frame one; **no path ever finds a human**.
- `presentation/bloc/duel_play_cubit.dart`: full local simulation, 15 s rounds,
  1.8 s reveal, **withheld-correctness rule** (opponent's choice held privately
  until both answered), `_finish()` calls `submit_bot_duel`, `_playerBaseElo =
  1200` fallback.
- Screens: `matchmaking_screen.dart` (`arena.base` gradient, `VsHeader`, ELO
  constant `1240`, `MockPlayer.avatarEmoji`), `duel_play_screen.dart`
  (`arena.lite` gradient, `_RoundView`, imports `quiz_play`'s `TimerRing`, defines
  `DuelPlayArgs{opponent}`), `duel_result_screen.dart` (Rematch and Find-new both
  `pushReplacement(AppRoutes.duelMatchmaking)`, ✕ → `context.go(home)`,
  `celebrateBadges`).
- Widgets: `vs_header.dart` (null right avatar → shimmering searching side),
  `duel_status_chip.dart`.
- `DuelOpponent` is also imported by
  `lib/features/settings/presentation/screens/notifications_screen.dart` L15-57,
  which fakes a friend opponent and pushes `duelPlayPath` with `DuelPlayArgs`.
  That's a cross-feature dependency on duel internals.
- Tests: `test/features/duel/{duel_play_cubit,duel_repository,matchmaking_cubit}_test.dart`
  (mocktail + `fake_async`).

### Backend (live project, inspected via Supabase MCP on 27 Sep 2026)
- **No Edge Functions deployed.** `pg_cron` 1.6.4 is installed, with jobs `refresh-lb-weekly`
  (`*/2 * * * *`), `daily-rollover` (`0 0 * * *`) and `refresh-featured-quizzes`
  (hourly). pg_cron ≥1.5 supports `'10 seconds'` schedules.
- **Realtime**: the `supabase_realtime` publication has **no tables**;
  `realtime.send(payload jsonb, event text, topic text, private boolean)` and
  `realtime.broadcast_changes(...)` exist; **no RLS policies on
  `realtime.messages`** yet. The app has **zero** Realtime usage today.
- `public.duels` (1 row, a completed bot duel): `id, p1, p2, is_bot,
  question_ids uuid[], p1_answers/p2_answers jsonb, p1_rounds, p2_rounds, winner,
  status ('active','complete','forfeit'), p1/p2_elo_before/after, created_at,
  expires_at (+24h)`. RLS: `duels_select_participant` (select where
  `auth.uid() in (p1,p2)`), `duels_update_participant_active` (clients may
  update their own answers array while active, guarded by trigger
  `guard_duel_answer_update`). **That update policy lets a participant append
  answers directly with a forged `answeredAtMs`, and the select policy lets
  them read the opponent's `p*_answers` mid-round.** Both must go away for
  real play.
- `public.matchmaking_queue` (0 rows): `user_id pk, elo, queued_at`. RLS
  lets clients insert/delete/select their own row.
- Functions in `20260907120200_functions_and_triggers.sql` (+ fix in
  `20260910090500_language_scope_daily_and_duels.sql`): `submit_duel_answer`,
  `resolve_duel_round`, `resolve_duel` (built for §24 but **never called by the
  app**), and `submit_bot_duel` (the only duel RPC in use). Defects found:
  1. `resolve_duel` pays **nothing on a draw**, even though its comment says
     "both get the loser's consolation".
  2. `submit_bot_duel`'s `badge_duelist` check counts only
     `p1 = user and is_bot and winner = user` (bot wins), and hardcodes `10` even
     though `achievements.criteria = {"type":"duel_wins","count":10}`.
  3. None of these functions revoke `EXECUTE` from `anon/authenticated`, so
     `resolve_duel` / `resolve_duel_round` are directly callable by any client.
- `public.app_settings(key text pk, value jsonb, description, updated_at)`,
  publicly readable (`app_settings_select_all`), currently holding
  `boss_level_interval` and `questions_per_level`. This is the project's "tunable
  live, no redeploy" pattern.
- `profiles`: `username` (null for guests), `avatar_key` (emoji), `is_guest`,
  `elo` (default 1200), `league`, `player_level`, `xp`, `coins`. Live data: 43
  profiles (17 guests), ELO 985–1790, avg player level 5.
- `level_progress(user_id, subcategory_id, level, completed_at, …)` is
  publicly readable, and a topic's "level" = count of completed levels.
- `achievements`: `badge_duelist` (`duel_wins`, count 10, 1000 coins).
- **Content depth** (live questions per sub-category, by `categories.language_code`):
  `en` 26 sub-categories, **18 with ≥5 live questions** (16 with ≥25), 924 live
  questions; `ur` 1 sub-category with content (51 questions); `hi/ar/fr/es` 0.
  Duel topics must be filtered by content, or players will pick empty topics.
- `questions_select_live` RLS exposes every live question **including
  `correct_index`** to any client. Only `duel_api.dart` reads `questions`
  directly; everything else goes through RPCs.

### Client stack facts
- `supabase_flutter 2.17.2`, `realtime_client 2.13.0`:
  `supabase.channel(topic, opts: const RealtimeChannelConfig(private: true, key: …))`,
  `.onBroadcast(event: 'name', callback: (payload) {...})` (register one per event
  name; don't rely on wildcards), `.onPresenceSync(...)`,
  `.presenceState()`, `.track({...})`, `.subscribe((status, error) {...})`,
  `supabase.removeChannel(channel)`. supabase_flutter pushes refreshed access
  tokens to Realtime automatically (private channels need the user JWT).
- `ApiException.fromSupabase` (`lib/core/network/api_exception.dart`) maps a
  plain `raise exception '<identifier>'` (SQLSTATE P0001) to
  `ApiException.code == '<identifier>'`. All new RPC errors below use this
  convention (see memory note on the P0001 bug: always branch on `.code`).
- `lib/core/router/app_route_observer.dart` (`appRouteObserver`, used with
  `RouteAware` by `level_map_screen.dart`) is how a screen learns it was covered
  (`didPushNext`) or uncovered (`didPopNext`). Modal bottom sheets are not
  `PageRoute`s, so opening the topic picker does **not** fire `didPushNext`.
- Shared UI building blocks to reuse: `AppBottomSheet.show`
  (`core/widgets/app_bottom_sheet.dart`), `AppSnackbar.show` + `SnackbarIntent`,
  `AppDialog`, `ChunkyButton` (`.secondary/.success/.gold/.danger/.ghost/.line`),
  `SkeletonBox`, `EmptyStateView`, `ErrorStateView`, `ArenaColors` (`base`, `lite`,
  `danger`, `onArena`, `chrome`, `questionCard`, `optionRest`,
  `optionRestShadow`, `metaText`), `QuizooColors` (`p` mango, `g` grape, `gold`,
  `ok`, `bad`, `info`, …), `AppSpacing` (`xs 4, sm 8, md 12, base 16, lg 20,
  xl 24, xxl 32, screenMargin`), `AppRadius` (`card 20`, `pill`, `sheet 28`, …),
  `AppMotion` (`pop`, `slide`, `sheet`, `count`, `tick`, `shimmer`,
  `durationOf/curveOf` honour reduced motion), `flutter_animate`.
- `SessionCubit`, `ContentLanguageCubit` (`.state.code`) and `ConnectivityCubit`
  (a **debug toggle only**, not real connectivity) are app-root.
  `AppRoutes.saveProgress` (S-24) is the sign-in sheet route.
- Test conventions: flat `test/features/duel/*.dart`; `mocktail` mocks of the
  *API* for repository tests and of the *repository* for Cubit tests; `bloc_test`;
  `fake_async` for timers; widget tests via `test/support/pump_screen.dart`'s
  `tester.pumpScreen(...)`. Known gotchas (memory): `pumpAndSettle()` runs
  periodic-timer Cubits to completion, so use a bounded `pump()` for screens
  with live tickers, and collect all emitted states for timing invariants.
- l10n: `lib/l10n/app_en.arb` is the template, `app_ur.arb` is a partial subset,
  and untranslated keys are tracked in `lib/l10n/untranslated_messages.json` by
  `flutter gen-l10n`.

### Design references
- `.claude/docs/quizoo-design-bible.html` §15 (S-38…S-41) and §24 "Duel
  architecture" (queue → deal → play → reveal → resolve, withheld correctness,
  K=32 ELO, winner +200🪙 +250 XP / loser +40🪙 +80 XP, 30 s presence-gap
  forfeit, >3 disconnects/24 h suppress ELO gain, "never a secret bot").
  §21 (Supabase choice) notes Realtime Broadcast + Presence as the duel transport,
  with an Edge Function only if a secret is needed. None is needed here.

## Assumptions & open questions

### Decisions already made (product owner, this planning session)
1. **Join requests queue, one at a time.** Requests to a challenge are queued
   server-side; the creator sees one at a time with a 5 s countdown. Unanswered
   means auto-decline, and the next in line is presented.
2. **Creator away ⇒ challenge paused.** While the creator isn't on the arena
   screen, their card shows "Away" and can't be requested; the 5-minute clock
   keeps running.
3. **Skill metric = ELO first, topic level as a secondary weight** (widening ELO
   band per bible §24).
4. **Guests** may matchmake and request to join challenges (shown as
   "Guest 4821"), but **creating a challenge requires a signed-in account**.
5. **Full-screen arena** pushed over the shell (tab bar hidden, ✕ to close),
   on the grape `arena.lite` gradient.
6. **Feed is chat-style: newest at the bottom**, auto-scrolling when the
   viewer is at the bottom, with a "↓ N new challenges" pill when scrolled up.
7. **Ranked with an anti-farming cap**: both challenge and matchmade duels
   are ranked, but a given pair of players only moves ELO for their first 3
   ranked duels per rolling 24 h. After that, coins/XP only.
8. **Drop Quick Play and Daily** from the FAB. Daily stays a tab, and the sheet,
   its route, its test and its strings are deleted.

### Assumptions made by this plan (review these)
- **A1. One open challenge per user at a time**, plus the 2-minute cool-off
  measured from the previous creation. With a 5-minute TTL, a cool-off alone
  would allow three simultaneous open challenges, which contradicts "play one
  challenge at a time". Cancelling does not reset the cool-off, which is what
  makes it anti-spam.
- **A2. Questions are delivered one round at a time, never all five up front**
  (a deliberate deviation from bible §15's "all five questions up front"). Each
  round's prompt is fetched by the client at the round's server start time
  (`get_duel_round` refuses to return it earlier), so a modified client can't read
  ahead. The bible's concern (network latency deciding duels) is still met by
  the latency-tolerant timing in A3.
- **A3. Timing rule.** Each client times its own answer from the moment the
  question is displayed (`client_ms`). The server bounds it:
  `effective_ms = clamp(greatest(client_ms, server_elapsed_ms − 1500), 250,
  round_ms)` where `server_elapsed_ms` is measured from the round's `starts_at`.
  An honest player on a slow network loses at most nothing up to 1.5 s of
  latency. A cheater can shave at most 1.5 s. Both-correct → lower
  `effective_ms` wins the round; exactly equal → draw.
- **A4. Reconnect does not reset the round clock** (deviation from bible §24's
  "clock reset for that round only"). A player who reconnects mid-round resumes
  against the real server deadline. Resetting one player's clock would give them
  extra thinking time on a question they've already seen.
- **A5. Round length stays 15 s** (the current `DuelPlayCubit` value), not the
  bible's 10 s. All timings live in a tunable `app_settings.duel_config` row, so
  this is a config change later.
- **A6. Draws pay both players the loser consolation** (+40 🪙 +80 XP). This
  matches the existing `resolve_duel` comment's intent and fixes its bug.
- **A7. Duel results don't write `score_events`** (parity with today's
  `submit_bot_duel`), so duels don't affect the points leaderboards. **Open
  question:** should duel wins feed leaderboards / leagues? (It's a one-line
  insert in `_duel_finish` if yes.)
- **A8. Bot duels stay client-simulated** (existing `DuelPlayCubit` +
  `submit_bot_duel`, half-K ELO), now with questions from the chosen topic.
  They're always labelled BOT ("never a secret bot").
- **A9. Answer-bank lookups are not solved here.** `questions_select_live`
  exposes `correct_index`, and level play grades client-side from
  `start_level_attempt`'s response, so a determined player can still build an
  answer bank per topic. This plan prevents *opponent-reveal* leaks and
  *read-ahead*, which are the duel-specific cheats. Hiding `correct_index`
  app-wide needs server-graded level play (separate plan). Flagged, not in
  scope.
- **A10. Heartbeats instead of Realtime Presence for server decisions.**
  Postgres can't see Realtime Presence, so server-side "is this person still
  here" uses cheap throttled heartbeat RPCs: arena creator/requester every 10 s,
  matchmaking every 3 s (the same call also retries pairing with the widened
  band), duel every 5 s. Presence is used only for UI niceties (arena head
  count, "opponent reconnecting" chip) and can be switched off via config.
- **A11. Arena feed is capped at the 50 newest** open/in-progress challenges per
  language. At current scale (43 players) that's everything. At large scale it
  bounds payload size and render cost.
- **A12. Unanswered-request "retry" cool-down**: after a decline or expiry, the
  same requester can't re-request the same challenge for 15 s (shown as a
  countdown on the card).
- **A13. `pg_cron` sweeper every 10 s** is the backstop for everything
  time-based (request expiry, challenge expiry/deletion, stale creators,
  stale queue rows, round deadlines when both clients vanish, 30 s disconnect
  forfeits, no-show duels). The happy path never waits on it: clients call
  explicit RPCs at their own deadlines, and the sweeper only catches what's
  left over.
- **A14. The live duel keeps the arena under it in the navigation stack**, so
  closing the result screen returns to the arena (`context.pop()`, falling back to
  `context.go(AppRoutes.home)` when there's nothing to pop).

### Conflicts with governance / design bible (flagged, not silently resolved)
- **CLAUDE.md §10** (router is add-only; don't touch other features): the spec
  requires *removing* the `playLauncher` route and the shell's sheet. Changing
  `DuelOpponent` → `DuelPlayer` and live-routing `duelPlayPath` also breaks
  `features/settings/.../notifications_screen.dart`'s fake-duel shortcut, which
  must be edited (Phase 12) to push `AppRoutes.duelArena` instead. That also
  removes an existing cross-feature import of duel internals.
- **Bible S-38** (four-way play sheet) is replaced by the arena per spec.
  **S-39** (bot after 20 s) becomes 30 s per spec.
- **Bible §15/§24** deviations: A2, A4, A5 above.

### Open questions (safe defaults chosen, confirm before/while executing)
- Q1. Should duel wins write `score_events` (leaderboards/leagues)? Default: no (A7).
- Q2. Daily challenge-creation cap: default **60/day**. Join requests: **max 3
  outstanding**, **20 per 5 minutes**. Matchmaking joins: **20 per 10 minutes**.
  Tune in `duel_config`.
- Q3. Before applying migrations to the live project, do you want them tried
  on a Supabase development branch first (`mcp__supabase__create_branch` has a
  cost)? Plans 007/008/016 were applied straight to live. Default: same as
  before, after the developer approves the SQL.

## Design overview

### Architecture at a glance

```
Flutter (features/duel)                         Supabase
────────────────────────                        ─────────────────────────────────────
DuelArenaScreen ─ DuelArenaBloc ─┐              RPCs (security definer, RLS-bypassing,
DuelTopicPickerSheet ─ Cubit ────┤               all rules enforced inside):
                                 ├─ DuelArenaRepository ─ DuelArenaApi ─┐  get_duel_lobby, list_duel_topics,
MatchmakingScreen ─ MatchmakingCubit ─ MatchmakingRepository ─ Api ─────┤  create/cancel_duel_challenge,
LiveDuelScreen ─ LiveDuelBloc ─ LiveDuelRepository ─ LiveDuelApi ───────┤  set_duel_lobby_presence,
DuelResultScreen ─ DuelRematchCubit ────────────┘                       │  request/withdraw/respond_duel_join,
DuelPlayScreen (bot) ─ DuelPlayCubit ─ DuelRepository ─ DuelApi ────────┤  join/leave_matchmaking, matchmaking_heartbeat,
                                                                        │  get_duel_state, mark_duel_ready, get_duel_round,
            DuelRealtime (one channel per topic, ref-counted) ──────────┤  submit_duel_answer, claim_duel_round_timeout,
            ServerClock (offset from serverNow)                         │  duel_heartbeat, leave_duel, request/decline_duel_rematch,
                                                                        │  submit_bot_duel
                                                                        │
            Realtime Broadcast (private channels, RLS on realtime.messages)
              duel-lobby:<lang>   challenge_upsert / challenge_remove  (+ presence for head count)
              duel-user:<uid>     join_request / join_request_cleared / join_request_status / duel_start
              duel:<duelId>       round_start / answer_locked / round_result / duel_end / rematch
                                                                        │
            pg_cron 'duel-sweeper' every 10 s → _duel_sweeper()        ─┘
```

- **Clients never publish broadcasts.** RLS on `realtime.messages` only
  allows clients to *receive* broadcasts and *track presence*. Every
  broadcast is sent by the database (`realtime.send`) from inside an RPC, a
  trigger or the sweeper, so events can't be forged and fan-out is Realtime's
  job, not N polling clients'.
- **Snapshot + deltas.** Every screen loads a snapshot RPC first
  (`get_duel_lobby`, `get_duel_state`), then applies broadcast deltas. On any
  channel re-subscribe it refetches the snapshot, so missed messages self-heal.
- **Server time is the only time.** Every RPC returns `serverNow`, and
  `ServerClock` keeps a per-app offset so countdowns (challenge TTL, 5 s
  request window, cool-off, round clocks) agree across devices.
- **One-duel-at-a-time is a row lock, not a hope.** `duel_player_state.current_duel_id`
  is set/cleared only inside `_duel_create` / `_duel_finish` / `_duel_abandon`,
  under `SELECT … FOR UPDATE` on both players' rows (locked in `user_id` order to
  avoid deadlocks). Every path into a duel (accept, pair, rematch) goes through
  `_duel_create`.
- **When a duel is created for a player**, the server atomically: removes them
  from the matchmaking queue, withdraws all their outgoing join requests
  (notifying those creators so their queues advance), and cancels their own
  open challenge unless that's the challenge being played (which becomes
  `matched` → "In progress" card).

### Challenge lifecycle (server state machine)

```
                create_duel_challenge            (TTL 5 min from created_at)
                        │
                        ▼
   ┌──────────── status = open ─────────────┐  creator_present toggles via presence RPC /
   │  creator_present=true  ⇄  false (Away)  │  sweeper (stale > 25 s) — Away blocks new
   └──────┬──────────────┬──────────────┬────┘  requests and clears queued/pending ones
          │ accept        │ cancel       │ expires_at < now()
          ▼               ▼              ▼
   status = matched   DELETE row      DELETE row           (every DELETE → challenge_remove
   duel_id set        (broadcast)     (sweeper, broadcast)  broadcast; queued requesters get
   "In progress"                                            join_request_status 'unavailable')
          │ duel ends (complete / forfeit)      │ duel abandoned before round 1
          ▼                                     ▼
   DELETE row (inside _duel_finish)       back to status = open (if not expired)
```

### Join-request queue (per challenge)

```
request_duel_join ─► queued ──(head of line & creator present)──► pending (expires_at = now()+5 s)
                        │                                             │
                        │ withdraw / creator away / challenge gone    ├─ accept  ──► accepted → _duel_create
                        ▼                                             ├─ decline ──► declined (retry_after = +15 s)
                     withdrawn                                        └─ 5 s + 1.5 s grace ─► expired (retry_after)
                                                                           (creator client auto-calls respond(false)
                                                                            at 0 s; sweeper is the backstop)
After any pending request resolves: _duel_promote_next_request(challenge) presents the next queued one.
```

### Matchmaking

- `join_matchmaking(topic)` upserts a queue row `(user, subcategory, language,
  elo, topic_level, queued_at, last_seen_at)` and immediately tries to pair.
- `matchmaking_heartbeat()` (every 3 s) refreshes `last_seen_at` and retries
  pairing. This is what makes the **band widen over time** without a
  scheduler. The call is throttled server-side: a call within 1 s of the last
  one skips the pairing work.
- **Band** = `min(band_max, band_start + band_step × floor(waited / band_step_seconds))`,
  default ±100, +50 every 5 s, max ±600. A pair (A, B) is eligible when
  `|eloA − eloB| ≤ max(bandA, bandB)` (the longer-waiting player's tolerance
  counts), same sub-category and language, both seen within 12 s.
- **Ordering** among eligible candidates:
  `|Δelo| + topic_level_weight × |Δtopic_level|` (weight default 10, so one
  cleared level ≈ 10 ELO), then oldest `queued_at`.
- Pairing inside one topic is serialised with
  `pg_try_advisory_xact_lock(hashtextextended('duel-mm:'||subcategory_id, 0))`.
  If the lock isn't available, skip this tick (no waiting, no deadlocks).
- At `waited ≥ bot_after_seconds` (30) the response carries
  `botAvailable: true`. The player can keep searching or take the labelled bot.

### Live duel protocol

```
_duel_create ─► duels.status='pending' + 5 duel_rounds rows (question ids only)
             ─► duel_start {duelId} to both inboxes
both clients: get_duel_state → subscribe duel:<id> → mark_duel_ready
both ready  ─► status='active', _duel_start_round(1, delay = intro 3 s)
             ─► round_start {round, startsAt, deadline, serverNow}          (no question text)
client @ startsAt−300 ms (server clock): get_duel_round(duel, round) → {prompt, options, kind, mediaUrl}
             (server refuses before startsAt − 500 ms: 'too_early')
client shows question, starts local stopwatch; on tap: submit_duel_answer(choice, client_ms)
             ─► answer_locked {userId, round, ms}   (opponent's "answered in 3.1s" chip; no choice leaked)
both locked, or deadline passed (client claim_duel_round_timeout / sweeper)
             ─► _duel_resolve_round ─► round_result {round, outcome, correctIndex, p1Choice, p2Choice, p1Ms, p2Ms, p1Rounds, p2Rounds}
             ─► round < 5: _duel_start_round(n+1, delay = reveal 2 s)   round = 5: _duel_finish('completed')
_duel_finish ─► ELO (K=32, if ranked & not suppressed), payouts, achievements, free players,
                delete challenge row ─► duel_end {…per-player results…}
disconnect: duels.pN_seen_at stale > 30 s (sweeper) ─► _duel_finish('forfeit', absent) — unresolved rounds go to the present player
no-show:    status='pending' and not both ready within 20 s ─► _duel_abandon (no ELO, no payout; challenge re-opens)
```

### Flutter layering (all inside `lib/features/duel/`)

```
data/      duel_realtime.dart, duel_broadcast.dart, server_clock.dart,
           duel_arena_api.dart, duel_arena_repository.dart,
           matchmaking_api.dart, matchmaking_repository.dart,
           live_duel_api.dart, live_duel_repository.dart,
           duel_api.dart (bot, modified), duel_repository.dart (bot, modified)
domain/    duel_player.dart (replaces duel_opponent.dart), duel_elo_band.dart,
           duel_topic.dart, duel_config.dart, duel_challenge.dart,
           incoming_join_request.dart, outgoing_join_request.dart,
           duel_lobby_snapshot.dart, lobby_event.dart,
           matchmaking_ticket.dart, duel_question.dart, live_duel_snapshot.dart,
           duel_room_event.dart, duel_round.dart (modified), duel_result.dart (modified)
presentation/
  bloc/    duel_arena_bloc.dart (+_event, +_state), duel_topic_picker_cubit.dart (+_state),
           matchmaking_cubit.dart (+_state, rewritten), live_duel_bloc.dart (+_event, +_state),
           duel_play_cubit.dart (+_state, modified), duel_rematch_cubit.dart (+_state)
  screens/ duel_arena_screen.dart (new), matchmaking_screen.dart (rewritten),
           live_duel_screen.dart (new), duel_play_screen.dart (bot, refactored),
           duel_result_screen.dart (modified)
  widgets/ arena_top_bar.dart, quick_match_card.dart, challenge_feed.dart,
           challenge_card.dart, challenge_countdown_ring.dart, challenge_composer_bar.dart,
           incoming_request_banner.dart, rejoin_duel_banner.dart,
           duel_topic_picker_sheet.dart, duel_topic_row.dart,
           matchmaking_bot_offer.dart, match_intro_view.dart, duel_round_view.dart,
           rematch_actions.dart, vs_header.dart (existing), duel_status_chip.dart (existing)
```

`DuelRealtime` and `ServerClock` are **app-root `RepositoryProvider`s** (added
to `lib/app/app.dart`). The arena, matchmaking and live-duel screens are stacked
on each other and all listen to the same `duel-user:<uid>` inbox. One ref-counted
channel per topic avoids duplicate joins, and one clock offset keeps countdowns
consistent. Everything else is constructed inline in each screen's
`BlocProvider.create`, matching today's `DuelRepository(DuelApi(supabase))`
pattern.

### UX / UI design (stays on the design bible's language)

Visual language reused from the existing duel screens: `arena.lite` grape
gradient, white "answer-option" plates with a 4 px hard ledge for tappable cards
(`arena.optionRest` + `arena.optionRestShadow`), Baloo2 display type for scores
and countdowns, emoji avatars, `VsHeader`, `ChunkyButton`, pop and slide motion
tokens, and reduced-motion respected through `AppMotion.durationOf/curveOf`.

**1. Duel Arena (S-38, new).** The arena is invariant across light and dark, like every arena surface.

```
┌───────────────────────────────────────┐
│ ✕          ⚔️ Duel Arena        ● 23  │ ArenaTopBar — presence pill = arena head count
│ ╭───────────────────────────────────╮ │
│ │ ⚡ QUICK MATCH                     │ │ QuickMatchCard (fixed; lemon ledge CTA)
│ │ Auto-paired with a player near    │ │  tap → topic picker → MatchmakingScreen
│ │ your level              [Find ▸]  │ │
│ ╰───────────────────────────────────╯ │
│ ╭─ 🐯 Danish M. wants to duel! ─────╮ │ IncomingRequestBanner (creator only; slides
│ │ 🥈 Silver · 1,380 · Football Lv 4 │ │  down over the feed; 5 s bar synced to server;
│ │ ▓▓▓▓▓▓▓▓▓▓░░░░  3s   +2 waiting   │ │  medium haptic on appear; Decline | Accept)
│ │ [ Decline ]          [ ⚔️ Accept ] │ │
│ ╰───────────────────────────────────╯ │
│ LIVE CHALLENGES · 8                   │
│   ⋮ older (scroll up)                 │ ChallengeFeed — bottom-anchored (reverse list),
│ ╭───────────────────────────────────╮ │  new cards slide up + fade in at the bottom
│ │ 🐯 Danish · 🥈 1,380    ● LIVE    │ │ in-progress: translucent chrome plate,
│ │ 🪐 Solar System · vs Zara N.      │ │  raspberry pulsing dot, not tappable
│ ╰───────────────────────────────────╯ │
│ ╭───────────────────────────────────╮ │
│ │ 🦊 Ayesha K.  🥇 1,412 · Lv 7  ◔4:12│ open: white plate, countdown ring
│ │ ⚽ Football · Sports   ⚖ Even match │ │  (mint → lemon <2 min → raspberry <30 s)
│ │ 5 rounds · winner +200 🪙 [⚔ Join] │ │
│ ╰───────────────────────────────────╯ │
│          ╭──────────────────────────╮ │ own card: aligned to the end (chat "me"
│          │ Your challenge   ◔3:02 🐼│ │  bubble), lemon border, "Waiting for a
│          │ ⚽ Football · Waiting…     │ │  challenger…", Cancel
│          ╰──────────────────────────╯ │
│        [ ↓ 2 new challenges ]         │ pill only when scrolled up (ephemeral UI state)
│ ╭───────────────────────────────────╮ │ ChallengeComposerBar (sticky, safe-area aware):
│ │ ＋ Create challenge                │ │  create | cool-off "New challenge in 1:42" (ring)
│ ╰───────────────────────────────────╯ │  | own open "Your Football challenge · 3:02" |
└───────────────────────────────────────┘  guest "Sign in to create challenges"
```

Challenge card states (one `ChallengeCard` widget, state derived in the Bloc):

| State | Visual | Action |
|---|---|---|
| Open | white plate, avatar, name (or "Guest ####"), league emoji + ELO, "Lv N" topic level, topic plate (sub-category emoji + name + category), countdown ring, fairness hint (`⚖ Even match` if \|Δelo\| ≤ 100, `🔥 Tough one` if opponent ≥ +150, `🟢 Favourable` if ≤ −150), reward line | `⚔ Join` (mango ChunkyButton small) |
| Requested (queued) | same, button area → "⏳ Request sent · 2 ahead" + small ✕ | withdraw |
| Requested (pending) | grape outline glow + "Ayesha is deciding…" with 5 s bar | withdraw |
| Declined / expired | "Not this time" for 2 s, then "Try again in 13s" disabled | — |
| Away | 55% opacity, "💤 Away" chip, ring keeps ticking | disabled |
| In progress | translucent `arena.chrome` plate, white text, "● LIVE · vs {name}" | disabled |
| Own | end-aligned, lemon border, "Waiting for a challenger…" or "💤 Paused while you're away" | Cancel |

Semantics: each card has one `Semantics` label ("Challenge from Ayesha K.,
Gold, 1412 ELO, Football, 4 minutes 12 seconds left. Double tap to request a
duel."). The countdown ring is excluded from semantics.

Empty feed: `EmptyStateView`-style block on the arena ("No live challenges yet —
throw down the first one", CTA opens the create flow). Loading: 3 `SkeletonBox`
card placeholders (animated, which also keeps widget tests deterministic).
Error: `ErrorStateView` with Retry. Reconnecting: a small "Reconnecting…" chip
replaces the presence pill until the channel re-subscribes, after which the
snapshot refetches.

Rejoin: if `get_duel_lobby` reports `me.activeDuelId`, a `RejoinDuelBanner`
("You have a duel in progress · Rejoin") pins above the composer.

**2. Topic picker sheet (new).** `AppBottomSheet` titled "Pick your
battleground" (create) or "Match in which topic?" (matchmake), with the message
"You'll only face players in the same topic." Sections by category (category
emoji + name as a `SectionHeader`), rows = `DuelTopicRow`: sub-category emoji
plate (`plateColor`), name, "Lv 4" if played, and activity chips
"🔥 3 searching" / "⚔️ 2 open". Topics with activity sort first inside each
category. Rows are tappable and pop the sheet with the chosen `DuelTopic`.
Empty (non-English today): "No duel topics in this language yet." Loading
skeleton rows; error with Retry.

**3. Matchmaking (S-39, rewritten, same look as today).** `arena.base`
gradient, ✕ top-left (leave queue), title "Finding an opponent", topic chip
under the title, `VsHeader` (real me avatar + "Gold · 1,412 ELO" | shimmering
❓ "Searching…" + "1,312 – 1,512 ELO"), spinner, "Searching for 12s · widening
range in 3s". At 30 s a `MatchmakingBotOffer` card slides up: "No one's around
in ⚽ Football right now", body "Play a practice bot — clearly labelled, results
count at half ELO", buttons `🤖 Play a bot` (primary) / `Keep searching` (line).
The search continues underneath until the player chooses. On match: haptic, the
right avatar pops in, then the route is replaced by the live duel.

**4. Live duel (S-40, new screen, same look as the bot duel).**
- `MatchIntroView` (status `pending`/before round 1): `arena.lite`, both
  avatars (`VsHeader`), names, league + ELO, topic plate, "Ranked"/"Unranked"
  chip, "Waiting for {name}…" until both ready, then a big 3-2-1 synced to
  round 1 `startsAt`.
- Round: `DuelRoundView` (extracted from today's `_RoundView`) — scores, timer ring,
  "ROUND 2/5", two status chips (me: "answered in 3.1s" / opponent: "Thinking…"
  → "Answered in 4s"), question card, four `AnswerOption`s (hourglass on my
  locked option; correct/wrong colours only once revealed). Adds an
  `OpponentConnection` chip ("🔌 Danish reconnecting… 24s") when presence drops.
- ✕ in the HUD → `AppDialog` "Leave the duel? Leaving forfeits the remaining
  rounds." (Leave = `leave_duel`).
- Between rounds: 2 s reveal. The next question appears at the server-synced
  `startsAt`.

**5. Result (S-41, modified).** Real me avatar; "Unranked — you've played
{name} 3 times today" note when `!isRanked`; forfeit captions ("Danish left —
the remaining rounds are yours" / "You left the duel"); **Rematch** for live
duels becomes a two-sided handshake (`RematchActions`: "Rematch" → "Waiting for
Danish…"; incoming → button pulses "Danish wants a rematch! Accept"; 30 s
window; "Danish has left" disables it). "Find a new opponent" → matchmaking in
the same topic (skips the picker). ✕ → pop back to the arena.

### New invariant arena tokens (`lib/core/theme/arena_colors.dart`, add-only)

Arena colours are identical in light and dark by design (class doc), so no
dark-mode twin is needed (CLAUDE.md §5's sync rule is satisfied by
construction). Add getters:
- `cardPlate` → `Colors.white.withValues(alpha: 0.97)` (same as `optionRest`)
- `cardInk` → `Color(0xFF1B1438)` (bible `--tx` light; ink on a white plate)
- `cardInkMuted` → `Color(0xFF6E668C)` (bible `--tx2` light)
- `cardLedge` → `Colors.black.withValues(alpha: 0.22)`
- `liveDot` → `Color(0xFFFF3D6E)` (raspberry)
- `ownCardBorder` → `Color(0xFFFFC61A)` (lemon)
- `countdownSafe` / `countdownWarn` / `countdownDanger` → mint `0xFF12C79B` /
  lemon `0xFFFFC61A` / raspberry `0xFFFF3D6E`

Reference existing `AppColors` constants where they already hold these
values instead of re-typing hex, if `AppColors` exposes them (it does for the
light palette: `lightTx`, `lightTx2`, `lightOk`, `lightGold`, `lightBad`).

## Implementation steps

### Phase 0 — Before you begin (read-only checks)
- [ ] Re-read `lib/features/duel/**`, `lib/features/shell/**`,
      `lib/app/router.dart`, `lib/core/router/app_routes.dart`,
      `lib/app/app.dart` and confirm they still match Research findings.
- [ ] Via Supabase MCP `execute_sql`, confirm the backend snapshot:
      `select count(*) from duels;` (≈1), `select count(*) from matchmaking_queue;`
      (0 — **Phase 1 deletes all rows; stop and ask if >0**),
      `select jobname from cron.job;` (3 jobs, no `duel-sweeper`),
      `select * from pg_policies where schemaname='realtime';` (none),
      `select proname from pg_proc p join pg_namespace n on n.oid=p.pronamespace
       where n.nspname='realtime' and proname='send';` (exists),
      `select conname from pg_constraint where conrelid='public.duels'::regclass
       and contype='c';` (note the status check constraint's exact name, expected
      `duels_status_check`).
- [ ] `mcp__supabase__list_migrations` to confirm the last applied migration is
      `20260921100100_activate_hi_ar_fr_es_languages` (or later). Name the new
      files after it.

### Phase 1 — Schema & config (`supabase/migrations/20260927120000_duel_arena_schema.sql`)
Wrap in `begin; … commit;` like `20260910090500_*`.
- [ ] **`app_settings` row `duel_config`** (single jsonb object; `insert … on
      conflict (key) do update`), with description "Duel arena / matchmaking /
      live duel tunables (plan 017)":
      ```json
      {"challenge_ttl_seconds":300,"challenge_cooldown_seconds":120,"challenge_daily_cap":60,
       "join_window_seconds":5,"join_grace_ms":1500,"join_max_outstanding":3,
       "join_rate_max":20,"join_rate_window_seconds":300,"join_retry_seconds":15,"join_queue_cap":10,
       "lobby_heartbeat_seconds":10,"creator_stale_seconds":25,"lobby_feed_limit":50,"lobby_presence_enabled":true,
       "min_topic_questions":5,
       "mm_heartbeat_seconds":3,"mm_stale_seconds":12,"mm_bot_after_seconds":30,
       "mm_band_start":100,"mm_band_step":50,"mm_band_step_seconds":5,"mm_band_max":600,
       "mm_topic_level_weight":10,"mm_join_rate_max":20,"mm_join_rate_window_seconds":600,
       "rounds":5,"round_seconds":15,"reveal_seconds":2,"intro_seconds":3,
       "latency_allowance_ms":1500,"min_answer_ms":250,
       "ready_timeout_seconds":20,"duel_heartbeat_seconds":5,"disconnect_forfeit_seconds":30,
       "rematch_window_seconds":30,"ranked_pair_cap_per_day":3,
       "rage_quit_forfeits_per_day":3,"elo_k":32,
       "reward_win_coins":200,"reward_win_xp":250,"reward_loss_coins":40,"reward_loss_xp":80,
       "reward_draw_coins":40,"reward_draw_xp":80}
      ```
- [ ] **`public.duel_challenges`**:
      ```sql
      create table public.duel_challenges (
        id uuid primary key default gen_random_uuid(),
        creator_id uuid not null references public.profiles (id) on delete cascade,
        subcategory_id uuid not null references public.subcategories (id) on delete cascade,
        language_code text not null references public.languages (code),
        status text not null default 'open' check (status in ('open', 'matched')),
        creator_present boolean not null default true,
        -- Display snapshot (so the feed card and its broadcast need no joins):
        creator_name text,            -- null for guests (never, today: guests can't create)
        creator_guest_tag text,
        creator_avatar text not null,
        creator_elo integer not null,
        creator_league text not null,
        creator_topic_level smallint not null default 0,
        topic_name text not null, topic_emoji text not null, topic_plate_color text not null,
        category_name text not null, category_emoji text not null,
        duel_id uuid references public.duels (id) on delete set null,
        opponent_name text, opponent_guest_tag text,   -- set when matched ("vs Zara N.")
        created_at timestamptz not null default now(),
        expires_at timestamptz not null
      );
      create unique index duel_challenges_one_open_per_creator
        on public.duel_challenges (creator_id) where status = 'open';
      create index duel_challenges_feed_idx on public.duel_challenges (language_code, created_at desc);
      create index duel_challenges_expiry_idx on public.duel_challenges (expires_at) where status = 'open';
      ```
- [ ] **`public.duel_join_requests`**:
      ```sql
      create table public.duel_join_requests (
        id uuid primary key default gen_random_uuid(),
        challenge_id uuid not null references public.duel_challenges (id) on delete cascade,
        creator_id uuid not null references public.profiles (id) on delete cascade,
        requester_id uuid not null references public.profiles (id) on delete cascade,
        status text not null check (status in ('queued','pending','accepted','declined','expired','withdrawn')),
        requester_name text, requester_guest_tag text, requester_avatar text not null,
        requester_elo integer not null, requester_league text not null,
        requester_topic_level smallint not null default 0,
        created_at timestamptz not null default now(),
        presented_at timestamptz, expires_at timestamptz,
        resolved_at timestamptz, retry_after timestamptz
      );
      create unique index duel_join_requests_active_uq
        on public.duel_join_requests (challenge_id, requester_id) where status in ('queued','pending');
      create unique index duel_join_requests_one_pending
        on public.duel_join_requests (challenge_id) where status = 'pending';
      create index duel_join_requests_requester_active
        on public.duel_join_requests (requester_id) where status in ('queued','pending');
      create index duel_join_requests_pending_expiry
        on public.duel_join_requests (expires_at) where status = 'pending';
      ```
      Note: `on delete cascade` from `duel_challenges` means **delete paths
      must notify requesters before deleting the challenge** (Phase 3 helper
      `_duel_clear_requests_for_challenge`).
- [ ] **`public.duel_player_state`** (one row per player who touched duels;
      the lock target for one-duel-at-a-time):
      ```sql
      create table public.duel_player_state (
        user_id uuid primary key references public.profiles (id) on delete cascade,
        current_duel_id uuid references public.duels (id) on delete set null,
        last_challenge_at timestamptz,
        lobby_seen_at timestamptz,
        updated_at timestamptz not null default now()
      );
      ```
- [ ] **`public.duel_rate_buckets`** (fixed-window counters):
      ```sql
      create table public.duel_rate_buckets (
        user_id uuid not null references public.profiles (id) on delete cascade,
        bucket text not null,
        window_start timestamptz not null,
        hits integer not null default 0,
        primary key (user_id, bucket)
      );
      ```
- [ ] **`public.duel_rounds`** (server-only round ledger; replaces the
      `p*_answers` arrays for live duels):
      ```sql
      create table public.duel_rounds (
        duel_id uuid not null references public.duels (id) on delete cascade,
        round smallint not null check (round between 1 and 10),
        question_id uuid not null references public.questions (id),
        starts_at timestamptz, deadline timestamptz,
        p1_choice smallint, p1_ms integer, p1_locked_at timestamptz,
        p2_choice smallint, p2_ms integer, p2_locked_at timestamptz,
        outcome text check (outcome in ('p1', 'p2', 'draw')),
        resolved_at timestamptz,
        primary key (duel_id, round)
      );
      ```
      "Locked" = `pN_locked_at is not null`. A null `pN_choice` with a lock
      means timeout / no answer.
- [ ] **Alter `public.duels`**:
      ```sql
      alter table public.duels
        add column subcategory_id uuid references public.subcategories (id),
        add column language_code text references public.languages (code),
        add column origin text not null default 'bot'
          check (origin in ('bot', 'challenge', 'matchmaking', 'rematch')),
        add column challenge_id uuid,           -- no FK: challenge rows are deleted by design
        add column rematch_of uuid references public.duels (id),
        add column is_ranked boolean not null default true,
        add column current_round smallint not null default 0,
        add column p1_ready_at timestamptz, add column p2_ready_at timestamptz,
        add column p1_seen_at timestamptz,  add column p2_seen_at timestamptz,
        add column p1_rematch_at timestamptz, add column p2_rematch_at timestamptz,
        add column end_reason text check (end_reason in ('completed', 'forfeit', 'abandoned')),
        add column forfeited_by uuid references public.profiles (id),
        add column p1_coins integer, add column p2_coins integer,
        add column p1_xp integer, add column p2_xp integer,
        add column ended_at timestamptz;
      alter table public.duels drop constraint duels_status_check;   -- name verified in Phase 0
      alter table public.duels add constraint duels_status_check
        check (status in ('pending', 'active', 'complete', 'forfeit', 'abandoned'));
      create index duels_live_idx on public.duels (status) where status in ('pending', 'active');
      create index duels_pair_idx on public.duels (least(p1, p2), greatest(p1, p2), created_at desc)
        where p2 is not null;
      create index duels_forfeited_by_idx on public.duels (forfeited_by, ended_at desc)
        where forfeited_by is not null;
      ```
      Existing row (bot, complete) is valid under the new constraint.
- [ ] **Alter `public.matchmaking_queue`** (0 rows, verified in Phase 0):
      ```sql
      delete from public.matchmaking_queue;
      alter table public.matchmaking_queue
        add column subcategory_id uuid not null references public.subcategories (id) on delete cascade,
        add column language_code text not null references public.languages (code),
        add column topic_level smallint not null default 0,
        add column last_seen_at timestamptz not null default now();
      create index matchmaking_queue_topic_idx
        on public.matchmaking_queue (subcategory_id, language_code, elo);
      ```
- [ ] **RLS**: `alter table … enable row level security` on all five new
      tables, with **no policies** (RPC-only access; security-definer functions
      bypass RLS). Drop the client write paths that real play makes unsafe:
      `drop policy duels_update_participant_active on public.duels;`
      `drop policy matchmaking_queue_insert_self on public.matchmaking_queue;`
      `drop policy matchmaking_queue_delete_self on public.matchmaking_queue;`
      (keep `duels_select_participant` and `matchmaking_queue_select_self`; they
      expose nothing secret once answers live in `duel_rounds`). Leave the
      `guard_duel_answer_update` trigger in place (harmless).
- [ ] Comments on each new table (house style: every table in the initial
      schema carries a comment explaining *why*).

### Phase 2 — Realtime authorization (`20260927120100_duel_realtime_authorization.sql`)
- [ ] RLS policies on `realtime.messages` (the table already has RLS enabled
      by Supabase; verify with `select relrowsecurity from pg_class where oid =
      'realtime.messages'::regclass`):
      ```sql
      -- Arena feed: any signed-in (incl. anonymous guest) user may receive, and may
      -- track presence, but may never publish a broadcast.
      create policy duel_lobby_receive on realtime.messages for select to authenticated
        using (realtime.topic() like 'duel-lobby:%' and extension in ('broadcast', 'presence'));
      create policy duel_lobby_presence on realtime.messages for insert to authenticated
        with check (realtime.topic() like 'duel-lobby:%' and extension = 'presence');

      -- Personal inbox: only its owner.
      create policy duel_inbox_receive on realtime.messages for select to authenticated
        using (realtime.topic() = 'duel-user:' || auth.uid()::text and extension = 'broadcast');

      -- Duel room: only the two participants.
      create policy duel_room_receive on realtime.messages for select to authenticated
        using (
          split_part(realtime.topic(), ':', 1) = 'duel'
          and extension in ('broadcast', 'presence')
          and exists (
            select 1 from public.duels d
            where d.id::text = split_part(realtime.topic(), ':', 2)
              and auth.uid() in (d.p1, d.p2)
          )
        );
      create policy duel_room_presence on realtime.messages for insert to authenticated
        with check (
          split_part(realtime.topic(), ':', 1) = 'duel'
          and extension = 'presence'
          and exists (
            select 1 from public.duels d
            where d.id::text = split_part(realtime.topic(), ':', 2)
              and auth.uid() in (d.p1, d.p2)
          )
        );
      ```
      Note the topic prefix `duel-lobby:` vs `duel-user:` vs `duel:`.
      `split_part(…,':',1) = 'duel'` only matches the room, never the other two.
- [ ] Document in the migration header that **no table is added to the
      `supabase_realtime` publication**. This design uses Broadcast from the
      database, not Postgres Changes, deliberately, because Postgres Changes
      re-evaluates RLS per subscriber per row (the "overloaded backend" failure
      mode the spec worries about).

### Phase 3 — Arena & challenge functions (`20260927120200_duel_arena_challenge_functions.sql`)
All functions: `language plpgsql security definer set search_path = public`.
Every public RPC ends with `grant execute … to authenticated;`. **Every
`_`-prefixed helper ends with `revoke execute on function … from public, anon,
authenticated;`** so only other definer functions / cron can call it. Error
convention: `raise exception '<identifier>'` (surfaces as `ApiException.code`).

Helpers:
- [ ] `_duel_cfg() returns jsonb` — `select value from app_settings where key
      = 'duel_config'`. `stable`. Plus `_duel_cfg_int(p_key text) returns
      integer` for readability.
- [ ] `_duel_guest_tag(p_user_id uuid) returns text` —
      `lpad((abs(hashtext(p_user_id::text)) % 10000)::text, 4, '0')`.
- [ ] `_duel_topic_level(p_user_id uuid, p_subcategory_id uuid) returns
      smallint` — `count(*)` of `level_progress` rows with `completed_at is not
      null` for that pair.
- [ ] `_duel_player_json(p_user_id uuid, p_subcategory_id uuid) returns jsonb`
      — `{id, name (username or null), isGuest, guestTag (null unless guest),
      avatar (avatar_key), elo, league, topicLevel, isBot:false}`.
- [ ] `_duel_topic_json(p_subcategory_id uuid) returns jsonb` — `{id, name,
      emoji, plateColor, categoryId, categoryName, categoryEmoji}` with names
      from `taxonomy_i18n` for the entity's own `language_code` (same lookup
      shape as `CatalogApi._taxonomyNames`: `entity_type in
      ('category','subcategory')`, `locale = categories.language_code`), falling
      back to `slug`.
- [ ] `_duel_state_lock(p_user_id uuid) returns duel_player_state` — `insert …
      on conflict do nothing`, then `select … for update`.
      `_duel_lock_pair(a uuid, b uuid)` locks both via `_duel_state_lock` in
      ascending `user_id` order.
- [ ] `_duel_rate_hit(p_user_id uuid, p_bucket text, p_max int, p_window
      interval, p_error text) returns void` — upsert the bucket. Reset when
      `window_start < now() - p_window`, otherwise `hits + 1`. Raise `p_error`
      when `hits > p_max`.
- [ ] `_duel_inbox_send(p_user_id uuid, p_event text, p_payload jsonb)` →
      `perform realtime.send(p_payload || jsonb_build_object('serverNow', now()),
      p_event, 'duel-user:' || p_user_id, true);`
- [ ] `_duel_room_send(p_duel_id uuid, p_event text, p_payload jsonb)` → same
      to `'duel:' || p_duel_id`.
- [ ] `_duel_challenge_card(c duel_challenges) returns jsonb` (from the row
      alone, no joins): `{id, status ('open'|'matched'), creatorPresent,
      createdAt, expiresAt, creator:{id, name, isGuest:false, guestTag, avatar,
      elo, league, topicLevel}, topic:{id, name, emoji, plateColor,
      categoryName, categoryEmoji}, opponentName, opponentGuestTag, duelId}`.
- [ ] Trigger function `_duel_challenges_broadcast()`: `AFTER INSERT OR
      DELETE` → `challenge_upsert` (card) / `challenge_remove` (`{id}`) on
      `'duel-lobby:' || language_code`. A separate `AFTER UPDATE` trigger with
      `WHEN (old.status is distinct from new.status or old.creator_present is
      distinct from new.creator_present or old.duel_id is distinct from
      new.duel_id)` sends `challenge_upsert`. This way heartbeat-only updates
      never broadcast.
- [ ] `_duel_request_status_payload(r duel_join_requests, p_reason text)` →
      `{requestId, challengeId, status, position (for queued: 1-based count of
      earlier queued rows), expiresAt, retryAfter, reason}` for the requester
      inbox event `join_request_status`.
- [ ] `_duel_present_request(p_request_id uuid)` — set `status='pending',
      presented_at=now(), expires_at=now()+join_window` and send
      `join_request` to the creator inbox (`{requestId, challengeId,
      requester:{…snapshot…}, expiresAt, queuedCount}`) and
      `join_request_status` (pending) to the requester.
- [ ] `_duel_promote_next_request(p_challenge_id uuid)` — if there's no
      `pending` row and the challenge is `open` and `creator_present`: pick the
      oldest `queued` whose requester is not in a duel and whose
      `duel_player_state.lobby_seen_at > now() - creator_stale_seconds`
      (skip and `withdraw` stale ones with reason `'requester_left'`), then
      `_duel_present_request`. Also send each still-queued requester an
      updated `position`.
- [ ] `_duel_resolve_request(p_request_id uuid, p_status text, p_reason text,
      p_set_retry boolean)` — terminal transition + `resolved_at` (+
      `retry_after = now() + join_retry_seconds` when `p_set_retry`) +
      `join_request_status` to the requester. If it was `pending`, also
      `join_request_cleared {requestId, reason}` to the creator.
- [ ] `_duel_clear_requests_for_challenge(p_challenge_id uuid, p_reason text)`
      — resolve every queued/pending request as `withdrawn` with `p_reason`
      (e.g. `'challenge_gone'`, `'creator_away'`, `'taken'`).
- [ ] `_duel_withdraw_user_requests(p_user_id uuid, p_reason text)` — resolve
      the user's queued/pending requests as `withdrawn`, then
      `_duel_promote_next_request` for each affected challenge.
- [ ] `_duel_delete_challenge(p_challenge_id uuid, p_reason text)` —
      `_duel_clear_requests_for_challenge` first, then `delete` (the trigger
      broadcasts the removal).

Public RPCs:
- [ ] `get_duel_lobby(p_language_code text) returns jsonb`:
      `_duel_state_lock` isn't needed (read-only), but upsert
      `duel_player_state.lobby_seen_at = now()`. Returns:
      ```json
      {"serverNow": "...",
       "config": {"challengeTtlSeconds":300,"cooldownSeconds":120,"joinWindowSeconds":5,
                  "lobbyHeartbeatSeconds":10,"mmHeartbeatSeconds":3,"botAfterSeconds":30,
                  "bandStepSeconds":5,"rounds":5,"roundSeconds":15,"revealSeconds":2,
                  "introSeconds":3,"duelHeartbeatSeconds":5,"rematchWindowSeconds":30,
                  "presenceEnabled":true,"winCoins":200},
       "me": {"player": {…_duel_player_json(me, null)…}, "isGuest": false,
              "activeDuelId": null, "openChallengeId": null,
              "cooldownEndsAt": null, "challengesLeftToday": 58},
       "challenges": [ …up to lobby_feed_limit cards, status in (open, matched),
                       open ones only if expires_at > now(), ordered created_at ASC… ],
       "myRequests": [ …_duel_request_status_payload for my queued/pending rows, plus
                       terminal rows with retry_after > now()… ],
       "incoming": null | {…same shape as the join_request event…}}
      ```
- [ ] `list_duel_topics(p_language_code text) returns jsonb` — array of
      `_duel_topic_json(s.id) || {myTopicLevel, openChallenges, searching,
      liveQuestionCount}` for active sub-categories in active categories of
      that language with `≥ min_topic_questions` live questions in that
      language. Ordered by category `sort_order`, then `(openChallenges +
      searching) desc`, then sub-category `sort_order`.
- [ ] `create_duel_challenge(p_subcategory_id uuid) returns jsonb` — in order:
      `not_authenticated` → `guest_cannot_create` (`profiles.is_guest`) →
      `_duel_state_lock(me)` → `already_in_duel` (`current_duel_id is not
      null`) → `challenge_already_open` → `challenge_cooldown`
      (`last_challenge_at > now() - cooldown`) → `_duel_rate_hit(me,
      'challenge_day', challenge_daily_cap, '24 hours', 'challenge_daily_cap')`
      → `topic_unavailable` (inactive, or `< min_topic_questions` live
      questions in the topic's language). Insert with snapshot columns and
      `expires_at = now() + ttl`. Set `last_challenge_at = now()`,
      `lobby_seen_at = now()`. Returns `{challenge: card, cooldownEndsAt,
      serverNow}`. Note the cool-off is written in the same transaction as the
      insert, so double-taps can't create two.
- [ ] `cancel_duel_challenge(p_challenge_id uuid) returns void` — creator only
      (`challenge_not_found` otherwise), status `open` only →
      `_duel_delete_challenge(id, 'challenge_gone')`. Cool-off unchanged.
- [ ] `set_duel_lobby_presence(p_present boolean) returns jsonb` — upsert
      `lobby_seen_at` (only when `p_present`). For the caller's `open`
      challenge: if `creator_present <> p_present`, update it (trigger
      broadcasts Away/Live). If going away, `_duel_clear_requests_for_challenge
      (id, 'creator_away')`. If coming back, `_duel_promote_next_request` (no-op
      when empty). If going away, also `_duel_withdraw_user_requests(me,
      'requester_left')` (a player off the arena can't be dropped into a duel).
      Returns `{serverNow}`. Throttle: if `p_present` and `lobby_seen_at >
      now() - 2 s`, return immediately.
- [ ] `request_duel_join(p_challenge_id uuid) returns jsonb` — checks in order:
      `not_authenticated`; challenge exists, `status='open'`, `expires_at >
      now()` else `challenge_unavailable`; `own_challenge`; `creator_away`;
      `_duel_state_lock(me)` → `already_in_duel`; existing active row →
      `already_requested`; latest terminal row with `retry_after > now()` →
      `retry_later`; outstanding count ≥ `join_max_outstanding` →
      `too_many_requests`; `_duel_rate_hit(me, 'join', join_rate_max,
      join_rate_window, 'rate_limited')`; queued+pending for the challenge ≥
      `join_queue_cap` → `challenge_busy`. Insert `queued` with the requester
      snapshot, set `lobby_seen_at = now()`, then `_duel_promote_next_request`.
      Return `_duel_request_status_payload` of the (possibly now pending) row.
- [ ] `withdraw_duel_join(p_request_id uuid) returns void` — requester only;
      no-op if already terminal. `_duel_resolve_request(…, 'withdrawn',
      'withdrawn', false)` → `_duel_promote_next_request`.
- [ ] `respond_duel_join(p_request_id uuid, p_accept boolean) returns jsonb` —
      creator only (`request_not_found`); `status='pending'` else
      `request_expired`.
      - If `now() > expires_at + join_grace_ms`: resolve `expired` (retry set)
        → promote → raise `request_expired`.
      - Decline: resolve `declined` (retry set) → promote → return
        `{accepted:false}`.
      - Accept: `_duel_lock_pair(creator, requester)`. If the requester's
        `current_duel_id` is set → resolve `expired` with reason
        `'requester_busy'` → promote → raise `requester_busy`. If the
        creator's is set → raise `already_in_duel`. Otherwise
        `v_duel := _duel_create(creator, requester, subcategory, language,
        'challenge', challenge_id, null)` (Phase 5). Mark the request
        `accepted`. Set the challenge `status='matched'`, `duel_id`,
        `opponent_name/guest_tag` (the trigger broadcasts "In progress"). Clear
        the challenge's other requests with reason `'taken'`. Return
        `{accepted:true, duelId}`.
      - `_duel_create` itself handles the requester's other requests, their own
        open challenge, queues and `duel_start` inboxes.

### Phase 4 — Matchmaking functions (`20260927120300_duel_matchmaking_functions.sql`)
- [ ] `_duel_mm_band(p_queued_at timestamptz) returns integer` (see Design
      overview formula).
- [ ] `_duel_mm_ticket(p_user_id uuid) returns jsonb` — if the user has
      `current_duel_id` of a `pending|active` duel → `{status:'matched', duelId}`.
      Else if queued → `{status:'queued', queuedAt, band:{min, max}, elo,
      botAvailable: waited ≥ mm_bot_after_seconds, botAvailableAt, me:
      _duel_player_json(me, subcategory), topic: _duel_topic_json(subcategory),
      serverNow}`. Else raise `not_in_queue`.
- [ ] `_duel_try_pair(p_user_id uuid) returns uuid` — read own queue row
      (return null if none); `if not pg_try_advisory_xact_lock(hashtextextended
      ('duel-mm:' || subcategory_id::text, 0)) then return null`. Pick the
      candidate:
      ```sql
      select q.user_id from public.matchmaking_queue q
      join public.duel_player_state s on s.user_id = q.user_id
      where q.subcategory_id = v_me.subcategory_id
        and q.language_code = v_me.language_code
        and q.user_id <> v_me.user_id
        and q.last_seen_at > now() - make_interval(secs => v_stale)
        and s.current_duel_id is null
        and abs(q.elo - v_me.elo) <= greatest(public._duel_mm_band(q.queued_at),
                                              public._duel_mm_band(v_me.queued_at))
      order by abs(q.elo - v_me.elo) + v_weight * abs(q.topic_level - v_me.topic_level),
               q.queued_at
      limit 1;
      ```
      If found → `return _duel_create(<older queued_at player as p1>, <other>,
      subcategory, language, 'matchmaking', null, null)`.
- [ ] `join_matchmaking(p_subcategory_id uuid) returns jsonb` —
      `not_authenticated`; `_duel_state_lock(me)` → `already_in_duel`;
      `topic_unavailable` (same check as challenges); `_duel_rate_hit(me,
      'mm_join', mm_join_rate_max, mm_join_rate_window, 'rate_limited')`;
      `_duel_withdraw_user_requests(me, 'requester_left')`; upsert the queue row
      (a re-join resets `queued_at` only if the topic changed); `_duel_try_pair
      (me)`; return `_duel_mm_ticket(me)`.
- [ ] `matchmaking_heartbeat() returns jsonb` — if `current_duel_id` is set →
      return the matched ticket. If there's no queue row → raise
      `not_in_queue`. If `last_seen_at > now() - 1 s` → return the ticket
      without pairing work (throttle). Else update `last_seen_at`,
      `_duel_try_pair(me)`, and return the ticket.
- [ ] `leave_matchmaking() returns void` — delete the caller's queue row
      (no-op when absent).

### Phase 5 — Live duel functions + bot fixes (`20260927120400_duel_live_play_functions.sql`)
- [ ] **Drop the unused §24 skeleton** (param names change, so `create or
      replace` can't be used; nothing in the app calls them — re-grep `lib/`
      for `submit_duel_answer|resolve_duel` first):
      `drop function if exists public.submit_duel_answer(uuid, smallint, smallint, integer);`
      `drop function if exists public.resolve_duel_round(uuid, smallint);`
      `drop function if exists public.resolve_duel(uuid);`
- [ ] `_duel_create(p1 uuid, p2 uuid, p_subcategory_id uuid, p_language
      text, p_origin text, p_challenge_id uuid, p_rematch_of uuid) returns
      uuid`:
      1. `_duel_lock_pair(p1, p2)`. If either has `current_duel_id` → raise
         `already_in_duel` (callers translate this).
      2. Question pick (prefer unseen by both, then random):
         ```sql
         select array_agg(id) into v_qids from (
           select q.id from public.questions q
           where q.subcategory_id = p_subcategory_id and q.status = 'live'
             and q.language_code = p_language
           order by (select count(*) from public.user_question_history h
                     where h.question_id = q.id and h.user_id in (p1, p2)),
                    random()
           limit v_rounds) s;
         ```
         Raise `topic_unavailable` if there are fewer than `rounds`.
      3. `v_ranked := (select count(*) from duels where least(p1,p2) =
         least($1,$2) and greatest(p1,p2) = greatest($1,$2) and is_ranked and
         status = 'complete' and created_at > now() - interval '24 hours') <
         ranked_pair_cap_per_day`.
      4. Insert the `duels` row: `status='pending'`, `is_bot=false`,
         `question_ids=v_qids`, `origin`, `challenge_id`, `rematch_of`,
         `subcategory_id`, `language_code`, `is_ranked=v_ranked`,
         `p1_seen_at=p2_seen_at=now()`, `expires_at=now()+interval '15
         minutes'`, `p1_elo_before/p2_elo_before` from profiles.
      5. Insert `duel_rounds` rows 1..rounds with `question_id` only.
      6. Set both `duel_player_state.current_duel_id`.
      7. For both players: `delete from matchmaking_queue`,
         `_duel_withdraw_user_requests(p, 'in_duel')`, and delete their `open`
         challenge (`_duel_delete_challenge(…, 'challenge_gone')`) **except**
         `p_challenge_id`.
      8. `_duel_inbox_send(p1/p2, 'duel_start', {duelId, origin})`.
      Return the id.
- [ ] `_duel_side(p_duel duels, p_user uuid) returns text` ('p1'|'p2', or raise
      `not_a_participant`).
- [ ] `_duel_touch(p_duel_id uuid, p_side text)` — `pN_seen_at = now()`.
- [ ] `_duel_start_round(p_duel_id uuid, p_round smallint, p_delay interval)` —
      `starts_at = now() + p_delay`, `deadline = starts_at + round_seconds +
      latency_allowance_ms`, `duels.current_round = p_round`, then
      `_duel_room_send('round_start', {round, startsAt, deadline, roundSeconds,
      totalRounds})`. **No question text in the broadcast** (A2).
- [ ] `_duel_resolve_round(p_duel_id uuid, p_round smallint) returns jsonb` —
      `select … for update` the round. Return if already resolved (idempotent).
      Fill any missing lock with `choice=null, ms=null, locked_at=now()`.
      `correct_index` from `questions`. Outcome: correct vs wrong → the
      correct side; both correct → lower ms (equal → `'draw'`); both
      wrong/none → `'draw'`. Update `duel_rounds.outcome/resolved_at` and
      `duels.p1_rounds/p2_rounds`. Upsert `user_question_history` for both
      players (`times_seen + 1`, `last_seen_at = now()`), matching the columns
      used by the level-attempt anti-repeat logic (verify its exact upsert in
      `20260910090200_question_bank_and_anti_repeat.sql`). Send `round_result
      {round, outcome, correctIndex, p1Choice, p2Choice, p1Ms, p2Ms,
      p1Rounds, p2Rounds}`. Then `round < rounds` → `_duel_start_round(round+1,
      reveal_seconds)`, else `_duel_finish(id, 'completed', null)`.
- [ ] `_duel_check_achievements(p_user_id uuid) returns text[]` — generalised
      from `submit_bot_duel`: for every `achievements` row with
      `criteria->>'type' = 'duel_wins'`, if not yet unlocked and
      `(select count(*) from duels where winner = p_user_id and status =
      'complete') >= (criteria->>'count')::int` → insert `user_achievements`
      and `_grant_currency(…, coin_reward, 'achievement_unlocked', null)`.
      Return the new ids.
- [ ] `_duel_finish(p_duel_id uuid, p_reason text, p_forfeited_by uuid)` —
      lock the duel; no-op if status is not `active`/`pending`.
      - If `p_reason = 'forfeit'`: resolve every unresolved round with outcome =
        the present side (not the forfeiter), update the tallies, and set
        `forfeited_by`.
      - Winner by rounds (tie → draw). Score `S` for p1 is 1 / 0.5 / 0.
      - ELO when `is_ranked`: `E = 1/(1+10^((Ro−R)/400))`, `R' = R + K(S−E)`,
        K from config. **Rage-quit rule**: if a player has
        `≥ rage_quit_forfeits_per_day` forfeits (`forfeited_by = them`,
        `ended_at > now()-24h`, *including this one*), clamp their ELO delta to
        `≤ 0`.
      - Payouts via `_grant_currency` (reasons `'duel_win'`, `'duel_loss'`,
        `'duel_draw'`, ref = duel id). Win/loss/draw coins + XP from config
        (A6), and `profiles.xp` incremented exactly the way `submit_bot_duel`
        does it.
      - Achievements for both, via `_duel_check_achievements`.
      - Persist `status='complete'`, `end_reason`, `winner`, `pN_elo_after`,
        `pN_coins`, `pN_xp`, `ended_at`. Clear both `current_duel_id`.
      - If `challenge_id` is set → `delete from duel_challenges where id =
        challenge_id` (trigger broadcasts removal).
      - `_duel_room_send('duel_end', {reason, winnerId, isRanked, forfeitedBy,
        p1Rounds, p2Rounds, p1AvgMs, p2AvgMs, p1:{eloBefore, eloAfter, coins,
        xp, badgeIds}, p2:{…}})`.
- [ ] `_duel_abandon(p_duel_id uuid, p_reason text)` — `status='abandoned'`,
      `end_reason='abandoned'`, `ended_at`, clear both `current_duel_id`, no
      ELO/payout. If the challenge row still exists and `expires_at > now()`,
      set it back to `status='open'`, `duel_id=null`, `opponent_*=null`, which
      re-opens the creator's challenge. Send `duel_end {reason:'abandoned',
      cause:p_reason}`.
- [ ] Public RPCs:
      - `get_duel_state(p_duel_id uuid) returns jsonb` — participant only
        (`duel_not_found` / `not_a_participant`). `_duel_touch`. Returns
        perspective-mapped state: `{serverNow, duelId, status, mySide,
        isRanked, origin, topic, me:player, opponent:player, config:{rounds,
        roundSeconds, revealSeconds}, currentRound, round:{number, startsAt,
        deadline, myLocked, myChoice, myMs, opponentLocked, opponentMs,
        question: (only if now() ≥ starts_at − 500 ms) {prompt, options, kind,
        mediaUrl}}, history:[{round, outcome:'me'|'opponent'|'draw',
        correctIndex, myChoice, opponentChoice, myMs, opponentMs}], myScore,
        opponentScore, result: null | {reason, won, draw, eloBefore,
        eloAfter, coins, xp, badgeIds, opponentForfeited, youForfeited,
        myAvgMs, opponentAvgMs}}`. `player` JSON reads from
        `_duel_player_json(user, duel.subcategory_id)`, with the ELO shown as
        `pN_elo_before`.
      - `mark_duel_ready(p_duel_id uuid) returns jsonb` — set `pN_ready_at` +
        touch. If both are ready and status is `pending` → `status='active'`,
        `_duel_start_round(1, intro_seconds)`. Returns `{serverNow, status}`.
      - `get_duel_round(p_duel_id uuid, p_round smallint) returns jsonb` —
        participant; `round = current_round`, else `round_closed`; `now() ≥
        starts_at − 500 ms`, else `too_early`. Returns `{round, startsAt,
        deadline, question:{prompt, options, kind, mediaUrl}, serverNow}`.
      - `submit_duel_answer(p_duel_id uuid, p_round smallint, p_choice
        smallint, p_client_ms integer) returns jsonb` — participant; `status =
        'active'`, `round = current_round`, not yet locked (else
        `already_answered`), `now() ≤ deadline` (else `round_closed`; the caller
        then waits for `round_result`). Compute `server_elapsed_ms`. Null
        `p_choice` or `p_client_ms > round_ms` means timeout (choice null, ms
        null). Otherwise `ms = least(round_ms, greatest(min_answer_ms,
        p_client_ms, server_elapsed_ms − latency_allowance_ms))`. Store it and
        `_duel_touch`. Send `answer_locked {userId, round, ms}` (never the
        choice). If both are locked → `_duel_resolve_round`. Return
        `{accepted:true}`. `p_choice` must be null or `0 ≤ choice <
        jsonb_array_length(options)`.
      - `claim_duel_round_timeout(p_duel_id uuid, p_round smallint) returns
        jsonb` — participant; `now() ≤ deadline` → `too_early`; otherwise
        `_duel_resolve_round` (idempotent). Returns `{resolved:true}`.
      - `duel_heartbeat(p_duel_id uuid) returns jsonb` — `_duel_touch`. Returns
        `{serverNow, opponentSeenAgoMs}`. Throttle 1 s.
      - `leave_duel(p_duel_id uuid) returns void` — `pending` →
        `_duel_abandon(id, 'left_before_start')`; `active` → `_duel_finish(id,
        'forfeit', me)`.
      - `request_duel_rematch(p_duel_id uuid) returns jsonb` — participant;
        duel `complete`, `ended_at > now() − rematch_window`, not bot, else
        `rematch_unavailable`. Set `pN_rematch_at = now()`. If the other side's
        `rematch_at` is set → `v_new := _duel_create(p1, p2, same topic,
        'rematch', null, p_duel_id)` (propagates `already_in_duel` →
        `rematch_unavailable`) and room-send `rematch {status:'started',
        duelId:v_new}`; else room-send `rematch {status:'requested',
        requestedBy:me}`. Return `{status, duelId?}`.
      - `decline_duel_rematch(p_duel_id uuid) returns void` — room-send
        `rematch {status:'declined', by:me}`.
- [ ] **`submit_bot_duel`**: drop the 4-arg version and recreate it with
      `p_subcategory_id uuid default null` as a 5th parameter (store it on
      the row). Replace the inline `badge_duelist` block with
      `_duel_check_achievements(v_user_id)` and return its result as
      `newlyEarnedBadgeIds` (fixes defect 2). Keep the rest byte-for-byte.
      Re-grant execute.
- [ ] Revoke `execute` from `public, anon, authenticated` on every `_duel_*`
      helper. Grant `execute` to `authenticated` on every public RPC. (Guests
      are `authenticated` with `is_anonymous`, which is what Decision 4 needs.)

### Phase 6 — Sweeper + cron (`20260927120500_duel_sweeper_cron.sql`) and SQL smoke test
- [ ] `_duel_sweeper() returns void`. Each step in its own `begin … exception
      when others then raise warning …; end;` block so one failure doesn't
      stall the rest. Every query uses a partial index from Phase 1:
      1. **Pending requests past `expires_at + join_grace`** →
         `_duel_resolve_request(…,'expired','no_response',true)` →
         `_duel_promote_next_request`.
      2. **Stale creators**: open challenges with `creator_present` whose
         creator's `lobby_seen_at < now() − creator_stale_seconds` →
         `creator_present=false` (trigger broadcasts Away) +
         `_duel_clear_requests_for_challenge(…, 'creator_away')`.
      3. **Expired open challenges** (`expires_at < now()`) →
         `_duel_delete_challenge(id, 'expired')`.
      4. **Orphaned matched challenges** (duel finished/abandoned or created >
         15 min ago) → delete.
      5. **Stale queue rows**: `last_seen_at < now() − mm_stale_seconds` → delete.
      6. **No-shows**: `status='pending'` and `created_at < now() −
         ready_timeout_seconds` → `_duel_abandon(id, 'no_show')`.
      7. **Stuck rounds**: `status='active'` and the current round's `deadline
         < now() − 2 s` and unresolved → `_duel_resolve_round`.
      8. **Disconnect forfeits**: `status='active'` where exactly one side's
         `seen_at < now() − disconnect_forfeit_seconds` → `_duel_finish(id,
         'forfeit', absent)`. Both stale → `_duel_abandon(id,
         'both_disconnected')`.
      9. **Hard expiry**: live duels past `expires_at` → abandon.
      10. **Housekeeping**: delete terminal `duel_join_requests` older than 10
          minutes (and whose `retry_after` has passed), and `duel_rate_buckets`
          whose window ended more than 24 h ago.
- [ ] `select cron.schedule('duel-sweeper', '10 seconds', $$select
      public._duel_sweeper();$$);`
- [ ] **Apply** migrations 1–6 via `mcp__supabase__apply_migration` (one call
      per file, in order, with the same name as the file), **only after the
      developer has reviewed the SQL** (Q3). Then run
      `mcp__supabase__get_advisors` (security + performance) and fix anything
      the new objects triggered (e.g. RLS enabled with no policy is expected;
      mutable `search_path` warnings are not).
- [ ] **SQL smoke test** (not a file, run via `execute_sql`; each scenario in
      its own `begin; … rollback;`). Impersonate with `set local role
      authenticated; select set_config('request.jwt.claims',
      json_build_object('sub', '<uuid>', 'role', 'authenticated')::text,
      true);`. Pick two real non-guest profile ids and one guest id from
      `profiles`, and a topic with ≥5 English live questions. Scenarios:
      create → second create raises `challenge_already_open`;
      cancel → create again raises `challenge_cooldown`; guest create raises
      `guest_cannot_create`; request → pending; second requester → queued
      position 1; decline → next becomes pending; accept → `duels` row
      `pending`, 5 `duel_rounds`, both `current_duel_id` set, challenge
      `matched`; both `mark_duel_ready` → round 1 scheduled;
      `get_duel_round` before start raises `too_early` (simulate with the
      clock by checking the `starts_at` math rather than sleeping);
      `submit_duel_answer` twice raises `already_answered`; direct `select
      p1_choice from duel_rounds` as `authenticated` returns **0 rows (RLS)**;
      `leave_duel` → `status='complete'`, `end_reason='forfeit'`, players
      freed. Matchmaking: two players join the same topic with ELO 1200/1260 →
      second join returns `matched`. Two with ELO 1000/1500 → both queued (band
      100). Also `select public._duel_sweeper();` runs without error. (Note
      `realtime.send` inside a rolled-back transaction is never delivered,
      which is expected.)

### Phase 7 — Flutter domain + data layer
Freezed/json models follow existing files (`part '*.freezed.dart'; part
'*.g.dart';`, `@freezed abstract class X with _$X`). Run `dart run build_runner
build --delete-conflicting-outputs` after adding them.

- [ ] **`domain/duel_player.dart`** (replaces `duel_opponent.dart`):
      `DuelPlayer{id, String? name, @Default(false) isGuest, String? guestTag,
      avatarEmoji, elo, @Default('bronze') league, @Default(0) topicLevel,
      @Default(false) isBot}` + `eloBand` getter (moved logic). `fromJson` keys
      match the SQL `_duel_player_json` (`avatar` → `@JsonKey(name: 'avatar')
      avatarEmoji`).
- [ ] **`domain/duel_elo_band.dart`**: move the `DuelEloBand` enum +
      `DuelBotTiming` extension out of `duel_opponent.dart` unchanged. Delete
      `duel_opponent.dart` (+ generated files) and update every import (list in
      Research findings: duel api/repo/result/cubits/states/screens/tests, and
      settings' `notifications_screen.dart`, handled in Phase 12).
- [ ] **`domain/duel_topic.dart`**: `DuelTopic{id, name, emoji, plateColor,
      categoryId, categoryName, categoryEmoji, @Default(0) myTopicLevel,
      @Default(0) openChallenges, @Default(0) searching}`.
- [ ] **`domain/duel_config.dart`**: `DuelConfig` with the lobby `config`
      keys (Phase 3 `get_duel_lobby`), plus `static const fallback` holding the
      same defaults, for screens reached without a lobby snapshot (e.g.
      rejoin by deep link).
- [ ] **`domain/duel_challenge.dart`**: `DuelChallenge{id, ChallengeStatus
      status, creatorPresent, createdAt, expiresAt, creator:DuelPlayer,
      topic:DuelTopic, String? opponentName, String? opponentGuestTag, String?
      duelId}` with `enum ChallengeStatus { open, matched }` in the same file
      (house precedent: `duel_round.dart` pairs an enum with its model).
- [ ] **`domain/incoming_join_request.dart`**: `{requestId, challengeId,
      requester:DuelPlayer, expiresAt, queuedCount}`.
- [ ] **`domain/outgoing_join_request.dart`**: `{requestId, challengeId,
      JoinRequestStatus status, int? position, DateTime? expiresAt, DateTime?
      retryAfter, String? reason}` with `enum JoinRequestStatus { queued,
      pending, accepted, declined, expired, withdrawn, unavailable }`.
- [ ] **`domain/duel_lobby_snapshot.dart`**: `{serverNow, config, me:
      DuelLobbyMe, challenges, myRequests, IncomingJoinRequest? incoming}` and
      `DuelLobbyMe{player, isGuest, String? activeDuelId, String?
      openChallengeId, DateTime? cooldownEndsAt, challengesLeftToday}`.
      One public class per file, so `DuelLobbyMe` goes in
      `domain/duel_lobby_me.dart`.
- [ ] **`domain/lobby_event.dart`**: `sealed class LobbyEvent` with `final
      class`es `ChallengeUpserted(DuelChallenge)`, `ChallengeRemoved(String
      id)`, `IncomingRequestPresented(IncomingJoinRequest)`,
      `IncomingRequestCleared(String requestId, String reason)`,
      `OutgoingRequestChanged(OutgoingJoinRequest)`, `DuelStarted(String
      duelId)`, `LobbyChannelStatusChanged(bool isLive)`,
      `LobbyPresenceChanged(int count)`.
- [ ] **`domain/matchmaking_ticket.dart`**: `sealed class MatchmakingTicket` →
      `MatchmakingQueued{queuedAt, bandMin, bandMax, botAvailable, me:
      DuelPlayer, topic: DuelTopic, serverNow}` and `MatchmakingMatched{duelId}`.
- [ ] **`domain/duel_question.dart`**: `DuelQuestion{text, options, kind,
      String? mediaUrl}`. **No `correctIndex`** by construction.
- [ ] **`domain/live_duel_snapshot.dart`** (+ `live_duel_round_state.dart`,
      `live_duel_outcome.dart` if needed for one-class-per-file): mirrors
      `get_duel_state`'s perspective-mapped shape.
- [ ] **`domain/duel_room_event.dart`**: `sealed class DuelRoomEvent` →
      `RoundScheduled{round, startsAt, deadline}`, `AnswerLocked{userId,
      round, ms}`, `RoundResolved{round, outcome(p1/p2/draw), correctIndex,
      p1Choice, p2Choice, p1Ms, p2Ms, p1Rounds, p2Rounds}`, `DuelFinished{…raw
      p1/p2 results…}`, `RematchUpdate{status, String? requestedBy, String?
      duelId}`, `RoomChannelStatusChanged(bool isLive)`,
      `OpponentPresenceChanged(bool online)`. The Bloc maps p1/p2 → me/opponent
      with `mySide`.
- [ ] **`domain/duel_round.dart`**: keep `RoundOutcome`/`DuelRoundRecord`, and
      add optional `int? correctIndex, int? playerChoice, int? opponentChoice`
      (default null) so live history can show them. The bot cubit is unaffected.
- [ ] **`domain/duel_result.dart`**: rename `opponent` → `DuelPlayer opponent`,
      add `DuelPlayer me`, `String? duelId`, `@Default(true) bool isBot`,
      `DuelTopic? topic`, `@Default(true) bool isRanked`, `@Default(0) int
      xpEarned`, `@Default(DuelEndReason.completed) DuelEndReason endReason`
      with `enum DuelEndReason { completed, opponentForfeited, youForfeited }`.
- [ ] **`data/server_clock.dart`**: pure Dart.
      ```dart
      class ServerClock {
        ServerClock({DateTime Function()? localNow}) : _localNow = localNow ?? DateTime.now;
        final DateTime Function() _localNow;
        Duration _offset = Duration.zero;
        /// Call with the serverNow from any RPC response; [sentAt]/[receivedAt]
        /// are local times around that call (half the round trip is added).
        void sync(DateTime serverNow, {required DateTime sentAt, required DateTime receivedAt});
        DateTime now();                          // local + offset
        Duration until(DateTime serverInstant);  // clamped at zero
      }
      ```
      Smooth the offset: keep the sample with the smallest round trip seen in
      the last 60 s, so a slow response doesn't jerk every countdown.
- [ ] **`data/duel_broadcast.dart`**: `sealed class DuelBroadcast` →
      `BroadcastMessage{event, Map<String,dynamic> payload}`,
      `BroadcastStatus{isLive}`, `BroadcastPresence{Set<String> userIds}`.
- [ ] **`data/duel_realtime.dart`**: wraps `SupabaseClient`.
      `Stream<DuelBroadcast> watch(String topic, {required List<String>
      events, bool trackPresence = false})`. Keeps **one `RealtimeChannel` per
      topic, ref-counted** (a map of topic → `(channel, StreamController.broadcast,
      listenerCount)`). The first listen creates `client.channel(topic, opts:
      RealtimeChannelConfig(private: true, key: currentUserId))`, registers
      `onBroadcast` for each event name, `onPresenceSync` (→ `BroadcastPresence`
      from `presenceState()`), and `subscribe((status, _) => …)` (subscribed →
      `BroadcastStatus(true)`, then `track({'userId': uid})` when
      `trackPresence`; channelError/timedOut/closed → `BroadcastStatus(false)`).
      The last cancel does `client.removeChannel(channel)`. Exposes `String?
      get currentUserId`. Topic builders: `static String lobby(String lang) =>
      'duel-lobby:$lang'`, `inbox(uid) => 'duel-user:$uid'`, `room(duelId) =>
      'duel:$duelId'`. Event-name constants are listed once here to match the
      SQL.
- [ ] **`data/duel_arena_api.dart`** (`DuelArenaApi(SupabaseClient,
      DuelRealtime)`): `fetchLobby(lang)`, `fetchTopics(lang)`,
      `createChallenge(subcategoryId)`, `cancelChallenge(id)`,
      `setPresence(bool)`, `requestJoin(challengeId)`, `withdrawJoin(requestId)`,
      `respondJoin(requestId, accept)`. Each returns the decoded
      `Map<String, dynamic>` / `List` and wraps errors with `throw
      ApiException.fromSupabase(e)` (existing pattern), plus `Stream<DuelBroadcast>
      lobbyStream(lang, {presence})` and `inboxStream()`.
- [ ] **`data/duel_arena_repository.dart`**: the only place JSON → domain
      (`DuelLobbySnapshot.fromJson`, etc.). It also feeds `ServerClock.sync`
      from every response's `serverNow` (stamping `sentAt`/`receivedAt` around
      the API call) and maps `DuelBroadcast` streams → `Stream<LobbyEvent>`
      (unknown events are ignored and logged with `debugPrint` in debug only).
      `Stream<LobbyEvent> events(String lang)` merges the lobby and inbox
      streams.
- [ ] **`data/matchmaking_api.dart` / `matchmaking_repository.dart`**:
      `join(subcategoryId)`, `heartbeat()`, `leave()` → `MatchmakingTicket`
      (+ clock sync); `Stream<String> duelStarts()` from the inbox
      (`duel_start` → duelId).
- [ ] **`data/live_duel_api.dart` / `live_duel_repository.dart`**:
      `fetchState(duelId)`, `markReady`, `fetchRound(duelId, round)`,
      `submitAnswer(duelId, round, choice?, clientMs)`, `claimTimeout`,
      `heartbeat`, `leave`, `requestRematch`, `declineRematch`, plus
      `Stream<DuelRoomEvent> roomEvents(duelId)` (room topic with presence;
      presence → `OpponentPresenceChanged` by checking the opponent's id is in
      `userIds`) and `Stream<String> duelStarts()` (inbox, for rematch).
- [ ] **`data/duel_api.dart` / `duel_repository.dart`** (bot path):
      `fetchRoundQuestions({required String subcategoryId, required String
      languageCode})`: drop the `football` slug lookup and filter
      `.eq('subcategory_id', subcategoryId)`. Keep returning `Question` (the bot
      cubit needs `correctIndex` for its local sim). `fetchBotOpponent` returns
      `DuelPlayer(isBot: true, …)`. `submitBotDuel` gains `String?
      subcategoryId` → `p_subcategory_id`. Update the file's doc comment
      (no longer "no real matchmaking server").
- [ ] **`lib/app/app.dart`**: add `late final DuelRealtime _duelRealtime =
      DuelRealtime(supabase);` and `late final ServerClock _serverClock =
      ServerClock();`, provided via `RepositoryProvider<DuelRealtime>.value` /
      `RepositoryProvider<ServerClock>.value`. Extend the class doc's "why the
      RepositoryProviders" paragraph: arena, matchmaking and live duel are
      stacked routes sharing one inbox channel and one clock offset.
- [ ] Tests (Phase 7): `test/features/duel/server_clock_test.dart` (offset,
      min-RTT smoothing, `until` clamps), `duel_arena_repository_test.dart`,
      `matchmaking_repository_test.dart`, `live_duel_repository_test.dart`
      (mocktail-mocked APIs: fixture maps → domain; an `ApiException('…',
      code: 'challenge_cooldown')` propagates unchanged; broadcast fixture →
      correct sealed event), and update `duel_repository_test.dart`.

### Phase 8 — Duel Arena screen, topic picker, shell & routes
- [ ] **Routes** (`lib/core/router/app_routes.dart`): add
      `static const String duelArena = '/duel';` (doc: "S-38 — Duel arena;
      the centre FAB pushes it (plan 017)") and `static const String duelBot =
      '/duel/bot';` (doc: "The labelled bot duel (S-40 variant); `extra`:
      `BotDuelArgs`"). Remove `playLauncher`. Set `s38 = duelArena` and change
      the `kScreenIndex` S-38 entry to `ScreenRef('S-38', 'Duel arena (FAB)',
      AppRoutes.duelArena, '017', group: 'Duel')`. Update the `duelPlay` doc to
      "S-40 live duel by server id".
- [ ] **Router** (`lib/app/router.dart`, "Duel" block): replace the
      `playLauncher` GoRoute with `GoRoute(path: AppRoutes.duelArena,
      parentNavigatorKey: rootNavigatorKey, builder: (_, _) => const
      DuelArenaScreen())`. `duelMatchmaking` builder →
      `MatchmakingScreen(topic: state.extra as DuelTopic?)`. Add `duelBot`
      **before** `duelPlay` (static segments must precede `/duel/:duelId`; the
      existing file already orders `duelMatchmaking` before `duelPlay` for the
      same reason) → `DuelPlayScreen(args: state.extra as BotDuelArgs?)`.
      `duelPlay` → `LiveDuelScreen(duelId: state.pathParameters['duelId']!)`.
      `duelResult` unchanged. Remove the `play_launcher_sheet.dart` import.
      Keep `_sheetPage` (3 other users).
- [ ] **Shell**: `app_shell_screen.dart` becomes a `StatelessWidget`;
      `onPlayPressed: () => context.push(AppRoutes.duelArena)`; remove the
      sheet import and state. `app_tab_bar.dart`: remove `isPlaySheetOpen` and
      the FAB's rotate/✕ state (`_PlayFab` keeps the ⚔️ glyph, `Semantics(button:
      true, label: l10n.tabPlay)`). Update both class docs ("opens the Duel
      Arena", no sheet). Delete
      `lib/features/shell/presentation/widgets/play_launcher_sheet.dart`.
- [ ] **`DuelTopicPickerCubit`** (`bloc/duel_topic_picker_cubit.dart` +
      `_state.dart`): `DuelTopicPickerLoading | DuelTopicPickerLoaded(List<DuelTopic>)
      | DuelTopicPickerFailed(ApiException)`. `load(lang)` / `retry()`.
- [ ] **`widgets/duel_topic_picker_sheet.dart`**: `static Future<DuelTopic?>
      show(BuildContext context, {required DuelTopicPurpose purpose})` →
      `AppBottomSheet.show` with its own `BlocProvider<DuelTopicPickerCubit>`
      (repository built from `context.read<DuelRealtime>()` + `supabase` +
      `context.read<ServerClock>()`, language from
      `context.read<ContentLanguageCubit>().state.code`). Body: an exhaustive
      `switch` on state. Loaded → grouped `ListView` with `SectionHeader` per
      category + `DuelTopicRow` (new widget). Empty list → empty copy.
      `enum DuelTopicPurpose { create, matchmake }` selects title copy.
- [ ] **`DuelArenaBloc`** (`bloc/duel_arena_bloc.dart`, `_event.dart`,
      `_state.dart`), constructor `(DuelArenaRepository, ServerClock, {required
      String languageCode})`:
      - **Events** (`sealed class DuelArenaEvent`): `ArenaOpened`,
        `ArenaVisibilityChanged(bool visible)`, `ArenaServerEvent(LobbyEvent)`,
        `ArenaTicked`, `ArenaRetryRequested`, `ChallengeCreateRequested(DuelTopic)`,
        `ChallengeCancelRequested`, `JoinRequested(String challengeId)`,
        `JoinWithdrawn(String challengeId)`, `IncomingAccepted`,
        `IncomingDeclined`, `IncomingTimedOut`, `NoticeConsumed`.
      - **States** (`sealed class DuelArenaState`): `DuelArenaLoading`,
        `DuelArenaFailed(ApiException)`, `DuelArenaReady{config, me,
        List<DuelChallenge> challenges (created_at asc), Map<String,
        OutgoingJoinRequest> outgoing (by challengeId), IncomingJoinRequest?
        incoming, int onlineCount, bool isLive, DateTime now (server time),
        bool isBusy (create/cancel/respond in flight), ArenaNotice? notice,
        int noticeSeq, String? startDuelId, String? activeDuelId}`.
        `ArenaNotice` is a `sealed class` in `bloc/arena_notice.dart` (or inside
        the state `part` file if it stays private to the Bloc): `CooldownNotice(Duration)`,
        `AlreadyOpenNotice`, `DailyCapNotice`, `TooManyRequestsNotice`,
        `RateLimitedNotice`, `CreatorAwayNotice(String name)`,
        `ChallengeGoneNotice`, `DeclinedNotice(name)`, `NoResponseNotice(name)`,
        `TakenByOtherNotice(name)`, `RequesterBusyNotice(name)`,
        `OpponentNoShowNotice`, `TopicUnavailableNotice`, `SignInRequiredNotice`,
        `GenericErrorNotice(ApiException)`.
      - **Behaviour**:
        - `ArenaOpened`: `fetchLobby` → Ready (or Failed), subscribe
          `repository.events(lang)` → `add(ArenaServerEvent)`, start a 1 s
          `Timer.periodic` → `ArenaTicked`, and a heartbeat timer at
          `config.lobbyHeartbeatSeconds` that calls `setPresence(true)` only
          while visible **and** (has an open challenge or any outgoing
          queued/pending request) (A10). Call `setPresence(true)` once on open.
        - `ArenaVisibilityChanged(false)` → `setPresence(false)`, clear local
          outgoing entries, pause the heartbeat. `(true)` → `setPresence(true)`
          + refetch the snapshot.
        - `ArenaServerEvent`: upsert/remove cards (max `lobby_feed_limit`,
          drop the oldest). Incoming presented → `incoming` + haptic flag.
          Cleared → null. Outgoing changed → update the map and emit notices
          for declined/expired/withdrawn reasons (`'taken'` →
          TakenByOtherNotice, `'creator_away'` → CreatorAwayNotice,
          `'challenge_gone'`/`'expired'` → ChallengeGoneNotice).
          `DuelStarted(duelId)` → `startDuelId = duelId`.
          `LobbyChannelStatusChanged(true)` after `false` → refetch the
          snapshot (self-heal).
        - `ArenaTicked`: `now = clock.now()`. Drop open cards past `expiresAt`
          (server deletes too). Drop terminal outgoing entries past
          `retryAfter`. If `incoming` has passed `expiresAt` → dispatch
          `IncomingTimedOut` once.
        - `ChallengeCreateRequested`: guest → `SignInRequiredNotice` (no RPC);
          else `createChallenge`. On error, map `code`
          (`challenge_cooldown`/`challenge_already_open`/`challenge_daily_cap`/
          `topic_unavailable`/`guest_cannot_create`/`already_in_duel`) → notice.
        - `JoinRequested`: optimistic `queued` entry → `requestJoin` → replace
          with the server status; on error, remove the entry and map the notice
          (`retry_later`, `too_many_requests`, `rate_limited`, `creator_away`,
          `challenge_unavailable`, `challenge_busy`, `already_in_duel`).
        - `IncomingAccepted` → `respondJoin(true)` → `startDuelId`. On
          `requester_busy`/`request_expired`, notice + clear the incoming
          request (the server presents the next). `IncomingDeclined` /
          `IncomingTimedOut` → `respondJoin(false)` (ignore
          `request_expired`).
        - `close()`: cancel timers/subscriptions, fire-and-forget
          `setPresence(false)`.
      - Derived getters on `DuelArenaReady` (pure, unit-tested):
        `cardStateFor(DuelChallenge)` → `ChallengeCardState` (sealed: `Open`,
        `Queued(position)`, `Pending(expiresAt)`, `Cooling(retryAt)`, `Away`,
        `InProgress(opponentLabel)`, `Own(paused)`), `fairnessFor(challenge)`
        (enum `Fairness { even, tough, favourable }` by the thresholds in
        Design), `composerState` (sealed: `ComposerCreate`,
        `ComposerCooldown(until)`, `ComposerOwnOpen(challenge)`,
        `ComposerSignIn`, `ComposerInDuel(duelId)`).
- [ ] **`screens/duel_arena_screen.dart`**: `StatelessWidget` providing
      `BlocProvider<DuelArenaBloc>(create: … ..add(const ArenaOpened()))`,
      child `_DuelArenaView`, a `StatefulWidget` **only** to host `RouteAware`
      (`appRouteObserver.subscribe`) and `WidgetsBindingObserver` (app
      lifecycle). These dispatch `ArenaVisibilityChanged` on
      `didPushNext`/`didPopNext`/`paused`/`hidden`/`resumed` (ephemeral UI
      plumbing, not business state). Layout: `AnnotatedRegion` light status
      bar, `DecoratedBox(gradient: arena.lite)`, `SafeArea`, then `Column[ArenaTopBar,
      QuickMatchCard, Expanded(body), ChallengeComposerBar]`, with body = exhaustive
      `switch` over `DuelArenaState`. `BlocListener` handles: `startDuelId`
      change → `context.push(AppRoutes.duelPlayPath(id))`; `noticeSeq`
      change → `AppSnackbar.show(…)` + `NoticeConsumed`; an incoming request
      appearing → `HapticFeedback.mediumImpact()` if
      `SettingsRepository`'s haptics preference is on (read via
      `context.read<SettingsRepository>()`; check its current API).
      Quick match tap → `DuelTopicPickerSheet.show(purpose: matchmake)` →
      `context.push(AppRoutes.duelMatchmaking, extra: topic)`. Create tap →
      picker (create) → `ChallengeCreateRequested`. Guest "Sign in" →
      `context.push(AppRoutes.saveProgress)`.
- [ ] Widgets (each its own file, `const` constructors, all sizes via
      screenutil, colors from `context.arena` / `context.quizoo`):
      `arena_top_bar.dart` (✕ = `context.pop()`, title, presence pill /
      "Reconnecting…" chip), `quick_match_card.dart`, `challenge_feed.dart`
      (stateful only for scroll-anchor + "N new" pill counting; uses
      `ListView.builder(reverse: true)` over the reversed list; new-arrival
      entry animation via `flutter_animate` keyed by challenge id and only
      for ids not in the initial snapshot; empty/skeleton variants),
      `challenge_card.dart` (renders a `DuelChallenge` + `ChallengeCardState`
      + `Fairness` + `DateTime now`; callbacks `onJoin`, `onWithdraw`,
      `onCancel`; guest names via `l10n.duelGuestName(tag)`; own cards
      end-aligned), `challenge_countdown_ring.dart` (`CustomPaint` ring,
      colour by remaining fraction), `challenge_composer_bar.dart`,
      `incoming_request_banner.dart` (`AnimatedSwitcher` slide-down; progress
      bar driven by `now` vs `expiresAt`; Decline `ChunkyButton.line`, Accept
      `ChunkyButton.success`), `rejoin_duel_banner.dart`, `duel_topic_row.dart`.
- [ ] **New arena tokens** in `lib/core/theme/arena_colors.dart` (Design
      overview list).
- [ ] Tests (Phase 8): `duel_arena_bloc_test.dart` — initial `DuelArenaLoading`;
      open → Ready (success); open → Failed (failure); challenge
      upsert/remove events; create → cooldown notice on `challenge_cooldown`;
      guest create → `SignInRequiredNotice` with no RPC; join → queued →
      server pending event → declined event → `Cooling` then `Open` after
      `retryAfter` (fake_async); incoming presented → accept → `startDuelId`;
      incoming timeout → `respondJoin(false)` called once; visibility false →
      `setPresence(false)`; channel re-live → snapshot refetched. Also
      `duel_topic_picker_cubit_test.dart` (initial, loaded, failed),
      `duel_arena_screen_test.dart` (one test per state: loading skeleton,
      failed + retry, empty feed, loaded with open/away/in-progress/own
      cards, incoming banner visible) using bounded `pump()` (live ticker), and
      `challenge_card_test.dart` (each `ChallengeCardState` renders its label/
      button). Replace `test/features/shell/play_launcher_sheet_test.dart` with
      `test/features/shell/app_shell_screen_test.dart` ("tapping the FAB
      pushes `AppRoutes.duelArena`"). Update `test/support/pump_screen.dart`
      to accept/provide `DuelRealtime` (a mocktail fake) and `ServerClock`.

### Phase 9 — Matchmaking rewrite + bot fallback
- [ ] **`MatchmakingCubit`** (rewrite), constructor `(MatchmakingRepository,
      DuelRepository botRepository, ServerClock, {required DuelTopic topic})`:
      - States (`sealed class MatchmakingState`): `MatchmakingJoining`,
        `MatchmakingSearching{me, topic, elapsedSeconds, bandMin, bandMax,
        secondsToNextWiden, botAvailable}`, `MatchmakingFound{duelId}`,
        `MatchmakingBotReady{me, opponent (DuelPlayer isBot), topic}`,
        `MatchmakingFailed(ApiException)`.
      - `start()`: `join(topic.id)` → Matched → Found, or Queued → Searching.
        Start a 1 s ticker (elapsed from `queuedAt` via ServerClock; widen
        countdown from `bandStepSeconds`), a heartbeat every `mmHeartbeatSeconds`
        (updates band/botAvailable, or → Found), and subscribe to
        `duelStarts()` (→ Found immediately, beating the next heartbeat).
        Heartbeat errors: `not_in_queue` → re-join once; network → keep
        searching (retry on the next tick).
      - `playBot()`: `leave()` then `botRepository.fetchBotOpponent(playerElo:
        me.elo)` → BotReady. Also keep the existing "stays searching on
        ApiException" behaviour.
      - `keepSearching()`: hides the bot offer for another
        `botAfterSeconds` (local UI flag in state: `botOfferDismissedAt`).
      - `cancel()` / `close()`: stop timers, `leave()` (fire-and-forget in
        `close`).
- [ ] **`screens/matchmaking_screen.dart`** (rewrite): `MatchmakingScreen({DuelTopic?
      topic})`. If `topic == null` (design-review deep link), show the picker
      post-frame and pop on cancel. `BlocConsumer`: Found →
      `context.pushReplacement(AppRoutes.duelPlayPath(id))`; BotReady →
      `context.pushReplacement(AppRoutes.duelBot, extra: BotDuelArgs(me,
      opponent, topic))`. Builder: exhaustive switch. Searching → existing
      layout with a real `me` avatar/ELO (remove `_playerElo` and `MockPlayer`),
      a topic chip, `l10n.duelSearchingBand(min, max)`, and
      `MatchmakingBotOffer` when `botAvailable`. ✕ (top-left, `arena.chrome`) →
      `cancel()` + `context.pop()`.
- [ ] `widgets/matchmaking_bot_offer.dart`.
- [ ] Tests: rewrite `matchmaking_cubit_test.dart` — initial `Joining`; join →
      Searching (success); join throws → Failed (failure); heartbeat returns
      matched → Found; `duelStarts` event → Found; at 30 s `botAvailable`;
      `playBot` → BotReady with `isBot: true`; `close` calls `leave`.
      `matchmaking_screen_test.dart`: one test per state branch.

### Phase 10 — Live duel play (+ bot screen refactor)
- [ ] **`widgets/duel_round_view.dart`**: extract `_RoundView` from
      `duel_play_screen.dart` into a public, prop-driven `DuelRoundView({me,
      opponent, myScore, opponentScore, roundNumber, totalRounds, DuelQuestion?
      question, secondsRemaining, secondsTotal, int? myChoice, int? mySeconds,
      bool opponentLocked, int? opponentSeconds, bool isRevealed, int?
      correctIndex, int? opponentChoice, bool opponentOnline = true, int?
      opponentReconnectSeconds, ValueChanged<int>? onAnswer, VoidCallback?
      onQuit})`. Answer-option state logic moves here unchanged (hourglass
      before reveal; correct/wrong after). When `question == null` show a
      compact "Get ready…" placeholder in the question card (fetch in flight).
      Keep using `quiz_play`'s `TimerRing` exactly as today (existing
      cross-feature import; moving it to `core/widgets` is a separate cleanup,
      noted in Risks).
- [ ] **`widgets/match_intro_view.dart`**: VS intro (Design §4).
- [ ] **`LiveDuelBloc`** (`bloc/live_duel_bloc.dart`, `_event.dart`,
      `_state.dart`), constructor `(LiveDuelRepository, ServerClock, {required
      String duelId})`:
      - Events (`sealed class LiveDuelEvent`): `LiveDuelStarted`,
        `LiveDuelServerEvent(DuelRoomEvent)`, `LiveDuelTicked`,
        `LiveDuelAnswerSelected(int index)`, `LiveDuelQuitConfirmed`,
        `LiveDuelResumed` (app resumed → refetch).
      - States (`sealed class LiveDuelState`): `LiveDuelConnecting`,
        `LiveDuelIntro{me, opponent, topic, isRanked, DateTime? startsAt,
        now}`, `LiveDuelRound{me, opponent, topic, isRanked, roundNumber,
        totalRounds, DuelQuestion? question, secondsRemaining, secondsTotal,
        int? myChoice, int? mySeconds, bool myLocked, bool opponentLocked,
        int? opponentSeconds, bool isRevealed, int? correctIndex, int?
        opponentChoice, myScore, opponentScore, List<DuelRoundRecord> history,
        bool opponentOnline, DateTime? opponentOfflineSince, DateTime?
        nextRoundAt}`, `LiveDuelEnded(DuelResult)`,
        `LiveDuelAbandoned(String cause)`, `LiveDuelFailed(ApiException)`.
      - **Withheld-correctness invariant** (same discipline as `DuelPlayCubit`):
        `correctIndex` and `opponentChoice` are null on every `LiveDuelRound`
        emitted before the matching `RoundResolved` event. Here it's
        guaranteed by the server (the data isn't on the client before reveal),
        and the state mirrors it.
      - Flow: `LiveDuelStarted` → `fetchState` (sync clock) → subscribe
        `roomEvents` → `markReady` → Intro or Round per snapshot (resume-safe).
        A 100 ms ticker → `LiveDuelTicked`. When `clock.now() ≥ startsAt −
        300 ms` and `question == null` and not fetching → `fetchRound` (retry
        on `too_early` after 250 ms; on `round_closed` just wait for
        `RoundResolved`). Start a `Stopwatch` when the question arrives.
        `secondsRemaining = roundSeconds − stopwatch.elapsed`. At 0 without an
        answer → `submitAnswer(choice: null, clientMs: roundMs)`. At local
        `deadline + 1 s` without `RoundResolved` → `claimTimeout` (retry on
        `too_early`). Heartbeat every `duelHeartbeatSeconds`.
      - `LiveDuelAnswerSelected`: ignore if locked or no question; lock locally
        (`myChoice`, `mySeconds`), then `submitAnswer(choice, stopwatch ms)`,
        retrying twice on network error while before the deadline.
        `already_answered` / `round_closed` are ignored.
      - `AnswerLocked` for the opponent id → `opponentLocked`,
        `opponentSeconds`. `RoundResolved` → reveal fields + history append +
        scores; `nextRoundAt` is set by the following `RoundScheduled`
        (question cleared, fetched again at its start). `DuelFinished` →
        build `DuelResult` (me/opponent perspective, `isBot:false`, `topic`,
        `isRanked`, `endReason`) → `LiveDuelEnded`. `abandoned` →
        `LiveDuelAbandoned(cause)`. `RoomChannelStatusChanged(true)` after a
        drop, or `LiveDuelResumed` → refetch the state and reconcile.
        `OpponentPresenceChanged` → `opponentOnline` + since.
      - `LiveDuelQuitConfirmed` → `leave()`; the resulting `duel_end` drives
        `LiveDuelEnded` (youForfeited).
- [ ] **`screens/live_duel_screen.dart`**: `LiveDuelScreen({required String
      duelId})`. `BlocProvider<LiveDuelBloc>`, `WidgetsBindingObserver` for
      `LiveDuelResumed`, `PopScope(canPop: false)` routing back-gestures to the
      quit dialog. `BlocConsumer`: Ended →
      `context.pushReplacement(AppRoutes.duelResultPath(duelId), extra:
      result)`; Abandoned → `AppSnackbar` (`OpponentNoShow` copy) +
      `context.pop()`. Builder: exhaustive switch → spinner / `MatchIntroView` /
      `DuelRoundView` / spinner / spinner / `_DuelError` (reuse the existing
      error layout).
- [ ] **Bot screen refactor** (`screens/duel_play_screen.dart`): rename
      `DuelPlayArgs` → `BotDuelArgs{me: DuelPlayer, opponent: DuelPlayer,
      topic: DuelTopic}`. The screen takes `BotDuelArgs? args`. With null args
      (design-review), build the existing review bot with a fallback `me`
      from `DuelPlayer(id:'me', name:null, avatarEmoji:'🐼', elo:1200)` and
      no topic → show `ErrorStateView`, since there's no topic to draw
      questions from. **Remove `MockPlayer` and `_playerElo`.** Render with
      `DuelRoundView`. `DuelPlayCubit.start(opponent, me:, topic:,
      languageCode:)` → `fetchRoundQuestions(subcategoryId: topic.id, …)`.
      `DuelPlayRound` swaps `Question question` → `DuelQuestion question` +
      `int? revealedCorrectIndex` (set only when `isRevealed`), keeping the
      correct index private in the cubit, the same way it already keeps the
      opponent's choice private. `_finish` passes `subcategoryId` and builds
      `DuelResult(me:, opponent:, isBot:true, topic:, …)`. `_playerBaseElo`
      fallback → `me.elo`. Its route is now `AppRoutes.duelBot`.
- [ ] Tests: `live_duel_bloc_test.dart` — initial `LiveDuelConnecting`;
      fetchState(pending) → Intro (success); fetchState throws → Failed
      (failure); `RoundScheduled` + tick past start → `fetchRound` called →
      Round with a question; answer → `myLocked` and `submitAnswer` args
      (clientMs from a fake clock); `AnswerLocked(opponent)` →
      `opponentLocked`; **invariant test**: collect every emitted state and
      assert `correctIndex == null && opponentChoice == null` on all states
      before `RoundResolved` (memory note: collect states, don't sample one
      instant); `RoundResolved` → revealed + score; `DuelFinished` → Ended with
      the right perspective; channel drop → refetch; quit → `leave` called.
      Update `duel_play_cubit_test.dart` for `DuelPlayer`/`DuelQuestion`/topic
      and add `revealedCorrectIndex == null` to its existing withheld-correctness
      test. `live_duel_screen_test.dart`: one test per state branch
      (bounded `pump()`).

### Phase 11 — Result screen & rematch
- [ ] **`DuelRematchCubit`** (`bloc/duel_rematch_cubit.dart` + `_state.dart`),
      constructor `(LiveDuelRepository, {required String duelId, required
      DuelPlayer opponent, required Duration window})`: states
      `RematchIdle`, `RematchWaiting`, `RematchOffered`,
      `RematchStarting(String duelId)`, `RematchUnavailable`. Subscribes to
      `roomEvents(duelId)` (`RematchUpdate`) and `duelStarts()`. A window timer
      → Unavailable. `request()`, `accept()` (= `request()`), and
      `close()` → `declineRematch` fire-and-forget unless Starting.
- [ ] **`screens/duel_result_screen.dart`**: read `me`/`opponent` avatars
      from the result (remove the hardcoded fallback avatar where it's a
      mock). Add the unranked note and forfeit caption. If `!result.isBot &&
      result.duelId != null`, provide `DuelRematchCubit` and render
      `RematchActions` (a new widget, the primary button state per cubit state;
      a `BlocListener` on Starting → `context.pushReplacement(duelPlayPath)`).
      Bot result → Rematch = new bot (`fetchBotOpponent`) →
      `pushReplacement(AppRoutes.duelBot, extra: BotDuelArgs(…same topic…))`.
      "Find a new opponent" → `pushReplacement(AppRoutes.duelMatchmaking,
      extra: result.topic)` (picker if the topic is null). ✕ → `context.canPop()
      ? context.pop() : context.go(AppRoutes.home)`. The `_fallback`
      design-review result gets `me`/`opponent` `DuelPlayer`s.
- [ ] Tests: `duel_rematch_cubit_test.dart` (initial Idle; request → Waiting;
      offered event → Offered; started → Starting; request throws
      `rematch_unavailable` → Unavailable; window expiry → Unavailable). Add
      result-screen widget tests for victory/defeat/unranked/forfeit captions
      and rematch button states.

### Phase 12 — Cleanup, l10n, cross-feature fix, final verification
- [ ] **`features/settings/presentation/screens/notifications_screen.dart`**:
      replace the fake-opponent block (L47-58) with
      `context.read<NotificationsCubit>().acceptChallenge(notification.id);
      context.push(AppRoutes.duelArena);`. Remove the two duel imports. (Flagged
      §10 exception: required because the duel internals it imported no longer
      exist.)
- [ ] **l10n** — add to `lib/l10n/app_en.arb` (with `@key` descriptions,
      placeholders typed like existing duel keys), then run
      `flutter gen-l10n` (or let `flutter pub get` / the build regenerate) so
      `untranslated_messages.json` records the Urdu gap. Add Urdu to
      `app_ur.arb` only if the translator is available; otherwise leave the
      tracked gap, which is the file's stated purpose. Keys (English):
      - Arena: `duelArenaTitle` "Duel Arena"; `duelArenaOnline` "{count} in the
        arena"; `duelArenaReconnecting` "Reconnecting…"; `duelArenaCloseLabel`
        "Close arena"; `duelQuickMatchTitle` "Quick match";
        `duelQuickMatchBody` "Auto-paired with a player near your level";
        `duelQuickMatchCta` "Find match"; `duelLiveChallengesHeader` "Live
        challenges"; `duelFeedEmptyTitle` "No live challenges yet";
        `duelFeedEmptyBody` "Throw down the first one — players in the same
        topic see it instantly."; `duelFeedNewPill` "{count, plural, =1{1 new
        challenge} other{{count} new challenges}}"; `duelRejoinTitle` "You
        have a duel in progress"; `duelRejoinCta` "Rejoin".
      - Card: `duelCardReward` "{rounds} rounds · winner +{coins} 🪙";
        `duelCardJoin` "Join"; `duelCardQueued` "Request sent · {ahead} ahead";
        `duelCardSent` "Request sent"; `duelCardDeciding` "{name} is
        deciding…"; `duelCardNotThisTime` "Not this time"; `duelCardRetryIn`
        "Try again in {seconds}s"; `duelCardAway` "Away"; `duelCardLive`
        "LIVE"; `duelCardInProgress` "In progress · vs {name}";
        `duelCardYours` "Your challenge"; `duelCardWaiting` "Waiting for a
        challenger…"; `duelCardPaused` "Paused while you're away";
        `duelCardCancel` "Cancel"; `duelFairnessEven` "Even match";
        `duelFairnessTough` "Tough one"; `duelFairnessFavourable` "Favourable";
        `duelGuestName` "Guest {tag}"; `duelTopicLevel` "Lv {level}";
        `duelCardSemantics` "Challenge from {name}, {league}, {elo} ELO,
        {topic}, {time} left".
      - Composer: `duelComposerCreate` "Create challenge";
        `duelComposerCooldown` "New challenge in {time}"; `duelComposerOpen`
        "Your {topic} challenge · {time} left"; `duelComposerSignIn` "Sign in
        to create challenges"; `duelComposerInDuel` "You're in a duel".
      - Incoming: `duelIncomingTitle` "{name} wants to duel!";
        `duelIncomingMeta` "{league} · {elo} ELO · {topic} Lv {level}";
        `duelIncomingAccept` "Accept"; `duelIncomingDecline` "Decline";
        `duelIncomingMore` "+{count} waiting".
      - Picker: `duelPickerTitleCreate` "Pick your battleground";
        `duelPickerTitleMatch` "Match in which topic?"; `duelPickerBody` "You'll
        only face players in the same topic."; `duelPickerSearching` "{count}
        searching"; `duelPickerOpen` "{count} open"; `duelPickerEmpty` "No duel
        topics in this language yet."
      - Notices: `duelNoticeCooldown` "You can create another challenge in
        {time}"; `duelNoticeAlreadyOpen` "You already have a live challenge";
        `duelNoticeDailyCap` "Daily challenge limit reached — try Quick match";
        `duelNoticeTooManyRequests` "You can wait on up to {max} challenges at
        once"; `duelNoticeRateLimited` "Slow down a little — try again in a
        moment"; `duelNoticeCreatorAway` "{name} stepped away";
        `duelNoticeChallengeGone` "That challenge is no longer available";
        `duelNoticeDeclined` "{name} passed this time";
        `duelNoticeNoResponse` "No answer from {name}";
        `duelNoticeTakenByOther` "{name} started a duel with someone else";
        `duelNoticeRequesterBusy` "{name} just started another duel";
        `duelNoticeOpponentNoShow` "Your opponent didn't show up";
        `duelNoticeTopicUnavailable` "That topic isn't available for duels
        right now"; `duelNoticeGeneric` "Something went wrong — please try
        again".
      - Matchmaking: `duelSearchingBand` "Searching… {min} – {max} ELO";
        `duelBotOfferTitle` "No one's around in {topic} right now";
        `duelBotOfferBody` "Play a practice bot — clearly labelled, results
        count at half ELO."; `duelBotOfferPlay` "🤖 Play a bot";
        `duelKeepSearching` "Keep searching"; `duelBotBadge` "BOT".
      - Live: `duelIntroRanked` "Ranked"; `duelIntroUnranked` "Unranked";
        `duelIntroStartsIn` "Starting in {seconds}"; `duelWaitingFor` "Waiting
        for {name}…"; `duelGetReady` "Get ready…"; `duelOpponentReconnecting`
        "{name} reconnecting… {seconds}s"; `duelQuitTitle` "Leave the duel?";
        `duelQuitBody` "Leaving forfeits the remaining rounds.";
        `duelQuitConfirm` "Leave"; `duelQuitStay` "Stay".
      - Result: `duelResultUnranked` "Unranked — you've played {name} {count}
        times today"; `duelResultOpponentForfeit` "{name} left — the remaining
        rounds are yours"; `duelResultYouForfeited` "You left the duel";
        `duelRematchWaiting` "Waiting for {name}…"; `duelRematchOffered`
        "{name} wants a rematch!"; `duelRematchAccept` "Accept rematch";
        `duelRematchUnavailable` "{name} has left".
      - **Remove** the now-unused keys: all `playSheet*` (12 keys listed in
        Research findings) and `duelCancelPlayBot` (only if no longer
        referenced after Phase 9), from both `.arb` files.
- [ ] Delete `lib/features/duel/domain/duel_opponent*.dart` (+ generated),
      `lib/features/shell/presentation/widgets/play_launcher_sheet.dart`,
      `test/features/shell/play_launcher_sheet_test.dart`.
- [ ] Update `MOCKED_FEATURES.md`'s `duel` section: the four rows are fixed
      (strike through, "Fixed by plan 017").
- [ ] `dart run build_runner build --delete-conflicting-outputs`,
      `dart format .`, `dart analyze` (**zero warnings**), `flutter test`
      (all green). No `// ignore:` added.
- [ ] Final summary ends with the **To verify:** list from Acceptance
      criteria's manual section.

## Data model / API changes

**New tables:** `duel_challenges`, `duel_join_requests`, `duel_player_state`,
`duel_rate_buckets`, `duel_rounds` (all RLS-enabled, no client policies).
**Altered:** `duels` (+ subcategory/language/origin/challenge/rematch/ranked/
round/ready/seen/rematch/end/payout columns; status check widened),
`matchmaking_queue` (+ subcategory/language/topic_level/last_seen_at).
**Dropped policies:** `duels_update_participant_active`,
`matchmaking_queue_insert_self`, `matchmaking_queue_delete_self`.
**New `realtime.messages` policies:** `duel_lobby_receive`,
`duel_lobby_presence`, `duel_inbox_receive`, `duel_room_receive`,
`duel_room_presence`.
**New config:** `app_settings.duel_config` (jsonb).
**New cron job:** `duel-sweeper` (`10 seconds`).
**Dropped functions:** `submit_duel_answer(uuid,smallint,smallint,integer)`,
`resolve_duel_round(uuid,smallint)`, `resolve_duel(uuid)`.
**Changed function:** `submit_bot_duel(+ p_subcategory_id uuid default null)`.

**Public RPCs (all `authenticated`):**

| RPC | Args | Returns | Raised identifiers |
|---|---|---|---|
| `get_duel_lobby` | `p_language_code text` | lobby snapshot | `not_authenticated` |
| `list_duel_topics` | `p_language_code text` | topic[] | — |
| `create_duel_challenge` | `p_subcategory_id uuid` | `{challenge, cooldownEndsAt, serverNow}` | `guest_cannot_create, already_in_duel, challenge_already_open, challenge_cooldown, challenge_daily_cap, topic_unavailable` |
| `cancel_duel_challenge` | `p_challenge_id uuid` | void | `challenge_not_found` |
| `set_duel_lobby_presence` | `p_present boolean` | `{serverNow}` | — |
| `request_duel_join` | `p_challenge_id uuid` | request status | `challenge_unavailable, own_challenge, creator_away, already_in_duel, already_requested, retry_later, too_many_requests, rate_limited, challenge_busy` |
| `withdraw_duel_join` | `p_request_id uuid` | void | `request_not_found` |
| `respond_duel_join` | `p_request_id uuid, p_accept boolean` | `{accepted, duelId?}` | `request_not_found, request_expired, requester_busy, already_in_duel, topic_unavailable` |
| `join_matchmaking` | `p_subcategory_id uuid` | ticket | `already_in_duel, topic_unavailable, rate_limited` |
| `matchmaking_heartbeat` | — | ticket | `not_in_queue` |
| `leave_matchmaking` | — | void | — |
| `get_duel_state` | `p_duel_id uuid` | perspective snapshot | `duel_not_found, not_a_participant` |
| `mark_duel_ready` | `p_duel_id uuid` | `{serverNow, status}` | same |
| `get_duel_round` | `p_duel_id uuid, p_round smallint` | round question | `round_closed, too_early` |
| `submit_duel_answer` | `p_duel_id uuid, p_round smallint, p_choice smallint, p_client_ms integer` | `{accepted}` | `already_answered, round_closed, invalid_choice` |
| `claim_duel_round_timeout` | `p_duel_id uuid, p_round smallint` | `{resolved}` | `too_early` |
| `duel_heartbeat` | `p_duel_id uuid` | `{serverNow, opponentSeenAgoMs}` | — |
| `leave_duel` | `p_duel_id uuid` | void | — |
| `request_duel_rematch` | `p_duel_id uuid` | `{status, duelId?}` | `rematch_unavailable` |
| `decline_duel_rematch` | `p_duel_id uuid` | void | — |

**Broadcast events** (all `private` channels; payload always includes `serverNow`):

| Topic | Event | Payload |
|---|---|---|
| `duel-lobby:<lang>` | `challenge_upsert` | challenge card |
| | `challenge_remove` | `{id}` |
| | (presence) | `{userId}` tracked by each viewer |
| `duel-user:<uid>` | `join_request` | `{requestId, challengeId, requester, expiresAt, queuedCount}` (to creator) |
| | `join_request_cleared` | `{requestId, reason}` (to creator) |
| | `join_request_status` | `{requestId, challengeId, status, position?, expiresAt?, retryAfter?, reason?}` (to requester) |
| | `duel_start` | `{duelId, origin}` |
| `duel:<duelId>` | `round_start` | `{round, startsAt, deadline, roundSeconds, totalRounds}` |
| | `answer_locked` | `{userId, round, ms}` |
| | `round_result` | `{round, outcome, correctIndex, p1Choice, p2Choice, p1Ms, p2Ms, p1Rounds, p2Rounds}` |
| | `duel_end` | `{reason, cause?, winnerId, isRanked, forfeitedBy, p1Rounds, p2Rounds, p1AvgMs, p2AvgMs, p1:{eloBefore, eloAfter, coins, xp, badgeIds}, p2:{…}}` |
| | `rematch` | `{status: requested|declined|started, requestedBy?, duelId?}` |
| | (presence) | `{userId}` |

**Routes:** add `AppRoutes.duelArena = '/duel'`, `AppRoutes.duelBot =
'/duel/bot'`. Remove `AppRoutes.playLauncher`. `duelPlay` now means "live duel
by id".

## Dependencies

N/A — no new packages. Everything uses `supabase_flutter` (Realtime is part of
it), `flutter_bloc`, `freezed`, `flutter_animate`, `flutter_screenutil`, and the
dev deps `bloc_test` / `mocktail` / `fake_async` already in `pubspec.yaml`. No
Edge Functions and no new Postgres extensions (`pg_cron` is already installed;
`realtime.send` is built in).

## Testing strategy

- **Unit (pure Dart):** `ServerClock`; `DuelArenaReady` derived getters
  (`cardStateFor`, `fairnessFor`, `composerState`); `DuelPlayer.eloBand`.
- **Repository tests** (`mocktail` mocks of `DuelArenaApi` / `MatchmakingApi`
  / `LiveDuelApi` / `DuelApi`): fixture JSON (copy exact shapes from the SQL
  contracts above) → domain; each surfaces an `ApiException` with the raised
  identifier in `.code`; broadcast fixtures → the right sealed event, unknown
  event ignored; `ServerClock.sync` called with `serverNow`.
- **`bloc_test`** for `DuelArenaBloc`, `DuelTopicPickerCubit`,
  `MatchmakingCubit`, `LiveDuelBloc`, `DuelRematchCubit`, and updated
  `DuelPlayCubit`. Each covers initial state, at least one success and one
  failure path, plus the behaviour lists in Phases 8–11. Timers use
  `fake_async`. Repository streams are `StreamController`s the test pushes
  into.
- **Widget tests** via `tester.pumpScreen`: `DuelArenaScreen`,
  `MatchmakingScreen` and `LiveDuelScreen` (one test per sealed branch),
  `ChallengeCard` (each card state), `DuelResultScreen` (captions, rematch
  states), and shell FAB → arena. Use bounded `await tester.pump()` for
  screens with live tickers (memory: `pumpAndSettle` runs periodic timers to
  completion). Loading branches must animate (skeleton/spinner), per the same
  memory note.
- **Backend:** the Phase 6 SQL smoke scenarios through `execute_sql` inside
  rolled-back transactions, plus `get_advisors` after applying.
- **Not run:** the app itself (CLAUDE.md §13). Realtime delivery and
  two-device timing are verified manually by the developer (see "To verify").

## Edge cases & error handling

- **Double-tap create / race between two creates**: the cool-off is written
  in the same transaction, and the partial unique index
  `duel_challenges_one_open_per_creator` is the last line of defence
  (surfaces as `23505` → treat as `challenge_already_open`).
- **Two creators accept the same requester simultaneously**: both lock the
  requester's `duel_player_state`. The second sees `current_duel_id` and gets
  `requester_busy`, and its queue auto-advances.
- **Requester's pending request accepted while they're mid-matchmaking**:
  `join_matchmaking` withdrew their requests, so the accept fails cleanly.
  Likewise, being paired in matchmaking withdraws all outgoing requests and
  cancels the player's own open challenge.
- **Creator leaves the arena with a request on screen**: presence false →
  pending expires with `creator_away`, queued requesters are notified, and the
  card shows Away.
- **App killed with an open challenge**: heartbeats stop → the sweeper marks
  Away within ~25–35 s → it expires and is deleted at 5 min.
- **App killed mid-duel**: 30 s later the sweeper forfeits the remaining
  rounds. On relaunch, `get_duel_lobby.me.activeDuelId` is null (duel over) or,
  if within 30 s, the Rejoin banner resumes via `get_duel_state`.
- **Opponent never loads the duel (no-show)**: abandoned after 20 s, no ELO,
  the creator's challenge re-opens if unexpired, and the creator sees "Your
  opponent didn't show up".
- **Missed broadcast** (flaky network): every re-subscribe refetches the
  snapshot. Clients also act on their own clocks (auto-decline at 5 s,
  timeout claim at the deadline), and the sweeper resolves anything
  left over.
- **Clock skew between devices**: all countdowns come from server
  timestamps via `ServerClock`. Local stopwatches only measure a player's own
  answer time.
- **Challenge expires while a request is pending**: the delete path clears
  requests first (`challenge_gone`), then the row is removed.
- **Topic runs out of questions / language without content**: the picker only
  lists topics with ≥5 live questions, `create` / `join` / `_duel_create`
  re-check, and the empty picker says so.
- **Guest taps Create**: sign-in notice + composer CTA to `AppRoutes.saveProgress`.
  The server also refuses (`guest_cannot_create`).
- **Rate-limit hits**: friendly snackbars, never a dead button. Retry
  cool-downs are visible countdowns.
- **Self-join**: the client hides Join on own cards, and the server raises
  `own_challenge`.
- **Stale queue ghost pairing**: candidates must have `last_seen_at` within
  12 s, so a user who killed the app can't be matched.
- **Band widening with no newcomers**: each waiting client's heartbeat
  re-runs pairing with its widened band.
- **Answer after the deadline** → `round_closed`; the client waits for
  `round_result`. **Answer with a forged tiny `client_ms`** → clamped by
  `server_elapsed − 1.5 s`.
- **Reading ahead**: `get_duel_round` refuses before `starts_at − 500 ms`,
  and `round_start` carries no question text.
- **Reading the opponent's choice**: `duel_rounds` has no client policy, and
  `answer_locked` carries no choice.
- **ELO farming between two accounts**: ranked only for the first 3 duels per
  pair per 24 h. The rage-quit rule suppresses gains after 3+ forfeits in
  24 h.
- **Language switch**: the arena reads the content language once on open.
  It's a full-screen route, so the language can't change underneath it.
- **Deep link to `/duel/<id>` for someone else's duel** → `not_a_participant`
  → error view with Back.
- **Reduced motion**: all new animations go through
  `AppMotion.durationOf/curveOf` (entry slide, banner, pill, countdown pulses).

## Acceptance criteria

Spec → criterion:
- [ ] Tapping the centre tab-bar button opens the full-screen Duel Arena
      directly. No bottom sheet exists anywhere, `PlayLauncherSheet`, its route
      and its test are gone, and Daily is still reachable from its tab.
- [ ] The arena shows a realtime, chat-style stream of challenges (newest at
      the bottom). A challenge created on device A appears on device B within
      ~1 s without refresh, and disappears on B when cancelled, expired or
      finished.
- [ ] Each card shows creator avatar, name, league, ELO, topic level, topic
      (emoji + name + category), time left, reward, and a fairness hint.
      Card state visibly covers Open / Request sent / Deciding / Not this time
      / Away / In progress / Own.
- [ ] Tapping Join on B shows "Request sent / deciding" on B's card and, on
      A (if A is on the arena), an incoming-request banner with a 5-second
      countdown and Accept/Decline. Accept starts the duel on both devices.
      Decline or no action for 5 s tells B and presents A's next queued request.
- [ ] A user can have requests outstanding on up to 3 challenges. Once one
      duel starts, all their other requests are withdrawn server-side. Nobody
      can be in two duels (enforced under row locks).
- [ ] An in-progress challenge shows "● LIVE · vs {name}" to everyone and
      can't be requested.
- [ ] Challenges expire and are deleted by the backend 5 minutes after
      creation. Completed and cancelled challenges are deleted too.
      (`select count(*) from duel_challenges where expires_at < now() - interval
      '30 seconds' and status = 'open'` stays 0.)
- [ ] Creating a second challenge within 2 minutes of the previous creation is
      refused by the server (`challenge_cooldown`), and the composer shows the
      remaining cool-off.
- [ ] Anti-spam is server-enforced: 1 open challenge, daily cap, guests can't
      create, request caps/rate/retry/queue limits, throttled heartbeats,
      matchmaking join rate. Clients can't publish broadcasts (RLS).
- [ ] Creating a challenge and starting matchmaking both require picking a
      sub-category in the bottom sheet. Only topics with enough live questions
      in the player's content language are offered.
- [ ] Quick match pairs two real players in the same topic, closest ELO first
      (topic level as secondary weight), with the band widening over time. After
      30 s without a match the player is offered a clearly labelled bot and
      can keep searching instead.
- [ ] Live duels: 5 rounds, questions revealed per round at a synced start,
      withheld correctness until both answer or time out, faster correct
      answer takes the round, ELO/coins/XP settled by the server, disconnect
      > 30 s forfeits the remaining rounds, explicit Leave forfeits, and a
      rematch handshake works on the result screen.
- [ ] Duel screens show the real player's avatar/ELO. No `MockPlayer` or
      hardcoded `1240` remains in `features/duel`.
- [ ] `dart analyze` clean, `dart format` applied, `flutter test` green, and
      every new Cubit/Bloc has a `bloc_test` file.

**To verify (manual, by the developer; two devices/simulators with two
different signed-in accounts, plus one guest):**
1. FAB → arena opens full-screen with ✕. Home tabs and Daily tab unaffected.
2. A: Create challenge → picker → Football. The card appears at the bottom on A
   (end-aligned, "Your challenge") and on B (start-aligned) with a ticking
   ring. A's composer shows the cool-off.
3. B: Join → "Request sent" → "{A} is deciding…". A: banner with 5 s bar. Let
   it lapse → B sees "No answer from A", then "Try again in 15s". Repeat, then
   Accept → both see the VS intro with a synced 3-2-1.
4. Play 5 rounds: the opponent's "answered in Xs" chip appears without
   revealing correctness; colours reveal only after both lock. The next
   question appears simultaneously. The result shows ELO/coins, and Rematch
   on both starts a new duel.
5. During a duel, background app B for >30 s → A wins by forfeit with the
   remaining rounds. Retry with a <30 s background → B resumes the same
   round with the real remaining time.
6. A creates a challenge, then opens Quick match → A's card shows "Away" on B
   and Join is disabled. Return → live again. Wait 5 min → the card vanishes
   everywhere.
7. Quick match on both devices in the same topic → paired within a few
   seconds. On one device alone → at 30 s the bot offer appears. "Keep
   searching" hides it, and "Play a bot" starts a BOT-labelled duel in that topic.
8. Guest: Create shows "Sign in to create challenges". Join and Quick match
   work, and the guest appears as "Guest ####".
9. Switch the content language to Urdu/Hindi → the picker shows only topics
   with content, or the empty message.
10. Dark mode: the arena looks identical (invariant). Reduced motion: no
    slide/pop animations.

## Risks & rollout notes

- **Live-DB migrations.** Phases 1–6 alter `duels`/`matchmaking_queue`, drop
  three unused functions and two client policies, and add a 10-second cron.
  Apply only after the developer reviews the SQL (Q3). Rollback: `select
  cron.unschedule('duel-sweeper');`, drop the new functions/tables/policies,
  re-create the dropped policies from `20260907120100_rls_policies.sql` L145-157
  and the dropped functions from `20260910090500_*` / `20260907120200_*`. The
  `duels` column additions are nullable/defaulted and harmless to leave.
  **Ship order matters**: apply the backend (Phases 1–6) before releasing the
  Flutter build. Old app builds keep working (they only call `submit_bot_duel`,
  whose new parameter has a default).
- **Realtime quotas.** Every arena viewer holds 2 channels (lobby + inbox), and
  a duel adds 1. The Supabase plan's concurrent-connection and messages/second
  limits cap how far this scales. Presence on the lobby is O(n²) diff
  traffic at large n, so `duel_config.lobby_presence_enabled=false` turns off
  the head-count pill without a release (the client must honour it). The bible's
  own cost note (5,000 concurrent duels fit one Realtime instance) applies.
- **Heartbeat load.** Lobby heartbeats only run for players with an open
  challenge or pending request (10 s), matchmaking every 3 s, and duels every
  5 s, all throttled server-side. At 1,000 concurrent searchers that's ~330
  RPC/s, the first number to watch. If needed, raise `mm_heartbeat_seconds`
  (pairing latency rises accordingly).
- **Sweeper cost.** 6 scans every 10 s, all on partial indexes over tiny
  "live" subsets. Watch `cron.job_run_details` for duration, and add
  `delete from cron.job_run_details where end_time < now() - interval '1 day'`
  housekeeping if the table grows (8,640 runs/day).
- **Timing fairness is bounded, not perfect** (A3). If players report
  "lost on a slow network", tune `latency_allowance_ms` (higher = more
  forgiving, larger cheat window).
- **Answer-bank cheating** remains possible app-wide (A9). Recommend a follow-up
  plan to move level-play grading server-side and revoke
  `select (correct_index, explanation)` on `questions` from clients (today
  only `duel_api.dart` reads that table directly).
- **Content gap**: only English has duel-able topics (18). Everyone else sees
  an empty picker until content is authored (`/generate-questions`).
- **Small player base**: with ~43 players, most Quick matches will hit the bot
  offer. The arena's open challenges and "N searching" chips steer players
  towards each other. That's the main UX lever at this scale.
- **Follow-ups worth planning:** FCM push for incoming requests (lets challenges
  stay live while backgrounded); friend challenges; duel results into
  `score_events`/leagues (Q1); moving `TimerRing` from `quiz_play` to
  `core/widgets` (it's now used by two features' screens); coin wagers;
  per-topic duel leaderboards.
- **Docs to update after implementation:** `MOCKED_FEATURES.md` (duel
  section), and `.claude/docs/backend/01-supabase-project-setup.md` (add the
  Realtime Broadcast authorization + `duel-sweeper` cron to the setup notes, if
  that doc lists cron jobs/policies — check first). Record the plan's status
  in memory (as done for plans 004/007/008) once executed.
