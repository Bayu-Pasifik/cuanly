-- Cuanly: business mode (products, point-of-sale sales, business expenses).
-- Business money is tracked separately from personal wallets and transactions.
-- Idempotent. Run once in the Supabase SQL editor (also merged into schema.sql).

create table if not exists business_products (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  name text not null,
  price numeric not null check (price >= 0),   -- selling price
  cost numeric not null default 0 check (cost >= 0),  -- cost of goods per unit
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists business_sales (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  total numeric not null check (total >= 0),
  cost_total numeric not null default 0,
  payment_method text not null default 'cash',  -- cash | qris | transfer
  items jsonb not null default '[]'::jsonb,     -- [{"name","qty","price","cost"}]
  note text,
  sold_on date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists business_expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  description text not null,
  amount numeric not null check (amount > 0),
  spent_on date not null default current_date,
  created_at timestamptz not null default now()
);

do $$
declare t text;
begin
  foreach t in array array['business_products', 'business_sales', 'business_expenses'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists own_rows on %I', t);
    execute format(
      'create policy own_rows on %I for all using (user_id = auth.uid()) with check (user_id = auth.uid())', t);
  end loop;
end $$;
