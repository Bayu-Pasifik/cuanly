-- Cuanly schema. Run in the Supabase SQL editor.
create table if not exists wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  name text not null,
  type text not null default 'regular', -- regular | credit_card | saving | investment
  balance numeric not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  wallet_id uuid references wallets on delete set null,
  kind text not null check (kind in ('income', 'expense')),
  amount numeric not null check (amount > 0),
  category text not null,
  note text,
  occurred_on date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists monthly_targets (
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  month date not null, -- first day of the month
  budget numeric not null,
  primary key (user_id, month)
);

create table if not exists dreams (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  title text not null,
  target numeric not null check (target > 0),
  saved numeric not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists debts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  person text not null,
  direction text not null check (direction in ('owe', 'lent')), -- owe: I owe them; lent: they owe me
  total numeric not null check (total > 0),
  paid numeric not null default 0,
  due_on date,
  created_at timestamptz not null default now()
);

do $$
declare t text;
begin
  foreach t in array array['wallets', 'transactions', 'monthly_targets', 'dreams', 'debts'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists own_rows on %I', t);
    execute format(
      'create policy own_rows on %I for all using (user_id = auth.uid()) with check (user_id = auth.uid())', t);
  end loop;
end $$;
