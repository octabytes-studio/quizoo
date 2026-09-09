-- ============================================================================
-- Plan 006 — per-player leaderboard totals.
--
-- `lb_weekly`/`lb_monthly`/`lb_alltime` (functions migration) group by
-- (user_id, subcategory_id, category_id, country_code) — the right shape for
-- `rank_subcategory`/`rank_category` (a genuine per-topic/per-category rank),
-- but `rank_global`/`rank_country` on those views are computed over each
-- *per-subcategory* row's own sum, not the player's grand total — a player
-- who scored across three topics gets three separate rows and three
-- different "global" ranks, none of which is their real overall rank. These
-- new views group by user only (plus country, for the country board) so the
-- global/country leaderboard, the self-entry lookup and the league-neighbour
-- read all rank a genuine total. The existing views are untouched and still
-- back the category board / category header, which are correctly scoped at
-- the subcategory/category grain already.
-- ============================================================================

create materialized view public.lb_weekly_totals as
select
  user_id, country_code,
  sum(points) as points,
  rank() over (order by sum(points) desc) as rank_global,
  rank() over (partition by country_code order by sum(points) desc) as rank_country
from public.score_events
where occurred_at >= date_trunc('week', now())
group by user_id, country_code;

create unique index lb_weekly_totals_pk on public.lb_weekly_totals (user_id);

create materialized view public.lb_monthly_totals as
select
  user_id, country_code,
  sum(points) as points,
  rank() over (order by sum(points) desc) as rank_global,
  rank() over (partition by country_code order by sum(points) desc) as rank_country
from public.score_events
where occurred_at >= date_trunc('month', now())
group by user_id, country_code;

create unique index lb_monthly_totals_pk on public.lb_monthly_totals (user_id);

create materialized view public.lb_alltime_totals as
select
  user_id, country_code,
  sum(points) as points,
  rank() over (order by sum(points) desc) as rank_global,
  rank() over (partition by country_code order by sum(points) desc) as rank_country
from public.score_events
group by user_id, country_code;

create unique index lb_alltime_totals_pk on public.lb_alltime_totals (user_id);

grant select on public.lb_weekly_totals, public.lb_monthly_totals, public.lb_alltime_totals
  to authenticated, anon;

create or replace function public._refresh_leaderboards()
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  refresh materialized view concurrently public.lb_weekly;
  refresh materialized view concurrently public.lb_monthly;
  refresh materialized view concurrently public.lb_alltime;
  refresh materialized view concurrently public.lb_weekly_totals;
  refresh materialized view concurrently public.lb_monthly_totals;
  refresh materialized view concurrently public.lb_alltime_totals;
end;
$$;
