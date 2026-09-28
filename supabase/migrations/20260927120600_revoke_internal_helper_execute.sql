-- ============================================================================
-- 20260927120600_revoke_internal_helper_execute.sql
--
-- Security fix found while implementing plan 017 (outside that plan's scope,
-- approved by the developer): every pre-existing `_`-prefixed helper in
-- `public` was still EXECUTE-able by `anon` and `authenticated` (Postgres
-- grants EXECUTE to PUBLIC by default, and PostgREST exposes every function
-- in the schema as an RPC). A guest could, for example, call
-- `rpc('_grant_currency', {p_user_id: <self>, p_currency: 'coins',
-- p_delta: 1000000, ...})` and mint currency, or trigger
-- `_settle_weekly_leagues` / `_daily_rollover` / `_unlock_achievement`.
--
-- These helpers are internal: every legitimate caller is a SECURITY DEFINER
-- function (which runs as its owner), a pg_cron job (runs as postgres), or a
-- trigger (trigger firing does not check EXECUTE). Verified on the live
-- project before writing this: no RLS policy, view or column default calls
-- any of them, no SECURITY INVOKER public function calls them, and the
-- Flutter client never RPCs a `_`-prefixed function. The plan 017 `_duel_*`
-- helpers already revoke themselves; this applies the same rule to the rest.
--
-- `_guard_duel_answer_update` is not listed: 20260927120000 drops it.
-- ============================================================================

begin;

revoke execute on function public._assign_weekly_league_cohorts() from public, anon, authenticated;
revoke execute on function public._bump_achievement_progress(uuid, text, jsonb) from public, anon, authenticated;
revoke execute on function public._daily_rollover() from public, anon, authenticated;
revoke execute on function public._difficulty_multiplier(integer) from public, anon, authenticated;
revoke execute on function public._evaluate_achievements(uuid, text, jsonb) from public, anon, authenticated;
revoke execute on function public._grant_currency(uuid, text, integer, text, uuid) from public, anon, authenticated;
revoke execute on function public._handle_new_user() from public, anon, authenticated;
revoke execute on function public._player_level_from_xp(integer) from public, anon, authenticated;
revoke execute on function public._rank_title_for_level(integer) from public, anon, authenticated;
revoke execute on function public._refresh_category_counts() from public, anon, authenticated;
revoke execute on function public._refresh_featured_quizzes_popularity() from public, anon, authenticated;
revoke execute on function public._refresh_leaderboards() from public, anon, authenticated;
revoke execute on function public._settle_hearts(uuid) from public, anon, authenticated;
revoke execute on function public._settle_weekly_leagues() from public, anon, authenticated;
revoke execute on function public._speed_bonus(integer, integer) from public, anon, authenticated;
revoke execute on function public._stars_for(integer, integer) from public, anon, authenticated;
revoke execute on function public._streak_multiplier(integer) from public, anon, authenticated;
revoke execute on function public._touch_daily_streak(uuid) from public, anon, authenticated;
revoke execute on function public._unlock_achievement(uuid, text) from public, anon, authenticated;
revoke execute on function public._xp_for_level(integer) from public, anon, authenticated;

commit;
