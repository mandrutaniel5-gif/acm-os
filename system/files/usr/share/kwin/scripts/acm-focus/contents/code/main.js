// La fiecare schimbare de fereastră, pornește acm-prio-focus@<pid>.service (sesiunea utilizatorului),
// care dă aplicației active prioritate și o notează pentru statistica de folosire.
function report(w) {
    if (!w || !(w.pid > 0)) return;
    callDBus("org.freedesktop.systemd1", "/org/freedesktop/systemd1", "org.freedesktop.systemd1.Manager",
             "StartUnit", "acm-prio-focus@" + w.pid + ".service", "replace");
}
workspace.windowActivated.connect(report);
report(workspace.activeWindow);
