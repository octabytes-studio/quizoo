-- ============================================================================
-- 20260928200659_duel_challenge_history_in_lobby_feed.sql
--
-- Surfaces the 7-day challenge history (20260928190557) in the arena feed
-- instead of it being audit-only:
--
--   * _duel_delete_challenge now archives with a specific end_reason instead
--     of reusing the join-request-facing p_reason verbatim (that string
--     ('challenge_gone') is shared with _duel_clear_requests_for_challenge's
--     requester notifications and must not change, or requesters stop
--     getting their "Challenge gone" notice). The archived reason is derived
--     from data already on the row: 'expired' (p_reason = 'expired'),
--     else 'cancelled' (was still open, no duel ever formed), else the
--     linked duel's own end_reason ('completed'/'forfeit' -> 'completed',
--     'abandoned' -> 'abandoned').
--   * New _duel_challenge_history_card: the same card shape as
--     _duel_challenge_card, plus endReason/endedAt, status always 'ended'.
--   * get_duel_lobby returns a new `recentlyEnded` array (same
--     lobby_feed_limit cap, newest-ended-first) alongside `challenges`.
-- ============================================================================

begin;

create or replace function public._duel_delete_challenge(p_challenge_id uuid, p_reason text)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_c public.duel_challenges;
  v_duel_end_reason text;
  v_end_reason text;
begin
  perform public._duel_clear_requests_for_challenge(p_challenge_id, p_reason);

  delete from public.duel_challenges where id = p_challenge_id returning * into v_c;
  if not found then
    return;
  end if;

  if p_reason = 'expired' then
    v_end_reason := 'expired';
  elsif v_c.duel_id is not null then
    select case d.end_reason
             when 'abandoned' then 'abandoned'
             else 'completed'
           end
      into v_duel_end_reason
      from public.duels d where d.id = v_c.duel_id;
    v_end_reason := coalesce(v_duel_end_reason, 'completed');
  else
    v_end_reason := 'cancelled';
  end if;

  insert into public.duel_challenge_history (
    id, creator_id, subcategory_id, category_id, language_code, status,
    creator_name, creator_guest_tag, creator_avatar, creator_elo, creator_league,
    creator_topic_level, topic_name, topic_emoji, topic_plate_color,
    category_name, category_emoji, duel_id, opponent_name, opponent_guest_tag,
    created_at, expires_at, end_reason
  ) values (
    v_c.id, v_c.creator_id, v_c.subcategory_id, v_c.category_id, v_c.language_code, v_c.status,
    v_c.creator_name, v_c.creator_guest_tag, v_c.creator_avatar, v_c.creator_elo, v_c.creator_league,
    v_c.creator_topic_level, v_c.topic_name, v_c.topic_emoji, v_c.topic_plate_color,
    v_c.category_name, v_c.category_emoji, v_c.duel_id, v_c.opponent_name, v_c.opponent_guest_tag,
    v_c.created_at, v_c.expires_at, v_end_reason
  );
end;
$$;

revoke execute on function public._duel_delete_challenge(uuid, text) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Card builder for a history row: same shape as _duel_challenge_card, plus
-- endReason/endedAt, status always 'ended'.
-- ---------------------------------------------------------------------------
create or replace function public._duel_challenge_history_card(p_h public.duel_challenge_history)
returns jsonb
language sql stable security definer
set search_path = public
as $$
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
      'isBot', false
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
$$;

revoke execute on function public._duel_challenge_history_card(public.duel_challenge_history) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- get_duel_lobby: unchanged apart from the new `recentlyEnded` array (same
-- shape/cap as `challenges`, sourced from duel_challenge_history).
-- ---------------------------------------------------------------------------
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
    'recentlyEnded', v_recently_ended,
    'myRequests', v_my_requests,
    'incoming', v_incoming
  );
end;
$$;

revoke execute on function public.get_duel_lobby(text) from public, anon, authenticated;
grant execute on function public.get_duel_lobby(text) to authenticated;

commit;
