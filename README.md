# JUSLUME Law Office Accounting

ระบบบัญชีสำหรับสำนักงานทนายความ โดยออกแบบให้ **คดีเป็นศูนย์กลางของบัญชี** และใช้ได้ทั้งเว็บเดสก์ท็อปและหน้าจอมือถือ

## ฟังก์ชันรุ่นแรก
- Dashboard เงินรับ / เงินจ่าย / กำไรก่อนภาษี / ภาษี
- ดูแบบรายวัน รายเดือน รายปี
- แยกรายรับ–รายจ่ายตามคดี
- ระบุบัญชีธนาคารหรือช่องทางที่รับเงิน
- Case Ledger: บัญชีรายวันของคดีนั้น
- หมวดค่าใช้จ่าย เช่น ค่าเดินทาง ค่าน้ำมัน ค่าธรรมเนียมศาล ค่าทนาย ค่าคัดเอกสาร
- ต้นทุนและคงเหลือรายคดี
- VAT และภาษีหัก ณ ที่จ่าย
- ทนายผู้รับผิดชอบคดี
- PostgreSQL/Supabase schema สำหรับต่อฐานข้อมูลจริง

## รัน
```bash
npm install
npm run dev
```

## ฐานข้อมูล
ไฟล์ `supabase/schema.sql` มีตาราง lawyers, clients, bank_accounts, cases, transactions และ view สำหรับ profitability รายคดี

## แนวทางต่อยอด
Authentication / Role, แนบใบเสร็จและเอกสาร, approval workflow, GL/Journal, P&L, VAT report, withholding tax report, export Excel/PDF, audit log.
