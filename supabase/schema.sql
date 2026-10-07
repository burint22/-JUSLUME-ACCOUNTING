create extension if not exists pgcrypto;

create table lawyers(
 id uuid primary key default gen_random_uuid(),
 full_name text not null,
 license_no text,
 phone text,
 email text,
 active boolean default true,
 created_at timestamptz default now()
);

create table clients(
 id uuid primary key default gen_random_uuid(),
 name text not null,
 tax_id text,
 phone text,
 email text,
 address text,
 created_at timestamptz default now()
);

create table bank_accounts(
 id uuid primary key default gen_random_uuid(),
 account_name text not null,
 bank_name text,
 account_no text,
 account_type text,
 active boolean default true,
 created_at timestamptz default now()
);

create table cases(
 id uuid primary key default gen_random_uuid(),
 internal_no text unique not null,
 court_case_no text,
 client_id uuid references clients(id),
 title text not null,
 responsible_lawyer_id uuid references lawyers(id),
 status text default 'open',
 opened_on date,
 closed_on date,
 agreed_fee numeric(14,2) default 0,
 notes text,
 created_at timestamptz default now()
);

create table transactions(
 id uuid primary key default gen_random_uuid(),
 txn_date date not null,
 case_id uuid references cases(id),
 txn_type text not null check(txn_type in ('income','expense')),
 category text not null,
 description text not null,
 amount numeric(14,2) not null check(amount>=0),
 vat_amount numeric(14,2) default 0,
 withholding_tax_amount numeric(14,2) default 0,
 bank_account_id uuid references bank_accounts(id),
 payment_method text,
 document_no text,
 created_at timestamptz default now()
);

create index idx_transactions_case_date on transactions(case_id,txn_date desc);
create index idx_transactions_type_date on transactions(txn_type,txn_date desc);

create view case_profitability as
select c.id,c.internal_no,c.court_case_no,c.title,
coalesce(sum(case when t.txn_type='income' then t.amount else 0 end),0) total_income,
coalesce(sum(case when t.txn_type='expense' then t.amount else 0 end),0) total_expense,
coalesce(sum(case when t.txn_type='income' then t.amount else -t.amount end),0) net_before_tax,
coalesce(sum(t.vat_amount),0) vat_amount,
coalesce(sum(t.withholding_tax_amount),0) withholding_tax_amount
from cases c left join transactions t on t.case_id=c.id
group by c.id;
