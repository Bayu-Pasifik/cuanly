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

create table if not exists transfers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  from_wallet uuid references wallets on delete set null,
  to_wallet uuid references wallets on delete set null,
  amount numeric not null check (amount > 0),
  note text,
  occurred_on date not null default current_date,
  created_at timestamptz not null default now()
);

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

create table if not exists travel_splits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  trip_name text not null,
  total_amount numeric not null default 0,
  participants jsonb not null default '[]'::jsonb,  -- [{"name": "Budi"}]
  expenses jsonb not null default '[]'::jsonb,      -- [{"description": "Hotel", "amount": 500000, "paidBy": "Budi"}]
  created_at timestamptz not null default now()
);

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

do $$
declare t text;
begin
  foreach t in array array['wallets', 'transactions', 'monthly_targets', 'dreams', 'debts', 'transfers', 'categories', 'recurring', 'category_budgets', 'debt_payments', 'dream_contributions', 'spending_challenges', 'travel_splits', 'investments'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists own_rows on %I', t);
    execute format(
      'create policy own_rows on %I for all using (user_id = auth.uid()) with check (user_id = auth.uid())', t);
  end loop;
end $$;

create table if not exists couples (
  id uuid primary key default gen_random_uuid(),
  inviter_id uuid not null default auth.uid() references auth.users on delete cascade,
  partner_id uuid references auth.users on delete cascade,
  invite_code text not null unique
    default upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8)),
  status text not null default 'pending' check (status in ('pending', 'active')),
  created_at timestamptz not null default now(),
  check (partner_id is null or partner_id <> inviter_id)
);

-- A person is in at most one partnership.
create unique index if not exists couples_one_per_inviter on couples (inviter_id);
create unique index if not exists couples_one_per_partner on couples (partner_id);

alter table couples enable row level security;

drop policy if exists couple_select on couples;
create policy couple_select on couples for select
  using (inviter_id = auth.uid() or partner_id = auth.uid());

-- Clients may only create a pending invite for themselves. Accepting goes through
-- accept_couple_invite(), so partner_id cannot be set directly.
drop policy if exists couple_insert on couples;
create policy couple_insert on couples for insert
  with check (inviter_id = auth.uid() and partner_id is null and status = 'pending');

drop policy if exists couple_delete on couples;
create policy couple_delete on couples for delete
  using (inviter_id = auth.uid() or partner_id = auth.uid());

create or replace function accept_couple_invite(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare cid uuid;
begin
  if auth.uid() is null then
    raise exception 'Belum masuk';
  end if;
  if exists (select 1 from couples where inviter_id = auth.uid() or partner_id = auth.uid()) then
    raise exception 'Kamu sudah punya pasangan atau undangan aktif';
  end if;
  update couples
     set partner_id = auth.uid(), status = 'active'
   where invite_code = upper(trim(p_code)) and status = 'pending' and inviter_id <> auth.uid()
  returning id into cid;
  if cid is null then
    raise exception 'Kode undangan tidak valid atau sudah dipakai';
  end if;
  return cid;
end $$;

-- Monthly aggregates for the caller and their partner. Returns nothing without an active partnership.
create or replace function couple_summary(p_month date)
returns table (who text, expense numeric, income numeric, top_category text)
language sql
security definer
set search_path = public
as $$
  with c as (
    select inviter_id, partner_id from couples
     where status = 'active' and (inviter_id = auth.uid() or partner_id = auth.uid())
     limit 1
  ),
  members as (
    select inviter_id as uid from c
    union all
    select partner_id from c
  ),
  tx as (
    select t.user_id, t.kind, t.category, t.amount
      from transactions t
      join members m on m.uid = t.user_id
     where t.occurred_on >= date_trunc('month', p_month)::date
       and t.occurred_on <  (date_trunc('month', p_month) + interval '1 month')::date
  )
  select case when m.uid = auth.uid() then 'me' else 'partner' end,
         coalesce(sum(tx.amount) filter (where tx.kind = 'expense'), 0),
         coalesce(sum(tx.amount) filter (where tx.kind = 'income'), 0),
         (select t2.category from tx t2
           where t2.user_id = m.uid and t2.kind = 'expense'
           group by t2.category order by sum(t2.amount) desc limit 1)
    from members m
    left join tx on tx.user_id = m.uid
   group by m.uid;
$$;

revoke all on function accept_couple_invite(text) from public;
revoke all on function couple_summary(date) from public;
grant execute on function accept_couple_invite(text) to authenticated;
grant execute on function couple_summary(date) to authenticated;
