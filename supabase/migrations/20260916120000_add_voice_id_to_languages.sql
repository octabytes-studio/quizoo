begin;

alter table public.languages
  add column if not exists voice_id text;

commit;
