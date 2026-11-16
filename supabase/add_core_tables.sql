-- Cuanly: tables for custom categories, recurring transactions and per-category budgets.
-- Idempotent. Run once in the Supabase SQL editor (also merged into schema.sql).
create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  kind text not null check (kind in ('income', 'expense')),
  name text not null,
  created_at timestamptz not null default now(),
  unique (user_id, kind, name)
);

create table if not exists recurring (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  kind text not null check (kind in ('income', 'expense')),
  amount numeric not null check (amount > 0),
  category text not null,
  note text,
  wallet_id uuid references wallets on delete set null,
  day_of_month int not null check (day_of_month between 1 and 31),
  next_due date not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists category_budgets (
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  category text not null,
  amount numeric not null check (amount > 0),
  primary key (user_id, category)
);

do $$
declare t text;
begin
  foreach t in array array['categories', 'recurring', 'category_budgets'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists own_rows on %I', t);
    execute format(
      'create policy own_rows on %I for all using (user_id = auth.uid()) with check (user_id = auth.uid())', t);
  end loop;
end $$;
