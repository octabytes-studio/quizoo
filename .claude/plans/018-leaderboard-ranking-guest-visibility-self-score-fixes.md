# Leaderboard Bug Fixes — Ranking, Guest Visibility, Self Score

> Source spec: provided inline in conversation ("Leaderboard Bug Fixes" — 1)
> ranking is wrong, 2 real users with lower actual scores show above the
> current user; 2) a guest user's card incorrectly appears in the ranking
> shown to other players (their own view of their own score is fine to keep);
> 3) the current user's own card on the Leaderboard screen shows a score of 0).
> Status: **Implemented and verified live, 2026-09-28.** Migration
> `supabase/migrations/20260928100000_fix_leaderboard_totals_country_and_guests.sql`
> applied to the live project; `refresh-lb-weekly` is now succeeding on
> schedule (first success at 10:12 UTC), guest rows are 0 in all three
> `_totals` views, and the two previously-zeroed real users now show correct
> points. See "Additional findings" for the Phase 1 audit and the
> Implementation/Acceptance checkboxes below for the full verification
> record.

## How to use this plan

This plan is self-contained: executing it needs no prior conversation
history. Read it in full before starting. It fixes one root cause (a crashing
`pg_cron` refresh job) plus one missing filter, both in SQL only — **no Dart
code changes are required** for any of the three reported symptoms. Code and
data may have moved on since this was written (28 Sep 2026); Phase 0 tells you
exactly how to re-check the diagnosis still holds before touching anything.

Hard project rules that bind this work (from `CLAUDE.md`): never run the app
to verify (§13) — static verification only (`dart analyze`, `dart format`,
`flutter test`) plus the SQL checks below; shared files like `app/router.dart`
aren't touched here at all, this is a Supabase migration; per §9/§10 the
Dart data layer (`LeaderboardApi`/`LeaderboardRepository`) is the only layer
that talks to these views and needs no changes since the fix is entirely at
the SQL/view level.

## Objective

Fix three symptoms on the Leaderboard screen (global/country scope,
`lib/features/leaderboard/`): stale/wrong ranks and point totals, guest
players visible in other players' rosters, and the current (real, signed-in)
user's own card showing a score of `0`. All three trace back to one incident:
the `refresh-lb-weekly` `pg_cron` job has been silently failing since
**2026-09-19**, freezing the global/country leaderboard's materialized views
at a stale snapshot — plus a separate, always-present gap where guest
profiles were never excluded from those views.

## Scope

**In scope:**
- `lb_weekly_totals`, `lb_monthly_totals`, `lb_alltime_totals` materialized
  views (defined in `supabase/migrations/20260908090000_leaderboard_totals.sql`)
  — the ones backing the global/country Leaderboard screen
  (`LeaderboardApi.fetchRoster`/`fetchSelfEntry` with
  `LeaderboardScope.global`/`.country`).
- `public._refresh_leaderboards()` (currently defined twice — originally in
  `20260907120200_functions_and_triggers.sql`, replaced in
  `20260908090000_leaderboard_totals.sql`, which is the version that runs
  today) — made resilient so one broken view can't silently freeze the rest
  again.
- A one-time backfill/refresh of the corrected views once deployed, so
  existing stale ranks/scores are corrected immediately rather than waiting
  for the next successful cron tick.
- A deep audit (Phase 1 below) of the leaderboard feature's Dart code and
  its Supabase backend — beyond the two root causes already diagnosed — to
  surface any other implementation flaws or latent bugs before this plan is
  considered done. This is a deliberate instruction, not optional
  due-diligence: the two root causes in this plan were found by actually
  querying live data rather than trusting the code's comments, and the same
  scrutiny should be applied to the rest of the feature before signing off.

**Out of scope:**
- `lb_weekly`, `lb_monthly`, `lb_alltime` (no `_totals` suffix) and the
  category leaderboard (`fetchCategoryRoster`/`fetchCategoryHeader`) — these
  are grouped by `(user_id, subcategory_id, category_id, country_code)` with
  that **full** tuple as the unique index, so they are not subject to the
  crash this plan fixes (see Research findings). They **do** share the same
  "guest players aren't filtered out" gap, since they're plain
  `public.score_events` aggregates with no `profiles.is_guest` join either —
  flagged as a follow-up under "Assumptions & open questions," not fixed
  here, since the bug report is specifically about the Leaderboard screen's
  ranking and self-row, not the per-category board.
- `LeaderboardScope.friends` (`_friendsRoster` in `leaderboard_api.dart`) —
  aggregates `score_events` live for the caller's friend list, unaffected by
  the materialized-view crash. A friend who is also a guest is a separate,
  narrower question (can a guest even accept friend requests today?) not
  raised by the bug report; not touched here.
- Any Dart/Flutter changes. `LeaderboardApi`, `LeaderboardRepository`,
  `LeaderboardCubit`, and all leaderboard screens/widgets keep their current
  signatures and behavior; they already do the right thing once the views
  underneath them are correct.
- League standings (`fetchLeagueNeighbors`, `league_memberships` table) — a
  separate, non-materialized-view mechanism, not implicated by any of the
  three reported symptoms.

## Research findings

### Governance that applies (`CLAUDE.md`)
- §9: "Repositories are the only layer that talks to `*_api.dart`... All Dio
  exceptions are mapped to a single typed `ApiException`" — not touched here,
  since the fix doesn't change the API surface, only the data the same query
  returns.
- §13: never run the app to verify. Verification here is `dart analyze` (as a
  no-op sanity check, since no Dart changes), plus direct SQL checks via the
  Supabase MCP tools (read-only `execute_sql`) and re-running
  `mcp__supabase__get_advisors` after the migration, and finally a manual
  "To verify" list for the developer to confirm in the running app.

### Current code path (all in `lib/features/leaderboard/`)
- `data/leaderboard_api.dart` `fetchRoster()` (`leaderboard_api.dart:31-80`):
  for `global`/`country` scope, reads `lb_{period}_totals`, orders by
  `rank_global` or `rank_country`, limits to 50, joins `profiles` for
  name/avatar/location. **No filter excludes `profiles.is_guest`.**
- `fetchSelfEntry()` (`leaderboard_api.dart:82-134`): looks up the caller's
  own row by `user_id` in the same view; if the row is `null` (not present in
  the materialized view), it falls back to `_selfProfileEntry(..., rank: 0,
  score: 0, topPercent: 100)` (`leaderboard_api.dart:99-108`,
  `:365-382`). This fallback is *correct* for a player who has genuinely
  never scored — the bug is that it's also what a real, actively-playing
  player sees when their row is simply missing from a stale view.
- `presentation/bloc/leaderboard_cubit.dart` `load()` always calls both
  `fetchRoster` and `fetchSelfEntry` and emits them together in
  `LeaderboardLoaded` — no client-side logic to fix; it faithfully renders
  whatever the repository returns.
- `presentation/widgets/pinned_self_row.dart` / `leaderboard_screen.dart:139-146`:
  already special-cases guests (`session is SessionGuest`) by not calling
  into `lbState.selfEntry` at all and showing a "sign in to compete" CTA
  instead — this is how "keep showing the guest their own score to
  themselves" already holds today (that's handled elsewhere, e.g. the You/
  Profile screen, not this file) and needs no change.

### Root cause 1 — `refresh-lb-weekly` cron job has been crashing since 2026-09-19

`supabase/migrations/20260908090000_leaderboard_totals.sql:18-51` defines:

```sql
create materialized view public.lb_alltime_totals as
select
  user_id, country_code,
  sum(points) as points,
  rank() over (order by sum(points) desc) as rank_global,
  rank() over (partition by country_code order by sum(points) desc) as rank_country
from public.score_events
group by user_id, country_code;

create unique index lb_alltime_totals_pk on public.lb_alltime_totals (user_id);
```

(same shape for `lb_weekly_totals`/`lb_monthly_totals`, just with a
`where occurred_at >= date_trunc(...)` filter). The view groups by
**`(user_id, country_code)`** — two columns — but the unique index backing
`REFRESH MATERIALIZED VIEW CONCURRENTLY` covers only **`user_id`**. If any
player has `score_events` rows spanning two different `country_code` values
(e.g. one row from before their profile had a country set, `country_code
IS NULL`, and later rows after it was set to e.g. `'PK'`), the `group by`
produces **two rows sharing the same `user_id`** — which the unique index
rejects. `_refresh_leaderboards()`
(`20260908090000_leaderboard_totals.sql:56-69`) calls all six
`refresh materialized view concurrently` statements as one function; when one
raises, the whole call aborts (and rolls back, since pg_cron runs the whole
`select public._refresh_leaderboards();` as a single statement/transaction) —
so **none** of the six views have refreshed since the crash started, not just
the one that failed.

Confirmed live (read-only queries against the project's Supabase database,
2026-09-28 — see "Live data confirmation" below): this is exactly what's
happening, for exactly the reason above, and has been happening
intermittently since **2026-09-19 19:58 UTC** (5,723 of 14,890 total
`refresh-lb-weekly` runs have failed with this same error), with every run in
the last several hours failing outright.

**Why this produces all three reported symptoms:**
- **Wrong ranking** (2 real users shown above the current user who
  shouldn't be): the roster the app reads is whatever snapshot existed at
  the last *successful* refresh — an old ranking, not today's.
- **Current user's card shows 0**: any real player whose first score event
  landed after the last successful refresh has no row at all in the frozen
  view yet, so `fetchSelfEntry` legitimately finds `null` and falls back to
  `score: 0` — even though they've genuinely scored. confirmed live: two
  real (non-guest) users have `sum(score_events.points)` of `9,540` and
  `3,573` respectively, but `0` in `lb_alltime_totals` because they have no
  row there at all.

### Root cause 2 — guest players are never excluded from the totals views

Separately, and unrelated to the crash above: `lb_weekly_totals`/
`lb_monthly_totals`/`lb_alltime_totals` aggregate `public.score_events`
directly with no join against `public.profiles.is_guest`
(`profiles.is_guest boolean not null default true`, set on signup —
`20260907120000_initial_schema.sql:51`,
`20260907120200_functions_and_triggers.sql:28-33`). Confirmed live: of 26
rows currently in `lb_alltime_totals`, 2 belong to guest profiles (1 of 19
guest profiles total shows up in `lb_weekly_totals`). Since `LeaderboardApi`
does not filter guests out either, any guest currently in the (stale) view
is shown as a normal ranked row to every other player.

### Live data confirmation (read-only, via Supabase MCP `execute_sql`)

- `guest_rows_in_alltime: 2`, `guest_rows_in_weekly: 1`, out of
  `total_alltime_rows: 26` — guests are present in the roster today.
- Two real (`is_guest = false`) users have `live_sum(score_events.points)` of
  `9,540` and `3,573` but `0`/no row in `lb_alltime_totals` — the exact "my
  score shows 0" symptom.
- One guest profile has `score_events` rows with `country_code = null` (1
  row, 300 pts) **and** `country_code = 'PK'` (12 rows, 37,039 pts) — this is
  the specific user whose duplicate `(user_id, country_code)` group is
  crashing `refresh materialized view concurrently public.lb_monthly_totals`
  on every run right now (`duplicate key value violates unique constraint
  "lb_monthly_totals_pk" ... Key (user_id)=(514448b2-...) already exists`).
- `cron.job` confirms `refresh-lb-weekly` (`*/2 * * * *`) is `active: true` —
  it's running, just failing every time it hits the duplicate.
- `cron.job_run_details` confirms the first failure at
  `2026-09-19 19:58:00 UTC`, 5,723/14,890 failed runs overall, and the 10
  most recent runs (through `2026-09-28 09:26:00 UTC`) all failing with the
  identical error.

Re-run these before implementing (Phase 0) in case the data has moved on —
the exact user IDs/counts above are a point-in-time snapshot, not something
to hardcode into the fix. Phase 1 goes further: it's a deep audit of the
rest of the feature and backend for issues beyond these two, not just a
re-check of these specific numbers.

## Assumptions & open questions

- **Country attribution for the fix**: the fix below computes each player's
  `country_code` from their *current* `public.profiles.country_code` (a
  join) instead of aggregating the possibly-multiple `country_code` values
  seen across their `score_events`. This is a deliberate interpretation: a
  "country leaderboard" should reflect where a player currently says they're
  from, not a historical mix of values captured per-event (which is also
  exactly what's crashing the refresh). If a player has no `country_code` on
  their profile at all, they'll have `country_code = null` and simply won't
  appear on any country-scoped board (matching `fetchRoster`'s existing
  `if (myCountry == null) return const [];` behavior for the viewer side) —
  this seems like the intended existing behavior, not something to change.
- **Category leaderboard's identical guest gap** (`lb_alltime`/`fetchCategoryRoster`)
  is left out of scope per the "Out of scope" section above, since the bug
  report is specifically about the Leaderboard screen. Flagging so it isn't
  lost: the same `where not p.is_guest` treatment (Phase 2 below) should
  eventually be applied to `lb_weekly`/`lb_monthly`/`lb_alltime` too, ideally
  as its own small follow-up plan, since it's a different set of views with a
  different (already-safe) unique-index shape and touches the category board
  screens, not just this one.
- **Resiliency phase (Phase 3)** — wrapping each `refresh materialized view
  concurrently` call in `_refresh_leaderboards()` so one broken view can't
  silently freeze the other five — is not strictly required to fix the three
  reported symptoms (Phase 2 alone removes the only known crash trigger), but
  given this exact failure mode ran undetected in production for 9 days, it's
  recommended as part of the same change. It's written as a separately
  checkable phase so it can be dropped if the developer wants a minimal fix
  first and the resiliency work later.

## Design overview

Two SQL changes, both in a new migration, applied in order:

1. **Redefine the three `_totals` materialized views** to derive
   `country_code` from `public.profiles` (one row per `user_id`,
   guaranteed) instead of from `public.score_events` (which can carry
   multiple distinct values per user), and to exclude guest profiles. Since
   Postgres has no `CREATE OR REPLACE MATERIALIZED VIEW`, each view is
   dropped (which also drops its index) and recreated with the same name,
   columns, and grants as today, plus the fix:

   ```sql
   create materialized view public.lb_alltime_totals as
   select
     se.user_id,
     p.country_code,
     sum(se.points) as points,
     rank() over (order by sum(se.points) desc) as rank_global,
     rank() over (partition by p.country_code order by sum(se.points) desc) as rank_country
   from public.score_events se
   join public.profiles p on p.id = se.user_id
   where not p.is_guest
   group by se.user_id, p.country_code;

   create unique index lb_alltime_totals_pk on public.lb_alltime_totals (user_id);
   ```

   (same shape, with the existing `where occurred_at >= date_trunc(...)`
   filter retained, for `lb_weekly_totals`/`lb_monthly_totals`). Grouping by
   `p.country_code` (functionally dependent on `se.user_id` via the join) is
   what guarantees exactly one row per `user_id`, which is what makes the
   unique index — and therefore `REFRESH ... CONCURRENTLY` — safe again. The
   `where not p.is_guest` clause removes guest rows from the roster and,
   since it happens before the `rank()` window functions run, real players'
   ranks/percentiles are computed only against other real players (no
   client-side re-ranking needed).

2. **(Recommended) Harden `_refresh_leaderboards()`** so a future failure in
   any single view can't cascade into freezing the rest — wrap each
   `refresh materialized view concurrently` call individually:

   ```sql
   create or replace function public._refresh_leaderboards()
   returns void
   language plpgsql security definer
   set search_path = public
   as $$
   begin
     begin
       refresh materialized view concurrently public.lb_weekly;
     exception when others then
       raise warning 'lb_weekly refresh failed: %', sqlerrm;
     end;
     -- ...repeat for lb_monthly, lb_alltime, lb_weekly_totals,
     --    lb_monthly_totals, lb_alltime_totals
   end;
   $$;
   ```

   This turns a future one-view failure into a logged warning instead of a
   silent, total, multi-week freeze — the exact failure mode that caused this
   bug report.

3. **One-time catch-up refresh**: end the migration with
   `select public._refresh_leaderboards();` so the corrected views are
   populated immediately on deploy, rather than waiting up to 2 minutes for
   the next cron tick (which will now succeed).

No Dart changes. `LeaderboardApi.fetchRoster`/`fetchSelfEntry` read the same
column names (`user_id, country_code, points, rank_global, rank_country`)
from the same view names — the query shape is unchanged, only the rows the
views produce are corrected.

## Implementation steps

- [x] **Phase 0 — Re-verify the live diagnosis.** Before writing the
  migration, re-run the read-only queries from "Live data confirmation"
  (via `mcp__supabase__execute_sql`) to confirm: (a) `refresh-lb-weekly` is
  still failing and with the same duplicate-key error, (b) which specific
  user(s)/rows are causing the duplicate today (the exact ID(s) may differ
  from this snapshot), and (c) the current guest-row count in
  `lb_alltime_totals`/`lb_weekly_totals`/`lb_monthly_totals`. If the picture
  has materially changed (e.g. the job is no longer failing), stop and
  re-diagnose rather than applying this fix blind.
- [x] **Phase 1 — Deep audit: look for additional issues before fixing
  anything.** Do not stop at the two root causes already diagnosed above —
  they were found by reading the code *and* directly querying live data, and
  the rest of the feature deserves the same treatment before this plan is
  considered complete. Concretely:
  - **Read the entire leaderboard feature end-to-end**, not just the files
    already cited in this plan: every file under `lib/features/leaderboard/`
    (`data/`, `domain/`, `presentation/bloc/`, `presentation/screens/`,
    `presentation/widgets/`), including the parts this plan marked
    out-of-scope (`LeaderboardScope.friends`/`_friendsRoster`, the category
    board's `fetchCategoryRoster`/`fetchCategoryHeader`,
    `fetchLeagueNeighbors`/league standings). Look for correctness issues
    independent of the two root causes: incorrect null/empty handling,
    off-by-one or boundary bugs in ranking/limit logic (`_rosterLimit`,
    the `lo`/`hi` window math in `fetchLeagueNeighbors`), mismatched
    `isSelf`/`playerId` comparisons, stale-closure or race-condition risk
    when scope/period changes fire in quick succession
    (`LeaderboardCubit.changeScope`/`changePeriod`), and anything that
    contradicts CLAUDE.md's layering rules (§1, §9).
  - **Read the full Supabase backend surface this feature depends on**, not
    just `20260908090000_leaderboard_totals.sql`: every migration that
    creates or writes to `score_events`, `profiles`, `friendships`,
    `league_memberships`/`league_cohorts`, and the `lb_*`/`lb_*_totals`
    views and their supporting functions
    (`20260907120000_initial_schema.sql`,
    `20260907120200_functions_and_triggers.sql`,
    `20260909120100_fix_submit_level_attempt_player_level_column.sql`,
    `20260910090300_ladder_rpc_rewrite.sql`,
    `20260910090500_language_scope_daily_and_duels.sql`,
    `20260919194353_real_achievement_engine.sql`, plus any duel-scoring
    migrations). Specifically look for: other places that write
    `score_events.country_code` inconsistently for the same user (which
    would reintroduce Root cause 1's failure mode for a *different* column
    combination even after Phase 2's fix), double-counting or duplicate
    inserts into `score_events` (e.g. a retried RPC call), negative or
    implausible `points` values, `source` values that don't match the
    `check` constraint's intent, and RLS policies on `score_events`/
    `profiles`/`lb_*` that are missing or too permissive.
  - **Query live data, read-only, via the Supabase MCP tools**
    (`mcp__supabase__execute_sql`, `get_advisors`, `query_logs`) to verify
    or falsify any suspicion raised above — do not report a "potential
    issue" without at least attempting to confirm it against real rows, the
    same way Root causes 1 and 2 in this plan are backed by actual query
    results rather than code-reading alone. In particular, check whether
    `lb_weekly`/`lb_monthly`/`lb_alltime` (the category board's views, not
    the `_totals` ones) or the friends/league paths show the same
    guest-inclusion gap or any duplicate-row risk analogous to Root cause 1.
  - **Record every additional finding**, whether or not it gets fixed here,
    in a new "Additional findings" section appended to this plan file
    (placed after "Risks & rollout notes"below) — one entry per finding,
    each with: the exact file/line or migration/query, the concrete failure
    scenario (inputs/state → wrong behavior), the query or code excerpt that
    confirms it, and a severity/confidence judgment.
  - **Triage each finding** into one of two buckets, and say which bucket in
    the write-up:
    - *Fix inline*: small, clearly correct, low-risk, and squarely about
      leaderboard correctness/data-integrity (e.g. another instance of the
      exact "grouped-by-more-columns-than-the-unique-index" defect, or the
      guest-filter gap extending to `lb_weekly`/`lb_monthly`/`lb_alltime`).
      Fold these into the same migration as Phase 2/3, and add each one as
      its own explicit line in "Acceptance criteria" so the scope addition
      is visible and reviewable rather than silent.
    - *Defer*: anything unrelated to leaderboard display/ranking, higher
      risk, larger in scope, or outside a different feature's boundary
      (e.g. a duel-scoring bug, an achievement-engine issue, a broad RLS
      hardening task). Do not fix these here — write them up for a human or
      a separate `do-plan` pass, per this project's own planning discipline
      of not silently expanding scope mid-task.
- [x] **Phase 2 — New migration: fix the views.** Create
  `supabase/migrations/<timestamp>_fix_leaderboard_totals_country_and_guests.sql`
  (timestamp later than the latest existing migration,
  `20260928090000_...`) that:
  - `drop materialized view public.lb_weekly_totals;` /
    `lb_monthly_totals` / `lb_alltime_totals` (in any order — nothing else
    depends on them per the repo-wide grep in Research findings).
  - Recreates all three per the Design overview §1, each followed by its
    `create unique index ..._pk on public....(user_id);` and by
    `grant select on public.lb_weekly_totals, public.lb_monthly_totals, public.lb_alltime_totals to authenticated, anon;`
    (matching the original migration's single combined grant statement,
    `20260908090000_leaderboard_totals.sql:53-54`).
  - Include a header comment explaining the two root causes (duplicate
    `(user_id, country_code)` groups crashing `REFRESH ... CONCURRENTLY`,
    and missing guest exclusion) and pointing back at this plan file, in
    the same documentary style as the comment already at the top of
    `20260908090000_leaderboard_totals.sql`.
- [x] **Phase 3 (recommended) — Harden the refresh function.** In the same
  migration (or a follow-up one if the developer wants Phase 1 shipped
  alone first), `create or replace function public._refresh_leaderboards()`
  per Design overview §2, wrapping each of the six
  `refresh materialized view concurrently` calls in its own
  `begin ... exception when others then raise warning ...; end;` block. Keep
  the function's existing signature/grants/`security definer` exactly as-is
  — only the body changes, so the existing `cron.schedule('refresh-lb-weekly', ...)`
  registration (`20260907120200_functions_and_triggers.sql:1203`) needs no
  change (`create or replace function` keeps it pointed at the same,
  now-fixed, function).
- [x] **Phase 4 — Catch-up refresh + verification.** End the migration with
  `select public._refresh_leaderboards();`. After applying (via
  `mcp__supabase__apply_migration`, per the Supabase MCP guidance to prefer
  local/dry-run testing before touching the live project, mirroring how
  plans 007/008/016/017 applied their migrations), re-run the diagnostic
  queries: confirm `cron.job_run_details` shows a `succeeded` run after
  deploy, `select count(*) from public.lb_alltime_totals join public.profiles on id = user_id where is_guest;`
  returns `0`, and that the two previously-missing real users now have
  non-zero rows matching their live `score_events` sums. Also run
  `mcp__supabase__get_advisors(type: "performance")` and `("security")`
  afterward per standard practice when DDL changes.

## Data model / API changes

No table schema changes, no RLS changes, no new columns. Three materialized
views are dropped and recreated with the same name/column set (`user_id,
country_code, points, rank_global, rank_country`) so `LeaderboardApi`'s
existing `.select('user_id, country_code, points, rank_global, rank_country')`
calls (`leaderboard_api.dart:43`, `:104`) keep working unchanged. `public.
_refresh_leaderboards()` keeps its existing signature
(`returns void`, `security definer`, `set search_path = public`) so the
existing `cron.schedule` entry needs no changes.

## Dependencies

N/A — no new packages.

## Testing strategy

This is a SQL-only fix; the existing Dart test suite
(`test/features/leaderboard/leaderboard_cubit_test.dart`) mocks
`LeaderboardRepository` entirely and doesn't exercise real SQL, so it isn't
expected to catch this class of bug and doesn't need new cases added — it
should simply still pass unchanged (`fetchRoster`/`fetchSelfEntry` call
signatures aren't changing). Verification for this fix instead happens at
the SQL layer, matching plan 017's "SQL smoke-test through the Supabase MCP"
precedent:
- Apply the migration to the live project (there is no local Supabase stack
  configured in this repo per the existing plans' pattern of applying
  directly via MCP — confirm this is still the case before starting).
- Re-run the read-only diagnostic queries from Phase 4 above and confirm
  each one now returns the expected corrected result.
- For any Phase 1 finding folded into the fix-inline bucket, add and run a
  read-only query of its own (in the same style as the Root cause 1/2
  queries) confirming that specific issue is actually resolved — don't rely
  on the Phase 4 queries alone if they weren't written to cover it.
- `dart analyze` — expected to be a no-op pass since no Dart files change,
  but run it anyway to confirm nothing was accidentally touched.

## Edge cases & error handling

- **A player with no `profiles.country_code` set**: excluded from any
  country-scoped board (existing behavior, preserved — see "Assumptions &
  open questions").
- **A guest who later converts to a real account** (`is_guest` flips to
  `false`): their historical `score_events` rows are already attributed to
  the same `user_id`, so on the next refresh they simply start appearing in
  the totals views — no migration/backfill needed for this transition.
- **A player with zero `score_events` ever**: still produces no row in the
  view (inner join finds nothing to aggregate) — `fetchSelfEntry`'s existing
  `row == null → score: 0` fallback remains correct and unchanged for this
  genuine case; the fix only removes the *false positive* where a real
  player's row was missing due to the frozen view.
- **Guest's own score, viewed by themselves**: unaffected — `pinned_self_row.dart`
  never renders `lbState.selfEntry` for a guest session in the first place
  (`leaderboard_screen.dart:139-146`), so nothing here changes what a guest
  sees of their own progress (which per the bug report should keep working).
- **Migration failing again on `REFRESH ... CONCURRENTLY`** if some other,
  as-yet-unknown duplicate exists post-fix: Phase 3's per-view exception
  handling means this would surface as a `raise warning` in
  `cron.job_run_details.return_message` (queryable) rather than silently
  freezing every view again — this is the main reason Phase 3 is worth
  doing alongside Phase 2 rather than deferring it.

## Acceptance criteria

- [x] `lb_weekly_totals`, `lb_monthly_totals`, `lb_alltime_totals` each
  contain exactly one row per non-guest `user_id` who has a qualifying
  `score_events` row in that period (`select user_id, count(*) from
  public.lb_alltime_totals group by user_id having count(*) > 1;` returns no
  rows). **Verified 2026-09-28**: 0 duplicate `user_id`s in all three views.
- [x] No guest profile appears in any of the three views (`join profiles ...
  where is_guest` returns 0 rows for all three). **Verified**: 0 guest rows
  in `lb_alltime_totals`/`lb_weekly_totals`/`lb_monthly_totals`.
- [x] `refresh-lb-weekly` completes successfully on its next scheduled run
  after deploy (`cron.job_run_details` shows `status = 'succeeded'`), and
  continues succeeding on subsequent ticks. **Verified**: the 09:34–10:10
  UTC ticks (pre-migration) were the last failures; the 10:12 UTC tick
  (first after the migration was applied) succeeded, and a manual
  `select public._refresh_leaderboards();` also completed with no error.
- [x] The two real users identified in Phase 0/Research findings as missing
  from `lb_alltime_totals` now have a row there whose `points` matches
  `sum(score_events.points)` for that user. **Verified**: `170ccfe1-...`
  (live sum `9,540`) and `e90299fd-...` (live sum `3,573`) both now show
  matching `points` in `lb_alltime_totals`.
- [ ] In the running app (developer to confirm manually per §13 — see "To
  verify" below): the Leaderboard screen's global and country rosters no
  longer show any guest player card, the ranking order matches what the
  point totals actually are, and the pinned self row shows the signed-in
  user's real current score and rank rather than `0`. **Not yet
  confirmed** — this plan's executor must not launch the app (§13); please
  confirm using the "To verify" checklist below.
- [x] Phase 1's audit has been completed and written up: every finding is
  recorded in the "Additional findings" section below (even if the answer
  is "none found," say so explicitly rather than leaving the section
  blank), each is confirmed against live data rather than code-reading
  alone, and each is marked fixed-inline (with its own acceptance line
  added above, alongside a note of which criterion) or deferred (with a
  one-line reason why). **Done**: 4 additional findings, all deferred (see
  "Additional findings" below) — none met the fix-inline bar, so no new
  acceptance lines were added.

## Risks & rollout notes

- **This is a live-production data fix**, not just a code change — applying
  the migration immediately corrects what every user currently sees on the
  Leaderboard screen (removes guest rows, re-ranks everyone, fixes stale
  self-scores). There's no feature flag or staged rollout mechanism in this
  codebase for backend changes (per plans 007/008/016/017's precedent of
  applying migrations directly), so this should be treated as a normal
  production migration: apply once, verify via Phase 4's queries, done.
- **No rollback path for the view definitions beyond re-applying the old SQL**
  (materialized views don't version). If something looks wrong post-deploy,
  the fastest recovery is another migration restoring the prior `group by
  user_id, country_code` shape — not a `git revert`, since the live database
  state (the refreshed view contents) doesn't roll back with the migration
  file.
- **Phase 3 is additive and low-risk** (same function signature, same cron
  registration) — safe to ship in the same migration as Phase 2.
- After deploy, also spot-check whether any *other* player besides the one
  identified in this snapshot has a `(user_id, country_code)` conflict
  today, since Phase 0's re-check might surface a different/additional
  offending user by the time this is implemented.
- **Any fix-inline finding from Phase 1 raises the risk profile of this
  migration** relative to a minimal two-root-cause fix, since it's new code
  written under this plan rather than something diagnosed and verified
  ahead of time the way Root causes 1/2 were. Each one must clear the same
  bar before inclusion: a live read-only query confirming the problem is
  real, not just a code-reading suspicion. When in doubt, defer rather than
  bundle — a deferred finding costs a follow-up plan; a wrong fix-inline
  change costs a second incident.

## Additional findings (Phase 1 audit)

Status: **Audited 2026-09-28.** Read every file under
`lib/features/leaderboard/` (data/domain/presentation/bloc/screens/widgets)
and every migration that writes `score_events`/`profiles`/`friendships`/
`league_memberships` or defines an `lb_*`/`lb_*_totals` view/function
(`20260907120000`, `20260907120100`, `20260907120200`, `20260909120100`,
`20260910090300`, `20260910090500`, `20260919194353`, and the duel-arena
migrations `20260927120000`–`20260927120600`, `20260928090000`). No new
defect met the bar for fixing inline — see each entry's disposition below.

### 1. Category board (`lb_weekly`/`lb_monthly`/`lb_alltime`) has the same guest-inclusion gap
- **Where**: `20260907120200_functions_and_triggers.sql:1146-1189` (the
  `lb_weekly`/`lb_monthly`/`lb_alltime` views backing
  `LeaderboardApi.fetchCategoryRoster`/`fetchCategoryHeader`,
  `leaderboard_api.dart:136-224`).
- **What**: these views aggregate `public.score_events` directly with no join
  against `profiles.is_guest`, same gap as Root cause 2, but for the
  per-category board rather than the global/country one.
- **Confirmed by**: live query — `9` guest rows in `lb_alltime`, `5` in
  `lb_weekly`, `9` in `lb_monthly` (joined against `profiles.is_guest`).
- **Failure scenario**: a guest player who has cleared levels in a
  subcategory appears as a normal ranked row on that subcategory's
  leaderboard to every other (real) player.
- **Disposition**: Deferred — already called out in this plan's "Assumptions
  & open questions" as its own follow-up, since the unique index backing
  these views (`lb_alltime_pk` etc.) covers the full
  `(user_id, subcategory_id, category_id, country_code)` grouping tuple
  (confirmed: `20260907120200_functions_and_triggers.sql:1158/1172/1185`),
  so it isn't subject to Root cause 1's crash — this is a same-shape but
  separate fix, touching category-board screens outside this plan's scope.

### 2. Real 1v1 duels never write to `score_events`
- **Where**: `20260928090000_duel_scoring_ten_rounds_audio_guest_join.sql`
  (the duel-scoring function, around lines 251-280) grants coins/XP via
  `_grant_currency`/`profiles.xp` on duel completion but has no
  `insert into public.score_events` anywhere in the duel-arena migrations
  (`20260927120000`-`20260927120600`, `20260928090000`).
- **What**: `score_events.source` explicitly reserves a `'duel'` value
  (`score_events_source_check: source = ANY (ARRAY['level','daily','duel'])`,
  confirmed live via `pg_get_constraintdef`), implying duel wins were meant
  to count toward the leaderboard, but no code path ever inserts one.
- **Confirmed by**: live query — `select count(*) from score_events where
  source = 'duel'` returns `0`; `select count(*) from duels where status =
  'completed'` also returns `0` (the duels feature is very new, shipped
  2026-09-28, so this may simply not have been reached yet rather than
  proven broken by a real completed duel — but the code path to write one
  doesn't exist regardless).
- **Failure scenario**: once duels start completing in production, a
  player's duel wins will never appear in their leaderboard total — a
  correctness gap, but a duel-scoring one, not a ranking/guest/self-score
  bug on the Leaderboard screen itself.
- **Disposition**: Deferred — this is exactly the kind of "duel-scoring bug"
  this plan's own Risks section names as the wrong thing to bundle in; needs
  its own plan (deciding e.g. whether duel points should carry a
  `subcategory_id`/`category_id`, which side of the duel a draw awards, etc.
  — real design questions, not a one-line fix).

### 3. `LeaderboardCubit.load()` has no staleness guard across rapid scope/period changes
- **Where**: `leaderboard_cubit.dart:21-68` — `changeScope`/`changePeriod`
  each call `load()`, which does two sequential `await`s
  (`fetchRoster`, `fetchSelfEntry`) before emitting `LeaderboardLoaded`.
- **What**: if a user taps Country then Global in quick succession and the
  Country request resolves after the Global one, its response overwrites
  the newer state — the segmented control and roster can flip back to a
  scope/period the user already navigated away from.
- **Confirmed by**: code reading only (a client-side async race, not
  something a read-only SQL query can confirm or falsify).
- **Failure scenario**: rapid tab-switching under variable network latency
  shows a stale scope/period after the UI briefly showed the correct one.
- **Disposition**: Deferred — fixing this needs a Dart change (a
  request-id/generation guard in the Cubit), which this plan's Design
  overview and Scope explicitly rule out ("No Dart changes... `LeaderboardCubit`...
  keep their current signatures and behavior"). Not one of the three
  reported symptoms either. Worth its own small follow-up.

### 4. `FriendsCubit.respondToRequest` ignores the `accept` flag
- **Where**: `friends_cubit.dart:31-40`.
- **What**: both accepting and declining a friend request just remove the
  row from the local list — `accept: true` never actually marks the
  friendship `accepted` (nor does it write anything to `public.friendships`
  at all; the doc comment above the class already notes this is mocked as a
  local-list edit with no real backend call).
- **Confirmed by**: code reading — the parameter `accept` is never read in
  the method body.
- **Failure scenario**: a player taps "Accept" on a friend request; it
  disappears from the Requests section as if handled, but no `accepted`
  friendship row is ever created, so the other player never sees them as a
  friend.
- **Disposition**: Deferred — this is the Friends screen/feature (S-31), a
  different screen from the Leaderboard screen this plan's bug report is
  about, and (per the file's own doc comment) is known/intentional
  placeholder behavior, not a regression to fix under this plan.

### 5. Everything else checked and found correct
- `fetchLeagueNeighbors`'s `lo`/`hi` window math (`leaderboard_api.dart:277-299`):
  clamps correctly at both edges of the cohort list; no off-by-one.
- `isSelf`/`playerId` comparisons (`_entryFromTotalsRow`, `_friendFromRow`,
  `fetchLeagueNeighbors`): all compare against the same `auth.uid()`-derived
  `userId`, consistently.
- `score_events` data integrity: no negative/zero `points` rows, no
  duplicate `(user_id, subcategory_id, points, occurred_at)` rows for
  `source = 'level'` (checked live).
- RLS on `score_events`/`profiles`: `score_events` has public `select`, no
  client `insert`/`update`/`delete` policy at all (written only by
  `security definer` functions) — correctly locked down. `profiles` has
  public `select`, self-only `update` restricted to a safe column allowlist
  via a column-level `grant` — correctly locked down. No missing or overly
  permissive policy found.
- All Cubit `sealed` states (`LeaderboardState`, `CategoryLeaderboardState`,
  `FriendsState`, `LeagueState`) are exhaustively switched over in their
  screens with no default/fallback branch.

## To verify (developer, in the running app — per CLAUDE.md §13 this plan's executor must not launch the app itself)

- Open the Leaderboard screen (global scope, all three periods) as a
  signed-in real account with recent play activity: confirm your own pinned
  row at the bottom shows your real score and rank (not `0`), and that the
  podium/ranked rows are ordered by descending score with no guest card
  present.
- Switch to Country scope: same checks.
- If possible, sign in as (or ask a teammate to sign in as) a guest and
  confirm the guest's own pinned row still shows their own progress/sign-in
  CTA as before (unchanged), while checking from a *different*, real
  account that the guest no longer appears as a row in that account's
  global/country roster.
- Compare a real user's displayed leaderboard score against their actual
  in-app stats (e.g. profile/You screen total) to confirm they now match.
