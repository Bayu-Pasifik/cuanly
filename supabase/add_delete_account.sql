-- Cuanly: lets a signed-in user delete their own account and, through the
-- "on delete cascade" foreign keys, all of their data.
-- Idempotent. Run once in the Supabase SQL editor (also merged into schema.sql).
create or replace function delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'Belum masuk';
  end if;
  delete from auth.users where id = auth.uid();
end $$;

revoke all on function delete_my_account() from public;
grant execute on function delete_my_account() to authenticated;
