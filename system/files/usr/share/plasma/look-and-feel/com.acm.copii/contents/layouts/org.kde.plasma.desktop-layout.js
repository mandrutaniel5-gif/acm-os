// Generat de tools/gen-themes.js — nu edita de mână.
var top = new Panel;
top.location = "top";
top.height = 40;
top.floating = false;
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");
var clock = top.addWidget("org.kde.plasma.digitalclock");
var all = desktops();
for (var i = 0; i < all.length; i++) {
  var d = all[i];
  d.wallpaperPlugin = "org.kde.image";
  d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
  d.writeConfig("Image", "file:///usr/share/wallpapers/ACM-Ivory/");
  if (i === 0) {
    var w = d.addWidget("com.acm.copii", 40, 60, 1200, 700);
    var geo = "Applet-" + w.id + ":40,60,1200,700,0;";
    d.currentConfigGroup = ["General"];
    d.writeConfig("ItemGeometries-1280x800", geo);
    d.writeConfig("ItemGeometriesHorizontal", geo);
  }
}
locked = true;
