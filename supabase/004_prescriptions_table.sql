-- Module 10: Prescription Manager
-- Run this AFTER 003_reminders_table.sql, in Supabase SQL Editor.

create table if not exists public.prescriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  category text not null default 'others', -- blood_test, xray, prescription, others
  file_path text not null,     -- storage object path, not a public URL
  notes text,
  created_at timestamptz not null default now()
);

alter table public.prescriptions enable row level security;

drop policy if exists "Users can view own prescriptions" on public.prescriptions;
create policy "Users can view own prescriptions"
  on public.prescriptions for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own prescriptions" on public.prescriptions;
create policy "Users can insert own prescriptions"
  on public.prescriptions for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own prescriptions" on public.prescriptions;
create policy "Users can delete own prescriptions"
  on public.prescriptions for delete
  using (auth.uid() = user_id);

-- Private bucket — unlike medicine-images (Module 3), prescriptions are
-- sensitive medical documents and should NOT be publicly readable by URL.
-- Files are fetched via short-lived signed URLs instead (see
-- PrescriptionRepository.getSignedUrl in the app code).
insert into storage.buckets (id, name, public)
values ('prescriptions', 'prescriptions', false)
on conflict (id) do update set public = false;

drop policy if exists "Users can upload own prescription files" on storage.objects;
create policy "Users can upload own prescription files"
  on storage.objects for insert
  with check (
    bucket_id = 'prescriptions'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can view own prescription files" on storage.objects;
create policy "Users can view own prescription files"
  on storage.objects for select
  using (
    bucket_id = 'prescriptions'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can delete own prescription files" on storage.objects;
create policy "Users can delete own prescription files"
  on storage.objects for delete
  using (
    bucket_id = 'prescriptions'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
