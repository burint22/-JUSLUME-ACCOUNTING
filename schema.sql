
-- JUSLUME ACCOUNTING V3 — Supabase/Postgres schema
create extension if not exists pgcrypto;

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'viewer' check (role in ('viewer','editor','owner')),
  created_at timestamptz not null default now()
);

create table if not exists law_offices (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  tax_id text,
  branch text,
  address text,
  phone text,
  vat_registered boolean not null default false,
  owner_user_id uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists cases (
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references law_offices(id) on delete cascade,
  court text,
  black_case_no text,
  red_case_no text,
  case_type text,
  client_side text,
  status text,
  plaintiff_json jsonb not null default '{}'::jsonb,
  defendant_json jsonb not null default '{}'::jsonb,
  responsible_lawyer_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists case_funds (
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references law_offices(id) on delete cascade,
  case_id uuid references cases(id) on delete set null,
  tx_date date not null,
  bucket text not null check (bucket in ('office','advance','client')),
  direction text not null check (direction in ('in','out')),
  amount numeric(14,2) not null check (amount > 0),
  cost_status text,
  memo text,
  status text not null default 'posted',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists invoices (
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references law_offices(id) on delete cascade,
  case_id uuid references cases(id) on delete set null,
  document_no text not null,
  issue_date date not null,
  due_date date,
  customer_name text not null,
  customer_tax_id text,
  customer_branch text,
  customer_address text,
  status text not null default 'issued',
  subtotal numeric(14,2) not null default 0,
  vat numeric(14,2) not null default 0,
  wht numeric(14,2) not null default 0,
  net_receivable numeric(14,2) not null default 0,
  paid_amount numeric(14,2) not null default 0,
  void_reason text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (office_id, document_no)
);

create table if not exists invoice_lines (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references invoices(id) on delete cascade,
  description text not null,
  qty numeric(12,2) not null default 1,
  unit_price numeric(14,2) not null default 0,
  vat_rate numeric(5,2) not null default 0,
  wht_rate numeric(5,2) not null default 0,
  revenue_account_code text
);

create table if not exists bills (
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references law_offices(id) on delete cascade,
  case_id uuid references cases(id) on delete set null,
  document_no text not null,
  bill_date date not null,
  vendor_name text not null,
  vendor_tax_id text,
  vendor_type text check (vendor_type in ('person','company')),
  subtotal numeric(14,2) not null default 0,
  vat numeric(14,2) not null default 0,
  wht_rate numeric(5,2) not null default 0,
  total numeric(14,2) not null default 0,
  paid_amount numeric(14,2) not null default 0,
  memo text,
  status text not null default 'open',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (office_id, document_no)
);

create table if not exists journal_entries (
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references law_offices(id) on delete cascade,
  journal_no text not null,
  entry_date date not null,
  memo text,
  source_type text,
  source_id uuid,
  status text not null default 'posted' check (status in ('draft','posted','reversed')),
  reversed_from uuid references journal_entries(id),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (office_id, journal_no)
);

create table if not exists journal_lines (
  id uuid primary key default gen_random_uuid(),
  journal_id uuid not null references journal_entries(id) on delete cascade,
  account_code text not null,
  debit numeric(14,2) not null default 0,
  credit numeric(14,2) not null default 0,
  check (debit >= 0 and credit >= 0)
);

create table if not exists tax_sales (
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references law_offices(id) on delete cascade,
  tax_date date not null,
  document_no text not null,
  customer_name text,
  customer_tax_id text,
  tax_base numeric(14,2) not null default 0,
  vat_amount numeric(14,2) not null default 0,
  source_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists tax_purchases (
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references law_offices(id) on delete cascade,
  tax_date date not null,
  document_no text not null,
  vendor_name text,
  vendor_tax_id text,
  tax_base numeric(14,2) not null default 0,
  vat_amount numeric(14,2) not null default 0,
  source_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists wht_certificates (
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references law_offices(id) on delete cascade,
  certificate_no text not null,
  certificate_date date not null,
  payee_name text not null,
  payee_tax_id text,
  payee_type text check (payee_type in ('person','company')),
  tax_form text check (tax_form in ('ภ.ง.ด.3','ภ.ง.ด.53')),
  tax_base numeric(14,2) not null default 0,
  tax_rate numeric(5,2) not null default 0,
  tax_amount numeric(14,2) not null default 0,
  source_id uuid,
  created_at timestamptz not null default now(),
  unique (office_id, certificate_no)
);

create table if not exists bank_accounts (
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references law_offices(id) on delete cascade,
  bank_name text not null,
  account_name text,
  account_no text,
  account_type text,
  opening_balance numeric(14,2) not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists bank_reconciliations (
  id uuid primary key default gen_random_uuid(),
  bank_account_id uuid not null references bank_accounts(id) on delete cascade,
  period_end date not null,
  book_balance numeric(14,2) not null default 0,
  statement_balance numeric(14,2) not null default 0,
  difference numeric(14,2) generated always as (statement_balance - book_balance) stored,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists accounting_periods (
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references law_offices(id) on delete cascade,
  label text not null,
  date_from date not null,
  date_to date not null,
  status text not null default 'open' check (status in ('open','closed')),
  close_reason text,
  reopen_reason text,
  closed_by uuid references auth.users(id),
  closed_at timestamptz,
  reopened_by uuid references auth.users(id),
  reopened_at timestamptz
);

create table if not exists documents (
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references law_offices(id) on delete cascade,
  case_id uuid references cases(id) on delete set null,
  related_type text,
  related_id uuid,
  storage_path text not null,
  file_name text not null,
  mime_type text,
  size_bytes bigint,
  version_no integer not null default 1,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists audit_log (
  id uuid primary key default gen_random_uuid(),
  office_id uuid references law_offices(id) on delete set null,
  actor_user_id uuid references auth.users(id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  detail jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);


create table if not exists office_members (
  office_id uuid not null references law_offices(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'viewer' check (role in ('viewer','editor','owner')),
  created_at timestamptz not null default now(),
  primary key (office_id,user_id)
);

-- Cloud snapshot keeps the current front-end model transactionally persistent while
-- normalized accounting tables remain available for reporting/integration.
create table if not exists app_state (
  office_id uuid primary key references law_offices(id) on delete cascade,
  state jsonb not null default '{}'::jsonb,
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);

create or replace function public.can_access_office(p_office uuid)
returns boolean language sql stable security definer set search_path=public
as $$
  select exists(
    select 1 from law_offices o
    where o.id=p_office and o.owner_user_id=auth.uid()
  ) or exists(
    select 1 from office_members m
    where m.office_id=p_office and m.user_id=auth.uid()
  );
$$;

create or replace function public.can_edit_office(p_office uuid)
returns boolean language sql stable security definer set search_path=public
as $$
  select exists(
    select 1 from law_offices o
    where o.id=p_office and o.owner_user_id=auth.uid()
  ) or exists(
    select 1 from office_members m
    where m.office_id=p_office and m.user_id=auth.uid() and m.role in ('owner','editor')
  );
$$;

alter table profiles enable row level security;
alter table law_offices enable row level security;
alter table office_members enable row level security;
alter table app_state enable row level security;
alter table cases enable row level security;
alter table case_funds enable row level security;
alter table invoices enable row level security;
alter table invoice_lines enable row level security;
alter table bills enable row level security;
alter table journal_entries enable row level security;
alter table journal_lines enable row level security;
alter table tax_sales enable row level security;
alter table tax_purchases enable row level security;
alter table wht_certificates enable row level security;
alter table bank_accounts enable row level security;
alter table bank_reconciliations enable row level security;
alter table accounting_periods enable row level security;
alter table documents enable row level security;
alter table audit_log enable row level security;

drop policy if exists profiles_self on profiles;
create policy profiles_self on profiles for all to authenticated
using (id=auth.uid()) with check (id=auth.uid());

drop policy if exists office_select on law_offices;
create policy office_select on law_offices for select to authenticated
using (owner_user_id=auth.uid() or public.can_access_office(id));

drop policy if exists office_insert on law_offices;
create policy office_insert on law_offices for insert to authenticated
with check (owner_user_id=auth.uid());

drop policy if exists office_update on law_offices;
create policy office_update on law_offices for update to authenticated
using (public.can_edit_office(id)) with check (public.can_edit_office(id));

drop policy if exists members_select on office_members;
create policy members_select on office_members for select to authenticated
using (public.can_access_office(office_id));

drop policy if exists members_owner_write on office_members;
create policy members_owner_write on office_members for all to authenticated
using (exists(select 1 from law_offices o where o.id=office_id and o.owner_user_id=auth.uid()))
with check (exists(select 1 from law_offices o where o.id=office_id and o.owner_user_id=auth.uid()));

drop policy if exists app_state_select on app_state;
create policy app_state_select on app_state for select to authenticated
using (public.can_access_office(office_id));
drop policy if exists app_state_write on app_state;
create policy app_state_write on app_state for all to authenticated
using (public.can_edit_office(office_id)) with check (public.can_edit_office(office_id));

-- Office-scoped tables.
do $$
declare t text;
begin
  foreach t in array array[
    'cases','case_funds','invoices','bills','journal_entries','tax_sales','tax_purchases',
    'wht_certificates','bank_accounts','accounting_periods','documents','audit_log'
  ]
  loop
    execute format('drop policy if exists office_read on %I',t);
    execute format('drop policy if exists office_write on %I',t);
    execute format('create policy office_read on %I for select to authenticated using (public.can_access_office(office_id))',t);
    execute format('create policy office_write on %I for all to authenticated using (public.can_edit_office(office_id)) with check (public.can_edit_office(office_id))',t);
  end loop;
end $$;

drop policy if exists invoice_lines_read on invoice_lines;
create policy invoice_lines_read on invoice_lines for select to authenticated
using (exists(select 1 from invoices i where i.id=invoice_id and public.can_access_office(i.office_id)));
drop policy if exists invoice_lines_write on invoice_lines;
create policy invoice_lines_write on invoice_lines for all to authenticated
using (exists(select 1 from invoices i where i.id=invoice_id and public.can_edit_office(i.office_id)))
with check (exists(select 1 from invoices i where i.id=invoice_id and public.can_edit_office(i.office_id)));

drop policy if exists journal_lines_read on journal_lines;
create policy journal_lines_read on journal_lines for select to authenticated
using (exists(select 1 from journal_entries j where j.id=journal_id and public.can_access_office(j.office_id)));
drop policy if exists journal_lines_write on journal_lines;
create policy journal_lines_write on journal_lines for all to authenticated
using (exists(select 1 from journal_entries j where j.id=journal_id and public.can_edit_office(j.office_id)))
with check (exists(select 1 from journal_entries j where j.id=journal_id and public.can_edit_office(j.office_id)));

drop policy if exists bank_recon_read on bank_reconciliations;
create policy bank_recon_read on bank_reconciliations for select to authenticated
using (exists(select 1 from bank_accounts b where b.id=bank_account_id and public.can_access_office(b.office_id)));
drop policy if exists bank_recon_write on bank_reconciliations;
create policy bank_recon_write on bank_reconciliations for all to authenticated
using (exists(select 1 from bank_accounts b where b.id=bank_account_id and public.can_edit_office(b.office_id)))
with check (exists(select 1 from bank_accounts b where b.id=bank_account_id and public.can_edit_office(b.office_id)));

-- Private document bucket. Files must be stored as {office_id}/{uuid}-{filename}.
insert into storage.buckets(id,name,public)
values ('law-office-documents','law-office-documents',false)
on conflict (id) do update set public=false;

drop policy if exists law_docs_select on storage.objects;
create policy law_docs_select on storage.objects for select to authenticated
using (
  bucket_id='law-office-documents'
  and public.can_access_office((storage.foldername(name))[1]::uuid)
);
drop policy if exists law_docs_insert on storage.objects;
create policy law_docs_insert on storage.objects for insert to authenticated
with check (
  bucket_id='law-office-documents'
  and public.can_edit_office((storage.foldername(name))[1]::uuid)
);
drop policy if exists law_docs_update on storage.objects;
create policy law_docs_update on storage.objects for update to authenticated
using (
  bucket_id='law-office-documents'
  and public.can_edit_office((storage.foldername(name))[1]::uuid)
)
with check (
  bucket_id='law-office-documents'
  and public.can_edit_office((storage.foldername(name))[1]::uuid)
);
drop policy if exists law_docs_delete on storage.objects;
create policy law_docs_delete on storage.objects for delete to authenticated
using (
  bucket_id='law-office-documents'
  and public.can_edit_office((storage.foldername(name))[1]::uuid)
);
