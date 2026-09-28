-- ============================================================================
-- 20260927120300_duel_matchmaking_functions.sql
--
-- Plan 017, Phase 4: Quick match. A queue per (sub-category, language),
-- pairing on ELO with a band that widens the longer a player waits (the
-- longer-waiting player's tolerance counts), topic level as a secondary
-- weight, heartbeat-based liveness, and a labelled-bot offer at 30 s.
--
-- There is no scheduler for pairing: every join and every heartbeat (3 s)
-- re-runs _duel_try_pair with the caller's current band, which is what makes
-- the band widen over time. Pairing within one topic is serialised with a
-- non-blocking transaction advisory lock; a caller that can't take it just
-- skips this tick.
--
-- Lock order: the caller's duel_player_state row is locked BEFORE its
-- matchmaking_queue row is written (join and heartbeat alike), and the
-- candidate's state row is taken with SKIP LOCKED, so pairing never waits on
-- another transaction's player lock (see 20260927120200's header).
-- ============================================================================

begin;

-- Band = min(band_max, band_start + band_step * floor(waited / band_step_seconds)).
create or replace function public._duel_mm_band(p_queued_at timestamptz)
returns integer
language plpgsql stable security definer
set search_path = public
as $$
declare
  v_cfg jsonb := public._duel_cfg();
begin
  return least(
    (v_cfg ->> 'mm_band_max')::integer,
    (v_cfg ->> 'mm_band_start')::integer
      + (v_cfg ->> 'mm_band_step')::integer
        * floor(
            greatest(0, extract(epoch from (now() - p_queued_at)))
            / (v_cfg ->> 'mm_band_step_seconds')::integer
          )::integer
  );
end;
$$;

-- matched: {status:'matched', duelId, serverNow}
-- queued:  {status:'queued', duelId:null, queuedAt, band:{min,max}, elo,
--           botAvailable, botAvailableAt, me, topic, serverNow}
-- neither: raises not_in_queue.
create or replace function public._duel_mm_ticket(p_user_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_live uuid := public._duel_live_duel_id(p_user_id);
  v_q public.matchmaking_queue;
  v_band integer;
  v_bot_at timestamptz;
begin
  if v_live is not null then
    return jsonb_build_object('status', 'matched', 'duelId', v_live, 'serverNow', now());
  end if;

  select * into v_q from public.matchmaking_queue where user_id = p_user_id;
  if not found then
    raise exception 'not_in_queue';
  end if;

  v_band := public._duel_mm_band(v_q.queued_at);
  v_bot_at := v_q.queued_at + public._duel_cfg_int('mm_bot_after_seconds') * interval '1 second';

  return jsonb_build_object(
    'status', 'queued',
    'duelId', null,
    'queuedAt', v_q.queued_at,
    'band', jsonb_build_object('min', v_q.elo - v_band, 'max', v_q.elo + v_band),
    'elo', v_q.elo,
    'botAvailable', now() >= v_bot_at,
    'botAvailableAt', v_bot_at,
    'me', public._duel_player_json(p_user_id, v_q.subcategory_id),
    'topic', public._duel_topic_json(v_q.subcategory_id),
    'serverNow', now()
  );
end;
$$;

-- Tries to pair the caller with the best eligible waiting player in the same
-- topic. Returns the new duel id, or null (no candidate / lock busy).
create or replace function public._duel_try_pair(p_user_id uuid)
returns uuid
language plpgsql security definer
set search_path = public
as $$
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
  -- avoid re-reading the config per row.
  select q.user_id, q.queued_at into v_other, v_other_queued_at
  from public.matchmaking_queue q
  join public.duel_player_state s on s.user_id = q.user_id
  where q.subcategory_id = v_me.subcategory_id
    and q.language_code = v_me.language_code
    and q.user_id <> p_user_id
    and q.last_seen_at > now() - v_stale
    and s.current_duel_id is null
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
$$;

create or replace function public.join_matchmaking(p_subcategory_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_cfg jsonb := public._duel_cfg();
  v_stale interval := (v_cfg ->> 'mm_stale_seconds')::integer * interval '1 second';
  v_state public.duel_player_state;
  v_lang text;
  v_elo integer;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  v_state := public._duel_state_lock(v_me);
  if v_state.current_duel_id is not null then
    raise exception 'already_in_duel';
  end if;

  v_lang := public._duel_topic_language(p_subcategory_id);
  if v_lang is null then
    raise exception 'topic_unavailable';
  end if;

  perform public._duel_rate_hit(
    v_me, 'mm_join', (v_cfg ->> 'mm_join_rate_max')::integer,
    (v_cfg ->> 'mm_join_rate_window_seconds')::integer * interval '1 second', 'rate_limited'
  );

  -- A searching player can't also be waiting on a challenge.
  perform public._duel_withdraw_user_requests(v_me, 'requester_left');

  select elo into v_elo from public.profiles where id = v_me;

  -- A re-join keeps its place (and its widened band) unless the topic
  -- changed or the old row had already gone stale.
  insert into public.matchmaking_queue as mq (
    user_id, elo, queued_at, subcategory_id, language_code, topic_level, last_seen_at
  ) values (
    v_me, v_elo, now(), p_subcategory_id, v_lang,
    public._duel_topic_level(v_me, p_subcategory_id), now()
  )
  on conflict (user_id) do update set
    elo = excluded.elo,
    topic_level = excluded.topic_level,
    queued_at = case
      when mq.subcategory_id is distinct from excluded.subcategory_id
        or mq.language_code is distinct from excluded.language_code
        or mq.last_seen_at < now() - v_stale
      then now()
      else mq.queued_at
    end,
    subcategory_id = excluded.subcategory_id,
    language_code = excluded.language_code,
    last_seen_at = now();

  perform public._duel_try_pair(v_me);

  return public._duel_mm_ticket(v_me);
end;
$$;

-- Every 3 s from the matchmaking screen: refreshes liveness and retries
-- pairing with the (now wider) band. Throttled: within 1 s of the last beat
-- it returns the ticket without pairing work.
create or replace function public.matchmaking_heartbeat()
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_q public.matchmaking_queue;
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;

  if public._duel_live_duel_id(v_me) is not null then
    return public._duel_mm_ticket(v_me);
  end if;

  select * into v_q from public.matchmaking_queue where user_id = v_me;
  if not found then
    raise exception 'not_in_queue';
  end if;

  if v_q.last_seen_at > now() - interval '1 second' then
    return public._duel_mm_ticket(v_me);
  end if;

  -- Player lock before the queue-row write (lock order, see header).
  perform public._duel_state_lock(v_me);
  if public._duel_live_duel_id(v_me) is not null then
    return public._duel_mm_ticket(v_me);
  end if;

  update public.matchmaking_queue set last_seen_at = now() where user_id = v_me;
  if not found then
    raise exception 'not_in_queue';
  end if;

  perform public._duel_try_pair(v_me);

  return public._duel_mm_ticket(v_me);
end;
$$;

-- No-op when not queued.
create or replace function public.leave_matchmaking()
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then
    raise exception 'not_authenticated';
  end if;
  delete from public.matchmaking_queue where user_id = v_me;
end;
$$;

revoke execute on function public._duel_mm_band(timestamptz) from public, anon, authenticated;
revoke execute on function public._duel_mm_ticket(uuid) from public, anon, authenticated;
revoke execute on function public._duel_try_pair(uuid) from public, anon, authenticated;

revoke execute on function public.join_matchmaking(uuid) from public, anon;
revoke execute on function public.matchmaking_heartbeat() from public, anon;
revoke execute on function public.leave_matchmaking() from public, anon;

grant execute on function public.join_matchmaking(uuid) to authenticated;
grant execute on function public.matchmaking_heartbeat() to authenticated;
grant execute on function public.leave_matchmaking() to authenticated;

commit;
