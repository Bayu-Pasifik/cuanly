-- Cuanly: spending challenges (spending cap for chosen categories over a date range).
-- Idempotent. Run once in the Supabase SQL editor (also merged into schema.sql).
create table if not exists spending_challenges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  title text not null,
  category text not null,            -- comma-separated expense category names
  budget_limit numeric not null check (budget_limit > 0),
  start_date date not null,
  end_date date not null,
  auto_renew boolean not null default false,
  created_at timestamptz not null default now(),
  check (end_date >= start_date)
);

alter table spending_challenges enable row level security;
drop policy if exists own_rows on spending_challenges;
create policy own_rows on spending_challenges for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
