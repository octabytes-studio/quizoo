# Mocked / Stubbed Features — Snapshot Audit

**Date:** 2026-09-19
**Scope:** `lib/` across the whole app. This is a point-in-time audit, not a design doc — items here may already be tracked as known follow-ups in code comments (quoted where useful), but are compiled here so they're visible in one place. Auth *code* itself (signup/social/reset) is real; where auth is blocked it's external dashboard config, tracked separately in `AUTH_SETUP_CHECKLIST.md`, not repeated below.

---

## `core/` — shared mock fixtures still in active use

| File | What's mocked | Impact |
|---|---|---|
| `core/mock/mock_player.dart` | Entire "signed-in player" fixture: name (`Waleed`), avatar emoji, `dayStreak` (12), `playerLevel` (12), `xpIntoLevel`, wallet (`currency`), power-up counts, `livesPerLevel`, 8 fixed avatar emoji, 6 fixed countries, `takenUsernames` set. | High — pulled into Home, Auth, Quiz Play, Duel, Catalog widgets, often **instead of** real per-user data that already exists elsewhere in the app (see Home below). |
| `core/mock/mock_catalog.dart` | Full taxonomy fixture (categories/subcategories/levels) plus `levelId`/`parseLevelId`/`bandFor`/`secondsFor` helpers. | Mixed — `CatalogApi` (real Supabase) only reuses the pure ID/band helpers, which is fine, but several **screens** import `MockCatalog` directly for display data (see Leaderboard, Achievements, Profile below), bypassing the real repository layer entirely. |
| `core/mock/mock_api.dart` | A documented "temporary" base class for simulated latency/failure. | Low — no `*_api.dart` file extends it anymore (all now hit Supabase directly), but it's still live test infrastructure (`test/core/mock/mock_api_test.dart`, `test/support/pump_app.dart`'s `useMockApiFailureRate`) — not dead code, kept. |

---

## `quiz_play` — core gameplay economy is disconnected from the real wallet

| File:Line | What's mocked | Impact |
|---|---|---|
| `quiz_play_repository.dart` / `quiz_play_api.dart` / `daily_repository` | Questions, level pacing, and daily-challenge scoring are **real** (`start_level_attempt`, `get_daily_challenge_questions` RPCs). | — (confirms this part is *not* mocked, included for contrast) |
| `presentation/bloc/quiz_play_cubit.dart:238,311` | `heartsRemaining` for every level/daily run is hardcoded to `MockPlayer.livesPerLevel` (always 3), not read from any per-user state. | Medium — "lives" is a fixed game-design constant today, not a real economy, so this only matters if per-user extra-lives is ever intended. |
| ~~`quiz_play_cubit.dart:373-377` (`_beginQuestion`)~~ | **Fixed by plan 013.** Power-ups are now granted once per level (`QuizRun.powerUps`, one 50:50 + one +5s) and spent from that same pool across every question, never re-seeded per question. | — |
| ~~`quiz_play_cubit.dart:861-864` (`watchAdForHeart`)~~ | **Fixed by plan 013.** The out-of-lives "watch an ad for 1 ❤️" flow is now a real `google_mobile_ads` rewarded ad (`HeartAdCubit`/`AdMobRewardedAdService`), using Google's public test rewarded ad unit IDs. | — |
| ~~`quiz_play_cubit.dart:887-892,906-919` (`refillHeartsWithCoins`)~~ | **Removed by plan 013**, along with the Shop it depended on — the out-of-lives dialog now offers exactly two actions (watch ad, back to map), no paid coin refill. | — |
| `data/mock_questions.dart` | A hand-written pool of ~15 football + 10 solar-system questions, explicitly flagged in its own doc comment as a fixture ("plan 002, Assumption 4"). | Low — appears to be **dead code** now; `quiz_play_repository.dart` sources questions from the real Supabase question bank (`start_level_attempt`). Only remaining reference is `lib/app/router.dart:441` (see Dev/Router below). Safe to delete if confirmed unreferenced elsewhere. |
| `core/ads/ad_unit_ids.dart` + native AdMob App IDs (`Info.plist`, `AndroidManifest.xml`) | **Every ad in the app still runs on Google's public test ids** — the rewarded heart ad and (plan 022) the interstitial, banner and native ads. Test ads always fill and earn nothing. | High before release — a build shipped with these shows test ads and makes no revenue. Swap all twelve unit ids and both App IDs for the real ones from the AdMob account (plan 022, Open question 1; steps in `.claude/docs/backend/04-flutter-app-configuration.md` §7). |
| `presentation/screens/quiz_play_screen.dart:353-370` (report-question sheet) | "Report question" submit handler just pops the sheet and shows a success snackbar — **no backend call, nothing is persisted**. | Medium — players believe their report was sent; it goes nowhere. |

---

## `shop` — removed entirely (plan 013)

The Shop feature (`lib/features/shop/`) was deleted outright rather than fixed: coins/gems are still earned (daily challenge, duel payouts) and still shown in the Home top bar, but there is no longer any spend surface for them, and nothing in the app can be purchased with coins or gems. `PowerUp.skip`/`PowerUp.freeze` (Skip removed from play, Freeze was Shop-only) were removed from `core/models/power_up.dart` alongside it.

---

## `duel` — ~~no real matchmaking or opponent~~ (fixed by plan 017)

| File:Line | What's mocked | Impact |
|---|---|---|
| ~~`data/duel_api.dart` (`fetchBotOpponent`)~~ | **Fixed by plan 017.** Real player-vs-player duels now run on the server (`LiveDuelApi` + Postgres RPCs + Realtime Broadcast). The bot roster remains only as the clearly labelled practice bot Quick match offers after 30 s with nobody around. | — |
| ~~`presentation/bloc/matchmaking_cubit.dart` (always-bot search)~~ | **Fixed by plan 017.** `MatchmakingCubit` queues server-side per topic, pairs on ELO with a widening band (topic level as a secondary weight), and only offers the labelled bot after 30 s — the player can keep searching instead. | — |
| ~~`presentation/screens/matchmaking_screen.dart` (`playerElo` constant `1240`)~~ | **Fixed by plan 017.** The player's real ELO/league/avatar come from the server's `_duel_player_json`. | — |
| ~~`duel_play_screen.dart` / `matchmaking_screen.dart` (`MockPlayer.avatarEmoji`)~~ | **Fixed by plan 017.** Every duel surface shows the real player's avatar (`DuelPlayer.avatarEmoji`). | — |
| ~~`data/duel_api.dart` (Football-only questions)~~ | **Fixed by plan 017.** Duels are fought in a picked topic, and the picker only lists topics with enough live questions in the player's content language (only English has duel-able topics today — a content gap, not a code stub). | — |

---|---|---|
| `data/duel_api.dart:9-18,27-48` (`fetchBotOpponent`) | Explicitly commented: *"There is still no real matchmaking server... keeps dealing a bot, explicitly labelled as one, from the same small fixed roster."* A 6-name bot roster with a randomized ELO offset. | **High** — "Duel" never matches against another real player; every duel is vs. a bot. |
| `presentation/bloc/matchmaking_cubit.dart:32-70` | The search UI always ends by calling `fetchBotOpponent` — either on a 20s auto-timeout or an explicit "play a bot instead" tap. There is no code path that finds a human opponent. | High — same root issue as above; the "searching for opponent" UX is theater. |
| `presentation/screens/matchmaking_screen.dart:28` | `playerElo` is a hardcoded constant (`1240`), not the real player's `profiles.elo`. | Medium — self-flagged in `duel_api.dart`'s own comment as a follow-up. |
| `presentation/screens/duel_play_screen.dart:187,210`, `matchmaking_screen.dart:88` | The local player's avatar is always `MockPlayer.avatarEmoji` (🐼), never the real signed-in user's chosen avatar. | Low-medium — cosmetic but visible every duel. |
| `data/duel_api.dart:50-56` | Duel questions are only ever drawn from the Football subcategory (only content pool seeded); non-English/other-topic duels resolve to an empty round. | Low — content-completeness limitation, not a code stub. |

---

## `home` — top bar shows fake level/streak even for real users

| File:Line | What's mocked | Impact |
|---|---|---|
| ~~`presentation/screens/home_screen.dart:302-306,496-500`~~ | **Fixed by plan 019.** `PlayerTopBar` now reads `dayStreak`/`playerLevel` from `HomeContent` (`HomeApi.fetchCachedHome`'s `profiles` query now selects `streak_days`/`player_level`), never `MockPlayer`. The pre-fetch skeleton shows an honest `0`/`Level 0` instead of a fabricated specific number. | — |
| `home_screen.dart:135-136` | Continue-row category lookup keys off `MockCatalog.footballId`/`solarSystemId` constants (IDs only, not display data) — low impact, just noted for completeness. | Low |

---

## Screens bypassing the repository layer to read `MockCatalog` directly

CLAUDE.md §1/§9 requires Presentation → Domain → Data via a repository; these screens instead import `core/mock/mock_catalog.dart` directly for display data, even though the real catalog now lives in Supabase (via `catalog_api.dart`):

| File:Line | What's mocked | Impact |
|---|---|---|
| `leaderboard/presentation/screens/category_leaderboard_screen.dart:56-58,114,216` | The subcategory's name/emoji/plate-color header comes from `MockCatalog.subcategoryById`, not the real `CategoryDetail`/`Subcategory` the catalog repository would return. Falls back silently to Football if the id isn't in the fixture list. | Medium — any subcategory added to Supabase after the original fixture will show the wrong (Football) header on its leaderboard, even though the actual scores/ranks below it are real. |
| `achievements/presentation/widgets/badge_detail_dialog.dart:122,147,149` | "Play this topic" CTA and its label resolve the target subcategory via `MockCatalog`, with the same Football fallback on a miss. | Medium — same silent-wrong-topic risk for badges tied to newer subcategories. |
| `profile/presentation/screens/profile_screen.dart:242` | Tapping a "best category" row looks up the subcategory via `MockCatalog.subcategoryById` instead of data already in `ProfileSummary`. | Medium — same failure mode if `entry.subcategoryId` isn't one of the ~26 fixture ids. |
| `home/presentation/screens/search_screen.dart:238` | Search result category name resolved via `MockCatalog.categoryById`. | Low-medium — same class of risk. |

---

## `auth` — profile creation UI limited to fixed picker lists

| File:Line | What's mocked | Impact |
|---|---|---|
| `presentation/screens/profile_creation_screen.dart:54,56` | Avatar picker cycles through 8 fixed emoji (`MockPlayer.avatarChoices`); country picker cycles through 6 fixed countries (`MockPlayer.countries`). Username availability check itself **is real** (queries `profiles` table). | Medium — new users can only choose from 8 avatars / 6 countries, not a real picker or full ISO country list. |
| `presentation/widgets/save_progress_sheet.dart:54,99` | Guest "save your progress" card shows `MockPlayer.dayStreak`/`avatarEmoji` as an illustrative example, not the guest's real (zeroed) state. | Low — cosmetic marketing card, guest has no real streak yet anyway. |

---

## `settings` — several rows are visual-only

| File:Line | What's mocked | Impact |
|---|---|---|
| `presentation/screens/delete_account_screen.dart:18-24,61-69` | Explicitly commented: *"Mock delete just signs out to Guest and shows a snackbar — there is no real account to erase."* | **High** — a user who completes the typed-confirmation flow believes their account/data was deleted; it was not. Real account and data remain on the server. |
| `presentation/screens/privacy_settings_screen.dart:9-15,24-25` | "Show on leaderboards" / "Show activity to friends" toggles are local `setState` only — not persisted (not even to `shared_preferences`), and nothing in the leaderboard/friends code reads them. | Medium — settings silently reset every time the screen is reopened and have zero effect on actual visibility. |
| `presentation/screens/notification_permission_screen.dart:11-18,39-48` | "Turn on notifications" doesn't request the real OS notification permission (no `permission_handler`/FCM/APNs call) and the picked reminder time is never persisted or scheduled — just a snackbar. Self-documented as reachable only via a debug row, since real trigger tracking ("after 3rd level") is out of scope. | Medium — no real push-notification opt-in exists anywhere in the app yet. |

Real by contrast: `notifications_api.dart` (in-app notification list, mark-read, accept-challenge) and `settings_repository.dart` (sound/music/haptics toggles via `shared_preferences`) are genuinely wired up.

---

## Dev / Router

| File:Line | What's mocked | Impact |
|---|---|---|
| `lib/app/router.dart:436-441` (`_reportQuestionDemo`) | A design-review-only route builds the report-question sheet against `MockQuestions.football.first`, a fixture question. | Low — explicitly a design-review demo route, not reachable through normal navigation. |

---

## `subscription` — Quizoo Pro placeholders (plan 023)

| File:Line | What's mocked | Impact |
|---|---|---|
| `core/subscription/revenuecat_config.dart` (`termsUrl`, `privacyUrl`) | Both are `https://example.com/...` placeholders. | **High before release** — both stores require a real Terms of Use and Privacy Policy link on a subscription paywall, and Apple rejects a build over a dead one. Owner checklist item 7 in doc 03 §1. |
| `core/subscription/revenuecat_config.dart` (`appleApiKey`, `googleApiKey`) | Real RevenueCat **public** SDK keys, but the RevenueCat apps have **no store credentials uploaded yet** and the six real store products do not exist — only the Test Store's three placeholder-priced dev products. | **High before release** — a release build would point at real store apps that cannot serve products, so the paywall shows its unavailable state. Owner checklist items 1–3 in doc 03 §1. |
| `supabase/functions/{revenuecat-webhook,sync-pro-status}` | Deployed and complete, but fail **closed** until `REVENUECAT_SECRET_KEY` and `REVENUECAT_WEBHOOK_SECRET` are set. **Verified live on 2026-10-02: `pro_subscriptions`, `revenuecat_events` and `profiles.is_pro` are all still empty (0 rows)** — neither secret is set, so nothing has ever written the server mirror. | **High** — `profiles.is_pro` is the only thing other players' leaderboards and duel surfaces read, so a real member looks like a free player to everyone else. Their own rows are covered by the client (see below). Set the two secrets (doc 03 §2), then launch the app once: `SubscriptionRepository.start` re-syncs every already-Pro device on launch, which backfills the whole member base. |

Real by contrast: the entitlement layer (`core/subscription/`), the paywall
and membership screens, and the server-side mirror (`profiles.is_pro`,
`pro_subscriptions`, the level lock, Pro avatars, streak-shield refill) are
all genuinely wired up against the Test Store — the mirror is simply empty
because the secrets that let it be written are not set.

**The Pro badge itself** is the gold verified tick after the name and
nothing else: no crown on any avatar. For the player's *own* rows the tick
is driven by this device's entitlement (`proBadge` in
`core/subscription/pro_badge.dart`), so it appears the instant a purchase
lands even though `profiles.is_pro` is still false.

---

## Summary

10 of 14 features had at least one mocked/stubbed item. The highest-impact clusters are:

1. ~~**Shop/monetization is entirely non-functional**~~ — **the Shop feature was deleted outright (plan 013)**, not fixed; coin packs, "Remove Ads", and power-up purchases no longer exist as a surface at all.
2. ~~**Quiz Play's in-game economy is disconnected from the wallet**~~ — **fixed by plan 013**: power-ups are now granted once per level and spent from that pool, and "watch ad for heart" is a real `google_mobile_ads` rewarded ad rather than a `Timer`.
3. ~~**Duel has no real matchmaking**~~ — **fixed by plan 017**: a realtime Duel Arena (challenges + join requests), server-side matchmaking and server-refereed live duels; the bot is now only a labelled practice fallback.
4. **Delete Account doesn't delete anything** — it signs out to guest and shows a success message.
5. ~~**Home's top bar shows a fixed level/streak**~~ — **fixed by plan 019**: `PlayerTopBar` now reads the signed-in player's real `streak_days`/`player_level` from `HomeContent`.
6. **Quizoo Pro's legal URLs and store catalogue are placeholders** — the code and the database are complete, but the Terms/Privacy URLs are `example.com` and the six real store products need creating in both consoles (plan 023, owner checklist in doc 03 §1).
