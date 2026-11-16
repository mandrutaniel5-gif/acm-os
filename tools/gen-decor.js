// Decorația ferestrelor (Aurorae, cu bulinele roșu/galben/verde) și temele de iconițe ACM.
// Apelat din gen-themes.js.
const fs = require('fs'), path = require('path');

// Iconițele din machete (design/common.js), viewBox 30x30.
const ICONS = {
  files: '<path d="M4 9a2 2 0 0 1 2-2h6l2 2.5h10a2 2 0 0 1 2 2V22a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z" fill="#7fb3e8"/><path d="M4 12h22v10a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z" fill="#a6cdf3"/>',
  term: '<rect x="3" y="5" width="24" height="20" rx="4" fill="#1b1b1c"/><path d="M8 11l4 3.5L8 18" stroke="#BD9A6A" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/><path d="M14 19h7" stroke="#e8e6e1" stroke-width="2" stroke-linecap="round"/>',
  update: '<circle cx="15" cy="15" r="12" fill="#BD9A6A"/><path d="M21 12.5A6.5 6.5 0 1 0 21.3 18" stroke="#111" stroke-width="2" fill="none" stroke-linecap="round"/><path d="M21.6 8.5v4.4h-4.4" stroke="#111" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
  settings: '<circle cx="15" cy="15" r="12" fill="#8e8e93"/><circle cx="15" cy="15" r="7" fill="none" stroke="#e9e9ec" stroke-width="2.4" stroke-dasharray="3 2.5"/><circle cx="15" cy="15" r="3.2" fill="#e9e9ec"/>',
  trash: '<path d="M8 9h14l-1.3 15a2 2 0 0 1-2 1.8h-7.4a2 2 0 0 1-2-1.8z" fill="#c9c6c0"/><rect x="6" y="6" width="18" height="3" rx="1.5" fill="#a9a59e"/>',
  trashFull: '<path d="M8 9h14l-1.3 15a2 2 0 0 1-2 1.8h-7.4a2 2 0 0 1-2-1.8z" fill="#c9c6c0"/><rect x="6" y="6" width="18" height="3" rx="1.5" fill="#a9a59e"/><path d="M11 13h8M11 17h8M11 21h6" stroke="#8e8a83" stroke-width="1.6" stroke-linecap="round"/>',
  launchpad: '<rect x="2" y="2" width="26" height="26" rx="7" fill="#2a2a2e"/>' +
    [7.5, 15, 22.5].map((y, r) => [7.5, 15, 22.5].map((x, c) =>
      `<circle cx="${x}" cy="${y}" r="2.6" fill="${['#ec6a5e', '#f4bf4f', '#61c554', '#5aa9e6', '#BD9A6A', '#9b6ad6', '#e8e6e1', '#6cb3b0', '#f28b54'][r * 3 + c]}"/>`).join('')).join(''),
  claude: '<rect x="2" y="2" width="26" height="26" rx="7" fill="#d97757"/>' +
    [0, 45, 90, 135].map(a => `<rect x="14" y="7" width="2" height="16" rx="1" fill="#fff" transform="rotate(${a} 15 15)"/>`).join(''),
};
const svg = body => `<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 30 30">${body}</svg>\n`;

// numele sub care caută aplicațiile iconițele lor
const APP_ICONS = {
  'apps/system-file-manager': 'files', 'apps/org.kde.dolphin': 'files',
  'apps/utilities-terminal': 'term', 'apps/org.kde.konsole': 'term',
  'apps/system-software-update': 'update',
  // nu „preferences-system”: iconițele preferences-system-* (Bluetooth, Wi-Fi…) ar cădea pe ea.
  // Setările primesc iconița prin /usr/local/share/applications/systemsettings.desktop.
  'apps/acm-setari': 'settings',
  'apps/acm-launchpad': 'launchpad', 'apps/acm-claude': 'claude',
  'places/user-trash': 'trash', 'places/user-trash-full': 'trashFull',
};

module.exports = function (THEMES, write, rgb) {
  const seal = n => fs.readFileSync(path.join(__dirname, '..', 'design', n), 'utf8');

  // --- teme de iconițe: ACM-Light (peste breeze) și ACM-Dark (peste breeze-dark)
  for (const [name, base, sealFile] of [['ACM-Light', 'breeze', 'sigiliu-pe-fundal-deschis.svg'],
                                         ['ACM-Dark', 'breeze-dark', 'sigiliu-pe-fundal-inchis.svg']]) {
    write(`icons/${name}/index.theme`, `[Icon Theme]
Name=${name.replace('-', ' ')}
Comment=Iconițele ACM OS
Inherits=${base},hicolor
Directories=apps/scalable,places/scalable

[apps/scalable]
Size=48
MinSize=16
MaxSize=512
Type=Scalable
Context=Applications

[places/scalable]
Size=48
MinSize=16
MaxSize=512
Type=Scalable
Context=Places
`);
    for (const [file, key] of Object.entries(APP_ICONS)) {
      const [ctx, icon] = file.split('/');
      write(`icons/${name}/${ctx}/scalable/${icon}.svg`, svg(ICONS[key]));
    }
    // sigiliul din bara de sus: deschis pe teme închise, închis pe tema luminoasă
    write(`icons/${name}/apps/scalable/acm-os.svg`, seal(sealFile));
    // butonul de meniu din bara de sus: același sigiliu, decupat strâns ca să umple butonul
    write(`icons/${name}/apps/scalable/acm-meniu.svg`, seal(sealFile).replace(/viewBox="[^"]*"/, 'viewBox="24 24 352 352"'));
  }

  // --- decorația ferestrelor
  for (const t of Object.values(THEMES)) {
    const dir = `aurorae/themes/ACM${t.name}`, hd = t.header;
    write(`${dir}/metadata.desktop`, `[Desktop Entry]
Name=ACM ${t.name}
X-KDE-PluginInfo-Name=ACM${t.name}
X-KDE-PluginInfo-Author=ACM
X-KDE-PluginInfo-License=GPL
X-KDE-PluginInfo-Version=0.2
`);
    write(`${dir}/metadata.json`, JSON.stringify({ KPlugin: { Id: `ACM${t.name}`, Name: `ACM ${t.name}`, Authors: [{ Name: 'ACM' }], License: 'GPL' } }, null, 2));

    // cadru 3x3 de 8px; colțurile de sus rotunjite. Laturile și josul stau sub fereastră (BorderLeft/Right/Bottom=0).
    const cell = (id, x, y, d) => d
      ? `<path id="${id}" d="${d}" fill="${hd}"/>`
      : `<rect id="${id}" x="${x}" y="${y}" width="8" height="8" fill="${hd}"/>`;
    const frame = p => [
      cell(p + 'topleft', 0, 0, 'M0 8 A8 8 0 0 1 8 0 L8 8 Z'), cell(p + 'top', 8, 0),
      cell(p + 'topright', 16, 0, 'M16 0 A8 8 0 0 1 24 8 L16 8 Z'),
      cell(p + 'left', 0, 8), cell(p + 'center', 8, 8), cell(p + 'right', 16, 8),
      cell(p + 'bottomleft', 0, 16), cell(p + 'bottom', 8, 16), cell(p + 'bottomright', 16, 16),
    ].join('\n');
    write(`${dir}/decoration.svg`, `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24">
${frame('decoration-')}
${frame('decoration-inactive-')}
</svg>
`);

    const off = t.dark ? '#4a4a4d' : '#cfcac1';
    const button = (color, glyph) => {
      const state = (id, x, fill, withGlyph) => `<g id="${id}"><rect x="${x}" y="0" width="14" height="14" fill="none"/>` +
        `<circle cx="${x + 7}" cy="7" r="6" fill="${fill}"/>` +
        (withGlyph ? `<path d="${glyph(x)}" stroke="#4d0000" stroke-opacity=".7" stroke-width="1.4" stroke-linecap="round" fill="none"/>` : '') +
        '</g>';
      return `<svg xmlns="http://www.w3.org/2000/svg" width="70" height="14">` +
        state('active-center', 0, color) + state('hover-center', 14, color, true) + state('pressed-center', 28, color, true) +
        state('inactive-center', 42, off) + state('deactivated-center', 56, off) + '</svg>\n';
    };
    write(`${dir}/close.svg`, button('#ec6a5e', x => `M${x + 4.5} 4.5 L${x + 9.5} 9.5 M${x + 9.5} 4.5 L${x + 4.5} 9.5`));
    write(`${dir}/minimize.svg`, button('#f4bf4f', x => `M${x + 4} 7 H${x + 10}`));
    write(`${dir}/maximize.svg`, button('#61c554', x => `M${x + 7} 4 V10 M${x + 4} 7 H${x + 10}`));
    write(`${dir}/restore.svg`, button('#61c554', x => `M${x + 4} 7 H${x + 10}`));
    write(`${dir}/ACM${t.name}rc`, `[General]
ActiveTextColor=${rgb(t.ink)}
InactiveTextColor=${rgb(t.ink2)}
TitleAlignment=Center
TitleVerticalAlignment=Center
Animation=0
UseTextShadow=false
Shadow=true

[Layout]
BorderLeft=0
BorderRight=0
BorderBottom=0
TitleEdgeTop=0
TitleEdgeBottom=0
TitleEdgeLeft=12
TitleEdgeRight=12
TitleBorderLeft=8
TitleBorderRight=8
TitleHeight=30
ButtonWidth=14
ButtonHeight=14
ButtonSpacing=8
ButtonMarginTop=8
ExplicitButtonSpacer=10
PaddingTop=0
PaddingBottom=0
PaddingLeft=0
PaddingRight=0
`);
  }
};
