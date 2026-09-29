-- ============================================================================
-- 20260928190557_duel_challenge_history_retention.sql
--
-- Previously every duel_challenges row was hard-deleted the instant it went
-- terminal (cancelled, expired, matched-and-ended, or swept as an orphan) --
-- see 20260927120000's table comment ("deleted, not archived"). This keeps a
-- snapshot for 7 days instead of discarding it immediately, without touching
-- the live arena feed at all:
--
--   * New duel_challenge_history table -- a copy of the row at the moment
--     it's deleted from duel_challenges, plus the deletion reason. RPC-only
--     (RLS on, no policies); nothing reads it back today, this is
--     retention/audit only.
--   * _duel_delete_challenge -- the single choke point every deletion path
--     already goes through (cancel_duel_challenge, create_duel_challenge's
--     stale-open cleanup, _duel_finish, and sweeper steps 3/4) -- now
--     archives the row before deleting it. The live table, its indexes,
--     RLS, and the insert/delete/update broadcast trigger are completely
--     unchanged: the feed still only ever shows what is live.
--   * _duel_sweeper gets a new step 12: purge history rows whose ended_at
--     is older than 7 days.
-- ============================================================================

begin;

create table public.duel_challenge_history (
  id uuid primary key,
  creator_id uuid references public.profiles (id) on delete cascade,
  subcategory_id uuid references public.subcategories (id) on delete set null,
  category_id uuid references public.categories (id) on delete set null,
  language_code text references public.languages (code),
  status text not null,
  creator_name text,
  creator_guest_tag text,
  creator_avatar text,
  creator_elo integer,
  creator_league text,
  creator_topic_level smallint,
  topic_name text,
  topic_emoji text,
  topic_plate_color text,
  category_name text,
  category_emoji text,
  duel_id uuid references public.duels (id) on delete set null,
  opponent_name text,
  opponent_guest_tag text,
  created_at timestamptz not null,
  expires_at timestamptz,
  end_reason text not null,
  ended_at timestamptz not null default now()
);

comment on table public.duel_challenge_history is
  'Snapshot of a duel_challenges row taken at the moment _duel_delete_challenge '
  'removes it (cancelled, expired, matched-and-ended, or swept as an orphan). '
  'Retained for 7 days (purged by _duel_sweeper step 12), then gone for good. '
  'RPC-only, no client read path today -- audit/retention only.';

create index duel_challenge_history_ended_idx
  on public.duel_challenge_history (ended_at);
create index duel_challenge_history_creator_idx
  on public.duel_challenge_history (creator_id, ended_at desc);

alter table public.duel_challenge_history enable row level security;

revoke all on public.duel_challenge_history from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- _duel_delete_challenge: now archives before it deletes. Same signature,
-- same callers, same broadcast (the live table's insert/delete trigger is
-- untouched) -- only the row's fate after removal changes.
-- ---------------------------------------------------------------------------
create or replace function public._duel_delete_challenge(p_challenge_id uuid, p_reason text)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_c public.duel_challenges;
begin
  perform public._duel_clear_requests_for_challenge(p_challenge_id, p_reason);

  delete from public.duel_challenges where id = p_challenge_id returning * into v_c;
  if not found then
    return;
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
    v_c.created_at, v_c.expires_at, p_reason
  );
end;
$$;

revoke execute on function public._duel_delete_challenge(uuid, text) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- _duel_sweeper: steps 1-11 unchanged (copied verbatim from
-- 20260927120500_duel_sweeper_cron.sql), plus new step 12 purging history
-- rows past their 7-day retention window.
-- ---------------------------------------------------------------------------
create or replace function public._duel_sweeper()
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_cfg jsonb := public._duel_cfg();
  v_grace interval := (v_cfg ->> 'join_grace_ms')::integer * interval '1 millisecond';
  v_creator_stale interval := (v_cfg ->> 'creator_stale_seconds')::integer * interval '1 second';
  v_mm_stale interval := (v_cfg ->> 'mm_stale_seconds')::integer * interval '1 second';
  v_ready_timeout interval := (v_cfg ->> 'ready_timeout_seconds')::integer * interval '1 second';
  v_disconnect interval := (v_cfg ->> 'disconnect_forfeit_seconds')::integer * interval '1 second';
  v_row record;
begin
  if not pg_try_advisory_xact_lock(hashtextextended('duel-sweeper', 0)) then
    return;
  end if;

  -- 1. Pending requests past expires_at + grace -> expired (retry cool-down),
  --    then present the next queued request.
  begin
    for v_row in
      select r.id, r.challenge_id
      from public.duel_join_requests r
      where r.status = 'pending' and r.expires_at < now() - v_grace
    loop
      begin
        perform 1 from public.duel_challenges where id = v_row.challenge_id for update;
        if public._duel_resolve_request(v_row.id, 'expired', 'no_response', true) then
          perform public._duel_promote_next_request(v_row.challenge_id);
        end if;
      exception when others then
        raise warning '_duel_sweeper step 1 (request %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 1: %', sqlerrm;
  end;

  -- 2. Stale creators: open, "present" challenges whose creator stopped
  --    heartbeating -> Away (trigger broadcasts) + clear their queue.
  begin
    for v_row in
      select c.id
      from public.duel_challenges c
      left join public.duel_player_state s on s.user_id = c.creator_id
      where c.status = 'open'
        and c.creator_present
        and (s.lobby_seen_at is null or s.lobby_seen_at < now() - v_creator_stale)
    loop
      begin
        update public.duel_challenges
          set creator_present = false
          where id = v_row.id and status = 'open' and creator_present;
        if found then
          perform public._duel_clear_requests_for_challenge(v_row.id, 'creator_away');
        end if;
      exception when others then
        raise warning '_duel_sweeper step 2 (challenge %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 2: %', sqlerrm;
  end;

  -- 3. Expired open challenges -> delete (requesters notified first).
  begin
    for v_row in
      select c.id from public.duel_challenges c
      where c.status = 'open' and c.expires_at < now()
    loop
      begin
        perform public._duel_delete_challenge(v_row.id, 'expired');
      exception when others then
        raise warning '_duel_sweeper step 3 (challenge %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 3: %', sqlerrm;
  end;

  -- 4. Orphaned "In progress" cards: the duel is gone / no longer live, or
  --    the card is implausibly old (5 min TTL + 15 min duel expiry < 30 min).
  begin
    for v_row in
      select c.id
      from public.duel_challenges c
      left join public.duels d on d.id = c.duel_id
      where c.status = 'matched'
        and (d.id is null
             or d.status not in ('pending', 'active')
             or c.created_at < now() - interval '30 minutes')
    loop
      begin
        perform public._duel_delete_challenge(v_row.id, 'challenge_gone');
      exception when others then
        raise warning '_duel_sweeper step 4 (challenge %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 4: %', sqlerrm;
  end;

  -- 5. Stale matchmaking rows (the searcher stopped heartbeating).
  begin
    delete from public.matchmaking_queue where last_seen_at < now() - v_mm_stale;
  exception when others then
    raise warning '_duel_sweeper step 5: %', sqlerrm;
  end;

  -- 6. No-shows: still pending (not both ready) after ready_timeout.
  begin
    for v_row in
      select d.id from public.duels d
      where d.status = 'pending' and d.created_at < now() - v_ready_timeout
    loop
      begin
        perform public._duel_abandon(v_row.id, 'no_show');
      exception when others then
        raise warning '_duel_sweeper step 6 (duel %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 6: %', sqlerrm;
  end;

  -- 7. Stuck rounds: current round past its deadline (+2 s) and unresolved
  --    (both clients vanished before claiming the timeout).
  begin
    for v_row in
      select d.id, d.current_round
      from public.duels d
      join public.duel_rounds r on r.duel_id = d.id and r.round = d.current_round
      where d.status = 'active'
        and r.resolved_at is null
        and r.deadline < now() - interval '2 seconds'
    loop
      begin
        perform public._duel_resolve_round(v_row.id, v_row.current_round);
      exception when others then
        raise warning '_duel_sweeper step 7 (duel %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 7: %', sqlerrm;
  end;

  -- 8. Disconnects: one side silent > disconnect_forfeit_seconds -> forfeit
  --    (remaining rounds to the present player); both silent -> abandon.
  begin
    for v_row in
      select d.id, d.p1, d.p2,
             (d.p1_seen_at is null or d.p1_seen_at < now() - v_disconnect) as p1_gone,
             (d.p2_seen_at is null or d.p2_seen_at < now() - v_disconnect) as p2_gone
      from public.duels d
      where d.status = 'active'
        and (d.p1_seen_at is null or d.p1_seen_at < now() - v_disconnect
             or d.p2_seen_at is null or d.p2_seen_at < now() - v_disconnect)
    loop
      begin
        if v_row.p1_gone and v_row.p2_gone then
          perform public._duel_abandon(v_row.id, 'both_disconnected');
        elsif v_row.p1_gone then
          perform public._duel_finish(v_row.id, 'forfeit', v_row.p1);
        else
          perform public._duel_finish(v_row.id, 'forfeit', v_row.p2);
        end if;
      exception when others then
        raise warning '_duel_sweeper step 8 (duel %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 8: %', sqlerrm;
  end;

  -- 9. Hard expiry: any live duel past duels.expires_at (15 min) -> abandon.
  begin
    for v_row in
      select d.id from public.duels d
      where d.status in ('pending', 'active') and d.expires_at < now()
    loop
      begin
        perform public._duel_abandon(v_row.id, 'expired');
      exception when others then
        raise warning '_duel_sweeper step 9 (duel %): %', v_row.id, sqlerrm;
      end;
    end loop;
  exception when others then
    raise warning '_duel_sweeper step 9: %', sqlerrm;
  end;

  -- 10. Housekeeping: terminal join requests older than 10 min whose retry
  --     cool-down has passed; rate buckets whose (<= 24 h) window ended more
  --     than 24 h ago.
  begin
    delete from public.duel_join_requests
      where status not in ('queued', 'pending')
        and resolved_at < now() - interval '10 minutes'
        and (retry_after is null or retry_after < now());
    delete from public.duel_rate_buckets
      where window_start < now() - interval '48 hours';
  exception when others then
    raise warning '_duel_sweeper step 10: %', sqlerrm;
  end;

  -- 11. This job's own run history (8,640 rows/day) older than a day
  --     (plan's Risks section). Only this job's rows are touched.
  begin
    delete from cron.job_run_details
      where jobid in (select jobid from cron.job where jobname = 'duel-sweeper')
        and end_time < now() - interval '1 day';
  exception when others then
    raise warning '_duel_sweeper step 11: %', sqlerrm;
  end;

  -- 12. Challenge history retention: purge rows past their 7-day window.
  begin
    delete from public.duel_challenge_history where ended_at < now() - interval '7 days';
  exception when others then
    raise warning '_duel_sweeper step 12: %', sqlerrm;
  end;
end;
$$;

revoke execute on function public._duel_sweeper() from public, anon, authenticated;

commit;
