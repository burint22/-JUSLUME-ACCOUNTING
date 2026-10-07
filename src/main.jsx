import React,{useMemo,useState}from'react';import{createRoot}from'react-dom/client';import'./styles.css';

const cases=[
{id:'C-2569-001',caseNo:'ผบ.1234/2569',client:'บริษัท แสงธรรม จำกัด',title:'ผิดสัญญาซื้อขาย',lawyer:'ทนายกิตติ',received:125000,paid:43800,tax:8750,account:'KBANK •••• 4821',status:'กำลังดำเนินการ'},
{id:'C-2569-002',caseNo:'พ.456/2569',client:'นางสาววราภรณ์',title:'ละเมิดเรียกค่าเสียหาย',lawyer:'ทนายมนัส',received:80000,paid:21650,tax:5600,account:'SCB •••• 9088',status:'นัดสืบพยาน'},
{id:'C-2569-003',caseNo:'อ.919/2569',client:'นายธนภัทร',title:'คดีอาญา',lawyer:'ทนายกิตติ',received:60000,paid:17700,tax:4200,account:'Cash',status:'เตรียมคดี'}];

const tx=[
{date:'07/10/2569',caseId:'C-2569-001',type:'รับ',category:'ค่าทนายความ',detail:'รับค่าดำเนินคดีงวดที่ 2',amount:50000,account:'KBANK •••• 4821'},
{date:'07/10/2569',caseId:'C-2569-001',type:'จ่าย',category:'ค่าเดินทาง',detail:'เดินทางไปศาลจังหวัดนครราชสีมา',amount:1800,account:'เงินสดย่อย'},
{date:'06/10/2569',caseId:'C-2569-002',type:'จ่าย',category:'ค่าน้ำมัน',detail:'เติมน้ำมันรถสำนักงาน',amount:1500,account:'SCB •••• 9088'},
{date:'05/10/2569',caseId:'C-2569-002',type:'จ่าย',category:'ค่าธรรมเนียมศาล',detail:'ค่าขึ้นศาลและค่าส่งหมาย',amount:3200,account:'SCB •••• 9088'},
{date:'04/10/2569',caseId:'C-2569-003',type:'รับ',category:'ค่าทนายความ',detail:'รับค่าทนายงวดแรก',amount:30000,account:'Cash'},
{date:'03/10/2569',caseId:'C-2569-003',type:'จ่าย',category:'ค่าคัดเอกสาร',detail:'คัดสำเนาสำนวน',amount:850,account:'เงินสดย่อย'}];

const money=n=>new Intl.NumberFormat('th-TH',{style:'currency',currency:'THB',maximumFractionDigits:0}).format(n);

function App(){
const [selected,setSelected]=useState(cases[0].id);
const c=cases.find(x=>x.id===selected);
const caseTx=tx.filter(x=>x.caseId===selected);
const totals=useMemo(()=>({received:cases.reduce((s,x)=>s+x.received,0),paid:cases.reduce((s,x)=>s+x.paid,0),tax:cases.reduce((s,x)=>s+x.tax,0)}),[]);
return <div className="app">
<aside><div className="brand">JUSLUME<div>LAW OFFICE ACCOUNTING</div></div>
<nav>{['ภาพรวมบัญชี','รายการคดี','เงินรับ','เงินจ่าย','ต้นทุนคดี','ภาษี','บัญชีธนาคาร','รายงาน'].map((x,i)=><button className={i===0?'active':''}>{x}</button>)}</nav>
<div className="asideNote">ระบบบัญชีสำนักงานทนายความ<br/>Case-based Accounting</div></aside>

<main>
<header><div><h1>ภาพรวมบัญชีสำนักงานทนาย</h1><p>รายวัน • รายเดือน • รายปี และแยกตามคดี</p></div><button className="primary">+ บันทึกรายการ</button></header>

<section className="period"><button className="active">วันนี้</button><button>เดือนนี้</button><button>ปีนี้</button><span>7 ตุลาคม 2569</span></section>

<section className="cards">
<div className="card"><label>เงินรับ</label><strong>{money(totals.received)}</strong><small>รวมทุกคดี</small></div>
<div className="card"><label>เงินจ่าย</label><strong>{money(totals.paid)}</strong><small>ค่าใช้จ่ายและต้นทุน</small></div>
<div className="card"><label>กำไรก่อนภาษี</label><strong>{money(totals.received-totals.paid)}</strong><small>รายรับหักค่าใช้จ่าย</small></div>
<div className="card"><label>ภาษีที่เกี่ยวข้อง</label><strong>{money(totals.tax)}</strong><small>VAT / หัก ณ ที่จ่าย</small></div>
</section>

<section className="grid">
<div className="panel">
<div className="panelHead"><div><h2>คดีและผลประกอบการ</h2><p>คลิกเลือกคดีเพื่อดูบัญชีรายวัน</p></div></div>
<div className="tableWrap"><table><thead><tr><th>เลขคดี</th><th>ลูกความ</th><th>ทนายรับผิดชอบ</th><th>เงินรับ</th><th>ต้นทุน/จ่าย</th><th>คงเหลือ</th></tr></thead><tbody>
{cases.map(x=><tr onClick={()=>setSelected(x.id)} className={selected===x.id?'selected':''}><td><b>{x.caseNo}</b><span>{x.id}</span></td><td>{x.client}<span>{x.title}</span></td><td>{x.lawyer}</td><td>{money(x.received)}</td><td>{money(x.paid)}</td><td><b>{money(x.received-x.paid)}</b></td></tr>)}
</tbody></table></div></div>

<div className="panel casePanel">
<div className="panelHead"><div><h2>รายละเอียดคดี</h2><p>{c.caseNo}</p></div><span className="status">{c.status}</span></div>
<div className="caseMeta"><div><label>ลูกความ</label><b>{c.client}</b></div><div><label>ทนายผู้รับผิดชอบ</label><b>{c.lawyer}</b></div><div><label>บัญชีรับเงิน</label><b>{c.account}</b></div><div><label>ภาษี</label><b>{money(c.tax)}</b></div></div>
<div className="summaryLine"><span>เงินรับ {money(c.received)}</span><span>เงินจ่าย {money(c.paid)}</span><b>คงเหลือ {money(c.received-c.paid)}</b></div>
<h3>บัญชีรายวันของคดี</h3>
{caseTx.map(t=><div className="tx"><div><b>{t.detail}</b><span>{t.date} • {t.category} • {t.account}</span></div><strong className={t.type==='รับ'?'in':'out'}>{t.type==='รับ'?'+':'-'}{money(t.amount)}</strong></div>)}
</div>
</section>

<section className="panel">
<div className="panelHead"><div><h2>รายการรับ–จ่ายล่าสุด</h2><p>ตรวจสอบเงินรับ เงินจ่าย และบัญชีที่ใช้รับ/จ่าย</p></div><button>ส่งออก CSV</button></div>
<div className="tableWrap"><table><thead><tr><th>วันที่</th><th>คดี</th><th>ประเภท</th><th>รายละเอียด</th><th>หมวด</th><th>บัญชี</th><th>จำนวนเงิน</th></tr></thead><tbody>
{tx.map(t=><tr><td>{t.date}</td><td>{t.caseId}</td><td><span className={'pill '+(t.type==='รับ'?'inBg':'outBg')}>{t.type}</span></td><td>{t.detail}</td><td>{t.category}</td><td>{t.account}</td><td className={t.type==='รับ'?'in':'out'}><b>{t.type==='รับ'?'+':'-'}{money(t.amount)}</b></td></tr>)}
</tbody></table></div></section>
</main></div>
}
createRoot(document.getElementById('root')).render(<App/>);