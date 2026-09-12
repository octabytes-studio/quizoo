-- ============================================================================
-- 20260910090400_ladder_rls_and_grants_cleanup.sql
--
-- Two gaps get_advisors surfaced right after the plan 007 migrations applied:
--   1. app_settings/difficulty_tiers/languages were created without RLS --
--      every other reference table in this schema (rank_titles,
--      achievements, streak_milestones) enables it with a permissive
--      select-all policy; these three should match, not rely on bare table
--      grants alone.
--   2. get_level_questions's own doc comment says "deliberately no grant
--      execute ... to authenticated", but Postgres grants EXECUTE on a new
--      function to PUBLIC by default -- the comment's intent was never
--      actually enforced. Revoked explicitly here.
-- ============================================================================

begin;

alter table public.app_settings enable row level security;
drop policy if exists app_settings_select_all on public.app_settings;
create policy app_settings_select_all on public.app_settings for select using (true);

alter table public.difficulty_tiers enable row level security;
drop policy if exists difficulty_tiers_select_all on public.difficulty_tiers;
create policy difficulty_tiers_select_all on public.difficulty_tiers for select using (true);

alter table public.languages enable row level security;
drop policy if exists languages_select_all on public.languages;
create policy languages_select_all on public.languages for select using (true);

revoke execute on function public.get_level_questions(uuid, int, text) from public, anon, authenticated;

commit;
