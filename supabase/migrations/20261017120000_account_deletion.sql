-- ============================================================================
-- 20261017120000_account_deletion.sql
--
-- Plan: .claude/plans/025-app-review-readiness-fixes.md (Phase 1)
--
-- Real account deletion, step 1 of 2: a service-role-only cleanup function
-- that removes the rows whose `NO ACTION` foreign keys would otherwise block
-- the `auth.users -> profiles` cascade when the `delete-account` Edge
-- Function calls `admin.auth.admin.deleteUser(user.id)` (step 2).
--
-- Live FK survey (2026-10-17): the tables below are the only ones whose FKs
-- to `profiles`/`duels` use `NO ACTION`. Every other profile-owned table
-- cascades from `auth.users` or `profiles` (or is cleared by a `SET NULL`
-- rule) and needs no manual cleanup. `user_question_history` and
-- `level_attempt_question_sets` reference `auth.users` directly with
-- `ON DELETE CASCADE`.
--
-- IMPORTANT: do NOT delete `profiles` here -- the Edge Function's
-- `admin.deleteUser` removes the auth user, which cascades `profiles` and
-- every `ON DELETE CASCADE` child.
--
-- Rollback: `drop function public.delete_account_data(uuid);`. A deleted
-- account cannot be restored -- the rows this function removes are gone.
-- ============================================================================

begin;

create or replace function public.delete_account_data(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_duel_ids uuid[];
begin
  if p_user_id is null then
    raise exception 'user_id_required';
  end if;

  select coalesce(array_agg(id), '{}'::uuid[])
    into v_duel_ids
    from public.duels
    where p1 = p_user_id or p2 = p_user_id;

  -- app_notifications has NO ACTION FKs to profiles (challenger_id) and
  -- duels (duel_id). user_id is CASCADE but is deleted here too so the
  -- cleanup does not rely on the profile cascade running afterwards.
  delete from public.app_notifications
   where user_id = p_user_id
      or challenger_id = p_user_id
      or duel_id = any (v_duel_ids);

  -- duels has NO ACTION FKs (p1/p2/winner/forfeited_by) and a self-FK
  -- (rematch_of). Clear every reference to the duels about to be deleted --
  -- including rematches created by the opponent -- before removing them.
  update public.duels
     set rematch_of = null
   where rematch_of = any (v_duel_ids);

  delete from public.duels
   where p1 = p_user_id or p2 = p_user_id;

  delete from public.friendships
   where requester_id = p_user_id or addressee_id = p_user_id;

  delete from public.iap_transactions where user_id = p_user_id;
  delete from public.level_attempts    where user_id = p_user_id;
  delete from public.question_reports  where user_id = p_user_id;
  delete from public.score_events      where user_id = p_user_id;
  delete from public.wallet_ledger     where user_id = p_user_id;

  -- Provider ledger: our copy stores the user id in plain text and has no FK.
  delete from public.revenuecat_events
   where app_user_id = p_user_id::text;
end;
$$;

comment on function public.delete_account_data(uuid) is
  'Service-role-only cleanup of rows whose NO ACTION FKs block the auth.users -> profiles cascade during account deletion. Called only by the delete-account Edge Function before admin.auth.admin.deleteUser().';

revoke all on function public.delete_account_data(uuid)
  from public, anon, authenticated;
grant execute on function public.delete_account_data(uuid) to service_role;

commit;
