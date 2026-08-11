-- Module 11: Family Profiles
-- Run this AFTER 004_prescriptions_table.sql, in Supabase SQL Editor.
--
-- Model: one Supabase auth user (the account holder / primary caregiver)
-- can manage multiple "profiles" -- themselves plus family members like
-- Mother, Father, children. Profiles are NOT separate logins; they're
-- rows the account holder manages, same as the PRD describes ("Son"
-- caregiver managing "Mother" patient under one account).

create table if not exists public.family_members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  relationship text not null default 'Other',
  is_self boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.family_members enable row level security;

drop policy if exists "Users can view own family members" on public.family_members;
create policy "Users can view own family members"
  on public.family_members for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own family members" on public.family_members;
create policy "Users can insert own family members"
  on public.family_members for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own family members" on public.family_members;
create policy "Users can update own family members"
  on public.family_members for update
  using (auth.uid() = user_id);

drop policy if exists "Users can delete own family members" on public.family_members;
create policy "Users can delete own family members"
  on public.family_members for delete
  using (auth.uid() = user_id and is_self = false);

alter table public.medicines
  add column if not exists profile_id uuid references public.family_members(id) on delete cascade;

alter table public.prescriptions
  add column if not exists profile_id uuid references public.family_members(id) on delete cascade;

do $$
declare
  u record;
  self_profile_id uuid;
begin
  for u in
    select distinct user_id from public.medicines
    union
    select distinct user_id from public.prescriptions
  loop
    insert into public.family_members (user_id, name, relationship, is_self)
    values (u.user_id, 'Myself', 'Myself', true)
    returning id into self_profile_id;

    update public.medicines
      set profile_id = self_profile_id
      where user_id = u.user_id and profile_id is null;

    update public.prescriptions
      set profile_id = self_profile_id
      where user_id = u.user_id and profile_id is null;
  end loop;
end $$;

create index if not exists idx_medicines_profile on public.medicines (profile_id);
create index if not exists idx_prescriptions_profile on public.prescriptions (profile_id);
