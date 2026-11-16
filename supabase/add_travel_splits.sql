-- Cuanly: travel split (shared trip expenses divided equally between participants).
-- Idempotent. Run once in the Supabase SQL editor (also merged into schema.sql).
create table if not exists travel_splits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  trip_name text not null,
  total_amount numeric not null default 0,
  participants jsonb not null default '[]'::jsonb,  -- [{"name": "Budi"}]
  expenses jsonb not null default '[]'::jsonb,      -- [{"description": "Hotel", "amount": 500000, "paidBy": "Budi"}]
  created_at timestamptz not null default now()
);

alter table travel_splits enable row level security;
drop policy if exists own_rows on travel_splits;
create policy own_rows on travel_splits for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
