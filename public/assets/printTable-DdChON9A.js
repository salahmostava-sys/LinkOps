function e(e,t){let{title:n,subtitle:r}=t;if(!e||!(e instanceof HTMLTableElement))throw Error(`Invalid table element`);if(!t.title||typeof t.title!=`string`)throw Error(`Title is required`);let i=document.createElement(`iframe`);i.style.position=`fixed`,i.style.right=`0`,i.style.bottom=`0`,i.style.width=`0`,i.style.height=`0`,i.style.border=`none`,document.body.appendChild(i);let a=i.contentWindow?.document;if(!a)throw document.body.removeChild(i),Error(`Failed to create print iframe`);a.open(),a.close(),a.documentElement.lang=`ar`,a.documentElement.dir=`rtl`;let o=a.head,s=a.body;if(!o||!s)return;let c=a.createElement(`meta`);c.setAttribute(`charset`,`UTF-8`),o.appendChild(c);let l=a.createElement(`title`);l.textContent=n,o.appendChild(l);let u=a.createElement(`style`);u.textContent=`
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: Arial, sans-serif; font-size: 11px; direction: rtl; color: #111; background: white; }
    h2 { text-align: center; margin-bottom: 8px; font-size: 15px; }
    p.subtitle { text-align: center; color: #666; font-size: 11px; margin-bottom: 12px; }
    table { width: 100%; border-collapse: collapse; }
    th { background: #1e3a5f; color: white; padding: 6px 8px; text-align: right; font-size: 10px; white-space: nowrap; }
    td { padding: 5px 8px; border-bottom: 1px solid #e0e0e0; text-align: right; white-space: nowrap; vertical-align: middle; }
    tr:nth-child(even) td { background: #f9f9f9; }
    @media print {
      body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      .no-print-table-export { display: none !important; }
    }
  `,o.appendChild(u);let d=a.createElement(`h2`);if(d.textContent=n,s.appendChild(d),r){let e=a.createElement(`p`);e.className=`subtitle`,e.textContent=r,s.appendChild(e)}s.appendChild(e.cloneNode(!0));let f=i.contentWindow;f?(f.focus(),setTimeout(()=>{f.print(),setTimeout(()=>{document.body.contains(i)&&document.body.removeChild(i)},500)},200)):document.body.contains(i)&&document.body.removeChild(i)}export{e as t};