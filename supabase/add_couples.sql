-- Cuanly: couple mode. Two accounts link through an invite code and see each other's
-- monthly totals (spending, income, top category). Only aggregates are shared, never
-- individual transactions. Idempotent. Run once in the Supabase SQL editor
-- (also merged into schema.sql).

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
