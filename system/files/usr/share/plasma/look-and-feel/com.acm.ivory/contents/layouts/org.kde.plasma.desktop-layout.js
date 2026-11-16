// Generat de tools/gen-themes.js — nu edita de mână.
var top = new Panel;
top.location = "top";
top.height = 28;
var menu = top.addWidget("org.kde.plasma.kickoff");
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "acm-os");
top.addWidget("org.kde.plasma.appmenu");
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");
var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "true");
clock.writeConfig("dateDisplayFormat", "BesideTime");

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
  "applications:org.kde.konsole.desktop", "applications:acm-actualizari.desktop", "applications:systemsettings.desktop"]);
tasks.writeConfig("showOnlyCurrentDesktop", "false");
dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.trash");

var all = desktops();
for (var i = 0; i < all.length; i++) {
  var d = all[i];
  d.wallpaperPlugin = "org.kde.image";
  d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
  d.writeConfig("Image", "file:///usr/share/wallpapers/ACM-Ivory/");
  if (i === 0) {
    var g = screenGeometry(d.screen);
    var x = g.width - 270;
    d.addWidget("org.kde.plasma.digitalclock", x, 50, 250, 120);
    d.addWidget("org.kde.plasma.battery", x, 185, 250, 110);
    d.addWidget("org.kde.plasma.systemmonitor.memory", x, 310, 250, 150);
  }
}
