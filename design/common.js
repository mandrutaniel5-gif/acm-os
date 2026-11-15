// Shared pieces for the ACM OS mockups: menu bar, dock and icons.
const ICONS = {
  files: `<svg viewBox="0 0 30 30"><path d="M4 9a2 2 0 0 1 2-2h6l2 2.5h10a2 2 0 0 1 2 2V22a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z" fill="#7fb3e8"/><path d="M4 12h22v10a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z" fill="#a6cdf3"/></svg>`,
  chrome: `<svg viewBox="0 0 30 30"><circle cx="15" cy="15" r="12" fill="#e2463a"/><path d="M15 15 L4.6 21 A12 12 0 0 0 21 25.4z" fill="#2fa45a"/><path d="M15 15 L21 25.4 A12 12 0 0 0 25.4 9H15z" fill="#f6c343"/><circle cx="15" cy="15" r="5.4" fill="#fff"/><circle cx="15" cy="15" r="4.2" fill="#3b7de0"/></svg>`,
  code: `<svg viewBox="0 0 30 30"><path d="M21 4l5 2.5v17L21 26 9 15z" fill="#2f8fd8"/><path d="M21 4L9 15l12 11V4z" fill="#58b0f0"/><path d="M4 11l3-1.5L21 21v5L4 19z" fill="#1f6fb0"/></svg>`,
  term: `<svg viewBox="0 0 30 30"><rect x="3" y="5" width="24" height="20" rx="4" fill="#1b1b1c"/><path d="M8 11l4 3.5L8 18" stroke="#BD9A6A" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/><path d="M14 19h7" stroke="#e8e6e1" stroke-width="2" stroke-linecap="round"/></svg>`,
  studio: `<svg viewBox="0 0 30 30"><circle cx="15" cy="15" r="12" fill="#111"/><path d="M15 6v10m0 0l-4-4m4 4l4-4" stroke="#BD9A6A" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round" transform="rotate(180 15 13)"/><path d="M9 21h12" stroke="#f3f2ee" stroke-width="2" stroke-linecap="round"/></svg>`,
  update: `<svg viewBox="0 0 30 30"><circle cx="15" cy="15" r="12" fill="#BD9A6A"/><path d="M21 12.5A6.5 6.5 0 1 0 21.3 18" stroke="#111" stroke-width="2" fill="none" stroke-linecap="round"/><path d="M21.6 8.5v4.4h-4.4" stroke="#111" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
  music: `<svg viewBox="0 0 30 30"><rect x="3" y="3" width="24" height="24" rx="6" fill="#f05a6e"/><path d="M12 20V9l9-2v11" stroke="#fff" stroke-width="2" fill="none"/><circle cx="10" cy="20" r="2.5" fill="#fff"/><circle cx="19" cy="18" r="2.5" fill="#fff"/></svg>`,
  settings: `<svg viewBox="0 0 30 30"><circle cx="15" cy="15" r="12" fill="#8e8e93"/><circle cx="15" cy="15" r="7" fill="none" stroke="#e9e9ec" stroke-width="2.4" stroke-dasharray="3 2.5"/><circle cx="15" cy="15" r="3.2" fill="#e9e9ec"/></svg>`,
  trash: `<svg viewBox="0 0 30 30"><path d="M8 9h14l-1.3 15a2 2 0 0 1-2 1.8h-7.4a2 2 0 0 1-2-1.8z" fill="#c9c6c0"/><rect x="6" y="6" width="18" height="3" rx="1.5" fill="#a9a59e"/></svg>`,
};

function menubar(appName, menus, sealFile) {
  return `<div class="menubar">
    <img class="seal" src="${sealFile}">
    <b>${appName}</b>${menus.map(m => `<span>${m}</span>`).join('')}
    <div class="right">
      <svg class="i" viewBox="0 0 16 16"><path d="M1.5 6a9.5 9.5 0 0 1 13 0M4 8.7a6 6 0 0 1 8 0M6.4 11.3a2.4 2.4 0 0 1 3.2 0"/><circle cx="8" cy="13.4" r=".6" fill="currentColor"/></svg>
      <svg class="i" viewBox="0 0 16 16"><path d="M2 6h2l3-3v10l-3-3H2z"/><path d="M10 5.5a3.5 3.5 0 0 1 0 5M12 3.8a6 6 0 0 1 0 8.4"/></svg>
      <span style="display:flex;align-items:center;gap:5px">100%<svg class="i" viewBox="0 0 24 16" style="width:24px"><rect x="1" y="3" width="19" height="10" rx="2.5"/><rect x="3" y="5" width="15" height="6" rx="1" fill="currentColor" stroke="none"/><path d="M22 6.5v3"/><path d="M11.6 4.5 8.6 8.6h3l-1.4 3" stroke="#111" stroke-width="1.3"/></svg></span>
      <svg class="i" viewBox="0 0 16 16"><circle cx="7" cy="7" r="4.5"/><path d="M10.5 10.5 14 14"/></svg>
      <span>Lun 16 nov.&nbsp; 21:41</span>
    </div></div>`;
}

function dock(running) {
  const main = ['files', 'chrome', 'code', 'term', 'studio', 'music', 'update', 'settings'];
  const cell = k => `<div class="app${running.includes(k) ? ' run' : ''}">${ICONS[k]}</div>`;
  return `<div class="dock">${main.map(cell).join('')}<div class="sep"></div>${cell('trash')}</div>`;
}
