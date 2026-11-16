// Generat de tools/gen-themes.js — nu edita de mână.
var top = new Panel;
top.location = "top";
top.height = 40;
top.floating = false;
var menu = top.addWidget("com.acm.launchpad");
menu.globalShortcut = "Alt+F1";
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
var pad = dock.addWidget("com.acm.launchpad");
pad.currentConfigGroup = ["General"];
pad.writeConfig("icon", "acm-launchpad");
var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", ["applications:org.kde.dolphin.desktop", "applications:google-chrome.desktop",
  "applications:org.kde.konsole.desktop", "applications:acm-claude.desktop", "applications:org.kde.gwenview.desktop",
  "applications:acm-actualizari.desktop", "applications:org.kde.plasmawindowed.desktop"]);
tasks.writeConfig("showOnlyCurrentDesktop", "false");
dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.trash");

var all = desktops();
for (var i = 0; i < all.length; i++) {
  var d = all[i];
  d.wallpaperPlugin = "org.kde.image";
  d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
  d.writeConfig("Image", "file:///usr/share/wallpapers/ACM-Obsidian/");
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
