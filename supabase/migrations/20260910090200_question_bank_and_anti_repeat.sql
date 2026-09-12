-- ============================================================================
-- 20260910090200_question_bank_and_anti_repeat.sql
-- (renamed from 0005_question_bank_and_anti_repeat.sql — see plan
-- .claude/plans/007-difficulty-ladder-language-question-bank.md, Phase 0)
--
-- Change Request: per-user "don't repeat a question" tracking, plus the
-- get_level_questions() function documenting the anti-repeat selection rule
-- that 20260910090300_ladder_rpc_rewrite.sql inlines directly into
-- start_level_attempt (plan 007, Assumption #4) — kept here as a
-- non-granted reference/documentation function, not a separately callable
-- RPC, so there is exactly one way to start a level.
--
-- Depends on: 20260910090000_difficulty_ladder_v2.sql,
-- 20260910090100_multilingual_content_model.sql
--
-- Fix applied on top of the original draft (plan 007, Research finding #3):
-- v_thin_question_pools selected `sc.name`, a column `subcategories` does
-- not have (names live in taxonomy_i18n) — a view definition is checked at
-- creation time, so this made the whole migration fail. Uses `sc.slug`
-- instead, which is sufficient for an internal ops view.
-- ============================================================================

begin;

create table if not exists user_question_history (
  user_id        uuid not null references auth.users(id) on delete cascade,
  question_id    uuid not null references questions(id) on delete cascade,
  times_seen     int  not null default 0,
  first_seen_at  timestamptz not null default now(),
  last_seen_at   timestamptz not null default now(),
  primary key (user_id, question_id)
);

alter table user_question_history enable row level security;
drop policy if exists "select own history" on user_question_history;
create policy "select own history" on user_question_history
  for select using (user_id = auth.uid());
-- Deliberately no insert/update/delete policy for `authenticated` -- only
-- start_level_attempt() (SECURITY DEFINER) writes to this table.

create table if not exists level_attempt_question_sets (
  id                   uuid primary key default gen_random_uuid(),
  user_id              uuid not null references auth.users(id) on delete cascade,
  subcategory_id       uuid not null references subcategories(id),
  difficulty_tier_id   uuid not null references difficulty_tiers(id),
  level                int  not null check (level between 1 and 50),
  language_code        text not null references languages(code),
  question_ids         uuid[] not null,
  is_repeat_padded     boolean not null default false,
  served_at            timestamptz not null default now(),
  graded_at            timestamptz
);

alter table level_attempt_question_sets enable row level security;
drop policy if exists "select own attempts" on level_attempt_question_sets;
create policy "select own attempts" on level_attempt_question_sets
  for select using (user_id = auth.uid());

create index if not exists idx_uqh_user  on user_question_history (user_id);
create index if not exists idx_laqs_user on level_attempt_question_sets (user_id, served_at desc);

-- ---------------------------------------------------------------------------
-- Reference implementation of the anti-repeat selection rule. NOT granted to
-- `authenticated` and not called by any Flutter code — start_level_attempt
-- (20260910090300_ladder_rpc_rewrite.sql) inlines this same query directly,
-- using the level_attempts row it already creates as the id it writes into
-- level_attempt_question_sets, rather than minting a second, disconnected
-- attempt concept (plan 007, Assumption #4). Kept here, unexported, purely
-- as living documentation of the rule and a target for a future standalone
-- "practice mode" RPC, so that day's implementer has a tested starting point.
--
-- Ordering rule: "least recently seen first" -- a never-seen question
-- (last_seen_at is null) always sorts ahead of any previously-seen one, and
-- once EVERY question in the pool has been seen at least once, the oldest-
-- seen one naturally rotates back in first. This single ordering rule is
-- what satisfies both stated edge cases without any special "pool exhausted"
-- branch -- there's no explicit reset step, it just keeps rotating.
--
-- Edge case (pool smaller than N): handled by tiling the ranked pool with
-- modulo indexing -- ((n-1) % pool_size) + 1 -- so a thin pool still fills
-- the level instead of erroring; is_repeat_padded records that it happened.
-- ---------------------------------------------------------------------------
create or replace function public.get_level_questions(
  p_subcategory_id uuid,
  p_level int,
  p_language_code text
)
returns table (
  attempt_id    uuid,
  question_id   uuid,
  display_order int,
  prompt        text,
  options       jsonb
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id      uuid := auth.uid();
  v_tier         difficulty_tiers;
  v_n            int;
  v_pool_ids     uuid[];
  v_pool_prompts text[];
  v_pool_options jsonb[];
  v_pool_size    int;
  v_attempt_id   uuid := gen_random_uuid();
  v_padded       boolean := false;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  select * into v_tier from difficulty_tiers where p_level between level_start and level_end;
  if not found then
    raise exception 'no difficulty tier configured for level %', p_level;
  end if;

  select coalesce(
    v_tier.override_questions_per_level,
    (select (value #>> '{}')::int from app_settings where key = 'questions_per_level'),
    20
  ) into v_n;

  select array_agg(id), array_agg(prompt), array_agg(options)
  into v_pool_ids, v_pool_prompts, v_pool_options
  from (
    select q.id, q.prompt, q.options
    from questions q
    left join user_question_history h
      on h.question_id = q.id and h.user_id = v_user_id
    where q.subcategory_id = p_subcategory_id
      and q.difficulty_tier_id = v_tier.id
      and q.language_code = p_language_code
      and q.status = 'live'
    order by h.last_seen_at asc nulls first, random()
  ) ranked;

  v_pool_size := coalesce(array_length(v_pool_ids, 1), 0);
  if v_pool_size = 0 then
    raise exception 'no live questions for subcategory %, tier %, language %',
      p_subcategory_id, v_tier.code, p_language_code;
  end if;

  if v_pool_size < v_n then
    v_padded := true;   -- edge case: pool too small -- repeats are unavoidable
  end if;

  return query
  with numbered as (
    select
      v_pool_ids[((n - 1) % v_pool_size) + 1]     as qid,
      v_pool_prompts[((n - 1) % v_pool_size) + 1]  as prompt,
      v_pool_options[((n - 1) % v_pool_size) + 1]  as options
    from generate_series(1, v_n) as n
  ),
  logged as (
    insert into level_attempt_question_sets
      (id, user_id, subcategory_id, difficulty_tier_id, level, language_code, question_ids, is_repeat_padded)
    select v_attempt_id, v_user_id, p_subcategory_id, v_tier.id, p_level, p_language_code,
           array_agg(qid), v_padded
    from numbered
    returning id
  ),
  history_upsert as (
    insert into user_question_history (user_id, question_id, times_seen, first_seen_at, last_seen_at)
    select v_user_id, d.qid, 1, now(), now()
    from (select distinct qid from numbered) d
    on conflict (user_id, question_id)
    do update set times_seen   = user_question_history.times_seen + 1,
                  last_seen_at = now()
    returning 1
  )
  select v_attempt_id, n.qid, row_number() over (order by random())::int, n.prompt, n.options
  from numbered n;
end;
$$;

-- Deliberately no `grant execute ... to authenticated` -- see the doc
-- comment above; this function is reference/documentation only.

-- ---------------------------------------------------------------------------
-- Observability: which (subcategory, difficulty, language) pools are thin
-- enough that repeats are already common? ("Thin" = fewer than 3x the
-- default questions-per-level, i.e. less than ~1.5 rotations before a player
-- who clears that level 3 times starts seeing repeats.) Use this to see
-- exactly where to prioritize authoring more content.
-- ---------------------------------------------------------------------------
create or replace view public.v_thin_question_pools as
select
  sc.id as subcategory_id,
  sc.slug as subcategory_slug,
  dt.code as difficulty_code,
  q.language_code,
  count(*) as live_question_count,
  (select (value #>> '{}')::int from app_settings where key = 'questions_per_level') * 3
    as recommended_minimum
from questions q
join subcategories sc on sc.id = q.subcategory_id
join difficulty_tiers dt on dt.id = q.difficulty_tier_id
where q.status = 'live'
group by sc.id, sc.slug, dt.code, q.language_code
having count(*) < (select (value #>> '{}')::int from app_settings where key = 'questions_per_level') * 3
order by live_question_count asc;

commit;
