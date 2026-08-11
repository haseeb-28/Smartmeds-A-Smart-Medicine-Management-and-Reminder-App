-- Module 3: Medicines table
-- Run this in Supabase SQL Editor (Project → SQL Editor → New Query)

create table if not exists public.medicines (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  brand_name text,
  generic_name text,
  dosage_form text not null default 'tablet',      -- tablet, capsule, injection, syrup, drops
  meal_timing text not null default 'anytime',     -- before_meal, after_meal, with_food, anytime
  quantity_total integer not null default 0,
  quantity_remaining integer not null default 0,
  image_url text,
  start_date date not null default current_date,
  end_date date,
  notes text,
  status text not null default 'active',           -- active, paused, archived
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Keep updated_at fresh on every edit
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_medicines_updated_at on public.medicines;
create trigger trg_medicines_updated_at
  before update on public.medicines
  for each row execute function public.set_updated_at();

-- Row Level Security — each user can only see/edit their own medicines
alter table public.medicines enable row level security;

drop policy if exists "Users can view own medicines" on public.medicines;
create policy "Users can view own medicines"
  on public.medicines for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own medicines" on public.medicines;
create policy "Users can insert own medicines"
  on public.medicines for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own medicines" on public.medicines;
create policy "Users can update own medicines"
  on public.medicines for update
  using (auth.uid() = user_id);

drop policy if exists "Users can delete own medicines" on public.medicines;
create policy "Users can delete own medicines"
  on public.medicines for delete
  using (auth.uid() = user_id);

-- Optional: storage bucket for medicine images
insert into storage.buckets (id, name, public)
values ('medicine-images', 'medicine-images', true)
on conflict (id) do nothing;

drop policy if exists "Users can upload own medicine images" on storage.objects;
create policy "Users can upload own medicine images"
  on storage.objects for insert
  with check (bucket_id = 'medicine-images' and auth.uid()::text = (storage.foldername(name))[1]);

drop policy if exists "Medicine images are publicly viewable" on storage.objects;
create policy "Medicine images are publicly viewable"
  on storage.objects for select
  using (bucket_id = 'medicine-images');
