// Generează schemele de culori și temele globale Plasma pentru Ivory, Obsidian și Olive.
// Rulare: node tools/gen-themes.js   (scrie în system/files/usr/share)
const fs = require('fs'), path = require('path');
const out = p => path.join(__dirname, '..', 'system', 'files', 'usr', 'share', p);
const write = (p, s) => { fs.mkdirSync(path.dirname(out(p)), { recursive: true }); fs.writeFileSync(out(p), s); };
const rgb = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16)).join(',');

const THEMES = {
  ivory:    { name: 'Ivory',    dark: false, win: '#f2efe9', view: '#fbfaf7', alt: '#ece7de', btn: '#ece7de', ink: '#121212', ink2: '#5f5a52', gold: '#BD9A6A', header: '#f7f5f0' },
  obsidian: { name: 'Obsidian', dark: true,  win: '#18181a', view: '#121213', alt: '#1e1e20', btn: '#26241f', ink: '#f3f2ee', ink2: '#a29c92', gold: '#C9A574', header: '#141415' },
  olive:    { name: 'Olive',    dark: true,  win: '#23251f', view: '#1c1e19', alt: '#2a2d25', btn: '#30342b', ink: '#f3f2ee', ink2: '#b2b3a6', gold: '#BD9A6A', header: '#1f211b' },
};

function colors(t) {
  const set = (bg, alt, fg) => `BackgroundAlternate=${rgb(alt)}
BackgroundNormal=${rgb(bg)}
DecorationFocus=${rgb(t.gold)}
DecorationHover=${rgb(t.gold)}
ForegroundActive=${rgb(t.gold)}
ForegroundInactive=${rgb(t.ink2)}
ForegroundLink=${rgb(t.gold)}
ForegroundNegative=218,68,83
ForegroundNeutral=224,163,58
ForegroundNormal=${rgb(fg)}
ForegroundPositive=76,175,106
ForegroundVisited=${rgb(t.ink2)}
`;
  return `[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
${set(t.btn, t.alt, t.ink)}
[Colors:Complementary]
${set('#111112', '#1e1e20', '#f3f2ee')}
[Colors:Header]
${set(t.header, t.alt, t.ink)}
[Colors:Selection]
${set(t.gold, t.gold, '#111111')}
[Colors:Tooltip]
${set(t.view, t.alt, t.ink)}
[Colors:View]
${set(t.view, t.alt, t.ink)}
[Colors:Window]
${set(t.win, t.alt, t.ink)}
[General]
ColorScheme=ACM${t.name}
Name=ACM ${t.name}
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground=${rgb(t.header)}
activeBlend=${rgb(t.ink)}
activeForeground=${rgb(t.ink)}
inactiveBackground=${rgb(t.header)}
inactiveBlend=${rgb(t.ink2)}
inactiveForeground=${rgb(t.ink2)}
`;
}

// Aranjamentul din machete: bară sus (sigiliu, meniu global, tray, ceas), dock plutitor jos,
// widget-uri în coloana din dreapta, fundalul temei.
function layout(t) {
  return `// Generat de tools/gen-themes.js — nu edita de mână.
var top = new Panel;
top.location = "top";
top.height = 36;
top.floating = false;
var menu = top.addWidget("org.kde.plasma.kickoff");
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "acm-meniu");
menu.writeConfig("favorites", ["google-chrome.desktop", "org.kde.dolphin.desktop", "org.kde.konsole.desktop",
  "acm-setari.desktop", "acm-actualizari.desktop"]);
top.addWidget("org.kde.plasma.appmenu");
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");
var search = top.addWidget("org.kde.plasma.icon");
search.currentConfigGroup = ["General"];
search.writeConfig("url", "file:///usr/share/applications/acm-cautare.desktop");
var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "true");
clock.writeConfig("dateDisplayFormat", "BesideTime");
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd d MMM");

var dock = new Panel;
dock.location = "bottom";
dock.height = 60;
dock.alignment = "center";
dock.lengthMode = "fit";
dock.floating = true;
dock.hiding = "none";
var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", ["applications:org.kde.dolphin.desktop", "applications:google-chrome.desktop",
  "applications:org.kde.konsole.desktop", "applications:acm-actualizari.desktop", "applications:acm-setari.desktop"]);
tasks.writeConfig("showOnlyCurrentDesktop", "false");
dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.trash");

var all = desktops();
for (var i = 0; i < all.length; i++) {
  var d = all[i];
  d.wallpaperPlugin = "org.kde.image";
  d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
  d.writeConfig("Image", "file:///usr/share/wallpapers/ACM-${t.name}/");
  if (i === 0) {
    // ecranul MacBook-ului e 1280x800; coloana de widget-uri stă în dreapta, ca în machete
    var x = 1010, geo = "";
    var items = [["com.acm.widgets", 48, 250, 560]];
    for (var k = 0; k < items.length; k++) {
      var it = items[k], w = d.addWidget(it[0], x, it[1], it[2], it[3]);
      geo += "Applet-" + w.id + ":" + x + "," + it[1] + "," + it[2] + "," + it[3] + ",0;";
    }
    d.currentConfigGroup = ["General"];
    d.writeConfig("ItemGeometries-1280x800", geo);
    d.writeConfig("ItemGeometriesHorizontal", geo);
  }
}
`;
}

for (const [id, t] of Object.entries(THEMES)) {
  write(`color-schemes/ACM${t.name}.colors`, colors(t));
  write(`wallpapers/ACM-${t.name}/metadata.json`, JSON.stringify({
    KPlugin: { Id: `ACM-${t.name}`, Name: `ACM ${t.name}`, Authors: [{ Name: 'ACM' }], License: 'CC-BY-SA-4.0' } }, null, 2));
  const lf = `plasma/look-and-feel/com.acm.${id}`;
  write(`${lf}/metadata.json`, JSON.stringify({
    KPackageStructure: 'Plasma/LookAndFeel',
    'X-Plasma-APIVersion': '2',
    KPlugin: { Id: `com.acm.${id}`, Name: `ACM ${t.name}`, Description: `Tema ${t.name} a ACM OS`,
      Authors: [{ Name: 'ACM' }], License: 'GPL-2.0+', Version: '0.2' } }, null, 2));
  write(`${lf}/contents/defaults`, `[kdeglobals][General]
ColorScheme=ACM${t.name}
AccentColor=${rgb(t.gold)}

[kdeglobals][Icons]
Theme=${t.dark ? 'ACM-Dark' : 'ACM-Light'}

[kdeglobals][KDE]
widgetStyle=Breeze

[plasmarc][Theme]
name=${t.dark ? 'breeze-dark' : 'default'}

[kcminputrc][Mouse]
cursorTheme=breeze_cursors

[kwinrc][org.kde.kdecoration2]
library=org.kde.kwin.aurorae
theme=__aurorae__svg__ACM${t.name}
ButtonsOnLeft=XIA
ButtonsOnRight=

[Wallpaper]
Image=ACM-${t.name}
`);
  write(`${lf}/contents/layouts/org.kde.plasma.desktop-layout.js`, layout(t));
}
// Konsole: câte o schemă de culori pe temă (terminalul deschis pe Ivory, închis pe Obsidian/Olive)
const ANSI = { dark: ['#1b1b1c', '#e0675a', '#7fb069', '#d9a85b', '#7d9fd1', '#b58cc6', '#6cb3b0', '#d8d5ce'],
               light: ['#2a2723', '#b6443a', '#4d7f3a', '#9a6c1e', '#3d64a3', '#81508f', '#2f7f7b', '#8a847a'] };
for (const t of Object.values(THEMES)) {
  const a = ANSI[t.dark ? 'dark' : 'light'];
  const c = (k, v) => `[${k}]\nColor=${rgb(v)}\n\n`;
  let cs = c('Background', t.view) + c('BackgroundIntense', t.view) + c('Foreground', t.ink) + c('ForegroundIntense', t.ink);
  a.forEach((v, i) => { cs += c(`Color${i}`, v) + c(`Color${i}Intense`, v); });
  write(`konsole/ACM-${t.name}.colorscheme`, cs + `[General]\nDescription=ACM ${t.name}\nOpacity=1\n`);
}
write('konsole/ACM.profile', `[Appearance]
ColorScheme=ACM-Obsidian
Font=JetBrains Mono,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1

[General]
Name=ACM
Parent=FALLBACK/
TerminalMargin=12
`);
require('./gen-decor')(THEMES, write, rgb);
console.log('teme generate:', Object.keys(THEMES).join(', '));
