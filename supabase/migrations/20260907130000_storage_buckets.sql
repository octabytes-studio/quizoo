-- Storage buckets per docs/backend/01-supabase-project-setup.md §5.
--
-- question-media: public read, referenced by questions.media_url; shown
-- before sign-in, so no auth required to view.
-- avatars: public read, authenticated write, for a future custom-avatar
-- upload (not in v1's scope, cheap to create now so the bucket name is
-- settled per doc 01 §5's own note).
insert into storage.buckets (id, name, public)
values
  ('question-media', 'question-media', true),
  ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "question-media public read" on storage.objects;
create policy "question-media public read"
  on storage.objects for select
  using (bucket_id = 'question-media');

drop policy if exists "avatars public read" on storage.objects;
create policy "avatars public read"
  on storage.objects for select
  using (bucket_id = 'avatars');

drop policy if exists "avatars authenticated upload" on storage.objects;
create policy "avatars authenticated upload"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'avatars' and owner = auth.uid());

drop policy if exists "avatars owner update" on storage.objects;
create policy "avatars owner update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'avatars' and owner = auth.uid());

drop policy if exists "avatars owner delete" on storage.objects;
create policy "avatars owner delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'avatars' and owner = auth.uid());
