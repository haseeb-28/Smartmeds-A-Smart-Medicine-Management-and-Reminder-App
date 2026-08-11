-- Module 4: Reminder System + Module 5: Confirmation
-- Run this AFTER 002_medicines_table.sql, in Supabase SQL Editor.

-- Each row = one reminder time for a medicine (e.g. Metformin @ 8:00 AM)
create table if not exists public.medicine_schedule (
  id uuid primary key default gen_random_uuid(),
  medicine_id uuid not null references public.medicines(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  time_of_day time not null,          -- e.g. 08:00:00
  label text not null default 'Custom', -- Morning, Afternoon, Evening, Night, Custom
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.medicine_schedule enable row level security;

drop policy if exists "Users can view own schedule" on public.medicine_schedule;
create policy "Users can view own schedule"
  on public.medicine_schedule for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own schedule" on public.medicine_schedule;
create policy "Users can insert own schedule"
  on public.medicine_schedule for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own schedule" on public.medicine_schedule;
create policy "Users can update own schedule"
  on public.medicine_schedule for update
  using (auth.uid() = user_id);

drop policy if exists "Users can delete own schedule" on public.medicine_schedule;
create policy "Users can delete own schedule"
  on public.medicine_schedule for delete
  using (auth.uid() = user_id);

-- One row per actual dose event — created when a reminder fires,
-- updated when the user responds (Take Now / Skip / Missed after timeout).
create table if not exists public.medicine_history (
  id uuid primary key default gen_random_uuid(),
  medicine_id uuid not null references public.medicines(id) on delete cascade,
  schedule_id uuid references public.medicine_schedule(id) on delete set null,
  user_id uuid not null references auth.users(id) on delete cascade,
  scheduled_time timestamptz not null,
  responded_time timestamptz,
  status text not null default 'upcoming', -- upcoming, taken, missed, skipped
  created_at timestamptz not null default now()
);

alter table public.medicine_history enable row level security;

drop policy if exists "Users can view own history" on public.medicine_history;
create policy "Users can view own history"
  on public.medicine_history for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own history" on public.medicine_history;
create policy "Users can insert own history"
  on public.medicine_history for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own history" on public.medicine_history;
create policy "Users can update own history"
  on public.medicine_history for update
  using (auth.uid() = user_id);

create index if not exists idx_medicine_history_user_time
  on public.medicine_history (user_id, scheduled_time);
