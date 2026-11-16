-- Cuanly: payment history for debts and contribution history for dreams.
-- Idempotent. Run once in the Supabase SQL editor (also merged into schema.sql).
create table if not exists debt_payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  debt_id uuid not null references debts on delete cascade,
  amount numeric not null check (amount > 0),
  paid_on date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists dream_contributions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  dream_id uuid not null references dreams on delete cascade,
  amount numeric not null check (amount > 0),
  saved_on date not null default current_date,
  created_at timestamptz not null default now()
);

do $$
declare t text;
begin
  foreach t in array array['debt_payments', 'dream_contributions'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists own_rows on %I', t);
    execute format(
      'create policy own_rows on %I for all using (user_id = auth.uid()) with check (user_id = auth.uid())', t);
  end loop;
end $$;
