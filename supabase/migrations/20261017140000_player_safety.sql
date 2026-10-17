-- ============================================================================
-- 20261017140000_player_safety.sql
--
-- Plan: .claude/plans/025-app-review-readiness-fixes.md (Phase 6)
--
-- Player safety for a UGC surface (App Review Guideline 1.2): report and
-- block tables with owner-reviewed storage, a shared blocked-pair predicate
-- enforced in matchmaking and duel joins, extended account-deletion cleanup,
-- and a server-side username term policy.
--
-- Changed functions — each recreated from its live body with ONLY the
-- predicates named here added:
--   * public._duel_try_pair(uuid): candidate search excludes blocked pairs.
--   * public.request_duel_join(uuid): raises 'blocked' for a blocked creator.
--   * public.respond_duel_join(uuid, boolean): raises 'blocked' for a blocked
--     requester.
--   * public.get_duel_lobby(text): feed hides blocked creators; incoming
--     request hidden when the requester is blocked.
--   * public.delete_account_data(uuid): also deletes user_reports and
--     user_blocks rows on either side of the deleted user.
--
-- Rollback: drop the tables, the trigger and the three helper functions;
-- re-apply the four duel functions and delete_account_data from their
-- pre-plan-025 definitions (20260927120300_duel_matchmaking_functions.sql /
-- 20260927120200_duel_arena_challenge_functions.sql, and the account_deletion
-- migration).
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- A. Schema + RLS.
-- ----------------------------------------------------------------------------

create table if not exists public.user_reports (
  id bigserial primary key,
  reporter_id uuid not null references public.profiles(id),
  reported_id uuid not null references public.profiles(id),
  reason text not null,
  note text,
  resolved boolean not null default false,
  created_at timestamptz not null default now(),
  constraint user_reports_no_self check (reporter_id <> reported_id)
);

alter table public.user_reports enable row level security;

drop policy if exists "insert own reports" on public.user_reports;
create policy "insert own reports" on public.user_reports
  for insert with check (reporter_id = auth.uid());
drop policy if exists "select own reports" on public.user_reports;
create policy "select own reports" on public.user_reports
  for select using (reporter_id = auth.uid());
-- No update/delete for clients: reports are write-once and reviewed by the
-- owner through SQL (`select * from public.user_reports where resolved =
-- false order by created_at;`).

create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles(id),
  blocked_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint user_blocks_no_self check (blocker_id <> blocked_id)
);

alter table public.user_blocks enable row level security;

drop policy if exists "select own blocks" on public.user_blocks;
create policy "select own blocks" on public.user_blocks
  for select using (blocker_id = auth.uid());
drop policy if exists "insert own blocks" on public.user_blocks;
create policy "insert own blocks" on public.user_blocks
  for insert with check (blocker_id = auth.uid());
drop policy if exists "delete own blocks" on public.user_blocks;
create policy "delete own blocks" on public.user_blocks
  for delete using (blocker_id = auth.uid());
-- The blocked player sees nothing: no policy matches rows where they are the
-- blocked side.

-- ----------------------------------------------------------------------------
-- B. Shared blocked-pair predicate.
-- ----------------------------------------------------------------------------

create or replace function public._blocked_between(p_a uuid, p_b uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.user_blocks
    where (blocker_id = p_a and blocked_id = p_b)
       or (blocker_id = p_b and blocked_id = p_a)
  );
$$;

comment on function public._blocked_between(uuid, uuid) is
  'Directed-block predicate, checked in both directions. Security definer so it can see rows hidden from the blocked side; used only inside other security-definer functions.';

revoke all on function public._blocked_between(uuid, uuid)
  from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- C. Duel enforcement.
-- ----------------------------------------------------------------------------

create or replace function public._duel_try_pair(p_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_cfg jsonb := public._duel_cfg();
  v_start integer := (v_cfg ->> 'mm_band_start')::integer;
  v_step integer := (v_cfg ->> 'mm_band_step')::integer;
  v_step_s integer := (v_cfg ->> 'mm_band_step_seconds')::integer;
  v_max integer := (v_cfg ->> 'mm_band_max')::integer;
  v_weight integer := (v_cfg ->> 'mm_topic_level_weight')::integer;
  v_stale interval := (v_cfg ->> 'mm_stale_seconds')::integer * interval '1 second';
  v_me public.matchmaking_queue;
  v_my_band integer;
  v_other uuid;
  v_other_queued_at timestamptz;
begin
  select * into v_me from public.matchmaking_queue where user_id = p_user_id;
  if not found then
    return null;
  end if;

  perform public._duel_state_lock(p_user_id);
  if public._duel_live_duel_id(p_user_id) is not null then
    return null;
  end if;

  if not pg_try_advisory_xact_lock(hashtextextended('duel-mm:' || v_me.subcategory_id::text, 0)) then
    return null;
  end if;

  v_my_band := public._duel_mm_band(v_me.queued_at);

  -- Band computed inline for candidates (same formula as _duel_mm_band) to
  -- avoid re-reading the config per row. Plan 025: blocked pairs are never
  -- dealt to each other.
  select q.user_id, q.queued_at into v_other, v_other_queued_at
  from public.matchmaking_queue q
  join public.duel_player_state s on s.user_id = q.user_id
  where q.subcategory_id = v_me.subcategory_id
    and q.language_code = v_me.language_code
    and q.user_id <> p_user_id
    and q.last_seen_at > now() - v_stale
    and s.current_duel_id is null
    and not public._blocked_between(p_user_id, q.user_id)
    and abs(q.elo - v_me.elo) <= greatest(
          v_my_band,
          least(v_max, v_start + v_step * floor(
            greatest(0, extract(epoch from (now() - q.queued_at))) / v_step_s
          )::integer)
        )
  order by abs(q.elo - v_me.elo) + v_weight * abs(q.topic_level - v_me.topic_level),
           q.queued_at,
           q.user_id
  limit 1
  for update of s skip locked;

  if v_other is null then
    return null;
  end if;

  -- The longer-waiting player is p1.
  if v_other_queued_at < v_me.queued_at
     or (v_other_queued_at = v_me.queued_at and v_other < p_user_id) then
    return public._duel_create(
      v_other, p_user_id, v_me.subcategory_id, v_me.language_code, 'matchmaking', null, null
    );
  end if;
  return public._duel_create(
    p_user_id, v_other, v_me.subcategory_id, v_me.language_code, 'matchmaking', null, null
  );
end;
$function$;

create or replace function public.request_duel_join(p_challenge_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_me uuid := auth.uid();
  v_cfg jsonb := public._duel_cfg();
  v_c public.duel_challenges;
  v_state public.duel_player_state;
  v_profile public.profiles;
  v_player jsonb;
  v_r public.duel_join_requests;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  -- Guests may watch the arena and use Quick match, but joining someone's
  -- challenge needs an account (2026-09-28).
  if exists (select 1 from public.profiles where id = v_me and is_guest) then
    raise exception 'guest_cannot_join';
  end if;

  select * into v_c from public.duel_challenges where id = p_challenge_id;
  if not found or v_c.status <> 'open' or v_c.expires_at <= now() then
    raise exception 'challenge_unavailable';
  end if;
  if v_c.creator_id = v_me then
    raise exception 'own_challenge';
  end if;
  -- Plan 025: neither side of a block may join the other's challenge.
  if public._blocked_between(v_me, v_c.creator_id) then
    raise exception 'blocked';
  end if;
  if not v_c.creator_present then
    raise exception 'creator_away';
  end if;

  v_state := public._duel_state_lock(v_me);
  if v_state.current_duel_id is not null then
    raise exception 'already_in_duel';
  end if;

  -- Re-check under the challenge lock (serialises requests per challenge).
  select * into v_c from public.duel_challenges where id = p_challenge_id for update;
  if not found or v_c.status <> 'open' or v_c.expires_at <= now() then
    raise exception 'challenge_unavailable';
  end if;
  if not v_c.creator_present then
    raise exception 'creator_away';
  end if;

  if exists (
    select 1 from public.duel_join_requests
    where challenge_id = p_challenge_id and requester_id = v_me
      and status in ('queued', 'pending')
  ) then
    raise exception 'already_requested';
  end if;

  if exists (
    select 1 from public.duel_join_requests
    where challenge_id = p_challenge_id and requester_id = v_me
      and retry_after > now()
  ) then
    raise exception 'retry_later';
  end if;

  if (select count(*) from public.duel_join_requests
      where requester_id = v_me and status in ('queued', 'pending'))
     >= (v_cfg ->> 'join_max_outstanding')::integer then
    raise exception 'too_many_requests';
  end if;

  perform public._duel_rate_hit(
    v_me, 'join', (v_cfg ->> 'join_rate_max')::integer,
    (v_cfg ->> 'join_rate_window_seconds')::integer * interval '1 second', 'rate_limited'
  );

  if (select count(*) from public.duel_join_requests
      where challenge_id = p_challenge_id and status in ('queued', 'pending'))
     >= (v_cfg ->> 'join_queue_cap')::integer then
    raise exception 'challenge_busy';
  end if;

  select * into v_profile from public.profiles where id = v_me;
  v_player := public._duel_player_json(v_me, v_c.subcategory_id);

  insert into public.duel_join_requests (
    challenge_id, creator_id, requester_id, status,
    requester_name, requester_guest_tag, requester_is_guest, requester_avatar,
    requester_elo, requester_league, requester_topic_level
  ) values (
    p_challenge_id, v_c.creator_id, v_me, 'queued',
    v_player ->> 'name', v_player ->> 'guestTag', v_profile.is_guest, v_player ->> 'avatar',
    (v_player ->> 'elo')::integer, v_player ->> 'league', (v_player ->> 'topicLevel')::smallint
  )
  returning * into v_r;

  -- Before promoting: promotion skips requesters not seen on the arena.
  update public.duel_player_state
    set lobby_seen_at = now(), updated_at = now()
    where user_id = v_me;

  perform public._duel_promote_next_request(p_challenge_id);

  select * into v_r from public.duel_join_requests where id = v_r.id;
  return public._duel_request_status_payload(v_r, null)
         || jsonb_build_object('serverNow', now());
end;
$function$;

create or replace function public.respond_duel_join(p_request_id uuid, p_accept boolean)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_me uuid := auth.uid();
  v_cfg jsonb := public._duel_cfg();
  v_grace interval := (v_cfg ->> 'join_grace_ms')::integer * interval '1 millisecond';
  v_r public.duel_join_requests;
  v_c public.duel_challenges;
  v_duel_id uuid;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_r from public.duel_join_requests
    where id = p_request_id and creator_id = v_me;
  if not found then
    raise exception 'request_not_found';
  end if;
  -- Plan 025: a blocked requester's request can never be accepted.
  if public._blocked_between(v_me, v_r.requester_id) then
    raise exception 'blocked';
  end if;
  if v_r.status <> 'pending' then
    raise exception 'request_expired';
  end if;

  if not coalesce(p_accept, false) then
    perform 1 from public.duel_challenges where id = v_r.challenge_id for update;
    select * into v_r from public.duel_join_requests where id = p_request_id for update;
    if not found or v_r.status <> 'pending' then
      raise exception 'request_expired';
    end if;

    -- The creator's client auto-declines at 0 s; that is "no answer", not a
    -- decline (see header).
    if now() >= v_r.expires_at then
      perform public._duel_resolve_request(p_request_id, 'expired', 'no_response', true);
    else
      perform public._duel_resolve_request(p_request_id, 'declined', 'declined', true);
    end if;
    perform public._duel_promote_next_request(v_r.challenge_id);

    return jsonb_build_object('accepted', false, 'duelId', null, 'serverNow', now());
  end if;

  -- Accept. Lock order: both players' state rows, then the challenge, then
  -- the request.
  perform public._duel_lock_pair(v_me, v_r.requester_id);
  if public._duel_live_duel_id(v_me) is not null then
    raise exception 'already_in_duel';
  end if;
  if public._duel_live_duel_id(v_r.requester_id) is not null then
    -- The duel that claimed the requester already withdrew this request and
    -- advanced the queue in its own transaction.
    raise exception 'requester_busy';
  end if;

  select * into v_c from public.duel_challenges where id = v_r.challenge_id for update;
  if not found or v_c.status <> 'open' then
    raise exception 'request_expired';
  end if;

  select * into v_r from public.duel_join_requests where id = p_request_id for update;
  if not found or v_r.status <> 'pending' then
    raise exception 'request_expired';
  end if;
  if now() > v_r.expires_at + v_grace then
    raise exception 'request_expired';
  end if;

  -- Mark accepted and clear the rest of the queue BEFORE _duel_create, so
  -- its "withdraw the requester's requests" step doesn't touch this row and
  -- nothing gets promoted onto this challenge.
  update public.duel_join_requests
    set status = 'accepted', reason = 'accepted', resolved_at = now()
    where id = p_request_id
    returning * into v_r;
  perform public._duel_clear_requests_for_challenge(v_c.id, 'taken');

  v_duel_id := public._duel_create(
    v_c.creator_id, v_r.requester_id, v_c.subcategory_id, v_c.language_code,
    'challenge', v_c.id, null
  );

  -- "In progress" card (the update trigger broadcasts it).
  update public.duel_challenges
    set status = 'matched',
        duel_id = v_duel_id,
        opponent_name = v_r.requester_name,
        opponent_guest_tag = v_r.requester_guest_tag
    where id = v_c.id;

  perform public._duel_inbox_send(
    v_r.requester_id, 'join_request_status', public._duel_request_status_payload(v_r, 'accepted')
  );

  return jsonb_build_object('accepted', true, 'duelId', v_duel_id, 'serverNow', now());
end;
$function$;

create or replace function public.get_duel_lobby(p_language_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_me uuid := auth.uid();
  v_cfg jsonb := public._duel_cfg();
  v_profile public.profiles;
  v_state public.duel_player_state;
  v_open public.duel_challenges;
  v_pending public.duel_join_requests;
  v_bucket public.duel_rate_buckets;
  v_has_bucket boolean;
  v_cap integer;
  v_left integer;
  v_cooldown_ends timestamptz;
  v_challenges jsonb;
  v_recently_ended jsonb;
  v_my_requests jsonb;
  v_incoming jsonb;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;
  select * into v_profile from public.profiles where id = v_me;
  if not found then
    raise exception 'not_authenticated';
  end if;

  insert into public.duel_player_state (user_id, lobby_seen_at) values (v_me, now())
  on conflict (user_id) do update set lobby_seen_at = now(), updated_at = now()
  returning * into v_state;

  select * into v_open from public.duel_challenges
    where creator_id = v_me and status = 'open' and expires_at > now();

  v_cooldown_ends := case
    when v_state.last_challenge_at is not null
         and v_state.last_challenge_at
           + (v_cfg ->> 'challenge_cooldown_seconds')::integer * interval '1 second' > now()
    then v_state.last_challenge_at
           + (v_cfg ->> 'challenge_cooldown_seconds')::integer * interval '1 second'
  end;

  v_cap := (v_cfg ->> 'challenge_daily_cap')::integer;
  select * into v_bucket from public.duel_rate_buckets
    where user_id = v_me and bucket = 'challenge_day';
  v_has_bucket := found;
  v_left := case
    when v_profile.is_guest then 0
    when not v_has_bucket or v_bucket.window_start < now() - interval '24 hours' then v_cap
    else greatest(0, v_cap - v_bucket.hits)
  end;

  -- Up to lobby_feed_limit newest live cards, returned oldest-first.
  -- Plan 025: blocked creators' cards never appear.
  select coalesce(jsonb_agg(public._duel_challenge_card(c) order by c.created_at, c.id), '[]'::jsonb)
    into v_challenges
  from public.duel_challenges c
  where c.id in (
    select f.id from public.duel_challenges f
    where f.language_code = p_language_code
      and (f.status = 'matched' or (f.status = 'open' and f.expires_at > now()))
      and not public._blocked_between(v_me, f.creator_id)
    order by f.created_at desc
    limit (v_cfg ->> 'lobby_feed_limit')::integer
  );

  -- Up to lobby_feed_limit most-recently-ended cards (7-day retention).
  select coalesce(jsonb_agg(public._duel_challenge_history_card(h) order by h.ended_at desc), '[]'::jsonb)
    into v_recently_ended
  from public.duel_challenge_history h
  where h.id in (
    select f.id from public.duel_challenge_history f
    where f.language_code = p_language_code
    order by f.ended_at desc
    limit (v_cfg ->> 'lobby_feed_limit')::integer
  );

  select coalesce(
           jsonb_agg(public._duel_request_status_payload(r, null) order by r.created_at, r.id),
           '[]'::jsonb)
    into v_my_requests
  from public.duel_join_requests r
  where r.requester_id = v_me
    and (r.status in ('queued', 'pending') or r.retry_after > now());

  if v_open.id is not null then
    -- Plan 025: a blocked requester's pending request is never shown.
    select * into v_pending from public.duel_join_requests
      where challenge_id = v_open.id and status = 'pending'
        and not public._blocked_between(v_me, requester_id);
    if found then
      v_incoming := public._duel_incoming_json(v_pending);
    end if;
  end if;

  return jsonb_build_object(
    'serverNow', now(),
    'config', jsonb_build_object(
      'challengeTtlSeconds', v_cfg -> 'challenge_ttl_seconds',
      'cooldownSeconds', v_cfg -> 'challenge_cooldown_seconds',
      'joinWindowSeconds', v_cfg -> 'join_window_seconds',
      'lobbyHeartbeatSeconds', v_cfg -> 'lobby_heartbeat_seconds',
      'mmHeartbeatSeconds', v_cfg -> 'mm_heartbeat_seconds',
      'botAfterSeconds', v_cfg -> 'mm_bot_after_seconds',
      'bandStepSeconds', v_cfg -> 'mm_band_step_seconds',
      'rounds', v_cfg -> 'rounds',
      'roundSeconds', v_cfg -> 'round_seconds',
      'revealSeconds', v_cfg -> 'reveal_seconds',
      'introSeconds', v_cfg -> 'intro_seconds',
      'duelHeartbeatSeconds', v_cfg -> 'duel_heartbeat_seconds',
      'rematchWindowSeconds', v_cfg -> 'rematch_window_seconds',
      'presenceEnabled', v_cfg -> 'lobby_presence_enabled',
      'winCoins', v_cfg -> 'reward_win_coins',
      -- extra (not in the plan's list): for the "up to {max}" notice copy.
      'joinMaxOutstanding', v_cfg -> 'join_max_outstanding'
    ),
    'me', jsonb_build_object(
      'player', public._duel_player_json(v_me, null),
      'isGuest', v_profile.is_guest,
      'activeDuelId', public._duel_live_duel_id(v_me),
      'openChallengeId', v_open.id,
      'cooldownEndsAt', v_cooldown_ends,
      'challengesLeftToday', v_left
    ),
    'challenges', v_challenges,
    'recentlyEnded', v_recently_ended,
    'myRequests', v_my_requests,
    'incoming', v_incoming
  );
end;
$function$;

-- ----------------------------------------------------------------------------
-- D. Account deletion also clears safety records on either side.
-- ----------------------------------------------------------------------------

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

  -- Player-safety records (plan 025 Phase 6): both sides.
  delete from public.user_reports
   where reporter_id = p_user_id or reported_id = p_user_id;
  delete from public.user_blocks
   where blocker_id = p_user_id or blocked_id = p_user_id;

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

-- ----------------------------------------------------------------------------
-- E. Username policy.
-- ----------------------------------------------------------------------------

create table if not exists public.username_policy_terms (
  term text primary key,
  kind text not null default 'profanity'
    check (kind in ('reserved', 'profanity'))
);

alter table public.username_policy_terms enable row level security;
revoke all on public.username_policy_terms from public, anon, authenticated;

insert into public.username_policy_terms (term, kind) values
  ('quizoo', 'reserved'),
  ('admin', 'reserved'),
  ('administrator', 'reserved'),
  ('moderator', 'reserved'),
  ('official', 'reserved'),
  ('support', 'reserved'),
  ('helpdesk', 'reserved'),
  ('staff', 'reserved'),
  ('fuck', 'profanity'),
  ('shit', 'profanity'),
  ('bitch', 'profanity'),
  ('cunt', 'profanity'),
  ('nazi', 'profanity'),
  ('hitler', 'profanity'),
  ('rape', 'profanity'),
  ('slut', 'profanity'),
  ('whore', 'profanity')
on conflict (term) do nothing;

-- Normalization: lowercase, strip everything but a-z0-9, then map common
-- leet substitutions. The owner extends the term list with plain SQL -- no
-- app release needed.
create or replace function public._username_is_allowed(p_username text)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select not exists (
    select 1
    from public.username_policy_terms t
    where translate(
            regexp_replace(lower(p_username), '[^a-z0-9]', '', 'g'),
            '013457@$', 'oieastas'
          ) like '%' || t.term || '%'
  );
$$;

comment on function public._username_is_allowed(text) is
  'Normalized reserved/profanity term check for usernames (plan 025). Security definer so the term table itself needs no client grants.';

create or replace function public._enforce_username_policy()
returns trigger
language plpgsql security definer
set search_path = public
as $$
begin
  if new.username is not null
     and not public._username_is_allowed(new.username) then
    raise exception 'username_not_allowed';
  end if;
  return new;
end;
$$;

revoke all on function public._username_is_allowed(text)
  from public, anon, authenticated;

drop trigger if exists trg_enforce_username_policy on public.profiles;
create trigger trg_enforce_username_policy
  before insert or update of username on public.profiles
  for each row execute function public._enforce_username_policy();

comment on trigger trg_enforce_username_policy on public.profiles is
  'Rejects reserved/profanity usernames at insert/update (plan 025); a null username always passes, so the auth bootstrap insert is unaffected.';

commit;
