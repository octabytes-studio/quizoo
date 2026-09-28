-- ============================================================================
-- 20260927120200_duel_arena_challenge_functions.sql
--
-- Plan 017, Phase 3: arena & challenge functions -- shared helpers, the
-- challenge feed broadcast trigger, the join-request queue, and the arena
-- RPCs (get_duel_lobby, list_duel_topics, create/cancel_duel_challenge,
-- set_duel_lobby_presence, request/withdraw/respond_duel_join).
--
-- Conventions (plan 017, Phase 3):
--   * Every function: security definer, search_path = public. Public RPCs are
--     granted to `authenticated` (guests are authenticated anonymous users)
--     and revoked from public/anon; every `_`-prefixed helper is revoked from
--     public, anon and authenticated, so only other definer functions / cron
--     can call it.
--   * Errors: `raise exception '<identifier>'` (SQLSTATE P0001), which
--     ApiException.fromSupabase surfaces as ApiException.code.
--   * Every RPC response object and every broadcast payload carries
--     serverNow. NOTE: realtime.send adds a random `id` key to any payload
--     that doesn't already have one -- clients must ignore unknown keys.
--   * _duel_create is defined in 20260927120400 (plpgsql bodies resolve
--     at call time, so respond_duel_join may reference it here).
--
-- Lock order used throughout (to keep deadlocks out of the common paths):
--   duels row  ->  duel_player_state rows (ascending user_id)
--              ->  duel_challenges row  ->  duel_join_requests rows.
-- Every modification of a duel_join_requests row happens while holding its
-- parent duel_challenges row lock.
--
-- Deviation from the plan (flagged in the report): a raise rolls back every
-- write in the same call, so "resolve expired -> promote -> raise
-- request_expired" can't persist the resolution. respond_duel_join therefore
--   * on DECLINE never raises for lateness: a decline at/after expires_at is
--     recorded as status 'expired' / reason 'no_response' (so the creator's
--     automatic decline at 0 s reads as "no answer", not "declined");
--   * on a late ACCEPT (past expires_at + grace) raises request_expired and
--     leaves the pending row for _duel_promote_next_request / the sweeper,
--     both of which expire overdue pending rows and present the next one.
-- ============================================================================

begin;

-- ============================================================================
-- Config
-- ============================================================================

-- The stored duel_config layered over the defaults, so a key missing from
-- the row never becomes a null threshold.
create or replace function public._duel_cfg()
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select '{"challenge_ttl_seconds":300,"challenge_cooldown_seconds":120,"challenge_daily_cap":60,
           "join_window_seconds":5,"join_grace_ms":1500,"join_max_outstanding":3,
           "join_rate_max":20,"join_rate_window_seconds":300,"join_retry_seconds":15,"join_queue_cap":10,
           "lobby_heartbeat_seconds":10,"creator_stale_seconds":25,"lobby_feed_limit":50,"lobby_presence_enabled":true,
           "min_topic_questions":5,
           "mm_heartbeat_seconds":3,"mm_stale_seconds":12,"mm_bot_after_seconds":30,
           "mm_band_start":100,"mm_band_step":50,"mm_band_step_seconds":5,"mm_band_max":600,
           "mm_topic_level_weight":10,"mm_join_rate_max":20,"mm_join_rate_window_seconds":600,
           "rounds":5,"round_seconds":15,"reveal_seconds":2,"intro_seconds":3,
           "latency_allowance_ms":1500,"min_answer_ms":250,
           "ready_timeout_seconds":20,"duel_heartbeat_seconds":5,"disconnect_forfeit_seconds":30,
           "rematch_window_seconds":30,"ranked_pair_cap_per_day":3,
           "rage_quit_forfeits_per_day":3,"elo_k":32,
           "reward_win_coins":200,"reward_win_xp":250,"reward_loss_coins":40,"reward_loss_xp":80,
           "reward_draw_coins":40,"reward_draw_xp":80}'::jsonb
         || coalesce((select value from public.app_settings where key = 'duel_config'), '{}'::jsonb);
$$;

create or replace function public._duel_cfg_int(p_key text)
returns integer
language sql stable security definer
set search_path = public
as $$
  select (public._duel_cfg() ->> p_key)::integer;
$$;

-- ============================================================================
-- Identity / topic helpers
-- ============================================================================

-- Stable 4-digit tag for "Guest 4821". bigint before abs(): hashtext can
-- return INT_MIN, whose abs() overflows int4.
create or replace function public._duel_guest_tag(p_user_id uuid)
returns text
language sql immutable security definer
set search_path = public
as $$
  select lpad((abs(hashtext(p_user_id::text)::bigint) % 10000)::text, 4, '0');
$$;

-- A topic's "level" for a player = number of completed levels in it.
create or replace function public._duel_topic_level(p_user_id uuid, p_subcategory_id uuid)
returns smallint
language sql stable security definer
set search_path = public
as $$
  select count(*)::smallint
  from public.level_progress
  where user_id = p_user_id
    and subcategory_id = p_subcategory_id
    and completed_at is not null;
$$;

-- Live, fully-formed questions in one topic + language (the pool _duel_create
-- draws from, so every availability check counts the same thing).
create or replace function public._duel_topic_question_count(p_subcategory_id uuid, p_language_code text)
returns integer
language sql stable security definer
set search_path = public
as $$
  select count(*)::integer
  from public.questions q
  where q.subcategory_id = p_subcategory_id
    and q.status = 'live'
    and q.language_code = p_language_code
    and q.prompt is not null
    and q.options is not null
    and q.correct_index is not null;
$$;

-- The topic's language when it is duel-able (active sub-category in an active
-- category with >= min_topic_questions live questions in its own language),
-- else null.
create or replace function public._duel_topic_language(p_subcategory_id uuid)
returns text
language plpgsql stable security definer
set search_path = public
as $$
declare
  v_lang text;
begin
  select c.language_code into v_lang
  from public.subcategories s
  join public.categories c on c.id = s.category_id
  where s.id = p_subcategory_id and s.is_active and c.is_active;

  if v_lang is null then
    return null;
  end if;
  if public._duel_topic_question_count(p_subcategory_id, v_lang)
       < public._duel_cfg_int('min_topic_questions') then
    return null;
  end if;
  return v_lang;
end;
$$;

-- {id, name, isGuest, guestTag, avatar, elo, league, topicLevel, isBot}.
-- guestTag is set for guests and for any player with no username yet, so a
-- client always has something to render.
create or replace function public._duel_player_json(p_user_id uuid, p_subcategory_id uuid)
returns jsonb
language sql stable security definer
set search_path = public
as $$
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
    'isBot', false
  )
  from public.profiles p
  where p.id = p_user_id;
$$;

-- {id, name, emoji, plateColor, categoryId, categoryName, categoryEmoji}.
-- Names come from taxonomy_i18n in the entity's own language (same lookup
-- as CatalogApi._taxonomyNames), falling back to the slug.
create or replace function public._duel_topic_json(p_subcategory_id uuid)
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select jsonb_build_object(
    'id', s.id,
    'name', coalesce(st.name, s.slug),
    'emoji', s.emoji,
    'plateColor', s.plate_color,
    'categoryId', c.id,
    'categoryName', coalesce(ct.name, c.slug),
    'categoryEmoji', c.emoji
  )
  from public.subcategories s
  join public.categories c on c.id = s.category_id
  left join public.taxonomy_i18n st
    on st.entity_type = 'subcategory' and st.entity_id = s.id and st.locale = c.language_code
  left join public.taxonomy_i18n ct
    on ct.entity_type = 'category' and ct.entity_id = c.id and ct.locale = c.language_code
  where s.id = p_subcategory_id;
$$;

-- The player's current duel id, only if that duel is still pending/active.
create or replace function public._duel_live_duel_id(p_user_id uuid)
returns uuid
language sql stable security definer
set search_path = public
as $$
  select s.current_duel_id
  from public.duel_player_state s
  join public.duels d on d.id = s.current_duel_id and d.status in ('pending', 'active')
  where s.user_id = p_user_id;
$$;

-- ============================================================================
-- Locks
-- ============================================================================

-- Row-locks the player's duel_player_state (creating it on first touch) and
-- self-heals a current_duel_id that points at a duel that is no longer live.
create or replace function public._duel_state_lock(p_user_id uuid)
returns public.duel_player_state
language plpgsql security definer
set search_path = public
as $$
declare
  v_state public.duel_player_state;
begin
  insert into public.duel_player_state (user_id) values (p_user_id)
  on conflict (user_id) do nothing;

  select * into v_state from public.duel_player_state
  where user_id = p_user_id
  for update;

  if v_state.current_duel_id is not null and not exists (
    select 1 from public.duels d
    where d.id = v_state.current_duel_id and d.status in ('pending', 'active')
  ) then
    update public.duel_player_state
      set current_duel_id = null, updated_at = now()
      where user_id = p_user_id
      returning * into v_state;
  end if;

  return v_state;
end;
$$;

-- Both players' state rows, always in ascending user_id order (deadlock-free
-- against any other caller that follows the same rule).
create or replace function public._duel_lock_pair(p_a uuid, p_b uuid)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  perform public._duel_state_lock(least(p_a, p_b));
  if p_a is distinct from p_b then
    perform public._duel_state_lock(greatest(p_a, p_b));
  end if;
end;
$$;

-- ============================================================================
-- Rate limiting (fixed window)
-- ============================================================================

-- Raises p_error once the window holds more than p_max hits. The increment
-- is rolled back together with the raise, so a limited caller stays exactly
-- at the limit until the window resets.
create or replace function public._duel_rate_hit(
  p_user_id uuid, p_bucket text, p_max integer, p_window interval, p_error text
)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_hits integer;
begin
  insert into public.duel_rate_buckets as b (user_id, bucket, window_start, hits)
  values (p_user_id, p_bucket, now(), 1)
  on conflict (user_id, bucket) do update set
    window_start = case when b.window_start < now() - p_window then now() else b.window_start end,
    hits = case when b.window_start < now() - p_window then 1 else b.hits + 1 end
  returning hits into v_hits;

  if v_hits > p_max then
    raise exception '%', p_error;
  end if;
end;
$$;

-- ============================================================================
-- Broadcast senders (private channels; payload always carries serverNow)
-- ============================================================================

create or replace function public._duel_inbox_send(p_user_id uuid, p_event text, p_payload jsonb)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  perform realtime.send(
    p_payload || jsonb_build_object('serverNow', now()),
    p_event,
    'duel-user:' || p_user_id::text,
    true
  );
end;
$$;

create or replace function public._duel_room_send(p_duel_id uuid, p_event text, p_payload jsonb)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  perform realtime.send(
    p_payload || jsonb_build_object('serverNow', now()),
    p_event,
    'duel:' || p_duel_id::text,
    true
  );
end;
$$;

create or replace function public._duel_lobby_send(p_language_code text, p_event text, p_payload jsonb)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  perform realtime.send(
    p_payload || jsonb_build_object('serverNow', now()),
    p_event,
    'duel-lobby:' || p_language_code,
    true
  );
end;
$$;

-- ============================================================================
-- Challenge card + feed broadcast trigger
-- ============================================================================

-- Built from the row alone (no joins): {id, status, creatorPresent,
-- createdAt, expiresAt, creator:{player keys}, topic:{topic keys},
-- opponentName, opponentGuestTag, duelId}.
create or replace function public._duel_challenge_card(p_c public.duel_challenges)
returns jsonb
language sql stable security definer
set search_path = public
as $$
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
      'isBot', false
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
$$;

-- challenge_upsert (card) on insert/state change, challenge_remove ({id}) on
-- delete, to 'duel-lobby:<language_code>'.
create or replace function public._duel_challenges_broadcast()
returns trigger
language plpgsql security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    perform public._duel_lobby_send(
      old.language_code, 'challenge_remove', jsonb_build_object('id', old.id)
    );
    return old;
  end if;

  perform public._duel_lobby_send(
    new.language_code, 'challenge_upsert', public._duel_challenge_card(new)
  );
  return new;
end;
$$;

drop trigger if exists duel_challenges_broadcast_ins_del on public.duel_challenges;
create trigger duel_challenges_broadcast_ins_del
  after insert or delete on public.duel_challenges
  for each row execute function public._duel_challenges_broadcast();

-- Heartbeat-only / snapshot-only updates never broadcast.
drop trigger if exists duel_challenges_broadcast_upd on public.duel_challenges;
create trigger duel_challenges_broadcast_upd
  after update on public.duel_challenges
  for each row
  when (
    old.status is distinct from new.status
    or old.creator_present is distinct from new.creator_present
    or old.duel_id is distinct from new.duel_id
  )
  execute function public._duel_challenges_broadcast();

-- ============================================================================
-- Join-request payloads
-- ============================================================================

create or replace function public._duel_requester_json(p_r public.duel_join_requests)
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select jsonb_build_object(
    'id', p_r.requester_id,
    'name', p_r.requester_name,
    'isGuest', p_r.requester_is_guest,
    'guestTag', p_r.requester_guest_tag,
    'avatar', p_r.requester_avatar,
    'elo', p_r.requester_elo,
    'league', p_r.requester_league,
    'topicLevel', p_r.requester_topic_level,
    'isBot', false
  );
$$;

-- 1-based position among the challenge's queued rows (null unless queued).
create or replace function public._duel_request_position(p_r public.duel_join_requests)
returns integer
language sql stable security definer
set search_path = public
as $$
  select case when p_r.status = 'queued' then
    1 + (
      select count(*)::integer
      from public.duel_join_requests q
      where q.challenge_id = p_r.challenge_id
        and q.status = 'queued'
        and (q.created_at, q.id) < (p_r.created_at, p_r.id)
    )
  end;
$$;

-- Requester-facing status: {requestId, challengeId, status, position,
-- expiresAt, retryAfter, reason}. expiresAt only while pending.
create or replace function public._duel_request_status_payload(
  p_r public.duel_join_requests, p_reason text
)
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select jsonb_build_object(
    'requestId', p_r.id,
    'challengeId', p_r.challenge_id,
    'status', p_r.status,
    'position', public._duel_request_position(p_r),
    'expiresAt', case when p_r.status = 'pending' then p_r.expires_at end,
    'retryAfter', p_r.retry_after,
    'reason', coalesce(p_reason, p_r.reason)
  );
$$;

-- Creator-facing incoming request: {requestId, challengeId, requester,
-- expiresAt, queuedCount}. Same shape as the join_request event and the
-- lobby snapshot's `incoming`.
create or replace function public._duel_incoming_json(p_r public.duel_join_requests)
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select jsonb_build_object(
    'requestId', p_r.id,
    'challengeId', p_r.challenge_id,
    'requester', public._duel_requester_json(p_r),
    'expiresAt', p_r.expires_at,
    'queuedCount', (
      select count(*)::integer from public.duel_join_requests q
      where q.challenge_id = p_r.challenge_id and q.status = 'queued'
    )
  );
$$;

-- ============================================================================
-- Join-request queue transitions
-- ============================================================================

-- queued -> pending (5 s window). Caller holds the challenge row lock.
create or replace function public._duel_present_request(p_request_id uuid)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_r public.duel_join_requests;
begin
  update public.duel_join_requests
    set status = 'pending',
        presented_at = now(),
        expires_at = now() + public._duel_cfg_int('join_window_seconds') * interval '1 second',
        reason = null
    where id = p_request_id and status = 'queued'
    returning * into v_r;

  if not found then
    return;
  end if;

  perform public._duel_inbox_send(v_r.creator_id, 'join_request', public._duel_incoming_json(v_r));
  perform public._duel_inbox_send(
    v_r.requester_id, 'join_request_status', public._duel_request_status_payload(v_r, null)
  );
end;
$$;

-- Terminal transition of a queued/pending request + notifications. Returns
-- false when the row was already terminal (idempotent). Caller holds the
-- challenge row lock.
create or replace function public._duel_resolve_request(
  p_request_id uuid, p_status text, p_reason text, p_set_retry boolean
)
returns boolean
language plpgsql security definer
set search_path = public
as $$
declare
  v_old public.duel_join_requests;
  v_new public.duel_join_requests;
begin
  select * into v_old from public.duel_join_requests where id = p_request_id for update;
  if not found or v_old.status not in ('queued', 'pending') then
    return false;
  end if;

  update public.duel_join_requests
    set status = p_status,
        reason = p_reason,
        resolved_at = now(),
        retry_after = case when p_set_retry
          then now() + public._duel_cfg_int('join_retry_seconds') * interval '1 second'
          else null end
    where id = p_request_id
    returning * into v_new;

  perform public._duel_inbox_send(
    v_new.requester_id, 'join_request_status', public._duel_request_status_payload(v_new, p_reason)
  );

  if v_old.status = 'pending' then
    perform public._duel_inbox_send(
      v_new.creator_id, 'join_request_cleared',
      jsonb_build_object('requestId', v_new.id, 'reason', p_reason)
    );
  end if;

  return true;
end;
$$;

-- Presents the next request when nothing is pending and the challenge is
-- open, unexpired and its creator present. Expires an overdue pending
-- request first, and skips (withdraws) queued requesters who are now in a
-- duel ('in_duel') or have left the arena ('requester_left'). Always ends by
-- re-sending every still-queued requester their current position.
create or replace function public._duel_promote_next_request(p_challenge_id uuid)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_cfg jsonb := public._duel_cfg();
  v_c public.duel_challenges;
  v_pending public.duel_join_requests;
  v_r public.duel_join_requests;
  v_seen timestamptz;
begin
  select * into v_c from public.duel_challenges where id = p_challenge_id for update;
  if not found then
    return;
  end if;

  if v_c.status = 'open' and v_c.creator_present and v_c.expires_at > now() then
    select * into v_pending from public.duel_join_requests
      where challenge_id = p_challenge_id and status = 'pending';
    if found and v_pending.expires_at
         + (v_cfg ->> 'join_grace_ms')::integer * interval '1 millisecond' < now() then
      perform public._duel_resolve_request(v_pending.id, 'expired', 'no_response', true);
    end if;

    if not exists (
      select 1 from public.duel_join_requests
      where challenge_id = p_challenge_id and status = 'pending'
    ) then
      loop
        select * into v_r from public.duel_join_requests
          where challenge_id = p_challenge_id and status = 'queued'
          order by created_at, id
          limit 1
          for update;
        exit when not found;

        select s.lobby_seen_at into v_seen
          from public.duel_player_state s where s.user_id = v_r.requester_id;

        if public._duel_live_duel_id(v_r.requester_id) is not null then
          perform public._duel_resolve_request(v_r.id, 'withdrawn', 'in_duel', false);
        elsif v_seen is null
              or v_seen < now() - (v_cfg ->> 'creator_stale_seconds')::integer * interval '1 second' then
          perform public._duel_resolve_request(v_r.id, 'withdrawn', 'requester_left', false);
        else
          perform public._duel_present_request(v_r.id);
          exit;
        end if;
      end loop;
    end if;
  end if;

  for v_r in
    select * from public.duel_join_requests
    where challenge_id = p_challenge_id and status = 'queued'
    order by created_at, id
  loop
    perform public._duel_inbox_send(
      v_r.requester_id, 'join_request_status', public._duel_request_status_payload(v_r, null)
    );
  end loop;
end;
$$;

-- Withdraws every queued/pending request on a challenge with p_reason
-- ('challenge_gone', 'expired', 'creator_away', 'taken'). No promotion.
create or replace function public._duel_clear_requests_for_challenge(p_challenge_id uuid, p_reason text)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  perform 1 from public.duel_challenges where id = p_challenge_id for update;

  for v_id in
    select id from public.duel_join_requests
    where challenge_id = p_challenge_id and status in ('queued', 'pending')
    order by (status = 'pending') desc, created_at, id
  loop
    perform public._duel_resolve_request(v_id, 'withdrawn', p_reason, false);
  end loop;
end;
$$;

-- Withdraws all of a player's outgoing queued/pending requests, then
-- advances each affected challenge's queue. Challenges are locked in id
-- order, each before its request rows.
create or replace function public._duel_withdraw_user_requests(p_user_id uuid, p_reason text)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_challenge_id uuid;
  v_id uuid;
begin
  for v_challenge_id in
    select distinct challenge_id from public.duel_join_requests
    where requester_id = p_user_id and status in ('queued', 'pending')
    order by challenge_id
  loop
    perform 1 from public.duel_challenges where id = v_challenge_id for update;

    for v_id in
      select id from public.duel_join_requests
      where challenge_id = v_challenge_id
        and requester_id = p_user_id
        and status in ('queued', 'pending')
    loop
      perform public._duel_resolve_request(v_id, 'withdrawn', p_reason, false);
    end loop;

    perform public._duel_promote_next_request(v_challenge_id);
  end loop;
end;
$$;

-- Notify requesters first (the FK cascade would delete their rows silently),
-- then delete; the trigger broadcasts challenge_remove.
create or replace function public._duel_delete_challenge(p_challenge_id uuid, p_reason text)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  perform public._duel_clear_requests_for_challenge(p_challenge_id, p_reason);
  delete from public.duel_challenges where id = p_challenge_id;
end;
$$;

-- ============================================================================
-- Public RPCs
-- ============================================================================

-- Arena snapshot. Also marks the caller as seen on the arena.
create or replace function public.get_duel_lobby(p_language_code text)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
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
  select coalesce(jsonb_agg(public._duel_challenge_card(c) order by c.created_at, c.id), '[]'::jsonb)
    into v_challenges
  from public.duel_challenges c
  where c.id in (
    select f.id from public.duel_challenges f
    where f.language_code = p_language_code
      and (f.status = 'matched' or (f.status = 'open' and f.expires_at > now()))
    order by f.created_at desc
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
    select * into v_pending from public.duel_join_requests
      where challenge_id = v_open.id and status = 'pending';
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
    'myRequests', v_my_requests,
    'incoming', v_incoming
  );
end;
$$;

-- Duel-able topics in one language, with live activity counts.
create or replace function public.list_duel_topics(p_language_code text)
returns jsonb
language plpgsql stable security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_cfg jsonb := public._duel_cfg();
  v_min integer := (v_cfg ->> 'min_topic_questions')::integer;
  v_stale interval := (v_cfg ->> 'mm_stale_seconds')::integer * interval '1 second';
  v_result jsonb;
begin
  with counts as (
    select q.subcategory_id, count(*)::integer as n
    from public.questions q
    where q.status = 'live'
      and q.language_code = p_language_code
      and q.prompt is not null
      and q.options is not null
      and q.correct_index is not null
    group by q.subcategory_id
  ),
  topics as (
    select
      s.id,
      s.sort_order as s_sort,
      c.id as category_id,
      c.sort_order as c_sort,
      counts.n,
      (select count(*)::integer from public.duel_challenges dc
        where dc.subcategory_id = s.id
          and dc.status = 'open'
          and dc.creator_present
          and dc.expires_at > now()) as open_n,
      (select count(*)::integer from public.matchmaking_queue mq
        where mq.subcategory_id = s.id
          and mq.language_code = p_language_code
          and mq.last_seen_at > now() - v_stale) as searching_n
    from public.subcategories s
    join public.categories c on c.id = s.category_id
    join counts on counts.subcategory_id = s.id
    where s.is_active
      and c.is_active
      and c.language_code = p_language_code
      and counts.n >= v_min
  )
  select coalesce(jsonb_agg(
           public._duel_topic_json(t.id) || jsonb_build_object(
             'myTopicLevel', case when v_me is null then 0
                                  else public._duel_topic_level(v_me, t.id) end,
             'openChallenges', t.open_n,
             'searching', t.searching_n,
             'liveQuestionCount', t.n
           )
           order by t.c_sort, t.category_id, (t.open_n + t.searching_n) desc, t.s_sort, t.id
         ), '[]'::jsonb)
    into v_result
  from topics t;

  return v_result;
end;
$$;

create or replace function public.create_duel_challenge(p_subcategory_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_cfg jsonb := public._duel_cfg();
  v_cooldown interval := (v_cfg ->> 'challenge_cooldown_seconds')::integer * interval '1 second';
  v_profile public.profiles;
  v_state public.duel_player_state;
  v_existing public.duel_challenges;
  v_lang text;
  v_topic jsonb;
  v_player jsonb;
  v_c public.duel_challenges;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;
  select * into v_profile from public.profiles where id = v_me;
  if not found then
    raise exception 'not_authenticated';
  end if;
  if v_profile.is_guest then
    raise exception 'guest_cannot_create';
  end if;

  v_state := public._duel_state_lock(v_me);
  if v_state.current_duel_id is not null then
    raise exception 'already_in_duel';
  end if;

  select * into v_existing from public.duel_challenges
    where creator_id = v_me and status = 'open'
    for update;
  if found then
    if v_existing.expires_at > now() then
      raise exception 'challenge_already_open';
    end if;
    -- Expired but not yet swept: clear it so the one-open index allows a new one.
    perform public._duel_delete_challenge(v_existing.id, 'expired');
  end if;

  if v_state.last_challenge_at is not null
     and v_state.last_challenge_at > now() - v_cooldown then
    raise exception 'challenge_cooldown';
  end if;

  perform public._duel_rate_hit(
    v_me, 'challenge_day', (v_cfg ->> 'challenge_daily_cap')::integer,
    interval '24 hours', 'challenge_daily_cap'
  );

  v_lang := public._duel_topic_language(p_subcategory_id);
  if v_lang is null then
    raise exception 'topic_unavailable';
  end if;

  v_topic := public._duel_topic_json(p_subcategory_id);
  v_player := public._duel_player_json(v_me, p_subcategory_id);

  insert into public.duel_challenges (
    creator_id, subcategory_id, category_id, language_code, status, creator_present,
    creator_name, creator_guest_tag, creator_avatar, creator_elo, creator_league,
    creator_topic_level, topic_name, topic_emoji, topic_plate_color,
    category_name, category_emoji, expires_at
  ) values (
    v_me, p_subcategory_id, (v_topic ->> 'categoryId')::uuid, v_lang, 'open', true,
    v_player ->> 'name', v_player ->> 'guestTag', v_player ->> 'avatar',
    (v_player ->> 'elo')::integer, v_player ->> 'league',
    (v_player ->> 'topicLevel')::smallint, v_topic ->> 'name', v_topic ->> 'emoji',
    v_topic ->> 'plateColor', v_topic ->> 'categoryName', v_topic ->> 'categoryEmoji',
    now() + (v_cfg ->> 'challenge_ttl_seconds')::integer * interval '1 second'
  )
  returning * into v_c;

  -- Written in the same transaction as the insert, so a double-tap can't
  -- create two.
  update public.duel_player_state
    set last_challenge_at = now(), lobby_seen_at = now(), updated_at = now()
    where user_id = v_me;

  return jsonb_build_object(
    'challenge', public._duel_challenge_card(v_c),
    'cooldownEndsAt', now() + v_cooldown,
    'serverNow', now()
  );
end;
$$;

-- Creator only, open only. The cool-off is deliberately NOT reset.
create or replace function public.cancel_duel_challenge(p_challenge_id uuid)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_c public.duel_challenges;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_c from public.duel_challenges
    where id = p_challenge_id and creator_id = v_me
    for update;
  if not found or v_c.status <> 'open' then
    raise exception 'challenge_not_found';
  end if;

  perform public._duel_delete_challenge(p_challenge_id, 'challenge_gone');
end;
$$;

-- Arena heartbeat / visibility. Present: refresh lobby_seen_at, flip an Away
-- challenge back to Live and advance its queue. Away: pause the challenge
-- (clearing its queue) and withdraw the caller's own outgoing requests.
-- Throttled: a present-heartbeat within 2 s of the last one is a no-op
-- unless it has an Away challenge to flip back.
create or replace function public.set_duel_lobby_presence(p_present boolean)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_present boolean := coalesce(p_present, false);
  v_state public.duel_player_state;
  v_c public.duel_challenges;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  if v_present then
    select * into v_state from public.duel_player_state where user_id = v_me;
    if found
       and v_state.lobby_seen_at > now() - interval '2 seconds'
       and not exists (
         select 1 from public.duel_challenges
         where creator_id = v_me and status = 'open' and not creator_present
       ) then
      return jsonb_build_object('serverNow', now());
    end if;

    insert into public.duel_player_state (user_id, lobby_seen_at) values (v_me, now())
    on conflict (user_id) do update set lobby_seen_at = now(), updated_at = now();
  end if;

  select * into v_c from public.duel_challenges
    where creator_id = v_me and status = 'open'
    for update;
  if found then
    if v_c.creator_present is distinct from v_present then
      update public.duel_challenges set creator_present = v_present where id = v_c.id;
    end if;
    if v_present then
      perform public._duel_promote_next_request(v_c.id);
    else
      perform public._duel_clear_requests_for_challenge(v_c.id, 'creator_away');
    end if;
  end if;

  if not v_present then
    -- A player off the arena can't be dropped into a duel.
    perform public._duel_withdraw_user_requests(v_me, 'requester_left');
  end if;

  return jsonb_build_object('serverNow', now());
end;
$$;

create or replace function public.request_duel_join(p_challenge_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
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

  select * into v_c from public.duel_challenges where id = p_challenge_id;
  if not found or v_c.status <> 'open' or v_c.expires_at <= now() then
    raise exception 'challenge_unavailable';
  end if;
  if v_c.creator_id = v_me then
    raise exception 'own_challenge';
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
$$;

-- Requester only; a no-op when the request is already terminal.
create or replace function public.withdraw_duel_join(p_request_id uuid)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_r public.duel_join_requests;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_r from public.duel_join_requests
    where id = p_request_id and requester_id = v_me;
  if not found then
    raise exception 'request_not_found';
  end if;
  if v_r.status not in ('queued', 'pending') then
    return;
  end if;

  perform 1 from public.duel_challenges where id = v_r.challenge_id for update;
  if public._duel_resolve_request(p_request_id, 'withdrawn', 'withdrawn', false) then
    perform public._duel_promote_next_request(v_r.challenge_id);
  end if;
end;
$$;

-- Creator answers the pending request. Returns {accepted, duelId, serverNow}.
create or replace function public.respond_duel_join(p_request_id uuid, p_accept boolean)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
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
$$;

-- ============================================================================
-- Privileges
-- ============================================================================

revoke execute on function public._duel_cfg() from public, anon, authenticated;
revoke execute on function public._duel_cfg_int(text) from public, anon, authenticated;
revoke execute on function public._duel_guest_tag(uuid) from public, anon, authenticated;
revoke execute on function public._duel_topic_level(uuid, uuid) from public, anon, authenticated;
revoke execute on function public._duel_topic_question_count(uuid, text) from public, anon, authenticated;
revoke execute on function public._duel_topic_language(uuid) from public, anon, authenticated;
revoke execute on function public._duel_player_json(uuid, uuid) from public, anon, authenticated;
revoke execute on function public._duel_topic_json(uuid) from public, anon, authenticated;
revoke execute on function public._duel_live_duel_id(uuid) from public, anon, authenticated;
revoke execute on function public._duel_state_lock(uuid) from public, anon, authenticated;
revoke execute on function public._duel_lock_pair(uuid, uuid) from public, anon, authenticated;
revoke execute on function public._duel_rate_hit(uuid, text, integer, interval, text) from public, anon, authenticated;
revoke execute on function public._duel_inbox_send(uuid, text, jsonb) from public, anon, authenticated;
revoke execute on function public._duel_room_send(uuid, text, jsonb) from public, anon, authenticated;
revoke execute on function public._duel_lobby_send(text, text, jsonb) from public, anon, authenticated;
revoke execute on function public._duel_challenge_card(public.duel_challenges) from public, anon, authenticated;
revoke execute on function public._duel_challenges_broadcast() from public, anon, authenticated;
revoke execute on function public._duel_requester_json(public.duel_join_requests) from public, anon, authenticated;
revoke execute on function public._duel_request_position(public.duel_join_requests) from public, anon, authenticated;
revoke execute on function public._duel_request_status_payload(public.duel_join_requests, text) from public, anon, authenticated;
revoke execute on function public._duel_incoming_json(public.duel_join_requests) from public, anon, authenticated;
revoke execute on function public._duel_present_request(uuid) from public, anon, authenticated;
revoke execute on function public._duel_resolve_request(uuid, text, text, boolean) from public, anon, authenticated;
revoke execute on function public._duel_promote_next_request(uuid) from public, anon, authenticated;
revoke execute on function public._duel_clear_requests_for_challenge(uuid, text) from public, anon, authenticated;
revoke execute on function public._duel_withdraw_user_requests(uuid, text) from public, anon, authenticated;
revoke execute on function public._duel_delete_challenge(uuid, text) from public, anon, authenticated;

revoke execute on function public.get_duel_lobby(text) from public, anon;
revoke execute on function public.list_duel_topics(text) from public, anon;
revoke execute on function public.create_duel_challenge(uuid) from public, anon;
revoke execute on function public.cancel_duel_challenge(uuid) from public, anon;
revoke execute on function public.set_duel_lobby_presence(boolean) from public, anon;
revoke execute on function public.request_duel_join(uuid) from public, anon;
revoke execute on function public.withdraw_duel_join(uuid) from public, anon;
revoke execute on function public.respond_duel_join(uuid, boolean) from public, anon;

grant execute on function public.get_duel_lobby(text) to authenticated;
grant execute on function public.list_duel_topics(text) to authenticated;
grant execute on function public.create_duel_challenge(uuid) to authenticated;
grant execute on function public.cancel_duel_challenge(uuid) to authenticated;
grant execute on function public.set_duel_lobby_presence(boolean) to authenticated;
grant execute on function public.request_duel_join(uuid) to authenticated;
grant execute on function public.withdraw_duel_join(uuid) to authenticated;
grant execute on function public.respond_duel_join(uuid, boolean) to authenticated;

commit;
