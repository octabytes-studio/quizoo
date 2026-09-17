-- Storage bucket for pre-generated question narration clips, per plan 011.
--
-- question-audio: public read, referenced by questions.audio_url; mirrors
-- question-media's own policy shape (20260907130000_storage_buckets.sql) —
-- no authenticated-upload policy, since files are uploaded out-of-band via
-- the service-role key by the user's separate audio-generation skill, the
-- same way question-media's own images are populated today.
insert into storage.buckets (id, name, public)
values ('question-audio', 'question-audio', true)
on conflict (id) do nothing;

drop policy if exists "question-audio public read" on storage.objects;
create policy "question-audio public read"
  on storage.objects for select
  using (bucket_id = 'question-audio');
