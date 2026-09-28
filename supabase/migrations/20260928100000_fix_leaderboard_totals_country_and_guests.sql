-- ============================================================================
-- Plan 018 — leaderboard bug fixes: ranking, guest visibility, self score.
--
-- Two root causes, confirmed live against this project's data on 2026-09-28
-- (see .claude/plans/018-leaderboard-ranking-guest-visibility-self-score-fixes.md):
--
-- 1. `lb_weekly_totals`/`lb_monthly_totals`/`lb_alltime_totals`
--    (20260908090000_leaderboard_totals.sql) grouped by
--    `(user_id, country_code)` — two columns — but `REFRESH ... CONCURRENTLY`
--    requires a unique index, and the index only covered `user_id`. A player
--    whose `score_events` rows carry more than one distinct `country_code`
--    (e.g. rows from before their profile had a country set, plus rows after)
--    produces two rows sharing one `user_id`, which the unique index rejects.
--    `_refresh_leaderboards()` runs all six refreshes as one call; when one
--    raises, the whole call aborts, so *none* of the six views refresh — this
--    has been silently failing every ~2 minutes since 2026-09-19 19:58 UTC.
--    That froze the global/country leaderboard at a 9-day-old snapshot: wrong
--    ranking, and any real player whose first score landed after the freeze
--    has no row at all (`fetchSelfEntry` falls back to score 0).
--
-- 2. The three views aggregated `score_events` directly with no join against
--    `profiles.is_guest`, so guest profiles appeared as normal ranked rows
--    to every other player.
--
-- The fix: derive `country_code` from the player's *current*
-- `profiles.country_code` (one row per `user_id`, guaranteed) instead of from
-- `score_events` (which can carry multiple distinct values per user), and
-- exclude `is_guest` profiles. Grouping by `p.country_code` — functionally
-- dependent on `se.user_id` via the join — guarantees exactly one row per
-- `user_id`, making the unique index (and `REFRESH ... CONCURRENTLY`) safe
-- again. `_refresh_leaderboards()` is also hardened so a future failure in
-- any single view can't cascade into freezing the other five.
-- ============================================================================

drop materialized view public.lb_weekly_totals;
drop materialized view public.lb_monthly_totals;
drop materialized view public.lb_alltime_totals;

create materialized view public.lb_weekly_totals as
select
  se.user_id,
  p.country_code,
  sum(se.points) as points,
  rank() over (order by sum(se.points) desc) as rank_global,
  rank() over (partition by p.country_code order by sum(se.points) desc) as rank_country
from public.score_events se
join public.profiles p on p.id = se.user_id
where not p.is_guest
  and se.occurred_at >= date_trunc('week', now())
group by se.user_id, p.country_code;

create unique index lb_weekly_totals_pk on public.lb_weekly_totals (user_id);

create materialized view public.lb_monthly_totals as
select
  se.user_id,
  p.country_code,
  sum(se.points) as points,
  rank() over (order by sum(se.points) desc) as rank_global,
  rank() over (partition by p.country_code order by sum(se.points) desc) as rank_country
from public.score_events se
join public.profiles p on p.id = se.user_id
where not p.is_guest
  and se.occurred_at >= date_trunc('month', now())
group by se.user_id, p.country_code;

create unique index lb_monthly_totals_pk on public.lb_monthly_totals (user_id);

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

grant select on public.lb_weekly_totals, public.lb_monthly_totals, public.lb_alltime_totals
  to authenticated, anon;

-- Hardened refresh: each view refreshes independently now, so one broken
-- view logs a warning (queryable via cron.job_run_details) instead of
-- silently freezing the other five, as happened here for 9 days.
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
  begin
    refresh materialized view concurrently public.lb_monthly;
  exception when others then
    raise warning 'lb_monthly refresh failed: %', sqlerrm;
  end;
  begin
    refresh materialized view concurrently public.lb_alltime;
  exception when others then
    raise warning 'lb_alltime refresh failed: %', sqlerrm;
  end;
  begin
    refresh materialized view concurrently public.lb_weekly_totals;
  exception when others then
    raise warning 'lb_weekly_totals refresh failed: %', sqlerrm;
  end;
  begin
    refresh materialized view concurrently public.lb_monthly_totals;
  exception when others then
    raise warning 'lb_monthly_totals refresh failed: %', sqlerrm;
  end;
  begin
    refresh materialized view concurrently public.lb_alltime_totals;
  exception when others then
    raise warning 'lb_alltime_totals refresh failed: %', sqlerrm;
  end;
end;
$$;

-- One-time catch-up refresh so the corrected views are populated immediately
-- rather than waiting up to 2 minutes for the next cron tick.
select public._refresh_leaderboards();
