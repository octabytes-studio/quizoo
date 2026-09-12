-- ============================================================================
-- 0003_difficulty_ladder_v2.sql
-- Change Request: bounded 50-level, 5-tier difficulty ladder
--   Easy(30s,L1-10) / Medium(25s,L11-20) / Hard(20s,L21-30) / Expert(15s,L31-40)
--   / Master(10s,L41-50)
--
-- Supersedes the unbounded "Master (L41+, infinite)" tier from
-- realtime-ai-questions-spec.md / migration 0001. Safe to run whether or not
-- 0001/0002 from that earlier change request were ever applied -- every
-- statement below is idempotent (create-if-missing, upsert-by-code, etc).
--
-- NOT executed against your live database from this session (no Supabase
-- connection here) -- review against your actual schema before running, and
-- run on a staging project / branch first. See the MANUAL FOLLOW-UP note at
-- the bottom -- it can't be scripted in SQL.
-- ============================================================================

begin;

create table if not exists app_settings (
  key         text primary key,
  value       jsonb not null,
  description text,
  updated_at  timestamptz not null default now()
);

create table if not exists difficulty_tiers (
  id                          uuid primary key default gen_random_uuid(),
  code                        text not null unique,
  label                       text not null,
  seconds_per_question        int  not null check (seconds_per_question > 0),
  level_start                 int  not null,
  level_end                   int  not null,
  sort_order                  int  not null,
  -- optional per-tier override of app_settings.questions_per_level (feature 2)
  override_questions_per_level int,
  created_at                  timestamptz not null default now(),
  constraint difficulty_tiers_range check (level_end >= level_start)
);

-- in case an older shape (from 0001) exists without this column
alter table difficulty_tiers add column if not exists override_questions_per_level int;

-- Upsert the bounded 5-tier ladder. If a row named 'master' already exists
-- with level_end = null / a very large number (the old "unbounded" shape),
-- this UPDATEs it in place to level_end = 50.
insert into difficulty_tiers (code, label, seconds_per_question, level_start, level_end, sort_order)
values
  ('easy',   'Easy',   30, 1,  10, 1),
  ('medium', 'Medium', 25, 11, 20, 2),
  ('hard',   'Hard',   20, 21, 30, 3),
  ('expert', 'Expert', 15, 31, 40, 4),
  ('master', 'Master', 10, 41, 50, 5)
on conflict (code) do update
  set label                 = excluded.label,
      seconds_per_question  = excluded.seconds_per_question,
      level_start           = excluded.level_start,
      level_end             = excluded.level_end,
      sort_order            = excluded.sort_order;

-- Drop any pre-existing "level range" check constraints on level_progress /
-- level_attempts (names unknown -- may be the original 1..20 baseline
-- constraint, or the "relaxed to >=1" version from 0001) and replace with a
-- single bounded 1..50 constraint on both tables.
do $$
declare r record;
begin
  for r in
    select conname, conrelid::regclass as tbl
    from pg_constraint
    where conrelid = any (array[
            case when to_regclass('public.level_progress') is not null
                 then 'public.level_progress'::regclass end,
            case when to_regclass('public.level_attempts') is not null
                 then 'public.level_attempts'::regclass end
          ]::regclass[])
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%level%'
  loop
    execute format('alter table %s drop constraint %I', r.tbl, r.conname);
  end loop;
end $$;

do $$
begin
  if to_regclass('public.level_progress') is not null then
    alter table level_progress
      add constraint level_progress_level_range check (level between 1 and 50);
  end if;
  if to_regclass('public.level_attempts') is not null then
    alter table level_attempts
      add constraint level_attempts_level_range check (level between 1 and 50);
  end if;
end $$;

create or replace function public.get_difficulty_for_level(p_level int)
returns difficulty_tiers
language sql stable
as $$
  select * from difficulty_tiers where p_level between level_start and level_end limit 1;
$$;

create or replace function public.is_boss_level(p_level int)
returns boolean
language sql stable
as $$
  select p_level % coalesce(
    (select (value #>> '{}')::int from app_settings where key = 'boss_level_interval'),
    10
  ) = 0;
$$;

insert into app_settings (key, value, description) values
  ('boss_level_interval', '10'::jsonb,
   'Every Nth level is a boss level (double payout). With 10-level tiers, this lands boss levels on 10/20/30/40/50 -- the last level of every tier.'),
  ('questions_per_level', '20'::jsonb,
   'Default number of questions served per level attempt (N). Configurable live, no redeploy needed. Per-tier override: difficulty_tiers.override_questions_per_level.')
on conflict (key) do nothing;

commit;

-- ============================================================================
-- MANUAL FOLLOW-UP -- cannot be scripted in SQL, this is an app-code change:
--
-- If migration 0001 from realtime-ai-questions-spec.md was applied, the
-- `submit-level` Edge Function was patched to FREEZE the score multiplier for
-- level > 40:
--     diffMult = level <= 40 ? 1 + (level-1)*0.05 : 2.95
-- That freeze existed ONLY because Master used to be unbounded (unfrozen, a
-- level-500 attempt would give an absurd x25.95 multiplier). Now that Master
-- is bounded at level 50, REVERT that patch back to the plain formula:
--     diffMult = 1 + (level - 1) * 0.05     -- max x3.45 at level 50, safe
-- Leaving the freeze in place would silently UNDER-score every Master-tier
-- level (41-50) versus what players should actually earn.
--
-- Also replace any hardcoded boss-level check (e.g. `level in (5,10,15,20)`)
-- with a call to `is_boss_level(level)` if not already done.
-- ============================================================================
