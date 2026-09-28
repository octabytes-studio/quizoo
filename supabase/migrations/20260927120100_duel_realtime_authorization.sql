-- ============================================================================
-- 20260927120100_duel_realtime_authorization.sql
--
-- Plan 017, Phase 2: who may join which private Realtime channel.
--
-- Transport choice (deliberate): duels use Realtime BROADCAST sent from the
-- database (realtime.send, from RPCs / triggers / the sweeper), NOT Postgres
-- Changes. No table is added to the `supabase_realtime` publication by this
-- plan. Postgres Changes re-evaluates RLS per subscriber per changed row,
-- which is exactly the "overloaded backend" failure mode the spec worries
-- about; database-originated broadcast is one insert per event and fan-out
-- is Realtime's job.
--
-- Clients never publish broadcasts: the policies below let a client RECEIVE
-- broadcasts on the channels it is entitled to and TRACK PRESENCE (the arena
-- head count, the duel room's "opponent reconnecting" chip) -- there is no
-- insert policy for extension = 'broadcast', so an event can't be forged.
--
-- Topics (note the distinct prefixes):
--   duel-lobby:<lang>   the arena feed for one content language
--   duel-user:<uid>     a player's private inbox
--   duel:<duelId>       one live duel room (participants only)
-- split_part(topic, ':', 1) = 'duel' matches only the room, never
-- 'duel-lobby' or 'duel-user'.
--
-- realtime.messages already has RLS enabled (verified in Phase 0:
-- relrowsecurity = true) and had no policies before this migration.
-- ============================================================================

begin;

-- Arena feed: any signed-in (incl. anonymous guest) user may receive, and may
-- track presence, but may never publish a broadcast.
drop policy if exists duel_lobby_receive on realtime.messages;
create policy duel_lobby_receive on realtime.messages
  for select to authenticated
  using (
    realtime.topic() like 'duel-lobby:%'
    and realtime.messages.extension in ('broadcast', 'presence')
  );

drop policy if exists duel_lobby_presence on realtime.messages;
create policy duel_lobby_presence on realtime.messages
  for insert to authenticated
  with check (
    realtime.topic() like 'duel-lobby:%'
    and realtime.messages.extension = 'presence'
  );

-- Personal inbox: only its owner, receive only.
drop policy if exists duel_inbox_receive on realtime.messages;
create policy duel_inbox_receive on realtime.messages
  for select to authenticated
  using (
    realtime.topic() = 'duel-user:' || (select auth.uid())::text
    and realtime.messages.extension = 'broadcast'
  );

-- Duel room: only the two participants (receive + presence).
drop policy if exists duel_room_receive on realtime.messages;
create policy duel_room_receive on realtime.messages
  for select to authenticated
  using (
    split_part(realtime.topic(), ':', 1) = 'duel'
    and realtime.messages.extension in ('broadcast', 'presence')
    and exists (
      select 1 from public.duels d
      where d.id::text = split_part(realtime.topic(), ':', 2)
        and (select auth.uid()) in (d.p1, d.p2)
    )
  );

drop policy if exists duel_room_presence on realtime.messages;
create policy duel_room_presence on realtime.messages
  for insert to authenticated
  with check (
    split_part(realtime.topic(), ':', 1) = 'duel'
    and realtime.messages.extension = 'presence'
    and exists (
      select 1 from public.duels d
      where d.id::text = split_part(realtime.topic(), ':', 2)
        and (select auth.uid()) in (d.p1, d.p2)
    )
  );

commit;
