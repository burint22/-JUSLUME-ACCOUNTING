
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

alter table profiles enable row level security;
alter table law_offices enable row level security;
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

-- Basic authenticated-user policies for prototype deployment.
-- For production, replace these with office-membership policies.
do $$
declare t text;
begin
  foreach t in array array[
    'profiles','law_offices','cases','case_funds','invoices','invoice_lines','bills',
    'journal_entries','journal_lines','tax_sales','tax_purchases','wht_certificates',
    'bank_accounts','bank_reconciliations','accounting_periods','documents','audit_log'
  ]
  loop
    execute format('drop policy if exists authenticated_all on %I', t);
    execute format('create policy authenticated_all on %I for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;
