begin;

alter table public.questions
  add column if not exists voice_id text;

comment on column public.questions.voice_id is
  'ElevenLabs voice id that produced this row''s audio_url, written by the generate-audios skill. NULL until narration is generated; provenance only, never read by the app.';

commit;
