
(function(){
'use strict';
var client=null,officeId=null,currentUser=null,currentRole='offline',pushTimer=null,pulling=false;
function cfg(){return window.office&&office.supabaseUrl&&office.supabaseAnon}
function sb(){
  if(client)return client;
  if(!cfg()||!window.supabase||!window.supabase.createClient)return null;
  client=window.supabase.createClient(office.supabaseUrl,office.supabaseAnon);
  return client;
}
function status(t,kind){
  var x=document.getElementById('cloudStatus');
  if(x){x.textContent=t;x.className='pill '+(kind||'')}
}
function snapshot(){return window.getJuslumeV3State?window.getJuslumeV3State():null}
async function ensureOffice(){
  var s=sb();if(!s||!currentUser)return null;
  var r=await s.from('law_offices').select('*').eq('owner_user_id',currentUser.id).limit(1);
  if(r.error)throw r.error;
  var o=r.data&&r.data[0];
  if(!o){
    var ins=await s.from('law_offices').insert({
      name:office.name||'JUSLUME LAW OFFICE',
      tax_id:office.taxId||office.regId||null,
      branch:office.branch||'สำนักงานใหญ่',
      address:office.address||null,
      phone:office.phone||null,
      vat_registered:!!office.vat,
      owner_user_id:currentUser.id
    }).select('*').single();
    if(ins.error)throw ins.error;o=ins.data;
  }
  officeId=o.id;currentRole='owner';
  await s.from('office_members').upsert({office_id:officeId,user_id:currentUser.id,role:'owner'});
  return o;
}
async function loadRole(){
  var s=sb();if(!s||!currentUser)return;
  if(officeId){
    var own=await s.from('law_offices').select('id').eq('id',officeId).eq('owner_user_id',currentUser.id).maybeSingle();
    if(own.data){currentRole='owner';return}
    var m=await s.from('office_members').select('role').eq('office_id',officeId).eq('user_id',currentUser.id).maybeSingle();
    if(m.data)currentRole=m.data.role||'viewer';
  }
}
async function pull(){
  var s=sb();if(!s||!officeId||pulling)return;pulling=true;
  try{
    status('กำลังดึงข้อมูลจาก Cloud','warn');
    var r=await s.from('app_state').select('state,updated_at').eq('office_id',officeId).maybeSingle();
    if(r.error)throw r.error;
    var local=snapshot();
    if(r.data&&r.data.state&&Object.keys(r.data.state).length){
      var remote=JSON.stringify(r.data.state),here=JSON.stringify(local||{});
      if(remote!==here){
        localStorage.setItem('juslumeAccountingV3',remote);
        status('โหลดข้อมูล Cloud แล้ว','ok');
        setTimeout(function(){location.reload()},250);return;
      }
    }else if(local){
      await push(local,true);
    }
    status('Cloud พร้อม • '+currentRole,'ok');
  }catch(err){status('Cloud error: '+(err.message||err),'bad')}
  finally{pulling=false}
}
async function push(state,immediate){
  var s=sb();if(!s||!officeId||!currentUser||currentRole==='viewer')return;
  try{
    var r=await s.from('app_state').upsert({
      office_id:officeId,state:state||snapshot()||{},updated_by:currentUser.id,updated_at:new Date().toISOString()
    },{onConflict:'office_id'});
    if(r.error)throw r.error;
    status('บันทึก Cloud แล้ว','ok');
  }catch(err){status('Cloud sync ไม่สำเร็จ','bad');if(immediate)throw err}
}
function queuePush(state){
  if(!client||!officeId||currentRole==='viewer')return;
  clearTimeout(pushTimer);pushTimer=setTimeout(function(){push(state)},500);
}
async function signIn(){
  if(!cfg())return alert('กรุณากรอก Supabase Project URL และ Publishable/anon key ในตั้งค่าสำนักงานก่อน');
  if(!office.ownerEmail)return alert('กรุณากรอกอีเมลเจ้าของสำนักงานก่อน');
  var s=sb();var r=await s.auth.signInWithOtp({email:office.ownerEmail,options:{shouldCreateUser:true}});
  if(r.error)return alert('ส่ง OTP ไม่สำเร็จ: '+r.error.message);
  var step=document.getElementById('cloudOtpStep');if(step)step.classList.remove('hidden');
  status('ส่ง OTP ไปที่ '+office.ownerEmail,'warn');
}
async function verify(){
  var code=(document.getElementById('cloudOtp')||{}).value||'';if(!code.trim())return;
  var s=sb();var r=await s.auth.verifyOtp({email:office.ownerEmail,token:code.trim(),type:'email'});
  if(r.error)return alert('OTP ไม่ถูกต้องหรือหมดอายุ');
  await boot();
}
async function signOut(){var s=sb();if(s)await s.auth.signOut();currentUser=null;officeId=null;currentRole='offline';renderCloud();status('ออกจาก Cloud แล้ว','warn')}
async function boot(){
  var s=sb();if(!s){renderCloud();return}
  var g=await s.auth.getSession();currentUser=g.data&&g.data.session&&g.data.session.user||null;
  if(!currentUser){renderCloud();status('ยังไม่ได้เข้าสู่ Cloud','warn');return}
  try{await ensureOffice();await loadRole();renderCloud();await pull()}catch(err){renderCloud();status('ตั้งค่า Cloud ไม่สำเร็จ: '+(err.message||err),'bad')}
}
async function uploadFiles(input){
  var s=sb();if(!s||!officeId||!currentUser)return alert('กรุณาเข้าสู่ Cloud ก่อน');
  if(currentRole==='viewer')return alert('Viewer ไม่มีสิทธิ์อัปโหลดเอกสาร');
  var files=Array.from(input.files||[]);if(!files.length)return;
  for(const f of files){
    var safe=f.name.replace(/[^A-Za-z0-9._ก-๙-]/g,'_');
    var path=officeId+'/'+crypto.randomUUID()+'-'+safe;
    var up=await s.storage.from('law-office-documents').upload(path,f,{upsert:false});
    if(up.error){alert('อัปโหลด '+f.name+' ไม่สำเร็จ: '+up.error.message);continue}
    var d=await s.from('documents').insert({office_id:officeId,storage_path:path,file_name:f.name,mime_type:f.type||null,size_bytes:f.size,created_by:currentUser.id});
    if(d.error)alert('บันทึกทะเบียนไฟล์ไม่สำเร็จ: '+d.error.message);
  }
  await listDocs();input.value='';
}
async function listDocs(){
  var box=document.getElementById('cloudDocs');if(!box)return;
  var s=sb();if(!s||!officeId){box.innerHTML='<div class="small">กรุณาเข้าสู่ Cloud</div>';return}
  var r=await s.from('documents').select('id,file_name,mime_type,size_bytes,created_at,storage_path').eq('office_id',officeId).order('created_at',{ascending:false}).limit(100);
  if(r.error){box.innerHTML='<div class="small">'+r.error.message+'</div>';return}
  box.innerHTML=(r.data||[]).length?(r.data||[]).map(function(x){
    return '<tr><td>'+esc(x.file_name)+'</td><td>'+esc(x.mime_type||'—')+'</td><td>'+fmtSize(x.size_bytes)+'</td><td>'+new Date(x.created_at).toLocaleString('th-TH')+'</td><td><button class="iconBtn" data-path="'+esc(x.storage_path)+'" onclick="JuslumeCloud.download(this.dataset.path)">เปิด</button></td></tr>'
  }).join(''):'<tr><td colspan="5" class="small">ยังไม่มีเอกสาร</td></tr>';
}
async function download(path){
  var s=sb();if(!s)return;var r=await s.storage.from('law-office-documents').createSignedUrl(path,60);
  if(r.error)return alert(r.error.message);window.open(r.data.signedUrl,'_blank');
}
function fmtSize(b){b=Number(b||0);if(b<1024)return b+' B';if(b<1048576)return (b/1024).toFixed(1)+' KB';return (b/1048576).toFixed(1)+' MB'}
function esc(s){return String(s==null?'':s).replace(/[&<>"']/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]})}
function renderCloud(){
  var h=document.getElementById('v3Host');if(!h)return;
  document.querySelectorAll('.page').forEach(function(x){x.classList.add('hidden')});h.classList.remove('hidden');
  document.querySelectorAll('aside nav button').forEach(function(x){x.classList.remove('active')});var nb=document.querySelector('[data-cloud="1"]');if(nb)nb.classList.add('active');
  var logged=!!currentUser;
  h.innerHTML='<div class="topbar"><div><h1>Cloud & เอกสาร</h1><div class="sub">Supabase Auth • Database • Private Storage • Role-Based Access</div></div><div class="top-actions"><span id="cloudStatus" class="pill '+(logged?'ok':'warn')+'">'+(logged?'Cloud พร้อม • '+currentRole:'ยังไม่ได้เข้าสู่ Cloud')+'</span></div></div>'+
  '<div class="card"><div class="form-title">การเชื่อมต่อ</div><div class="small">Project: '+esc((office&&office.supabaseUrl)||'ยังไม่ได้ตั้งค่า')+'<br>ผู้ใช้: '+esc(currentUser&&currentUser.email||'—')+'<br>สิทธิ์: '+esc(currentRole)+'</div><div style="margin-top:14px" class="top-actions">'+
  (!logged?'<button class="btn primary" onclick="JuslumeCloud.signIn()">ส่ง OTP เข้าสู่ระบบ</button>':'<button class="btn" onclick="JuslumeCloud.pull()">ดึงข้อมูล Cloud</button><button class="btn" onclick="JuslumeCloud.pushNow()">บันทึกขึ้น Cloud</button><button class="btn danger" onclick="JuslumeCloud.signOut()">ออกจากระบบ</button>')+
  '</div><div id="cloudMembers" style="margin-top:14px"></div><div id="cloudOtpStep" class="hidden" style="margin-top:14px"><label>รหัส OTP<input id="cloudOtp" class="otpCode" inputmode="numeric"></label><button class="btn primary" style="margin-top:10px" onclick="JuslumeCloud.verify()">ยืนยัน OTP</button></div></div>'+
  '<div class="card" style="margin-top:14px"><div class="head"><h2>เอกสารสำนักงาน</h2></div><div class="filebox"><label>อัปโหลดเอกสาร<input type="file" multiple onchange="JuslumeCloud.uploadFiles(this)"></label><div class="hint">ไฟล์ถูกเก็บใน private Supabase Storage และเปิดผ่าน Signed URL ชั่วคราว</div></div><div class="v3table" style="margin-top:14px"><table><thead><tr><th>ชื่อไฟล์</th><th>ประเภท</th><th>ขนาด</th><th>วันที่</th><th></th></tr></thead><tbody id="cloudDocs"></tbody></table></div></div>';
  listDocs();listMembers();
}

async function listMembers(){
  var box=document.getElementById('cloudMembers');if(!box)return;
  if(!currentUser||!officeId){box.innerHTML='';return}
  var s=sb();var r=await s.rpc('list_office_members',{p_office:officeId});
  if(r.error){box.innerHTML='<div class="small">สมาชิก: '+esc(r.error.message)+'</div>';return}
  var rows=(r.data||[]).map(function(x){return '<tr><td>'+esc(x.email)+'</td><td>'+esc(x.role)+'</td><td>'+(currentRole==='owner'&&x.role!=='owner'?'<button class="iconBtn danger" data-user="'+esc(x.user_id)+'" onclick="JuslumeCloud.removeMember(this.dataset.user)">ลบสิทธิ์</button>':'—')+'</td></tr>'}).join('');
  box.innerHTML='<div class="head"><h2>ผู้ใช้งานสำนักงาน</h2></div>'+(currentRole==='owner'?'<div class="v3form"><label>อีเมล<input id="memberEmail" type="email"></label><label>สิทธิ์<select id="memberRole"><option value="viewer">Viewer — ดูอย่างเดียว</option><option value="editor">Editor — เพิ่ม/แก้ไข</option></select></label><label style="align-self:end"><button class="btn primary" onclick="JuslumeCloud.addMember()">เพิ่มผู้ใช้</button></label></div><div class="hint">อีเมลนั้นต้องเข้าสู่ระบบด้วย OTP อย่างน้อย 1 ครั้งก่อนจึงเพิ่มสิทธิ์ได้</div>':'')+'<div class="v3table" style="margin-top:10px"><table><thead><tr><th>อีเมล</th><th>สิทธิ์</th><th></th></tr></thead><tbody>'+(rows||'<tr><td colspan="3">ยังไม่มีสมาชิก</td></tr>')+'</tbody></table></div>';
}
async function addMember(){
  if(currentRole!=='owner')return alert('เฉพาะ Owner เท่านั้น');
  var email=(document.getElementById('memberEmail')||{}).value||'',role=(document.getElementById('memberRole')||{}).value||'viewer';
  if(!email.trim())return alert('กรุณาระบุอีเมล');
  var r=await sb().rpc('add_office_member_by_email',{p_office:officeId,p_email:email.trim(),p_role:role});
  if(r.error)return alert('เพิ่มผู้ใช้ไม่สำเร็จ: '+r.error.message);
  await listMembers();
}
async function removeMember(userId){
  if(currentRole!=='owner')return alert('เฉพาะ Owner เท่านั้น');
  if(!confirm('ยืนยันลบสิทธิ์ผู้ใช้นี้?'))return;
  var r=await sb().rpc('remove_office_member',{p_office:officeId,p_user:userId});
  if(r.error)return alert(r.error.message);await listMembers();
}

function addNav(){
  var nav=document.querySelector('aside nav');if(!nav||nav.querySelector('[data-cloud]'))return;
  var b=document.createElement('button');b.textContent='Cloud & เอกสาร';b.dataset.cloud='1';b.onclick=renderCloud;nav.appendChild(b)
}
async function refreshAfterV3(){addNav();await boot()}
window.JuslumeCloud={queuePush:queuePush,signIn:signIn,verify:verify,signOut:signOut,pull:pull,pushNow:function(){return push(snapshot(),true)},uploadFiles:uploadFiles,download:download,render:renderCloud,boot:boot,getOfficeId:function(){return officeId},getRole:function(){return currentRole},addMember:addMember,removeMember:removeMember,listMembers:listMembers};
setTimeout(refreshAfterV3,0);
})();
