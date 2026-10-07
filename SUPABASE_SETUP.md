# JUSLUME ACCOUNTING — Supabase Deployment

## 1. Run database schema
Open Supabase Dashboard > SQL Editor and run the complete `schema.sql` file in this repository.

This creates:
- office/user roles (Owner, Editor, Viewer)
- RLS policies by office
- cloud state persistence
- accounting tables
- VAT/WHT tables
- private document storage bucket
- member-management RPC functions

## 2. Enable Email OTP
In Supabase Authentication:
- Enable Email provider
- Allow OTP / magic code sign-in
- Add the GitHub Pages domain to allowed redirect URLs if required

## 3. Configure JUSLUME
Open JUSLUME ACCOUNTING > ตั้งค่าสำนักงาน and enter:
- Supabase Project URL
- Supabase Publishable / anon key
- Owner email

Never place a service-role key in the browser.

## 4. First owner login
Open **Cloud & เอกสาร** > ส่ง OTP เข้าสู่ระบบ.
The first authenticated owner automatically gets an office record and Owner role.

## 5. Add Editor / Viewer
Each staff email must sign in once so the Auth user exists.
Owner can then add that email from **Cloud & เอกสาร** and choose:
- Editor — can create/update accounting data
- Viewer — read-only

## 6. Documents
Case, receipt and payment attachments are uploaded to the private bucket
`law-office-documents`. Files are served through short-lived signed URLs.

## 7. Production checklist
- Test RLS with one Owner, one Editor and one Viewer account.
- Confirm Viewer cannot write.
- Confirm a user from another office cannot read this office.
- Close a test accounting period and verify posting is blocked.
- Create and reverse a journal entry.
- Upload/download a test document.
- Verify VAT purchase/sales and WHT reports.
- Export management CSV.
- Take a database backup before importing real historical data.

## Important
The frontend keeps a browser cache for resilience, but once authenticated the Cloud snapshot is synchronized to Supabase. Do not treat browser cache as the only backup.
