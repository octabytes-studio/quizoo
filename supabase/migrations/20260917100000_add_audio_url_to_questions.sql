begin;

alter table public.questions
  add column if not exists audio_url text;

commit;
