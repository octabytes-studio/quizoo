# Social, Economy & Realtime Backend

> Source spec: provided inline in conversation — continuation of
> `.claude/plans/005-backend-foundation-core-loop.md`, covering everything
> that plan left out: leaderboards, daily challenge, achievements, shop/IAP,
> duels, settings, and push notifications.
> Status: Draft — not yet implemented

## How to use this plan

This plan is self-contained: executing it needs no prior conversation
history. Start by reading it in full, then read plan 005 in full too — this
plan assumes plan 005's Phase 0 (bootstrapping: `Supabase.instance.client`,
`ApiException.fromSupabase`, Firebase init) and Phase 1 (auth: a real
`auth.uid()` for every player, guest or signed-in) are already implemented.
Nothing else in plan 005 is a hard dependency — this plan's six phases are
independent of each other and of plan 005's Phases 2-4, and can be built and
reviewed in any order, though the order below (leaderboards → daily →
achievements → shop → duel → settings/notifications) is roughly
cheapest-and-least-risky first.

Code may have moved on since this was written (Sep 2026) — re-open the
files this plan cites before starting a phase, the same way plan 005 asks.

## Objective

Connect every remaining mock-data feature to the real backend: leaderboards
and friends, the daily challenge, achievements, the coin/gem shop
(including real IAP and rewarded ads), duels, and settings/push
notifications. Where a feature's current mock behavior doesn't map cleanly
onto "just swap the API body" — duels, most notably — this plan says so
explicitly and picks a scoped, honest v1 rather than silently expanding
into a much larger rewrite.

## Scope

**In scope:**
- `features/leaderboard`: `LeaderboardApi`/`LeaderboardRepository` — global/
  country/friends rosters, self entry, category board, friends list, league
  standings.
- `features/daily`: `DailyApi`/`DailyRepository` — today's challenge,
  streak status, playing it.
- `features/achievements`: `AchievementsApi`/`AchievementsRepository` — the
  badge grid and single-badge detail. (`features/profile`'s reuse of the
  same badge data was already covered by plan 005's Phase 4.)
- `features/shop`: `ShopApi`/`ShopRepository`, `ShopCubit`, `RewardedAdCubit`
  — real coin-pack IAP via `in_app_purchase` + `verify-purchase`, real
  rewarded ads via `google_mobile_ads` + `claim_ad_reward`.
- `features/duel`: `DuelApi`/`DuelRepository`, and — because the current
  implementation is entirely client-simulated (see Research findings) — a
  scoped change to `DuelPlayCubit`'s `_finish()` step to persist the result,
  not a rewrite of the duel play loop itself. Real player-vs-player
  matchmaking/realtime play is explicitly **out of scope** — see
  Assumptions #3.
- `features/settings`: `NotificationsApi`/`NotificationsRepository` (the
  in-app notification center) — real data + FCM device-token registration
  for push. `AppSettings`/`SettingsRepository` (sound/music/haptics) move to
  `shared_preferences`, not Supabase — see Assumptions #5.
- Firebase Remote Config initialization and read-through for the economy
  tunables listed in `docs/backend/02-firebase-project-setup.md` §3.

**Out of scope:**
- Real player-vs-player duel matchmaking and realtime play (Assumptions
  #3). The SQL for it already exists (`matchmaking_queue`,
  `submit_duel_answer`, `resolve_duel_round`, `resolve_duel` in the
  functions migration) — wiring a Flutter implementation against it is a
  larger, separate undertaking flagged for its own future plan.
- The `start-level`/`submit-level`/`matchmake`/`resolve-duel`/
  `verify-purchase`/`ad-reward`/`daily-rollover` **Edge Functions** as thin
  request-routing wrappers. Plan 005 and this plan call the underlying
  Postgres RPCs (`start_level_attempt`, `submit_bot_duel`,
  `claim_ad_reward`, etc.) directly via `supabase.rpc(...)`, which is a
  complete, secure implementation on its own (the RPCs are
  `security definer` and RLS-backed) — an Edge Function layer in front of
  them is optional hardening (rate limiting, request logging, a place to
  put the two receipt-validation integrations that need outbound HTTP calls
  no Postgres function can make) rather than a functional requirement. The
  one exception is **`verify-purchase`**, which this plan does implement as
  a real Edge Function, because receipt validation against Apple/Google's
  servers is an outbound HTTP call SQL genuinely cannot make — see Phase 4.
- Content authoring beyond `supabase/seed.sql`.
- Any new screen or visual change.

## Research findings

**`features/leaderboard/data/leaderboard_api.dart`** (read in full, all
~230 lines): five methods — `fetchRoster({scope, period})`,
`fetchSelfEntry({scope, period})`, `fetchCategoryRoster(subcategoryId)`,
`fetchCategoryHeader(subcategoryId)` (a `(rank, pointsFromTop, countryName)`
record), `fetchFriends()`, `fetchLeagueNeighbors()`. `LeaderboardScope`
(global/country/friends) × `LeaderboardPeriod` (week/month/allTime) is a 9-
way matrix the mock serves by re-slicing one fixture roster — the real
backend serves it from `lb_weekly`/`lb_monthly`/`lb_alltime` (functions
migration) keyed by which view + which of `rank_global`/`rank_country`/
friends-filtered the scope asks for.

**`features/daily/data/daily_api.dart`** (read in full): `fetchToday()` →
`DailyChallenge`, `fetchStreak()` → `StreakStatus`, `play()` →
`DailyPlayOutcome {correctCount, answerPattern}`. Its own doc comment is
explicit that the mock's `play()` "deals a plausible outcome directly
rather than routing through `features/quiz_play`" — the real
`play_daily_challenge(answer_pattern)` RPC (functions migration) takes the
**already-played** answer pattern as input rather than generating one, which
means the actual answering UI (currently absent — S-27's tab only shows the
challenge card and streak; there's no daily-play screen in the routed
screens list) needs to exist before this RPC has real input to send. See
Assumptions #1.

**`features/achievements/data/achievements_api.dart`** (read in full): the
mock layers an achievements-specific `_extras` map (per-badge
`BadgeCategory`, and for locked badges, `closestGroupLabel`/
`closestFractionLabel`/`closestProgress`/`nextActionLabel`/
`nextSubcategoryId`/`rewardCoins`) on top of `core/mock/mock_badges.dart`'s
shared `AppBadge` list. The `achievements` table (initial-schema migration)
carries the shared half (`name`/`emoji`/`description`/`gradient_from`/
`gradient_to`/`category`/`rarity_percent`/`coin_reward`); the per-player
"closest progress" half has no ready column — see Design overview.

**`features/shop/data/shop_api.dart`** (read in full): one method,
`fetchShop()` → `ShopContent {coins, gems, freeAdsWatchedToday,
freeAdsPerDay, freeCoinsReward, inventory, coinPacks}`. `coinPacks` is
static content (three fixed packs) — per `docs/backend/02-firebase-project-
setup.md` §3, this plan reads the coin-pack catalog from **Firebase Remote
Config**, not a Postgres table (design bible §22: "Remote Config to tune the
economy without shipping"), while `coins`/`gems`/`inventory` come from the
player's own `profiles` row and `wallet_ledger`.

**`features/shop/presentation/bloc/rewarded_ad_cubit.dart`** (read in
full): **zero repository/API dependency today** — `watch()` is a local
`Timer` plus a `Random` failure roll, no network call anywhere. This is the
biggest gap between the mock and a real implementation in this whole plan:
the real version needs an actual ad SDK (`google_mobile_ads`) load/show
cycle, and the coin grant needs to move from "the Cubit just says success"
to a server call (`claim_ad_reward`, functions migration) — see Design
overview and Assumptions #4.

**`features/duel/data/duel_api.dart`** (read in full): two methods,
`fetchBotOpponent({playerElo})` and `fetchRoundQuestions()` — that's the
entire API surface. **`features/duel/presentation/bloc/
duel_play_cubit.dart` and `matchmaking_cubit.dart`, read in full, contain
the actual duel simulation**: `DuelPlayCubit` runs its own per-round
`Timer`, decides the bot's answer and timing from a fixed
`DuelEloBand`→accuracy/speed table, and computes round/duel outcomes
entirely client-side — the API is only ever consulted twice, at the very
start (`fetchBotOpponent`, `fetchRoundQuestions`), never per-round.
`MatchmakingCubit` has **no code path that ever finds a real opponent** —
`playBotInstead()` is the only way `MatchmakingSearching` ever resolves to
`MatchmakingFound`. This is the finding behind Assumptions #3: the "real
multiplayer duel" the design bible's §24 describes (queue → deal → play →
reveal → resolve, over Realtime channels, with the correctness-withholding
rule enforced by the *server*) simply isn't what's built today — what's
built is a fully-featured **bot** duel with a client-side illusion of
real-time fairness (the withheld-correctness rule *is* implemented, just
against the Cubit's own private state, not a network boundary). Backing
that faithfully is this plan's Phase 5; backing §24's real thing is not.

**`features/settings/data/notifications_api.dart`** (read in full): three
methods over a **mutable in-memory list** — `fetchAll()`, `markAllRead()`
(returns the whole list synchronously, no `Future`), `acceptChallenge(id)`
(also synchronous, removes the row). Both mutators being synchronous in the
mock (not `Future<...>`) is worth flagging: a real implementation needs
`Future`s for both, since they become network calls — this **is** a
signature change, not just a body swap, and every call site
(`notifications_screen.dart`, `NotificationsCubit`) needs updating to
`await` them.

**`features/settings/domain/app_settings.dart` /
`features/settings/data/settings_repository.dart`** (read in full):
`SettingsRepository` has no `*_api.dart`/`MockApi` at all today — its own
doc comment says why: "no network round trip to simulate for a local
preference." This plan keeps that judgment (Assumptions #5) rather than
inventing a server round trip the mock deliberately never had.

**Testing conventions**: same as plan 005 — `bloc_test` + `mocktail`
against the `*_api.dart` boundary, no test hits a real Supabase project.

## Assumptions & open questions

1. **The daily challenge has no play screen to submit from yet.**
   `app/router.dart`'s route list has `AppRoutes.daily` (the tab, S-27) and
   `AppRoutes.dailyResult` (S-28), but nothing plays the ten questions in
   between — `DailyApi.play()` in the mock synthesizes an outcome rather
   than the player answering ten real questions. `play_daily_challenge`
   (functions migration) expects a real `answer_pattern` as input. **Two
   ways to close this gap, and a human should pick one before Phase 2**:
   (a) build a minimal play surface reusing `quiz_play`'s question-rendering
   widgets against the daily challenge's 10 questions (bigger: a real UI
   addition, out of this plan's stated "no new screens" scope, so this
   would need to be called out as an amendment); or (b) keep `play()`
   synthesizing a plausible pattern for v1 (matching current behavior
   exactly) and defer the real UI to a follow-up. This plan's Phase 2
   defaults to (b) — call `play_daily_challenge` with a synthesized pattern
   generated the same way the mock does today — specifically to honor the
   "no new screens" scope rule, but flags that this is almost certainly not
   the intended end state and should be revisited.

2. **`AchievementsApi`'s per-badge "closest progress" fields
   (`closestFractionLabel`, `closestProgress`, `nextActionLabel`,
   `nextSubcategoryId`) don't have a general server-side computation.**
   Each is specific to what the badge actually tracks (topics played in a
   category, correct-answer streak length, IQ-category flawless-level
   count...) — there's no one query that produces all of them. This plan's
   Phase 3 computes them with **per-badge SQL** in `AchievementsApi` itself
   (a `CASE` on `achievement_id`, one small subquery per badge id, mirroring
   the mock's own `_extras` map structure) rather than trying to generalize
   a "progress" engine — twelve special cases is honest about what this
   is; a generalized rule engine would be premature abstraction for twelve
   badges. Revisit if the badge catalogue grows enough that twelve special
   cases becomes forty.

3. **Real player-vs-player duels are out of scope for this plan.** Restated
   from Scope because it's the single biggest scope call here: the design
   bible's §24 duel architecture (queue/deal/play/reveal/resolve over
   Realtime, `matchmaking_queue`, `submit_duel_answer`, `resolve_duel_round`,
   `resolve_duel` — all already in the functions migration) describes a
   real two-client system the current Flutter code has no path to reach
   (`MatchmakingCubit` never finds a person, `DuelPlayCubit` never talks to
   a server per round). Building that Flutter side is a genuine rewrite of
   both Cubits' architecture — a local `Timer`-driven simulation becomes a
   Realtime-channel subscriber reacting to server broadcasts, which is a
   different shape of state machine, not a swapped method body — and
   belongs in its own plan once a decision is made to build real
   multiplayer duels. This plan instead gives the *existing* bot-duel
   feature a real backend (Phase 5), which is a faithful, much smaller
   change and is a strict improvement (currently: a duel's outcome is never
   saved anywhere, coins/ELO shown on `DuelResultScreen` vanish on next
   launch) without predetermining the bigger rewrite's design.

4. **Rewarded ads are capped server-side by a ledger count, not a real
   ad-network postback.** The design bible's `ad-reward` Edge Function is
   described as "server-to-server callback from the ad network" — the
   fully-hardened version. That requires registering a callback URL in
   AdMob's own dashboard and handling its specific payload format, which is
   meaningfully more setup than a v1 needs (see the SQL comment on
   `claim_ad_reward` in the functions migration for the full reasoning).
   This plan's Phase 4 uses the lighter version: the client calls
   `claim_ad_reward()` right after the Google Mobile Ads SDK's own
   `onUserEarnedReward` fires, and the function enforces the daily cap
   server-side (which a purely client-side counter cannot, since the app
   can be killed and relaunched to reset one) by counting today's
   `wallet_ledger` rows. **A human should confirm this is an acceptable
   trade-off** for launch; the real postback is a fine hardening pass later
   and needs no schema change to add (only a new Edge Function plus an
   AdMob dashboard configuration step).

5. **`AppSettings` (sound/music/haptics) and the two save-progress-prompt
   flags stay local (`shared_preferences`), never synced to Supabase.**
   Restated from Research findings because it's a decision, not just an
   observation: these are per-device UX preferences with no multi-device
   sync requirement stated anywhere in the design bible, and the mock's own
   `SettingsRepository` doc comment already treats them as local-only in
   spirit ("no network round trip to simulate for a local preference").

6. **`NotificationsApi.markAllRead()`/`acceptChallenge(id)` become
   `Future`-returning.** Flagged as a real signature change (not just a
   body swap) because the mock has them synchronous — every call site needs
   an `await` added. Small, but worth calling out explicitly per do-plan's
   own guidance to name every place this plan's premise ("only the body
   changes") doesn't quite hold.

7. **FCM device-token registration needs a moment in the app's lifecycle to
   happen, and the mock has no equivalent to hook it to.** This plan
   registers the token (a) once, right after a successful sign-in
   (`SessionCubit` emitting `SessionSignedIn`, listened to at the app root
   the same way `AuthRepository`'s anonymous bootstrap is wired in plan
   005), and (b) again on `FirebaseMessaging.onTokenRefresh`. Guests don't
   get push (there's no player to notify yet, and no UI moment asking a
   guest to opt in) — matching that a guest also has no
   `app_notifications` to receive, which only ever originate from a
   duel-challenge, streak, league or reward event tied to a real account.

## Design overview

**Leaderboard flow** (`features/leaderboard/data/leaderboard_api.dart`
rewritten):
- `fetchRoster({scope, period})`: select the matching materialized view
  (`lb_weekly`/`lb_monthly`/`lb_alltime`) ordered by the scope's rank
  column (`rank_global` for global, `rank_country` filtered to the caller's
  own `country_code` for country, or — for `friends` — no materialized view
  at all: join `score_events` aggregated live against
  `friendships` where `status = 'accepted'` and either side is the caller,
  since a friends board can't be usefully materialized per-pair; cap at,
  say, 50 rows and accept the extra query cost given a friends list is
  small). Join `profiles` for `name`/`avatarEmoji`/`locationLabel`
  (`country_code` + `city`, formatted client-side or in the query the same
  way `MockPlayer`'s "🇵🇰 Islamabad" strings are already formatted —
  confirm whether flag-emoji-from-country-code conversion belongs in Dart
  or SQL; Dart is simpler since it's a pure function of a 2-letter code with
  no I/O). `rankDelta` (▲/▼/— vs. the prior period) has no historical
  snapshot to diff against in this schema — either add a small
  `lb_snapshot_prior` table populated by daily-rollover, or ship `null`
  (row hides its delta) for v1 and treat the historical diff as a
  follow-up; this plan defaults to `null` to avoid adding a table this
  plan's Data model section doesn't already define — flag as a known gap,
  not a silent omission.
- `fetchSelfEntry({scope, period})`: same view, `where user_id =
  auth.uid()`; `topPercent` computed from `rank / (select count(*) from
  <view> where <scope's partition matches>)`.
- `fetchCategoryRoster(subcategoryId)`: `lb_alltime` (a "category board" in
  the UI reads best as an all-time ranking, matching the mock's own
  non-time-boxed `_categoryRoster` fixture) filtered to the subcategory,
  ordered by `rank_subcategory`, joined with `level_progress` aggregated
  per user for `levelsCleared`/`starsEarned`.
- `fetchCategoryHeader(subcategoryId)`: the caller's own `rank_subcategory`
  + `points`-from-10th-place delta + `profiles.country_code` resolved to a
  display name (a small fixed lookup, matching `MockPlayer.countries`'
  existing fixed list — keep it in Dart, it's UI copy, not data).
- `fetchFriends()`: `friendships` joined `profiles`, `status` mapped to
  `FriendStatus` (`pending` for an inbound request the caller is the
  `addressee` of, `online`/`offline` from Supabase Realtime **Presence** on
  a shared `presence:online` channel every signed-in client joins on
  launch — not a database column, since "online right now" is inherently
  transient state Presence is built for).
- `fetchLeagueNeighbors()`: `league_memberships` joined `league_cohorts`
  (current week) + `profiles`, ordered by `points`, sliced to the few rows
  around the caller's own rank.

**Daily challenge flow** (`features/daily/data/daily_api.dart` rewritten):
- `fetchToday()`: `daily_challenges` row for today, `playedTodayCount`/
  `averageCorrect`/`averageOutOf` from a `daily_attempts` aggregate for the
  same date.
- `fetchStreak()`: `profiles.streak_days`/`streak_freezes` +
  `streak_milestones` (upcoming two) + the 7-day mini calendar built from
  `daily_attempts` rows for the current week (client computes which
  weekday is "today"/"future"/"reward" — pure date logic, stays in Dart).
- `play()`: per Assumption #1, synthesizes a plausible answer pattern
  exactly as `DailyApi._today`'s mock does today, then calls
  `play_daily_challenge(pattern)` and maps the response into
  `DailyPlayOutcome`.

**Achievements flow** (`features/achievements/data/achievements_api.dart`
rewritten): `fetchAll()`/`fetchById(id)` select `achievements` left-joined
`user_achievements` for the caller, mapping `isLocked = unlocked_at is
null`. The per-badge "closest progress" `CASE` (Assumption #2) lives here,
e.g.:
```sql
select
  a.*, ua.unlocked_at,
  case a.id
    when 'badge_category_king' then (
      select jsonb_build_object(
        'fractionLabel', count(*) filter (where lp.stars = 3) || ' / ' || count(*) || ' TOPICS',
        'progress', count(*) filter (where lp.stars = 3)::float / nullif(count(*), 0)
      )
      from public.subcategories s
      left join public.level_progress lp
        on lp.subcategory_id = s.id and lp.user_id = auth.uid() and lp.level = 20
      where s.category_id = /* the player's best-progressed category — see note below */
    )
    -- ...one branch per badge id needing a closest-progress line...
  end as progress_detail
from public.achievements a
left join public.user_achievements ua on ua.achievement_id = a.id and ua.user_id = auth.uid();
```
This plan does not fully resolve every one of the twelve branches' exact
SQL (that's implementation work, not planning work) — it establishes the
shape (one `CASE`/`UNION` branch per badge id, executed as part of
`fetchAll`) and flags that `badge_category_king`'s "closest" needs a
"which category is the player furthest into" tie-break the mock's own
fixture hardcodes (`categoryId = MockCatalog.sportsId`'s Football progress)
rather than genuinely computing — port the same simplification unless
whoever implements this phase has a better rule in mind.

**Shop & IAP flow** (`features/shop/data/shop_api.dart` rewritten):
- `fetchShop()`: `coins`/`gems` from `profiles`, `inventory` — **there is
  no `power_up_inventory` table in the schema.** `PowerUpInventory`'s four
  counts (`fiftyFifty`/`addTime`/`skip`/`freeze`) need a home; the
  cleanest fit given `wallet_ledger`'s existing shape is treating each
  power-up as its own `currency` value (extend the `wallet_ledger.currency`
  check constraint from `('coins','gems','hearts')` to also allow
  `'powerup_fifty_fifty'`/`'powerup_add_time'`/`'powerup_skip'`/
  `'powerup_freeze'`, and derive each count as `sum(delta) where currency =
  '...'` — consistent with "every coin movement, no exceptions" already
  covering these). This is a schema change this plan makes (a migration
  altering the check constraint) rather than a new table, because a
  power-up is spent/granted exactly like a currency already is. `coinPacks`
  from Firebase Remote Config's `coin_pack_ids` parameter (doc 02 §3),
  resolved against `in_app_purchase`'s `queryProductDetails` for live
  store pricing (`priceLabel` — never hardcode a price string; store pricing
  varies by region/currency and `in_app_purchase` returns the
  store-localized price directly). `freeAdsWatchedToday`/`freeAdsPerDay`
  mirror `claim_ad_reward`'s own counting logic (Phase 4) — expose it via a
  small read-only query (`count(*) from wallet_ledger where reason =
  'ad_reward' and created_at >= today`) rather than duplicating the cap
  constant in two places; import the `v_free_ads_per_day`/`v_reward_coins`
  values from the same source (either hardcode `3`/`50` in both places with
  a comment pointing at the other, or add a tiny `select 3, 50` config RPC
  — this plan's judgment call is the comment approach, since a config RPC
  for two integers is more machinery than the problem needs).
- **Purchasing a coin pack**: `ShopCubit` (confirm its current mock
  behavior before changing it) calls `in_app_purchase`'s `buyConsumable`,
  listens for the platform purchase stream, and on a completed purchase
  calls a **`verify-purchase` Edge Function** (this plan's one real Edge
  Function — see Scope) with the raw receipt/transaction data; the function
  validates against Apple's App Store Server API or Google's Play Developer
  API (credentials from `docs/backend/03-store-iap-push-setup.md` §2),
  inserts into `iap_transactions` (unique on `(store,
  store_transaction_id)`, which is what makes a retried/duplicate client
  call safe), and calls `_grant_currency` for the coins. The client then
  calls `in_app_purchase`'s `completePurchase` only after the Edge Function
  confirms success — never before, or a failed/pending verification could
  let the store consider the purchase "delivered" with nothing actually
  credited.

**Rewarded ads** (`features/shop/presentation/bloc/rewarded_ad_cubit.dart`
rewritten): replace the `Timer`-based `watch()` with `google_mobile_ads`'
real flow — `RewardedAd.load(...)`, then `show(onUserEarnedReward: (ad,
reward) => ...)`. The states (`RewardedAdReady`/`Playing`/`Succeeded`/
`Failed`) stay the same four-way sealed class; only what drives the
transitions changes (a real SDK callback instead of a `Timer` +
`Random`-rolled failure). On `onUserEarnedReward`, call
`claim_ad_reward()` (functions migration) and emit `RewardedAdSucceeded`
with the response's real `coinsEarned` (should always be the same fixed 50
the mock uses, but read it from the response rather than hardcoding a
second copy of that number in Dart).

**Duel flow** (`features/duel/data/duel_api.dart`,
`duel_play_cubit.dart`'s `_finish()` only — per Assumption #3):
- `fetchBotOpponent({playerElo})`: unchanged shape, but `playerElo` should
  now be read from `profiles.elo` (a real, persisted value) rather than
  `DuelPlayCubit`'s hardcoded `_playerBaseElo = 1200` constant — thread the
  real value in from wherever `MatchmakingCubit`/`DuelPlayCubit` are
  constructed (check `matchmaking_screen.dart`/`duel_play_screen.dart` for
  the current call site).
- `fetchRoundQuestions()`: selects 5 live questions the same way
  `start_level_attempt` does (reuse `_question_difficulty_range`/a fixed
  mid-difficulty band, or keep it simple and pull from any live subcategory
  — the mock reuses the Football pool specifically because it's the only
  content-rich topic; do the same until more content exists).
- **`_finish()`** (in `DuelPlayCubit`): after building the local `DuelResult`
  exactly as today, additionally call `submit_bot_duel(opponentElo,
  playerRoundsWon, opponentRoundsWon, roundsPayload)` (functions migration)
  where `roundsPayload` is `_history` mapped to `[{roundNumber,
  playerCorrect, playerAnswerSeconds}]`, and use the **response's**
  `eloAfter`/`coinsEarned`/`xpEarned`/`newlyEarnedBadgeIds` to build the
  emitted `DuelResult` instead of the current client-computed `eloAfter:
  _playerBaseElo + (isVictory ? 18 : -12)` guess. This is the only change
  Phase 5 makes to `DuelPlayCubit` — the entire round-by-round simulation
  (clock, bot timing, withheld-correctness reveal) is untouched, because
  Assumption #3 keeps it as a faithful bot opponent rather than rebuilding
  it as a network protocol.

**Settings & notifications flow**
(`features/settings/data/notifications_api.dart` rewritten,
`AppSettings`/`SettingsRepository` per Assumption #5 unchanged from their
current in-memory-but-really-should-be-local-prefs state — swap the
in-memory field for `shared_preferences` reads/writes, same as plan 005's
Phase 5 treats `OnboardingRepository`):
- `fetchAll()`: `app_notifications` for `auth.uid()`, ordered by
  `created_at desc`, joined `profiles` for `challenger_name`/
  `challenger_avatar_emoji`/`challenger_elo` (via `challenger_id`).
- `markAllRead()`: `update app_notifications set is_read = true where
  user_id = auth.uid()` (the RLS migration's column-scoped grant already
  restricts this to the `is_read` column only) — now returns
  `Future<List<AppNotification>>`, re-selecting after the update (per
  Assumption #6).
- `acceptChallenge(id)`: `delete from app_notifications where id = ? and
  user_id = auth.uid()` — also now `Future`-returning. (Actually starting
  the challenged duel is a separate call into `features/duel`'s flow;
  confirm the current mock's call site doesn't conflate "dismiss the
  notification" with "start the duel" before assuming this one delete is
  the whole of `acceptChallenge`.)
- **FCM registration** (Assumption #7): a small addition to
  `AuthRepository` or a new tiny `PushRepository` (`core/` if it stays
  genuinely tiny and app-wide, `features/settings/` if it grows) —
  `FirebaseMessaging.instance.getToken()` on sign-in, upserted into
  `fcm_tokens (user_id, token, platform)`; `onTokenRefresh` re-upserts.

**Firebase Remote Config**: initialized once at app root (alongside
`Supabase.initialize`/`Firebase.initializeApp` in `main.dart`, per plan
005's Phase 0), with `setDefaults(...)` matching the values in
`docs/backend/02-firebase-project-setup.md` §3's table exactly, so a
Remote-Config fetch failure (offline first launch) never leaves the app
without a sane number to show.

## Implementation steps

**Phase 0 — Remote Config**
- [ ] Add `firebase_remote_config` initialization to `main.dart` (extends
      plan 005's Phase 0 bootstrapping — small enough to fold into this
      plan rather than reopening plan 005).
- [ ] `setDefaults` matching doc 02 §3's table.

**Phase 1 — Leaderboards & friends**
- [ ] Rewrite `features/leaderboard/data/leaderboard_api.dart` per Design
      overview (5 methods).
- [ ] Wire Supabase Realtime **Presence** for online/offline friend status
      — a small addition to wherever `FriendsScreen`'s Cubit lives
      (`friends_cubit.dart`), joining a shared presence channel on sign-in.
- [ ] Confirm `rankDelta: null` (the historical-diff gap, Design overview)
      renders acceptably in `leaderboard_screen.dart`/`pinned_self_row.dart`
      — check whether the widget already handles a null delta (the domain
      model has it as `int?` already, so it should) before treating this as
      done.

**Phase 2 — Daily challenge**
- [ ] Resolve Assumption #1 with a human before starting — this phase's
      shape depends on the answer.
- [ ] Rewrite `features/daily/data/daily_api.dart` per Design overview.

**Phase 3 — Achievements**
- [ ] Rewrite `features/achievements/data/achievements_api.dart` per Design
      overview, including the per-badge progress `CASE`.
- [ ] Cross-check `features/profile/data/profile_api.dart` (plan 005, Phase
      4) still gets what it needs from the same `achievements`/
      `user_achievements` tables for `recentBadges`/`badgeCount` — both
      plans read the same tables, confirm no query duplication turns into
      drift (e.g. one computing `isLocked` differently from the other).

**Phase 4 — Shop, IAP & rewarded ads**
- [ ] Migration: alter `wallet_ledger`'s `currency` check constraint to
      include the four power-up currencies (Design overview).
- [ ] Rewrite `features/shop/data/shop_api.dart` per Design overview.
- [ ] Add `in_app_purchase` wiring to `ShopCubit` (confirm current
      structure first) for the coin-pack purchase flow.
- [ ] Write the `verify-purchase` Edge Function (Deno/TypeScript,
      `supabase/functions/verify-purchase/`) per Design overview — this is
      the one piece of this plan that is genuine new backend *code*, not
      config or SQL, because receipt validation needs an outbound HTTP call
      to Apple/Google. Use the credentials doc 03 §2 sets up as environment
      secrets.
- [ ] Rewrite `features/shop/presentation/bloc/rewarded_ad_cubit.dart` per
      Design overview (`google_mobile_ads` real SDK flow).
- [ ] Add `google_mobile_ads` platform setup (AdMob app IDs in
      `AndroidManifest.xml`/`Info.plist`) — check `google_mobile_ads`'
      current setup docs at implementation time for the exact manifest keys
      it expects, since ad SDK integration steps change more often than
      most packages'.

**Phase 5 — Duel (bot persistence)**
- [ ] Rewrite `features/duel/data/duel_api.dart` (real `profiles.elo`,
      real question fetch).
- [ ] Add the `submit_bot_duel` call to `DuelPlayCubit._finish()` per
      Design overview — the only change to that Cubit's logic.
- [ ] `bloc_test` update for `DuelPlayCubit`'s new repository dependency in
      `_finish()`.
- [ ] File a follow-up (an issue, or a note wherever this project tracks
      backlog) for the real-multiplayer-duel plan Assumption #3 defers —
      don't let it silently disappear once this phase ships something that
      *looks* like a complete duel feature.

**Phase 6 — Settings & notifications**
- [ ] Rewrite `features/settings/data/notifications_api.dart` per Design
      overview, including the sync→async signature change.
- [ ] Update `NotificationsCubit`/`notifications_screen.dart` call sites
      for the new `Future`-returning methods.
- [ ] Move `AppSettings`/`SettingsRepository` to `shared_preferences`
      (Assumption #5).
- [ ] Add FCM token registration (Assumption #7).
- [ ] Handle an incoming push (background/foreground) — at minimum,
      tapping a duel-challenge push should deep-link to
      `AppRoutes.duelPlay`/matchmaking the same way accepting the in-app
      notification does; confirm this against however
      `notifications_screen.dart`'s existing accept-challenge navigation is
      wired today and mirror it.

## Data model / API changes

Builds on plan 005's schema files. New RPCs this plan's Flutter code calls:
`play_daily_challenge`, `claim_ad_reward`, `submit_bot_duel` (all in
`supabase/migrations/20260907120200_functions_and_triggers.sql` already).

**One additional migration this plan needs, not yet written** (add as
`supabase/migrations/<next-timestamp>_powerup_wallet.sql` when this phase
is implemented):
```sql
alter table public.wallet_ledger drop constraint wallet_ledger_currency_check;
alter table public.wallet_ledger add constraint wallet_ledger_currency_check
  check (currency in (
    'coins', 'gems', 'hearts',
    'powerup_fifty_fifty', 'powerup_add_time', 'powerup_skip', 'powerup_freeze'
  ));
```

**Edge Function**: `verify-purchase` (Phase 4) — the one genuinely new
piece of backend code this plan calls for. Contract:
- Input: `{store: 'app_store'|'play_store', productId: string,
  receiptData: string (App Store) | purchaseToken: string (Play Store)}`.
- Validates against the respective store's server API using the secrets
  from `docs/backend/03-store-iap-push-setup.md` §2.
- On success: inserts `iap_transactions`, calls `_grant_currency` (coins
  matching the product — 500/2,800/6,500 per
  `docs/backend/03-store-iap-push-setup.md` §1's table), returns
  `{success: true, coinsCredited: int}`.
- On a duplicate `store_transaction_id`: returns `{success: true,
  coinsCredited: 0, alreadyProcessed: true}` rather than an error — the
  unique constraint on `iap_transactions` makes this idempotent by
  construction; the function should catch that specific constraint
  violation and treat it as a success, not surface a 500 to a client that's
  legitimately retrying a purchase confirmation.

## Dependencies

- `in_app_purchase` — coin-pack purchases (design bible §25).
- `google_mobile_ads` — rewarded ads (design bible §25).
- `firebase_remote_config` — economy tunables (design bible §22/§25).
- `shared_preferences` — already added in plan 005's Phase 0/5; this plan
  adds no new local-persistence dependency, just more uses of it.

No new Supabase-side dependency — `supabase_flutter` (plan 005) already
covers Realtime (for Presence in Phase 1) and Functions invocation (for
`verify-purchase` in Phase 4).

## Testing strategy

Same conventions as plan 005 (CLAUDE.md §11, `mocktail` against the
`*_api.dart` boundary, no test against a real Supabase project):
- Every rewritten `*_api.dart` class gets a repository test per §11.
- `bloc_test` updates for every Cubit whose repository dependency's return
  shape changed: `LeaderboardCubit`/`FriendsCubit`/`LeagueCubit`/
  `CategoryLeaderboardCubit`, `DailyCubit`/`DailyResultCubit`,
  `AchievementsCubit`/`BadgeUnlockedCubit`, `ShopCubit`/`RewardedAdCubit`,
  `DuelPlayCubit` (the `_finish()` change only), `NotificationsCubit`,
  `SettingsCubit`.
- `verify-purchase`'s Edge Function is Deno/TypeScript, outside CLAUDE.md's
  Flutter-focused test conventions — test it with Supabase CLI's local
  Edge Function test runner (`supabase functions serve` +
  a Deno test file), mocking the Apple/Google HTTP calls rather than
  hitting their sandboxes in CI.

## Edge cases & error handling

- **`claim_ad_reward` hitting the daily cap**: map to a distinct error the
  Cubit turns into the existing "no more free ads today" UI state — check
  `rewarded_ad_dialog.dart`/`ShopScreen` for whether that state already
  exists (the mock's `freeAdsRemainingToday`/`hasFreeAdsRemaining` getters
  on `ShopContent` suggest it does) rather than assuming a new one is
  needed.
- **`verify-purchase` receiving a receipt for a product not in the known
  coin-pack table** (a stale build, a tampered request): reject rather than
  silently no-op, and log it — this is the one place in this plan's scope
  where a malformed request is worth actively flagging rather than quietly
  swallowing, since it's the most valuable single target for a client-side
  tamper attempt in the whole app.
- **A friend request between two accounts that already have a row in
  either direction**: `friendships`' primary key is
  `(requester_id, addressee_id)` — a second request in the *same* direction
  is a clean conflict the client can treat as "already sent"; a request in
  the *opposite* direction (both users requested each other) needs
  `fetchFriends`/the request-accept flow to check both orderings, since
  the schema doesn't normalize the pair. Note this for whoever implements
  Phase 1's request/accept UI wiring (not fully speced here — the mock's
  own `fetchFriends` doesn't model sending a NEW request at all, only
  listing existing ones, so this is new ground this plan's Design overview
  doesn't fully cover; flagged rather than guessed at).
- **A duel-challenge push arriving for a duel that's already been resolved
  or expired** (`duels.expires_at`): the deep link should land on
  `DuelResultScreen`/an "expired" state rather than a matchmaking screen
  that has nothing to match — confirm `AppRoutes.duelPlay`'s screen checks
  `duels.status` before assuming "active."

## Acceptance criteria

- [ ] Leaderboards render real, ranked data across all nine scope×period
      combinations, and a fresh account with zero `score_events` sees an
      empty-but-not-broken board (check against `leaderboard_screen.dart`'s
      existing empty-state handling).
- [ ] Playing today's daily challenge updates `profiles.streak_days` and
      shows a result screen sourced from `play_daily_challenge`'s response.
- [ ] The achievements grid reflects real `user_achievements` rows, and a
      level-clear that satisfies `badge_sharpshooter`/`badge_on_fire`/
      `badge_boss_slayer` (already checked server-side by plan 005's
      `submit_level_attempt`) shows up here without a second write.
- [ ] A real (sandbox) coin-pack purchase credits coins exactly once, even
      if the client retries `completePurchase` after a dropped connection.
- [ ] A rewarded ad, watched for real via AdMob's test ad unit, credits 50
      coins and is capped at 3/day server-side (verified by calling
      `claim_ad_reward` a 4th time in the same day and confirming it's
      rejected).
- [ ] A bot duel's result (ELO change, coins, XP) persists across an app
      restart — check `profiles.elo`/`profiles.coins` before and after.
- [ ] `flutter analyze` reports zero warnings after every phase.
- [ ] Every `bloc_test`/repository test this plan's changes touch exists
      and passes.

## Risks & rollout notes

- **`verify-purchase` is the one component in both plans that must not
  ship with a bug** — a broken receipt-validation function either loses
  players real money (charged, no coins) or lets coins be granted for free
  (a forged/replayed receipt). Test it against both stores' sandbox
  environments explicitly before any release build, not just against
  mocked HTTP responses.
- **Duel Assumption #3 is a product decision as much as a technical one.**
  Shipping "bot duels, backed for real" without also shipping real
  multiplayer might not be what the roadmap actually wants at this point —
  confirm this scoping against whatever the current product priority is
  before starting Phase 5, since the design bible's own roadmap (§26)
  places real 1v1 duels at "v1.2," after the v1.0/v1.1 scope this plan and
  005 otherwise track towards.
- **Rollback**: each phase is confined to one feature's `*_api.dart` (+ the
  specific Cubit changes each phase's Design overview calls out
  explicitly) — reverting one phase doesn't require reverting the others.
- **Docs to update after implementation**: `docs/backend/02-firebase-
  project-setup.md`'s Remote Config table should be updated if any default
  value changes during implementation, so the setup doc and the shipped
  `setDefaults(...)` never drift apart.
