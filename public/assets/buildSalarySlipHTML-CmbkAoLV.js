import{t as e}from"./security-CP_eWown.js";import{t}from"./purify.es-hHWRYpDA.js";var n={ALLOWED_TAGS:[`div`,`span`,`img`,`h1`,`h2`,`h3`,`p`,`br`,`strong`,`em`,`small`,`table`,`tr`,`td`,`th`],ALLOWED_ATTR:[`class`,`style`,`src`,`alt`,`width`,`height`],FORBID_ATTR:[`onerror`,`onload`,`onclick`],ALLOW_DATA_ATTR:!1},r=e=>e?t.sanitize(e,n):``,i={pending:`معلّق`,approved:`معتمد`,paid:`مصروف`},a={pending:`badge-pending`,approved:`badge-approved`,paid:`badge-paid`},o={green:`#16a34a`,red:`#dc2626`,blue:`#2563eb`,orange:`#ea580c`},s=`@import url('https://fonts.googleapis.com/css2?family=Noto+Naskh+Arabic:wght@400;600;700&display=swap');
*{box-sizing:border-box;margin:0;padding:0}
html,body{direction:rtl;font-family:'Noto Naskh Arabic','Segoe UI',Tahoma,sans-serif;font-size:13px;color:#1a1a1a;background:#fff;padding:0}
.slip-container{max-width:700px;margin:0 auto;padding:24px}
.header{display:flex;align-items:center;justify-content:space-between;border-bottom:3px solid #4f46e5;padding-bottom:12px;margin-bottom:16px}
.header-brand{font-size:20px;font-weight:800;color:#4f46e5}
.header-subtitle{font-size:11px;color:#666;margin-top:2px}
.badge{display:inline-block;padding:2px 10px;border-radius:12px;font-size:11px;font-weight:700}
.badge-pending{background:#fef9c3;color:#b45309}
.badge-approved{background:#dbeafe;color:#1d4ed8}
.badge-paid{background:#dcfce7;color:#15803d}
.info-grid{display:grid;grid-template-columns:1fr 1fr;gap:6px;background:#f8f8ff;border-radius:8px;padding:12px;margin-bottom:14px}
.info-row{display:flex;flex-direction:column}
.info-label{font-size:10px;color:#888;margin-bottom:1px}
.info-value{font-size:12px;font-weight:600;color:#111}
.section-title{font-size:12px;font-weight:700;color:#4f46e5;margin:14px 0 6px;text-transform:uppercase;letter-spacing:.5px}
table{width:100%;border-collapse:collapse;margin-bottom:10px}
td,th{padding:7px 10px;border:1px solid #e5e7eb;font-size:12px;text-align:right}
th{background:#e0e7ff;color:#4338ca;font-weight:700;text-align:center}
.label-cell{background:#f3f4f6;font-weight:600;width:55%}
.value-cell{font-weight:700;text-align:center}
.total-row td{background:#eff6ff;font-weight:700;font-size:13px}
.deduction-total td{background:#fff1f2;font-weight:700}
.net-row td{background:#f0fdf4;font-size:16px;font-weight:800}
.risk-banner{margin-bottom:16px;padding:10px;border-radius:6px;font-size:12px;font-weight:700;display:flex;align-items:center;gap:8px}
.risk-underpaid{background:#fff1f2;color:#be123c;border:1px solid #fda4af}
.risk-overpaid{background:#f0f9ff;color:#0369a1;border:1px solid #bae6fd}
.footer{display:flex;justify-content:space-between;margin-top:28px;border-top:1px solid #ddd;padding-top:16px;font-size:11px;color:#555}
.signature-box{text-align:center}
.signature-line{width:120px;border-bottom:1px solid #999;display:inline-block;margin-bottom:4px;height:24px}
@media print{
  body{padding:0}
  .slip-container{padding:16px;max-width:100%}
  .no-print{display:none!important}
}`,c=t=>typeof t==`number`?t.toLocaleString(`en-US`):e(String(t)),l=e=>{if(!e)return``;let t=o[e];return t?`color:${t}`:``},u=(t,n,o)=>o?r(o):`
    <div class="header">
      <div>
        <div class="header-brand">${e(n||`كشف راتب شهري`)}</div>
        <div class="header-subtitle">${e(t.month)}</div>
      </div>
      <span class="badge ${a[t.status]||`badge-pending`}">${i[t.status]||t.status}</span>
    </div>`,d=e=>{if(!e||e.risk===`normal`)return``;let t=e.risk===`underpaid`?`تنبيه: ملاحظة انخفاض في المستحقات`:`تنبيه: ملاحظة زيادة في المستحقات`;return`<div class="risk-banner ${e.risk===`underpaid`?`risk-underpaid`:`risk-overpaid`}">
    <span>⚠️</span>
    <span>${t} (${e.diff_percent}%) — الراتب المتوقع: ${e.expected_salary} ر.س</span>
  </div>`},f=t=>t.length===0?``:`
    <div class="info-grid">
      ${t.map(t=>`
        <div class="info-row">
          <span class="info-label">${e(t.label)}</span>
          <span class="info-value">${c(t.value)}</span>
        </div>`).join(``)}
    </div>`,p=t=>{if(t.length===0)return``;let n=t.reduce((e,t)=>e+t.orders,0),r=t.reduce((e,t)=>e+t.salary,0);return`
    <div class="section-title">الطلبات والراتب حسب المنصة</div>
    <table>
      <tr>
        <th>المنصة</th>
        <th>الطلبات</th>
        <th>الراتب</th>
      </tr>
      ${t.map(t=>`
        <tr>
          <td class="label-cell">${e(t.name)}</td>
          <td class="value-cell">${c(t.orders)}</td>
          <td class="value-cell" style="color:#2563eb">${c(t.salary)} ر.س</td>
        </tr>`).join(``)}
      <tr class="total-row">
        <td class="label-cell">إجمالي المنصات</td>
        <td class="value-cell">${c(n)}</td>
        <td class="value-cell" style="color:#2563eb">${c(r)} ر.س</td>
      </tr>
    </table>`},m=(t,n)=>t.length===0?``:`
    <div class="section-title">الاستحقاقات</div>
    <table>
      ${t.map(t=>`
        <tr>
          <td class="label-cell">${e(t.label)}</td>
          <td class="value-cell" style="${l(t.color||`green`)}">${typeof t.value==`number`?`+ ${c(t.value)} ر.س`:c(t.value)}</td>
        </tr>`).join(``)}
      ${n.filter(e=>e.key.includes(`earning`)).map(t=>`
        <tr class="total-row">
          <td class="label-cell">${e(t.label)}</td>
          <td class="value-cell" style="${l(t.color||`blue`)}">${c(t.value)} ر.س</td>
        </tr>`).join(``)}
    </table>`,h=(t,n)=>t.length===0?``:`
    <div class="section-title">المستقطعات</div>
    <table>
      ${t.map(t=>`
        <tr>
          <td class="label-cell">${e(t.label)}</td>
          <td class="value-cell" style="${l(t.color||`red`)}">${typeof t.value==`number`&&t.value>0?`- ${c(t.value)} ر.س`:c(t.value)}</td>
        </tr>`).join(``)}
      ${n.filter(e=>e.key.includes(`deduction`)).map(t=>`
        <tr class="deduction-total">
          <td class="label-cell">${e(t.label)}</td>
          <td class="value-cell" style="${l(t.color||`red`)}">- ${c(t.value)} ر.س</td>
        </tr>`).join(``)}
    </table>`,g=t=>t.length===0?``:`
    <div class="section-title">الصافي</div>
    <table>
      ${t.map(t=>`
        <tr class="net-row">
          <td class="label-cell">${e(t.label)}</td>
          <td class="value-cell" style="${l(t.color||`green`)}">${c(t.value)} ر.س</td>
        </tr>`).join(``)}
    </table>`,_=t=>t.length===0?``:`
    <table>
      ${t.map(t=>`
        <tr>
          <td class="label-cell">${e(t.label)}</td>
          <td class="value-cell" style="${l(t.color)}">${c(t.value)} ر.س</td>
        </tr>`).join(``)}
    </table>`,v=e=>e?r(e):`
    <div class="footer">
      <div class="signature-box">
        <div class="signature-line"></div>
        <div>توقيع المندوب</div>
      </div>
      <div class="signature-box">
        <div class="signature-line"></div>
        <div>اعتماد الإدارة</div>
      </div>
      <div>التاريخ: ${new Date().toLocaleDateString(`ar-SA`)}</div>
    </div>`;function y(t){let{employee:n,fields:r,platforms:i,projectName:a,template:o,analysis:c}=t,l=o?.selected_columns&&o.selected_columns.length>0?r.filter(e=>o.selected_columns?.includes(e.key)||e.type===`total`||e.type===`net`):r,y=l.filter(e=>e.type===`info`),b=l.filter(e=>e.type===`earning`),x=l.filter(e=>e.type===`deduction`),S=l.filter(e=>e.type===`total`),C=l.filter(e=>e.type===`net`),w=S.filter(e=>!e.key.includes(`earning`)&&!e.key.includes(`deduction`));return`<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>كشف راتب — ${e(n.name)}</title>
  <style>${s}</style>
</head>
<body>
  <div class="slip-container">
    ${u(n,a,o?.header_html)}
    ${d(c)}
    ${f(y)}
    ${p(i)}
    ${m(b,S)}
    ${h(x,S)}
    ${g(C)}
    ${_(w)}
    ${v(o?.footer_html)}
  </div>
</body>
</html>`}export{y as t};