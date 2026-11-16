-- Cuanly: investment portfolio tracker (capital, current value, sold/active).
-- Idempotent. Run once in the Supabase SQL editor (also merged into schema.sql).
create table if not exists investments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  investment_type text not null,
  amount numeric not null check (amount > 0),        -- capital put in
  current_value numeric not null check (current_value >= 0),
  purchase_date date not null default current_date,
  notes text,
  status text not null default 'active' check (status in ('active', 'sold')),
  created_at timestamptz not null default now()
);

alter table investments enable row level security;
drop policy if exists own_rows on investments;
create policy own_rows on investments for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
