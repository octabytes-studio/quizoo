-- ============================================================================
-- 20261001175452_quizoo_pro_subscriptions.sql
--
-- Plan: .claude/plans/023-in-app-subscription-quizoo-pro.md (Phase 2)
--
-- Quizoo Pro — the server side of the subscription: the public badge flag,
-- the private entitlement mirror, the event ledger, the two helpers the
-- webhook/sync Edge Functions drive, a server-side level lock, the monthly
-- streak-shield refill and the daily expiry sweep, Pro avatars, and `isPro`
-- in every duel identity blob.
--
-- Status note (2026-10-02): this migration was applied to the live project
-- (ughycvclcheuojifgkwx) as version `20261001175452` before the file was
-- committed, and this file is the reconciled record of that apply. It is
-- written to be idempotent (create or replace / if not exists / on conflict
-- do nothing) so a re-run on a database that already has it is a no-op. The
-- plan text names `20261002090000_quizoo_pro_subscriptions.sql`; the live
-- version number is kept here so `supabase migration list` and the remote
-- history stay in agreement.
--
-- Steps (see plan Phase 2):
--   A. Schema: profiles.is_pro, pro_subscriptions, revenuecat_events,
--      avatar_options.is_pro.
--   B. _is_pro / _apply_pro_status (service-role only).
--   C. Server-side level lock inside start_level_attempt.
--   D. pg_cron: pro-streak-freeze-refill, pro-expiry-sweep.
--   E. Duel identity JSON gains `isPro`.
--   F. Pro avatars + the _enforce_pro_avatar guard trigger.
--   G. Lock the is_pro column away from client roles.
--
-- Rollback: drop the two cron jobs, the trigger and
-- public._enforce_pro_avatar, then
--   `create or replace function public.start_level_attempt(...)` with the
--   body from 20261001090000_three_tier_difficulty_ladder.sql §"start_level_
--   attempt" (the tier lookup and everything after it, minus the
--   `level_locked` block), and re-run that migration's version of
--   _duel_player_json / _duel_challenge_card / _duel_challenge_history_card /
--   _duel_requester_json to drop `isPro`. Finally
--   `alter table public.profiles drop column is_pro;` and
--   `drop table public.pro_subscriptions, public.revenuecat_events;`.
--   Nothing else in the app depends on these objects; `pro_enabled = false`
--   in Remote Config already hides every entry point without a release.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- A. Schema.
-- ----------------------------------------------------------------------------

alter table public.profiles
  add column if not exists is_pro boolean not null default false;
comment on column public.profiles.is_pro is
  'Public Pro badge flag. Written only by _apply_pro_status (service role).';

create table if not exists public.pro_subscriptions (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  is_active boolean not null default false,
  plan text check (plan in ('monthly', 'yearly', 'lifetime')),
  store text,
  product_id text,
  period_type text,
  expires_at timestamptz,            -- null = lifetime
  will_renew boolean not null default false,
  billing_issue_at timestamptz,
  environment text,
  last_event_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.pro_subscriptions enable row level security;
drop policy if exists pro_subscriptions_select_self on public.pro_subscriptions;
create policy pro_subscriptions_select_self on public.pro_subscriptions
  for select using (user_id = auth.uid());

create table if not exists public.revenuecat_events (
  id text primary key,               -- RevenueCat event id
  type text not null,
  app_user_id text,
  payload jsonb not null,
  received_at timestamptz not null default now()
);
alter table public.revenuecat_events enable row level security;
-- no policies: service role only

alter table public.avatar_options
  add column if not exists is_pro boolean not null default false;

-- ----------------------------------------------------------------------------
-- B. _is_pro and _apply_pro_status.
--
-- _is_pro is the single definition of "currently Pro": an active row that
-- either never expires (lifetime) or expired less than 3 days ago, which
-- absorbs the store's billing grace period and a late webhook (plan
-- Assumption 11).
-- ----------------------------------------------------------------------------

create or replace function public._is_pro(p_user_id uuid)
returns boolean language sql stable security definer
set search_path to 'public' as $$
  select exists (
    select 1 from public.pro_subscriptions s
    where s.user_id = p_user_id and s.is_active
      and (s.expires_at is null or s.expires_at > now() - interval '3 days')
  );
$$;

create or replace function public._apply_pro_status(
  p_user_id uuid, p_is_active boolean, p_plan text, p_store text,
  p_product_id text, p_period_type text, p_expires_at timestamptz,
  p_will_renew boolean, p_billing_issue_at timestamptz,
  p_environment text, p_event_at timestamptz
) returns void language plpgsql security definer
set search_path to 'public' as $$
declare
  v_was_pro boolean;
  v_is_pro_now boolean;
begin
  if not exists (select 1 from public.profiles where id = p_user_id) then
    return;
  end if;

  v_was_pro := public._is_pro(p_user_id);

  insert into public.pro_subscriptions as s
    (user_id, is_active, plan, store, product_id, period_type, expires_at,
     will_renew, billing_issue_at, environment, last_event_at, updated_at)
  values
    (p_user_id, p_is_active, p_plan, p_store, p_product_id, p_period_type,
     p_expires_at, p_will_renew, p_billing_issue_at, p_environment,
     p_event_at, now())
  on conflict (user_id) do update
    set is_active = excluded.is_active,
        plan = excluded.plan,
        store = excluded.store,
        product_id = excluded.product_id,
        period_type = excluded.period_type,
        expires_at = excluded.expires_at,
        will_renew = excluded.will_renew,
        billing_issue_at = excluded.billing_issue_at,
        environment = excluded.environment,
        last_event_at = excluded.last_event_at,
        updated_at = now()
    where s.last_event_at is null or s.last_event_at < excluded.last_event_at;

  v_is_pro_now := public._is_pro(p_user_id);

  update public.profiles
    set is_pro = v_is_pro_now,
        streak_freezes = case
          when v_is_pro_now and not v_was_pro
          then greatest(streak_freezes, 2)
          else streak_freezes
        end
    where id = p_user_id;
end;
$$;

revoke execute on function public._is_pro(uuid) from public, anon, authenticated;
revoke execute on function public._apply_pro_status(uuid, boolean, text, text,
  text, text, timestamptz, boolean, timestamptz, text, timestamptz)
  from public, anon, authenticated;
grant execute on function public._apply_pro_status(uuid, boolean, text, text,
  text, text, timestamptz, boolean, timestamptz, text, timestamptz)
  to service_role;

-- ----------------------------------------------------------------------------
-- C. Server-side level lock.
--
-- Rewritten from the live body in 20261001090000_three_tier_difficulty_ladder
-- with exactly one addition: a free player may start level 1, any level they
-- have already cleared, and the level after one they have cleared. The client
-- map already enforces this; the server must too (plan 6.2 / acceptance
-- criteria). Raises `level_locked`, which ApiException.fromSupabase already
-- turns into `code: 'level_locked'`.
-- ----------------------------------------------------------------------------

create or replace function public.start_level_attempt(p_subcategory_id uuid, p_level smallint, p_locale text default 'en'::text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user_id uuid := auth.uid();
  v_attempt_id uuid;
  v_seed text := encode(extensions.gen_random_bytes(16), 'hex');
  v_tier public.difficulty_tiers;
  v_is_boss boolean;
  v_n int;
  v_pool_ids uuid[];
  v_pool_size int;
  v_padded boolean := false;
  v_questions jsonb;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  select * into v_tier from public.get_difficulty_for_level(p_level);
  if v_tier.id is null then
    raise exception 'no difficulty tier configured for level %', p_level;
  end if;
  v_is_boss := public.is_boss_level(p_level);

  if p_level > 1
     and not public._is_pro(v_user_id)
     and not exists (
       select 1 from public.level_progress lp
       where lp.user_id = v_user_id
         and lp.subcategory_id = p_subcategory_id
         and lp.level in (p_level, p_level - 1)
         and lp.completed_at is not null
     ) then
    raise exception 'level_locked';
  end if;

  select coalesce(
    v_tier.override_questions_per_level,
    (select (value #>> '{}')::int from public.app_settings where key = 'questions_per_level'),
    20
  ) into v_n;

  insert into public.level_attempts (user_id, subcategory_id, level, seed, locale, is_boss, seconds_per_question)
  values (v_user_id, p_subcategory_id, p_level, v_seed, p_locale, v_is_boss, v_tier.seconds_per_question)
  returning id into v_attempt_id;

  select array_agg(id) into v_pool_ids
  from (
    select q.id
    from public.questions q
    left join public.user_question_history h
      on h.question_id = q.id and h.user_id = v_user_id
    where q.subcategory_id = p_subcategory_id
      and q.difficulty_tier_id = v_tier.id
      and q.language_code = p_locale
      and q.status = 'live'
    order by h.last_seen_at asc nulls first, random()
  ) ranked;

  v_pool_size := coalesce(array_length(v_pool_ids, 1), 0);
  if v_pool_size = 0 then
    raise exception 'no live questions for subcategory %, tier %, language %',
      p_subcategory_id, v_tier.code, p_locale;
  end if;
  if v_pool_size < v_n then
    v_padded := true;
  end if;

  select jsonb_agg(row order by random()) into v_questions
  from (
    select jsonb_build_object(
      'id', q.id,
      'subcategoryId', q.subcategory_id,
      'difficulty', q.difficulty,
      'text', q.prompt,
      'options', q.options,
      'correctIndex', q.correct_index,
      'explanation', q.explanation,
      'hasImage', q.kind = 'image',
      'imageAsset', q.media_url,
      'ttsExcluded', q.tts_excluded,
      'audioUrl', q.audio_url
    ) as row
    from (
      select v_pool_ids[((n - 1) % v_pool_size) + 1] as qid
      from generate_series(1, v_n) as n
    ) numbered
    join public.questions q on q.id = numbered.qid
  ) sub;

  insert into public.level_attempt_question_sets
    (id, user_id, subcategory_id, difficulty_tier_id, level, language_code, question_ids, is_repeat_padded)
  select v_attempt_id, v_user_id, p_subcategory_id, v_tier.id, p_level, p_locale,
         array_agg((row ->> 'id')::uuid), v_padded
  from jsonb_array_elements(v_questions) row;

  insert into public.user_question_history (user_id, question_id, times_seen, first_seen_at, last_seen_at)
  select v_user_id, qid, 1, now(), now()
  from (
    select distinct (row ->> 'id')::uuid as qid
    from jsonb_array_elements(v_questions) row
  ) distinct_qids
  on conflict (user_id, question_id)
  do update set times_seen   = user_question_history.times_seen + 1,
                last_seen_at = now();

  update public.questions set seen_count = seen_count + 1
    where id in (select (row ->> 'id')::uuid from jsonb_array_elements(v_questions) row);

  return jsonb_build_object(
    'attemptId', v_attempt_id,
    'secondsPerQuestion', v_tier.seconds_per_question,
    'isBoss', v_is_boss,
    'questions', coalesce(v_questions, '[]'::jsonb)
  );
end;
$function$;

-- ----------------------------------------------------------------------------
-- D. Streak shield + expiry sweep.
--
-- _touch_daily_streak spends one streak_freezes on a 2+ day gap and nothing
-- else refilled them; Pro tops them up to 2 on becoming Pro (B) and on the
-- 1st of each month here. The sweep clears badges whose subscription lapsed
-- without a webhook (plan Assumption 11).
-- ----------------------------------------------------------------------------

select cron.schedule('pro-streak-freeze-refill', '5 0 1 * *',
  $$update public.profiles set streak_freezes = 2
    where is_pro and streak_freezes < 2$$);
select cron.schedule('pro-expiry-sweep', '20 0 * * *',
  $$update public.profiles p set is_pro = false
    where p.is_pro and not public._is_pro(p.id)$$);

-- ----------------------------------------------------------------------------
-- E. Duel identity JSON gains `isPro`.
--
-- Rewritten from the live bodies; only the one added key differs. The
-- snapshot-based cards look the flag up from profiles at read time so a
-- badge change is visible without rewriting history rows.
-- ----------------------------------------------------------------------------

create or replace function public._duel_player_json(p_user_id uuid, p_subcategory_id uuid)
returns jsonb
language sql
stable security definer
set search_path to 'public'
as $function$
  select jsonb_build_object(
    'id', p.id,
    'name', p.username::text,
    'isGuest', p.is_guest,
    'guestTag', case when p.is_guest or p.username is null then public._duel_guest_tag(p.id) end,
    'avatar', p.avatar_key,
    'elo', p.elo,
    'league', p.league,
    'topicLevel', case when p_subcategory_id is null then 0
                       else public._duel_topic_level(p.id, p_subcategory_id) end,
    'isBot', false,
    'isPro', p.is_pro
  )
  from public.profiles p
  where p.id = p_user_id;
$function$;

create or replace function public._duel_challenge_card(p_c duel_challenges)
returns jsonb
language sql
stable security definer
set search_path to 'public'
as $function$
  select jsonb_build_object(
    'id', p_c.id,
    'status', p_c.status,
    'creatorPresent', p_c.creator_present,
    'createdAt', p_c.created_at,
    'expiresAt', p_c.expires_at,
    'creator', jsonb_build_object(
      'id', p_c.creator_id,
      'name', p_c.creator_name,
      'isGuest', false,
      'guestTag', p_c.creator_guest_tag,
      'avatar', p_c.creator_avatar,
      'elo', p_c.creator_elo,
      'league', p_c.creator_league,
      'topicLevel', p_c.creator_topic_level,
      'isBot', false,
      'isPro', coalesce((select pr.is_pro from public.profiles pr where pr.id = p_c.creator_id), false)
    ),
    'topic', jsonb_build_object(
      'id', p_c.subcategory_id,
      'name', p_c.topic_name,
      'emoji', p_c.topic_emoji,
      'plateColor', p_c.topic_plate_color,
      'categoryId', p_c.category_id,
      'categoryName', p_c.category_name,
      'categoryEmoji', p_c.category_emoji
    ),
    'opponentName', p_c.opponent_name,
    'opponentGuestTag', p_c.opponent_guest_tag,
    'duelId', p_c.duel_id
  );
$function$;

create or replace function public._duel_challenge_history_card(p_h duel_challenge_history)
returns jsonb
language sql
stable security definer
set search_path to 'public'
as $function$
  select jsonb_build_object(
    'id', p_h.id,
    'status', 'ended',
    'creatorPresent', false,
    'createdAt', p_h.created_at,
    'expiresAt', coalesce(p_h.expires_at, p_h.ended_at),
    'creator', jsonb_build_object(
      'id', p_h.creator_id,
      'name', p_h.creator_name,
      'isGuest', false,
      'guestTag', p_h.creator_guest_tag,
      'avatar', p_h.creator_avatar,
      'elo', p_h.creator_elo,
      'league', p_h.creator_league,
      'topicLevel', p_h.creator_topic_level,
      'isBot', false,
      'isPro', coalesce((select pr.is_pro from public.profiles pr where pr.id = p_h.creator_id), false)
    ),
    'topic', jsonb_build_object(
      'id', p_h.subcategory_id,
      'name', p_h.topic_name,
      'emoji', p_h.topic_emoji,
      'plateColor', p_h.topic_plate_color,
      'categoryId', p_h.category_id,
      'categoryName', p_h.category_name,
      'categoryEmoji', p_h.category_emoji
    ),
    'opponentName', p_h.opponent_name,
    'opponentGuestTag', p_h.opponent_guest_tag,
    'duelId', p_h.duel_id,
    'endReason', p_h.end_reason,
    'endedAt', p_h.ended_at
  );
$function$;

create or replace function public._duel_requester_json(p_r duel_join_requests)
returns jsonb
language sql
stable security definer
set search_path to 'public'
as $function$
  select jsonb_build_object(
    'id', p_r.requester_id,
    'name', p_r.requester_name,
    'isGuest', p_r.requester_is_guest,
    'guestTag', p_r.requester_guest_tag,
    'avatar', p_r.requester_avatar,
    'elo', p_r.requester_elo,
    'league', p_r.requester_league,
    'topicLevel', p_r.requester_topic_level,
    'isBot', false,
    'isPro', coalesce((select pr.is_pro from public.profiles pr where pr.id = p_r.requester_id), false)
  );
$function$;

-- ----------------------------------------------------------------------------
-- F. Pro avatars + the guard trigger.
--
-- Only avatars that did not already exist are added, and only those become
-- Pro — a pre-existing free avatar is never flipped (plan 2.6). The trigger
-- is defence in depth for the app's own profile editor.
-- ----------------------------------------------------------------------------

insert into public.avatar_options (emoji, sort_order, is_active, is_pro)
select v.emoji,
       (select coalesce(max(sort_order), 0) from public.avatar_options) + v.ord,
       true,
       true
from (values
  ('👑', 1), ('🦄', 2), ('🐉', 3), ('🦁', 4), ('🦅', 5), ('🧙', 6),
  ('🥷', 7), ('🧞', 8), ('🦸', 9), ('🧜', 10), ('🤴', 11), ('👸', 12)
) as v(emoji, ord)
on conflict (emoji) do nothing;

create or replace function public._enforce_pro_avatar() returns trigger
language plpgsql security definer set search_path to 'public' as $$
begin
  if new.avatar_key is distinct from old.avatar_key
     and exists (select 1 from public.avatar_options
                 where emoji = new.avatar_key and is_pro)
     and not public._is_pro(new.id) then
    raise exception 'pro_avatar_required';
  end if;
  return new;
end; $$;

drop trigger if exists trg_enforce_pro_avatar on public.profiles;
create trigger trg_enforce_pro_avatar before update of avatar_key
  on public.profiles for each row execute function public._enforce_pro_avatar();

-- ----------------------------------------------------------------------------
-- G. is_pro is not a client-writable column.
--
-- `authenticated` holds table-level INSERT on profiles (profile rows are in
-- fact created by the _handle_new_user trigger, never by a client), so a
-- column-level REVOKE on is_pro is a no-op. A plain trigger closes the
-- residual hole without touching the grant table: a client role may not set
-- the flag, while _apply_pro_status and the cron jobs run as the definer
-- (postgres) and are unaffected.
-- ----------------------------------------------------------------------------

create or replace function public._guard_pro_flag() returns trigger
language plpgsql as $$
begin
  if current_user in ('anon', 'authenticated') then
    if tg_op = 'INSERT' and new.is_pro then
      raise exception 'pro_flag_readonly';
    end if;
    if tg_op = 'UPDATE' and new.is_pro is distinct from old.is_pro then
      raise exception 'pro_flag_readonly';
    end if;
  end if;
  return new;
end; $$;

drop trigger if exists trg_guard_pro_flag on public.profiles;
create trigger trg_guard_pro_flag before insert or update of is_pro
  on public.profiles for each row execute function public._guard_pro_flag();

commit;
