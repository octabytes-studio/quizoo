# Quizoo — Daily Challenge, Leaderboards & Social, Profile/Achievements/Stats

> Source spec: Quizoo Design Bible v1.0, sections 11–13 (S-26…S-35). **The full original
> HTML is saved at `.claude/docs/quizoo-design-bible.html` in this repo — that file is the
> ground truth for exact pixel-level UI, not this plan's prose (see below).**
> Status: Draft — not yet implemented
> Depends on: **001-design-foundation.md** (theme, router skeleton, core widgets, mock-data
> convention). Also expects **002-core-loop-screens.md**'s `SessionCubit` (guest/signed-in)
> to exist, since Profile and the leaderboard "self row" both branch on it — if 002 hasn't
> landed, stub a local equivalent rather than blocking, but prefer sequencing after 002.
> This plan's `quiz_result` cross-reference (S-23, S-26) fulfills a dependency 002 already
> declared — read 002's Phase E note before starting.

## How to use this plan

Self-contained given 001 (and ideally 002) are done. Read 001's mock-data convention and
folder skeleton once more before starting. This plan fills in the placeholder routes for
S-26 through S-35 that 001 already reserved, and specifically delivers the two screens
(S-23 Badge unlocked, S-26 League promotion) that plan 002's `QuizResultCubit` navigates to
conditionally — implementing this plan is what turns those navigations from "hits 001's
generic placeholder" into "shows the real screen."

This is plan **3 of 4** (see 001 for the full series map).

**Before building any screen in this plan, open `.claude/docs/quizoo-design-bible.html` in
a browser and find that screen's frame by its `id="s-XX"` anchor** (e.g. `id="s-29"` for
the global leaderboard). The user has asked for the Flutter implementation to match this
document's screens, components and widgets exactly — the podium layout, the pinned self-
row, the badge tile/dialog treatment, the stat charts, etc. all need to be read off the
live rendered page (toggle its light/dark and app-theme switches) rather than assembled
purely from this plan's prose. Where this plan's description and the HTML file ever seem
to disagree, the HTML file wins — flag the discrepancy rather than silently picking one.

## Objective

Implement, with mock data, the app's retention/status layer: the daily challenge loop
(S-27/28), leaderboards and friends (S-29/30/31, plus the league-promotion screen S-26
that belongs narratively to results but structurally to leagues), and the profile/
achievements/stats tab (S-32/33/34/35, plus the badge-unlock interstitial S-23 that
belongs narratively to results but structurally to achievements).

## Scope

**In scope — features and their screens:**
- `features/daily/` — S-27 Daily tab, S-28 Daily result.
- `features/leaderboard/` — S-29 Global leaderboard, S-30 Category leaderboard, S-31
  Friends, S-26 League promotion.
- `features/achievements/` (profile's achievements sub-area gets its own feature per
  CLAUDE.md's "one public widget/class per file" + reasonable feature-size judgment; kept
  separate from `features/profile` because achievements has its own domain model,
  repository and is the thing plan 002 needs a route for) — S-33 Achievements grid, S-34
  Badge detail dialog, S-23 Badge unlocked interstitial.
- `features/profile/` — S-32 Profile (header + stat strip + recent badges rail + best
  categories), S-35 Stats.

**Out of scope:**
- Real ELO/matchmaking (that's plan 004's duel feature).
- Real friend-invite deep links / contact-list access — `features/leaderboard`'s Friends
  screen (S-31) uses a fixed mock friends list; "Invite friends" and "Find people you know"
  are non-functional taps that show an `AppSnackbar` ("mock — no real sharing wired yet")
  rather than opening a real OS share sheet (S-53's real `ShareSheet` widget from 001 is
  used only where the bible explicitly shows a share flow — the Daily result screen S-28
  and, in plan 004, the achievements/duel share moments — not invented here for friends).
- Real weekly/monthly reset scheduling, real global player population — leaderboard rows
  are a fixed mock list; "this week/month/all-time" and "global/country/friends" tab
  switches re-slice the *same* fixture set with slightly different mock numbers rather than
  hitting a real time-boxed backend query.

## Research findings

**S-27 Daily tab** (`features/daily`): header "Daily / {full date}" + a streak chip (🔥 N
days) in the top bar. Today's-challenge card: gradient header (name "Mixed Bag", "N
questions from N categories · Ns each", reward chips: coins/XP/time-remaining), then a
white footer strip showing "{N} PLAYED TODAY / AVG {x}/{y}" + "Play now" CTA. Below: "Your
streak" card — a 7-day row of day-circles (✓ done in mint, 🔥 today in mango, plain number
for future days, 🎁 gift icon on the 7th/reward day) + a streak-freeze explainer line ("N
streak freezes left. Miss a day and one is spent automatically."). Below that: "Milestones"
list (upcoming streak-length rewards, e.g. "14-day streak · 2 days away · 1,000 🪙").

**S-28 Daily result**: purple gradient wash; "🎯 / N out of 10" + "Better than X% of players
today"; a card showing "TODAY'S DISTRIBUTION" as a 5-bucket bar chart (0-2/3-4/5-6/7-8/9-10
correct, the player's own bucket highlighted mango) — this is a genuinely global stat in the
real product; for mock data, hardcode a plausible-looking distribution and just highlight
whichever bucket the mock score lands in; then a 2-up stat pair (coins earned / streak now);
primary CTA "Share result 📤" (opens 001's `ShareSheet` with a spoiler-free emoji grid, e.g.
🟩🟩⬜🟩🟩/🟩⬜🟩🟩🟩, matching the day's actual right/wrong pattern), secondary "Back to
Daily".

**S-29 Global leaderboard** (`features/leaderboard`): top bar "Leaderboard" + search icon;
segmented control (Global/Country/Friends); a secondary chip row (This week/This month/All
time); a **podium** (top-3 only, center-tallest layout, avatar+name+score+plinth-number,
plinth heights are the *only* place in the whole app that uses variable "podium" heights —
everywhere else is a flat row, per the bible's explicit note); below, ranked rows 4+ (rank
number, avatar, name, "🇨🇴 City", score, a rank-delta arrow ▲/▼/—); finally, **the player's
own row pinned to the bottom of the screen, always visible**, 2px grape border, showing
"Top N% · {city}" if signed in or "Not ranked — sign in to compete" if guest (branches on
`SessionCubit`). This pinned-self-row is a real layout requirement (it sits outside/below
the scrollable list, not just "the last list item") — implement it as a fixed footer
above the tab bar, not as a `ListView` item that happens to scroll into view.

**S-30 Category leaderboard**: reached from a subcategory's context (e.g. Football);
header shows "You're #{n} in {country}" + "{points} points from the top 10" in a gradient
card; ranked rows show per-player "{levels}/20 levels · {stars} ⭐" as the secondary line
instead of a city; footer CTA "Play {Subcategory} Level {current}" deep-links back into
`features/catalog`'s level map (cross-feature navigation via `go_router` route, not a
direct import — per CLAUDE.md §10, features never import another feature's internals;
only route through `AppRoutes` constants).

**S-31 Friends**: "Friends / N friends · N pending" + add-friend icon; an "Invite friends"
promo card (mock reward text "You both get 200 🪙"); a "REQUESTS" section (incoming
requests as rows with ✓/✕ accept-decline icon buttons); a "FRIENDS" section (each row shows
online status — "🟢 Playing {subcategory} now" vs "Last seen {relative time} · {score}
pts" — and, only for online friends, a mango "⚔️ Duel" pill; offline friends get the same
pill visually dimmed/disabled). The duel pill navigates to plan 004's duel route (route
constant only, cross-feature-safe per the note above); if plan 004 hasn't landed, it will
correctly hit 001's placeholder.

**S-26 League promotion** (belongs here, not in plan 002, despite being reached from the
result flow): gold gradient wash; a "SILVER → GOLD" rank-icon transition row (previous
league dimmed/small, new league large/prominent); "You're in {League} League" headline +
explainer ("Top 30 finish this week promotes you to Platinum. Bottom 10 drops back to
Silver. Resets Sunday 00:00 UTC."); a mini league-standings card showing 3 rows (the two
neighbors + the player's own row, 2px grape border) with live rank numbers and points;
"Let's go" CTA. This screen is a **league** (weekly cohort of ~30 similar-XP players),
which is a distinct concept from the **leaderboard** (global/country/category all-time or
periodic ranking) — both live in `features/leaderboard` but are separate domain models
(`LeagueStanding` vs `LeaderboardEntry`) since the bible itself treats them as separate
systems (§19: "Leagues are separate from boards").

**S-32 Profile** (`features/profile`): full-bleed gradient header (cosmic grape→sky) with
a back-less top row (just a settings gear, right-aligned), avatar (74px, ringed), username,
"{city} · Joined {month year}", league + streak chips, and an XP bar sitting *inside* the
gradient (bible: "so progress reads as part of who you are, not a widget"). Below the
header: a 4-up stat strip (points/levels/accuracy/badges) in a card; "Recent badges" rail
(horizontal, 3-ish badges shown, "All N" link → S-33); "Best categories" rows (subcategory
icon, name, "Level N/20 · N ⭐", accuracy% + label). A **public profile** variant (reached
by tapping another player from a leaderboard/friends row) is "the same layout minus
settings and wallet" — implement as the same screen/widget with a `isOwnProfile` flag
rather than a duplicate screen, gating only the settings-gear and any owner-only actions.

**S-33 Achievements grid** (`features/achievements`): back + "Achievements" + "N of 48
unlocked" + an overall progress bar; filter chips (All/Skill/Streak/Social/Rare); a grid of
badge tiles (unlocked: full-color gradient plate + emoji + name; locked: greyscale plate at
~40% opacity, per the bible's explicit "you cannot want what you cannot see" — locked stays
*visible*, never hidden). Tapping any tile opens S-34.

**S-34 Badge detail dialog**: modal dialog, badge icon plate (bigger, 84px), name,
description ("Reach Level 20 with three stars in every subcategory of a single category"),
then — only for locked badges — a progress card showing the *closest* qualifying path
("SPORTS · CLOSEST / 3 / 8 TOPICS" + a thin progress bar + "Next up: {Subcategory} — you're
on Level N of 20"), then rarity/reward chips ("🏆 Rare · 2.1%" / "+2,000 🪙"), then two
actions: a deep-link CTA naming the exact next action ("Play {Subcategory}" → routes into
`features/catalog`) and "Close". For already-unlocked badges, this dialog can omit the
progress card (show unlock date/celebratory framing instead) — the bible only shows the
locked variant explicitly; extrapolate the unlocked variant reasonably (name, description,
reward chips, "unlocked {date}", single "Close" action) and flag that extrapolation here
rather than presenting it as bible-specified.

**S-23 Badge unlocked** (interstitial, full-screen, not a toast): grape gradient, "ACHIEVEMENT
UNLOCKED" eyebrow, large (140px) gradient badge plate, name, description, "only {rarity}% of
players have this one" framing, a reward chip; two actions: gold "Share this 📤" (opens
001's `ShareSheet`) and "Nice" (dismiss). Per plan 002's Phase E, this screen is reached by
`context.push` from `QuizResultCubit` when its mock data says a badge was newly earned this
run — this plan is responsible for the actual route/screen existing; it does not need to
know anything about `quiz_result`'s internals (route constant only).

**S-35 Stats**: back + "Your stats" + a "Last 30 days ▾" chip (mock: cosmetic only, doesn't
actually re-query — flag that the date-range picker is non-functional chrome in this phase);
"POINTS PER DAY" 7-bar chart (today's bar highlighted mango); "Accuracy by category"
per-category thin progress bars (color-coded: ≥70% mint-ish/`ok`, <50% raspberry/`bad`,
matching the bible's own worked example of Maths at 48% going raspberry) each followed
**immediately** by a coaching card for the single weakest category ("💡 Maths is your
weakest category. Ten minutes a day for a week would move you past 60%." — bible's own
explicit rule: "Never show a stat without saying what to do about it"); "Fastest answers"
single highlight row.

## Assumptions & open questions

1. **League vs. leaderboard as separate domain models, same feature folder.** Both are
   "ranking" concepts but the bible treats them as structurally different systems (leagues
   promote/relegate a fixed cohort of ~30; leaderboards are open periodic/all-time
   rankings). Housing both under one `features/leaderboard/` folder (with two domain
   models and two repositories) rather than splitting into `features/leaderboard/` +
   `features/league/` is a judgment call favoring fewer, denser features over more, thinner
   ones — flagging so the user can veto if they'd rather split it.
2. **S-34's unlocked-badge variant is extrapolated**, not bible-specified (see Research
   findings) — flagged inline there.
3. **S-35's "Last 30 days ▾" range picker is non-functional mock chrome.** Building a real
   date-range-driven mock data recompute is disproportionate effort for a UI-design pass;
   flagged rather than silently building a fake-but-convincing interactive picker.
4. **Friends' online/offline status is static mock data**, not a real presence system (that
   would require the realtime backend the bible itself defers to §24, out of scope
   everywhere in this whole plan series per 001's Scope).
5. **`ShareSheet` reuse**: this plan is the second of the two features 001's Assumption 6
   anticipated needing `core/widgets/share_sheet.dart` (daily result + badge-unlock). No
   new assumption needed here — just confirming the dependency is real and already
   accounted for.

## Design overview

```
features/
├── daily/
│   ├── data/daily_api.dart, daily_repository.dart
│   ├── domain/daily_challenge.dart, daily_result.dart, streak_status.dart
│   └── presentation/
│       ├── bloc/daily_cubit.dart (+state: Initial/Loading/Loaded/Error)
│       ├── bloc/daily_result_cubit.dart (+state)
│       ├── screens/daily_screen.dart, daily_result_screen.dart
│       └── widgets/streak_week_row.dart, distribution_chart.dart, milestone_row.dart
├── leaderboard/
│   ├── data/leaderboard_api.dart, leaderboard_repository.dart
│   ├── domain/leaderboard_entry.dart, league_standing.dart
│   └── presentation/
│       ├── bloc/leaderboard_cubit.dart (+state — params: scope Global/Country/Friends ×
│       │        period Week/Month/AllTime, re-fetched or re-sliced on change)
│       ├── bloc/league_cubit.dart (+state)
│       ├── screens/leaderboard_screen.dart, category_leaderboard_screen.dart,
│       │        friends_screen.dart, league_promotion_screen.dart
│       └── widgets/podium.dart, pinned_self_row.dart, friend_row.dart
├── achievements/
│   ├── data/achievements_api.dart, achievements_repository.dart
│   ├── domain/badge_progress.dart (uses core/models Badge)
│   └── presentation/
│       ├── bloc/achievements_cubit.dart (+state)
│       ├── screens/achievements_screen.dart, badge_unlocked_screen.dart
│       └── widgets/badge_tile.dart, badge_detail_dialog.dart
└── profile/
    ├── data/profile_api.dart, profile_repository.dart
    ├── domain/profile_summary.dart, category_accuracy.dart
    └── presentation/
        ├── bloc/profile_cubit.dart (+state), stats_cubit.dart (+state)
        ├── screens/profile_screen.dart (isOwnProfile flag — see Research findings), stats_screen.dart
        └── widgets/stat_strip.dart, points_per_day_chart.dart, category_accuracy_row.dart
```

## Implementation steps

- [ ] **Phase A — Daily.** `DailyRepository`/`DailyApi` mock returning today's challenge +
  streak status + milestones. `DailyScreen` per Research findings. `DailyResultScreen` +
  `DailyResultCubit` computing the mock distribution-bucket highlight from the player's
  score; wire "Share result" to 001's `ShareSheet` with a generated emoji grid derived from
  the mock per-question right/wrong array (not hardcoded to the bible's literal example
  string).
- [ ] **Phase B — Leaderboard & league.** `LeaderboardRepository`/`Api` mock with a fixed
  roster (recommend ~15-20 fixture players with names/avatars/countries/scores) sliced
  differently per scope/period param. Build `Podium`, `PinnedSelfRow` (fixed-position
  footer, branches on `SessionCubit`), then `LeaderboardScreen` and
  `CategoryLeaderboardScreen` reusing them. `FriendsScreen` with its own small fixed mock
  friends list (online/offline mix). `LeaguePromotionScreen` + `LeagueCubit` (separate mock
  roster of ~30 league-mates, player's neighbors picked out for the mini-standings card).
- [ ] **Phase C — Achievements.** `AchievementsRepository`/`Api` mock returning a fixed set
  of ~12-14 badges (mix of unlocked/locked, matching the bible's own named examples —
  Sharpshooter, Night Owl, Quick Draw, Week Warrior, Big Brain, Category King, Centurion,
  Globetrotter, Duelist, Scholar, Rocket, Flawless — reuse these names/emoji directly from
  the bible rather than inventing new ones, since they're already fully specified).
  `AchievementsScreen` (grid + filter chips — filtering is real client-side filtering over
  the fixed set, not mock chrome, since it's cheap to make functional). `BadgeDetailDialog`
  (locked variant per spec, unlocked variant per Assumption 2's extrapolation).
  `BadgeUnlockedScreen` as its own route (S-23), taking a badge id via route `extra`/param.
- [ ] **Phase D — Profile & stats.** `ProfileRepository`/`Api` mock returning the header
  stats + recent badges (reuse `AchievementsRepository`'s fixture set rather than
  duplicating badge data — this is exactly the kind of 3+-feature reuse that justifies
  `Badge` living in `core/models/` per 001) + best-categories list. `ProfileScreen` with the
  `isOwnProfile` flag. `StatsScreen` + `StatsCubit` with the 7-bar chart and per-category
  accuracy rows, each followed by the single weakest-category coaching card (compute "the
  weakest" client-side from the mock accuracy list, don't hardcode which category it is).

## Data model / API changes

New shared model, if not already covered by 001: none required beyond `core/models/
badge.dart` (already planned in 001) being consumed by both `achievements` and `profile`
here — this is the concrete case that justifies its `core/` placement.

Feature-local models: `LeaderboardEntry` (rank, playerId, name, avatarEmoji, country?,
score, rankDelta), `LeagueStanding` (same shape, league-scoped), `DailyChallenge`,
`DailyResult`, `BadgeProgress` (wraps `core.Badge` with a locked-progress payload).

## Dependencies

No new packages beyond 001's list. The bar/distribution charts (S-28, S-35) are simple
enough to hand-build with `Container`/`CustomPainter` per the bible's own minimal CSS bar-
chart pattern — no charting package needed.

## Testing strategy

- `DailyCubit`, `DailyResultCubit`, `LeaderboardCubit`, `LeagueCubit`, `AchievementsCubit`,
  `ProfileCubit`, `StatsCubit`: `bloc_test` suites, initial/success/failure each, per
  CLAUDE.md §11.
- Repository unit tests with `mocktail`-mocked `*Api` classes for each of the above.
- Widget tests per sealed-state branch: `LeaderboardScreen` (loading/loaded-with-self-
  ranked/loaded-guest-unranked/error), `AchievementsScreen` (loaded with a mix of locked/
  unlocked tiles rendering the correct opacity treatment), `ProfileScreen` (own-profile vs
  public-profile variants).
- A dedicated test asserting `PinnedSelfRow` never scrolls with the list (renders outside
  the scrollable's bounds) — this is a real, easy-to-regress layout requirement.

## Edge cases & error handling

- Guest viewing their own leaderboard row: must show "Not ranked — sign in to compete"
  and a tap-to-sign-in affordance (routes to `features/auth`'s save-progress sheet or
  profile creation, per plan 002) rather than a broken/zero rank.
- Achievements filter chip selected with zero matching badges: falls back to 001's
  `EmptyStateView`, not a blank grid.
- Friends tab with zero friends: falls back to 001's `EmptyStateView` per the bible's own
  S-47 example (this is in fact the bible's own worked example for the empty-state
  pattern — implement it exactly as shown: "No friends yet" + reward-framed body copy +
  Invite/Find-people actions).
- Stats screen with a category that has zero attempts yet: exclude it from the accuracy
  list entirely rather than showing a 0%/raspberry row that would misleadingly look like
  the "weakest category" coaching target.

## Acceptance criteria

- [ ] Every screen built in this plan (S-26…S-35) has been visually compared, side by
  side, against its frame in `.claude/docs/quizoo-design-bible.html`, not just implemented
  from this plan's prose description, since the user has asked for exact parity with that
  document.
- [ ] Global leaderboard shows a podium, ranked rows, and a pinned self-row that responds
  correctly to guest vs. signed-in `SessionCubit` state.
- [ ] Switching Global/Country/Friends and Week/Month/All-time visibly re-slices the mock
  roster (different order/scores), proving the params are wired even though the data is
  fixture-backed.
- [ ] Tapping a locked achievement shows its closest-progress path and a working deep-link
  CTA into the catalog feature; tapping an unlocked one shows the (extrapolated) unlocked
  variant.
- [ ] Stats screen's weakest-category coaching card always matches whichever category
  actually has the lowest accuracy in the mock data (verify this is computed, not
  hardcoded, by changing the fixture and re-running the test).
- [ ] `flutter analyze` zero warnings; all new Cubits have passing `bloc_test` suites.

## Risks & rollout notes

- The podium + pinned-self-row layout (S-29) is the second-most layout-complex piece in
  this plan (after the level map in plan 002) — the "always visible, outside the scroll"
  requirement is easy to get subtly wrong (e.g. accidentally clipping it under the tab bar
  on short screens); test on a small device size explicitly.
- No migration/rollback concerns — greenfield, mock data only.
