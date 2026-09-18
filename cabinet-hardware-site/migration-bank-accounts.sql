-- ============================================================================
-- Upgrades bank details from a single account to a list of accounts (you use
-- two banks). Safe to re-run.
-- Paste this whole file into Supabase → SQL Editor → Run.
-- ============================================================================

create table if not exists bank_accounts (
  id              uuid primary key default gen_random_uuid(),
  bank_name       text not null,
  account_title   text not null,
  account_number  text not null,
  ifsc_or_routing text not null default '',
  sort_order      integer not null default 0,
  active          boolean not null default true,
  created_at      timestamptz not null default now()
);

alter table bank_accounts enable row level security;

drop policy if exists public_read_active_bank_accounts on bank_accounts;
drop policy if exists admin_all_bank_accounts on bank_accounts;

create policy public_read_active_bank_accounts on bank_accounts for select using (active = true);
create policy admin_all_bank_accounts on bank_accounts for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- Avoid duplicates if this script is ever run more than once
create unique index if not exists bank_accounts_unique_idx on bank_accounts(bank_name, account_number);

insert into bank_accounts (bank_name, account_title, account_number, sort_order) values
  ('Meezan Bank', 'Shahid Iqbal', '02850106669725', 0),
  ('Standard Chartered', 'Shahid Iqbal', '01165940201', 1)
on conflict (bank_name, account_number) do nothing;
