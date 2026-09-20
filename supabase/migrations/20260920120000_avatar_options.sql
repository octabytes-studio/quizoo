-- ============================================================================
-- 20260920120000_avatar_options.sql
--
-- Plan 015: S-25's avatar picker moves from a hardcoded 8-emoji Dart list
-- (`MockPlayer.avatarChoices`) to a backend-driven catalog, matching how
-- `languages` already drives S-03's picker. `profiles.avatar_key` itself is
-- untouched — this only changes where the *offered choices* come from.
-- ============================================================================

begin;

create table public.avatar_options (
  id uuid primary key default gen_random_uuid(),
  emoji text not null unique,
  sort_order integer not null,
  is_active boolean not null default true
);

alter table public.avatar_options enable row level security;
create policy avatar_options_select_all
  on public.avatar_options for select using (true);

insert into public.avatar_options (emoji, sort_order) values
  ('🐼', 1),
  ('🦊', 2),
  ('🐯', 3),
  ('🦉', 4),
  ('🐨', 5),
  ('🐸', 6),
  ('🦁', 7),
  ('🐵', 8)
on conflict (emoji) do nothing;

commit;
