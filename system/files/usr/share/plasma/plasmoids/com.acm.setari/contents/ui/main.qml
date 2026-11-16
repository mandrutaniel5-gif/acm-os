// Setările ACM OS, ca în machete: bară laterală + pagini Aspect, Baterie, Actualizări, Despre.
// Rulează în fereastră proprie prin `plasmawindowed com.acm.setari` (vezi system/bin/acm-setari).
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    readonly property string bin: "/opt/acm-os/system/bin/"
    readonly property color ink: Kirigami.Theme.textColor
    readonly property color ink2: Kirigami.Theme.disabledTextColor
    readonly property color bg: Kirigami.Theme.backgroundColor
    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property color danger: "#d9534f"
    readonly property bool darkBg: (bg.r + bg.g + bg.b) / 3 < 0.5
    readonly property color card: darkBg ? Qt.lighter(bg, 1.35) : Qt.darker(bg, 1.04)
    readonly property color line: Qt.rgba(ink.r, ink.g, ink.b, 0.08)

    property string page: "aspect"
    property var look: ({})
    property var bat: ({})
    property var upd: ({})
    property var about: ({})
    property var wifi: ({ state: "", nets: [] })
    property var bt: ({ state: "", devs: [] })
    property var snd: ({})
    property string pickSsid: ""
    property string wifiMsg: ""
    property bool btBusy: false
    property bool updBusy: false
    property string updLine: ""
    // actualizare prin pkexec (regula polkit ACM: fără parolă pentru utilizatorul principal); progresul vine din jurnal
    function updRun(what) {
        if (updBusy) return;
        updBusy = true; updLine = "Pornesc…";
        run("pkexec /opt/acm-os/system/bin/acm-update " + what + " > $HOME/.cache/acm/update.log 2>&1; echo \"cod=$?\"", function (o) {
            root.updBusy = false;
            root.updLine = o.indexOf("cod=0") >= 0
                ? (what === "apply" ? "ACM OS e la zi. Repornește laptopul când vrei." : "Am revenit la versiunea de dinainte. Repornește laptopul.")
                : "Nu a mers. Încearcă din nou cu internetul pornit.";
            root.loadUpd();
        })
    }
    Timer {
        interval: 1500; repeat: true; running: root.updBusy
        onTriggered: root.run("tail -n 40 $HOME/.cache/acm/update.log 2>/dev/null | tr '\\r' '\\n' | grep -v '^\\s*$' | sed 's/\\x1b\\[[0-9;]*m//g' | tail -n 1",
                              function (o) { if (root.updBusy && o.trim() !== "") root.updLine = o.trim() })
    }
    property bool confirmDoctor: false
    property bool nearLaptop: false
    property var callbacks: ({})

    P5Support.DataSource {
        id: sh
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            var cb = root.callbacks[source];
            delete root.callbacks[source];
            disconnectSource(source);
            if (cb) cb(data["stdout"] || "");
        }
    }
    function run(cmd, cb) { callbacks[cmd] = cb || null; sh.connectSource(cmd) }
    function kv(out) {
        var o = {};
        out.split("\n").forEach(function (l) { var i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1) });
        return o;
    }
    function loadLook() { run(bin + "acm-theme status", function (o) { root.look = kv(o) }) }
    function loadBat() { run(bin + "acm-battery info", function (o) { root.bat = kv(o) }) }
    function loadUpd() {
        run("sed -n 's/^VERSION=//p' /etc/acm-release; " + bin + "acm-update check", function (o) {
            var l = o.split("\n");
            root.upd = { version: l[0], text: l.slice(1).join(" ").trim() };
        })
    }
    function loadAbout() {
        run("echo model=$(cat /sys/class/dmi/id/product_name 2>/dev/null); "
            + "echo cpu=$(sed -n 's/^model name[[:space:]]*: *//p' /proc/cpuinfo | head -n1); "
            + "echo ram=$(awk '/MemTotal/{printf \"%.1f GB\", $2/1048576}' /proc/meminfo); "
            + "echo disk=$(df -h / | awk 'NR==2{print $4 \" liberi din \" $2}'); "
            + "echo kernel=$(uname -r); echo version=$(sed -n 's/^VERSION=//p' /etc/acm-release); "
            + "echo boot=$(systemd-analyze 2>/dev/null | head -n1 | sed 's/^Startup finished in //'); "
            + "echo slow=$(systemd-analyze blame --no-pager 2>/dev/null | head -n3 | awk '{print $NF \" \" $1}' | paste -sd, | sed 's/,/, /g')",
            function (o) { root.about = kv(o) })
    }
    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function loadWifi() {
        run(bin + "acm-ctl wifi", function (o) {
            var w = { state: "", nets: [] };
            o.split("\n").forEach(function (l) {
                if (l.indexOf("wifi=") === 0) w.state = l.slice(5);
                if (l.indexOf("net=") === 0) {
                    var p = l.slice(4).split("|");
                    w.nets.push({ inuse: p[0] === "1", signal: parseInt(p[1]) || 0, secure: p[2] === "1", saved: p[3] === "1", ssid: p.slice(4).join("|") });
                }
            });
            w.nets.sort(function (a, b) { return (b.inuse - a.inuse) || (b.signal - a.signal) });
            root.wifi = w;
        })
    }
    function parseBt(o) {
        var b = { state: "", devs: [] };
        o.split("\n").forEach(function (l) {
            if (l.indexOf("bt=") === 0) b.state = l.slice(3);
            if (l.indexOf("dev=") === 0) {
                var p = l.slice(4).split("|");
                b.devs.push({ mac: p[0], paired: p[1] === "1", conn: p[2] === "1", name: p.slice(3).join("|") });
            }
        });
        root.bt = b; root.btBusy = false;
    }
    function loadBt() { run(bin + "acm-ctl bt", parseBt) }
    function btDo(cmd, mac) { btBusy = true; run(bin + "acm-ctl " + cmd + (mac ? " " + mac : ""), parseBt) }
    function loadSnd() { run(bin + "acm-ctl sound", function (o) { root.snd = kv(o) }) }
    function connectWifi(ssid, pw) {
        wifiMsg = "Mă conectez la " + ssid + "…";
        run((pw ? "printf '%s\n' " + q(pw) + " | " : "") + bin + "acm-ctl wifi-connect " + q(ssid) + (pw ? " -" : ""), function (o) {
            var r = kv(o);
            root.wifiMsg = r.ok === "1" ? "" : "Nu m-am putut conecta. Verifică parola.";
            if (r.ok === "1") root.pickSsid = "";
            root.loadWifi();
        })
    }
    function go(p) {
        if (p === "toate") return run("systemsettings");
        page = p; confirmDoctor = false;
        if (p === "aspect") loadLook();
        if (p === "baterie") loadBat();
        if (p === "actualizari") loadUpd();
        if (p === "despre") loadAbout();
        if (p === "wifi") { pickSsid = ""; wifiMsg = ""; loadWifi(); }
        if (p === "bluetooth") loadBt();
        if (p === "sunet") loadSnd();
    }

    Component.onCompleted: {
        run("cat $HOME/.cache/acm/setari-page 2>/dev/null", function (o) { root.go(o.trim() || "aspect") });
        loadBat();
    }
    Timer { interval: 4000; repeat: true; running: true; onTriggered: root.loadBat() }
    Timer { interval: 8000; repeat: true; running: root.page === "wifi" && root.pickSsid === ""; onTriggered: root.loadWifi() }
    Timer { interval: 5000; repeat: true; running: root.page === "bluetooth" && !root.btBusy; onTriggered: root.loadBt() }

    // ---------- piese comune ----------
    component Lbl: Text { color: root.ink; font.pixelSize: 14; wrapMode: Text.WordWrap }
    component Title: Text { color: root.ink; font.pixelSize: 26; font.weight: Font.DemiBold; Layout.bottomMargin: 10 }
    component Box: Rectangle {
        default property alias content: col.data
        Layout.fillWidth: true
        implicitHeight: col.implicitHeight
        radius: 14; color: root.card; border.color: root.line
        ColumnLayout { id: col; anchors.left: parent.left; anchors.right: parent.right; spacing: 0 }
    }
    component Setting: Item {
        default property alias content: right.data
        property string label
        property string hint
        property bool last: false
        Layout.fillWidth: true
        implicitHeight: Math.max(56, left.implicitHeight + 24)
        ColumnLayout {
            id: left
            anchors.left: parent.left; anchors.leftMargin: 20; anchors.verticalCenter: parent.verticalCenter
            anchors.right: right.left; anchors.rightMargin: 16
            spacing: 2
            Lbl { text: label; Layout.fillWidth: true }
            Text { visible: hint !== ""; text: hint; color: root.ink2; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }
        RowLayout { id: right; anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; spacing: 10 }
        Rectangle { visible: !last; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: root.line }
    }
    component Segmented: Rectangle {
        id: segRoot
        property var options: []
        property int current: -1
        signal picked(int index)
        implicitWidth: seg.implicitWidth + 8; implicitHeight: 36
        radius: 10; color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.06)
        RowLayout {
            id: seg; anchors.centerIn: parent; spacing: 2
            Repeater {
                model: segRoot.options
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    implicitWidth: t.implicitWidth + 28; implicitHeight: 28; radius: 8
                    color: index === segRoot.current ? (root.darkBg ? Qt.lighter(root.card, 1.5) : "white") : "transparent"
                    Text { id: t; anchors.centerIn: parent; text: modelData; color: root.ink; font.pixelSize: 13; font.weight: index === segRoot.current ? Font.DemiBold : Font.Normal }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: segRoot.picked(index) }
                }
            }
        }
    }
    component Btn: Rectangle {
        property string text
        property bool primary: false
        property color tint: root.accent
        signal clicked()
        implicitWidth: bt.implicitWidth + 36; implicitHeight: 40; radius: 10
        color: primary ? tint : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, ma.containsMouse ? 0.12 : 0.07)
        opacity: ma.pressed ? 0.8 : 1
        Text { id: bt; anchors.centerIn: parent; text: parent.text; font.pixelSize: 14; font.weight: Font.DemiBold; color: primary ? "#111111" : root.ink }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }
    component Ring: Item {
        property real value: 0
        property color tint: root.accent
        implicitWidth: 76; implicitHeight: 76
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.12); strokeWidth: 8; fillColor: "transparent"
                PathAngleArc { centerX: 38; centerY: 38; radiusX: 32; radiusY: 32; startAngle: 0; sweepAngle: 360 }
            }
            ShapePath {
                strokeColor: tint; strokeWidth: 8; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: 38; centerY: 38; radiusX: 32; radiusY: 32; startAngle: -90; sweepAngle: 3.6 * Math.max(0, Math.min(100, value)) }
            }
        }
    }
    component KillSwitch: Rectangle {
        visible: root.bat.doctor === "running"
        Layout.fillWidth: true
        implicitHeight: 52; radius: 12; color: root.danger
        RowLayout {
            anchors.centerIn: parent; spacing: 10
            Rectangle { implicitWidth: 14; implicitHeight: 14; radius: 3; color: "white" }
            Text { text: "KILL SWITCH · OPREȘTE DOCTORUL"; color: "white"; font.pixelSize: 15; font.weight: Font.Bold; font.letterSpacing: 1 }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.run(root.bin + "acm-battery stop", root.loadBat) }
    }

    fullRepresentation: Rectangle {
        Layout.preferredWidth: 940; Layout.preferredHeight: 620
        Layout.minimumWidth: 780; Layout.minimumHeight: 520
        color: root.bg

        // ---------- bara laterală ----------
        Rectangle {
            id: side
            width: 240; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
            color: root.darkBg ? Qt.darker(root.bg, 1.15) : Qt.darker(root.bg, 1.03)
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: root.line }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 14; anchors.topMargin: 20; spacing: 4
                Repeater {
                    model: [
                        { id: "wifi", name: "Wi-Fi", icon: "network-wireless", tint: "#3b82f6" },
                        { id: "bluetooth", name: "Bluetooth", glyph: "ᛒ", tint: "#3b82f6" },
                        { id: "sunet", name: "Sunet", icon: "audio-volume-high", tint: "#e5484d" },
                        { id: "baterie", name: "Baterie", icon: "battery-full", tint: "#46a758" },
                        { id: "aspect", name: "Aspect", glyph: "◐", tint: "#BD9A6A" },
                        { id: "actualizari", name: "Actualizări", icon: "update-none", tint: "#8e8e93" },
                        { id: "despre", name: "Despre", icon: "help-about", tint: "#BD9A6A" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; implicitHeight: 44; radius: 10
                        color: root.page === modelData.id ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
                             : (ma2.containsMouse ? Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.05) : "transparent")
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; spacing: 12
                            Rectangle {
                                implicitWidth: 28; implicitHeight: 28; radius: 7; color: modelData.tint
                                Kirigami.Icon { visible: !modelData.glyph; anchors.centerIn: parent; width: 18; height: 18; source: modelData.icon || ""; isMask: true; color: "white" }
                                Text { visible: !!modelData.glyph; anchors.centerIn: parent; text: modelData.glyph || ""; color: "white"; font.pixelSize: 16; font.weight: Font.Bold }
                            }
                            Text { text: modelData.name; color: root.ink; font.pixelSize: 15; Layout.fillWidth: true }
                        }
                        MouseArea { id: ma2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.go(modelData.id) }
                    }
                }
                Item { Layout.fillHeight: true }
                // KILL SWITCH vizibil din orice pagină cât timp doctorul rulează
                KillSwitch { implicitHeight: 44; Layout.bottomMargin: 6 }
                Text {
                    text: "Toate setările sistemului ›"; color: root.ink2; font.pixelSize: 13; Layout.leftMargin: 12; Layout.bottomMargin: 6
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.go("toate") }
                }
            }
        }

        // ---------- conținut ----------
        Flickable {
            anchors.left: side.right; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
            contentHeight: pages.implicitHeight + 64
            clip: true
            ColumnLayout {
                id: pages
                x: 44; y: 32; width: parent.width - 88
                spacing: 18

                // ===== Wi-Fi =====
                ColumnLayout {
                    visible: root.page === "wifi"; Layout.fillWidth: true; spacing: 18
                    Title { text: "Wi-Fi" }
                    Box {
                        Setting {
                            label: "Wi-Fi"; last: true
                            hint: root.wifi.state === "enabled" ? "Parolele rețelelor se salvează în sistem: nu ți se mai cer la pornire." : ""
                            Segmented {
                                options: ["Oprit", "Pornit"]; current: root.wifi.state === "enabled" ? 1 : 0
                                onPicked: (i) => root.run(root.bin + "acm-ctl wifi-" + (i ? "on" : "off"), root.loadWifi)
                            }
                        }
                    }
                    Lbl { visible: root.wifiMsg !== ""; text: root.wifiMsg; color: root.accent; Layout.fillWidth: true }
                    Box {
                        visible: root.wifi.state === "enabled"
                        Repeater {
                            model: root.wifi.nets
                            delegate: ColumnLayout {
                                id: net
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true; spacing: 0
                                Setting {
                                    label: net.modelData.ssid
                                    hint: net.modelData.inuse ? "Conectat" : (net.modelData.saved ? "Salvată" : "")
                                    last: net.index === root.wifi.nets.length - 1 && root.pickSsid !== net.modelData.ssid
                                    Kirigami.Icon { visible: net.modelData.secure; implicitWidth: 14; implicitHeight: 14; source: "object-locked" }
                                    Text { text: net.modelData.signal + "%"; color: root.ink2; font.pixelSize: 13 }
                                    Btn {
                                        visible: !net.modelData.inuse
                                        text: "Conectează"
                                        onClicked: {
                                            if (net.modelData.secure && !net.modelData.saved) { root.pickSsid = net.modelData.ssid; root.wifiMsg = "" }
                                            else root.connectWifi(net.modelData.ssid, "")
                                        }
                                    }
                                    Btn { visible: net.modelData.saved; text: "Uită"; onClicked: root.run(root.bin + "acm-ctl wifi-forget " + root.q(net.modelData.ssid), root.loadWifi) }
                                }
                                RowLayout {
                                    visible: root.pickSsid === net.modelData.ssid
                                    Layout.fillWidth: true; Layout.margins: 16; spacing: 10
                                    PlasmaComponents3.TextField {
                                        id: pw; Layout.fillWidth: true
                                        placeholderText: "Parola rețelei"; echoMode: TextInput.Password
                                        onAccepted: root.connectWifi(net.modelData.ssid, text)
                                    }
                                    Btn { text: "Conectează"; primary: true; onClicked: root.connectWifi(net.modelData.ssid, pw.text) }
                                }
                            }
                        }
                        Lbl { visible: root.wifi.nets.length === 0; text: "Caut rețele…"; color: root.ink2; Layout.margins: 20 }
                    }
                }

                // ===== Bluetooth =====
                ColumnLayout {
                    visible: root.page === "bluetooth"; Layout.fillWidth: true; spacing: 18
                    Title { text: "Bluetooth" }
                    Box {
                        Setting {
                            label: "Bluetooth"; last: true
                            hint: root.bt.state === "absent" ? "Nu găsesc placa Bluetooth." : ""
                            Segmented {
                                visible: root.bt.state !== "absent"
                                options: ["Oprit", "Pornit"]; current: root.bt.state === "yes" ? 1 : 0
                                onPicked: (i) => root.btDo(i ? "bt-on" : "bt-off")
                            }
                        }
                    }
                    Box {
                        visible: root.bt.state === "yes"
                        Repeater {
                            model: root.bt.devs
                            delegate: Setting {
                                id: dev
                                required property var modelData
                                label: dev.modelData.name
                                hint: dev.modelData.conn ? "Conectat" : (dev.modelData.paired ? "Asociat" : "Disponibil")
                                Btn {
                                    text: dev.modelData.conn ? "Deconectează" : (dev.modelData.paired ? "Conectează" : "Asociază")
                                    onClicked: root.btDo(dev.modelData.conn ? "bt-disconnect" : (dev.modelData.paired ? "bt-connect" : "bt-pair"), dev.modelData.mac)
                                }
                                Btn { visible: dev.modelData.paired; text: "Uită"; onClicked: root.btDo("bt-remove", dev.modelData.mac) }
                            }
                        }
                        Setting {
                            label: root.btBusy ? "Lucrez…" : "Caută dispozitive noi (căști, mouse, boxe)"; last: true
                            Btn { text: "Caută"; primary: true; opacity: root.btBusy ? 0.4 : 1; onClicked: if (!root.btBusy) root.btDo("bt-scan") }
                        }
                    }
                }

                // ===== Sunet =====
                ColumnLayout {
                    visible: root.page === "sunet"; Layout.fillWidth: true; spacing: 18
                    Title { text: "Sunet" }
                    Box {
                        Setting {
                            label: "Volum"; hint: root.snd.output || ""
                            PlasmaComponents3.Slider {
                                implicitWidth: 240; from: 0; to: 100; stepSize: 5
                                value: parseInt(root.snd.volume) || 0
                                onMoved: root.run(root.bin + "acm-ctl volume " + Math.round(value), root.loadSnd)
                            }
                            Lbl { text: (root.snd.volume || "0") + "%"; Layout.preferredWidth: 44 }
                        }
                        Setting {
                            label: "Fără sunet"
                            Segmented {
                                options: ["Nu", "Da"]; current: root.snd.muted === "1" ? 1 : 0
                                onPicked: (i) => { if ((i === 1) !== (root.snd.muted === "1")) root.run(root.bin + "acm-ctl mute", root.loadSnd) }
                            }
                        }
                        Setting {
                            label: "Microfon"; last: true
                            PlasmaComponents3.Slider {
                                implicitWidth: 240; from: 0; to: 100; stepSize: 5
                                value: parseInt(root.snd.mic) || 0
                                onMoved: root.run(root.bin + "acm-ctl mic " + Math.round(value), root.loadSnd)
                            }
                            Lbl { text: (root.snd.mic || "0") + "%"; Layout.preferredWidth: 44 }
                        }
                    }
                }

                // ===== Aspect =====
                ColumnLayout {
                    visible: root.page === "aspect"; Layout.fillWidth: true; spacing: 18
                    Title { text: "Aspect" }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 18
                        Repeater {
                            model: [
                                { id: "ivory", name: "Ivory", bg: "#efe9df", win: "#fbfaf7", card: "#f7f4ee", bar: "#e4ddd1" },
                                { id: "obsidian", name: "Obsidian", bg: "#0e0e0f", win: "#18181a", card: "#26262a", bar: "#2c2c30" },
                                { id: "olive", name: "Olive", bg: "#2b2f26", win: "#23251f", card: "#3a3e33", bar: "#41463a" }
                            ]
                            delegate: ColumnLayout {
                                id: tcard
                                required property var modelData
                                Layout.fillWidth: true; spacing: 8
                                readonly property bool sel: (root.look.theme || "obsidian") === modelData.id
                                Rectangle {
                                    Layout.fillWidth: true; implicitHeight: width * 0.66; radius: 14
                                    color: modelData.bg
                                    border.width: sel ? 3 : 1; border.color: sel ? root.accent : root.line
                                    Rectangle { x: parent.width * 0.07; y: parent.height * 0.12; width: parent.width * 0.6; height: parent.height * 0.55; radius: 8; color: modelData.win
                                        Rectangle { x: 10; y: 12; width: parent.width * 0.35; height: 5; radius: 2.5; color: "#BD9A6A" } }
                                    Repeater { model: 3
                                        delegate: Rectangle { required property int index
                                            x: parent.width * 0.72; y: parent.height * (0.12 + index * 0.19); width: parent.width * 0.21; height: parent.height * 0.15; radius: 6; color: tcard.modelData.card } }
                                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height * 0.8; width: parent.width * 0.5; height: parent.height * 0.1; radius: 5; color: modelData.bar }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.look = Object.assign({}, root.look, { theme: modelData.id }); root.run(root.bin + "acm-theme " + modelData.id, root.loadLook) } }
                                }
                                Text { Layout.alignment: Qt.AlignHCenter; text: modelData.name; color: root.ink; font.pixelSize: 15; font.weight: sel ? Font.DemiBold : Font.Normal }
                            }
                        }
                    }
                    Box {
                        Setting {
                            label: "Schimbă tema automat"
                            Segmented {
                                options: ["Niciodată", "Ivory ziua, Obsidian seara"]
                                current: root.look.auto === "on" ? 1 : 0
                                onPicked: (i) => root.run(root.bin + "acm-theme auto " + (i ? "on" : "off"), root.loadLook)
                            }
                        }
                        Setting {
                            label: "Culoare accent"
                            Repeater {
                                model: ["#BD9A6A", "#6f8f6a", "#6b7fa8", "#c8645a", "#8e8e93"]
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool sel: (root.look.accent || "#BD9A6A").toLowerCase() === modelData.toLowerCase()
                                    implicitWidth: 26; implicitHeight: 26; radius: 13; color: modelData
                                    border.width: sel ? 3 : 0; border.color: root.darkBg ? "#f3f2ee" : "#121212"
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.run(root.bin + "acm-theme accent '" + modelData + "'", root.loadLook) }
                                }
                            }
                        }
                        Setting {
                            label: "Animații"
                            Segmented {
                                options: ["Oprite", "Rapide", "Line"]
                                current: root.look.anim === "0" ? 0 : (root.look.anim === "1" ? 2 : 1)
                                onPicked: (i) => root.run(root.bin + "acm-theme anim " + ["0", "0.5", "1"][i], root.loadLook)
                            }
                        }
                        Setting {
                            label: "Fundal, fonturi, cursor"; last: true
                            Btn { text: "Deschide"; onClicked: root.run("kcmshell6 kcm_fonts") }
                        }
                    }
                }

                // ===== Baterie =====
                ColumnLayout {
                    visible: root.page === "baterie"; Layout.fillWidth: true; spacing: 18
                    Title { text: "Baterie" }
                    KillSwitch {}
                    Box {
                        RowLayout {
                            Layout.fillWidth: true; Layout.margins: 20; spacing: 20
                            Ring { value: parseFloat(root.bat.level) || 0 }
                            ColumnLayout {
                                spacing: 4; Layout.fillWidth: true
                                Text {
                                    text: root.bat.present === "1" ? Math.round(parseFloat(root.bat.level) || 0) + "%" : "Nicio baterie detectată"
                                    color: root.ink; font.pixelSize: 24; font.weight: Font.DemiBold
                                }
                                Text {
                                    color: root.ink2; font.pixelSize: 14
                                    text: {
                                        var s = { "Charging": "Se încarcă", "Discharging": "Pe baterie", "Full": "Încărcată",
                                                  "Not charging": "Conectat, dar nu se încarcă" }[root.bat.status];
                                        return (s || (root.bat.charger === "1" ? "Conectat la încărcător" : "")) +
                                               (root.bat.model ? " · " + root.bat.model : "");
                                    }
                                }
                            }
                        }
                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.line }
                        Setting { label: "Sănătate (capacitate față de cea nouă)"; Lbl { text: root.bat.health ? root.bat.health + "%" : "—" } }
                        Setting { label: "Cicluri de încărcare"; Lbl { text: root.bat.cycles || "—" } }
                        Setting { label: "Tensiune"; Lbl { text: root.bat.voltage ? root.bat.voltage + " V (" + root.bat.cell + " V pe celulă)" : "—" } }
                        Setting { label: "Temperatură"; last: true
                            Lbl { text: root.bat.temp ? root.bat.temp + " °C" : "—"; color: parseInt(root.bat.temp) > 45 ? root.danger : root.ink } }
                    }

                    Box {
                        ColumnLayout {
                            Layout.fillWidth: true; Layout.margins: 20; spacing: 10
                            Text { text: "Doctor baterie"; color: root.ink; font.pixelSize: 18; font.weight: Font.DemiBold }
                            Lbl {
                                Layout.fillWidth: true; color: root.ink2
                                text: "Ține laptopul la încărcător pe etape tot mai lungi (10, 30, 60 de minute) și urmărește dacă bateria primește curent. "
                                    + "Se oprește singur peste 45 °C și nu pornește deloc dacă tensiunea e sub 2,0 V pe celulă. "
                                    + "Încărcarea o decide Mac-ul (cipul SMC); la final primești un verdict clar: bateria e bună, uzată sau trebuie înlocuită."
                            }
                            // stare în timpul rulării
                            ColumnLayout {
                                visible: root.bat.doctor === "running"; spacing: 4; Layout.topMargin: 6
                                Text { color: root.accent; font.pixelSize: 15; font.weight: Font.DemiBold
                                    text: root.bat.d_phase === "etapa" ? "Etapa " + root.bat.d_stage + " din " + root.bat.d_stages + " · " + root.bat.d_minutes + " min · până la " + root.bat.d_ends : "Verific bateria…" }
                                Text { color: root.ink2; font.pixelSize: 13
                                    text: "Nivel " + (root.bat.d_level || "—") + "% · " + (root.bat.d_temp || "—") + " °C · " + (root.bat.d_voltage || "—") + " V" }
                            }
                            // verdict
                            Rectangle {
                                visible: root.bat.doctor !== "running" && !!root.bat.d_verdict
                                Layout.fillWidth: true; implicitHeight: vt.implicitHeight + 24; radius: 10
                                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
                                Lbl { id: vt; anchors.fill: parent; anchors.margins: 12; text: root.bat.d_verdict || "" }
                            }
                            // pornire, cu confirmare
                            RowLayout {
                                visible: root.bat.doctor !== "running" && !root.confirmDoctor; spacing: 10; Layout.topMargin: 6
                                Btn { text: "Pornește doctorul"; primary: true; onClicked: root.confirmDoctor = true }
                            }
                            ColumnLayout {
                                visible: root.bat.doctor !== "running" && root.confirmDoctor; spacing: 10; Layout.topMargin: 6; Layout.fillWidth: true
                                Lbl {
                                    Layout.fillWidth: true; font.weight: Font.DemiBold
                                    text: root.bat.charger === "1" ? "Sigur pornești? Lasă încărcătorul conectat tot timpul. Butonul roșu KILL SWITCH îl oprește oricând."
                                                                   : "Conectează întâi încărcătorul."
                                }
                                RowLayout {
                                    spacing: 10
                                    Rectangle {
                                        implicitWidth: 22; implicitHeight: 22; radius: 6
                                        color: root.nearLaptop ? root.accent : "transparent"; border.width: 2; border.color: root.nearLaptop ? root.accent : root.ink2
                                        Text { anchors.centerIn: parent; text: "✓"; visible: root.nearLaptop; color: "#111"; font.pixelSize: 14; font.weight: Font.Bold }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.nearLaptop = !root.nearLaptop }
                                    }
                                    Lbl { text: "Sunt lângă laptop (permite și etapele de 2 și 4 ore)" }
                                }
                                RowLayout {
                                    spacing: 10
                                    Btn {
                                        text: "Da, pornește"; primary: true; opacity: root.bat.charger === "1" ? 1 : 0.4
                                        onClicked: if (root.bat.charger === "1") { root.confirmDoctor = false; root.run(root.bin + "acm-battery start" + (root.nearLaptop ? " lung" : ""), root.loadBat) }
                                    }
                                    Btn { text: "Renunț"; onClicked: root.confirmDoctor = false }
                                }
                            }
                        }
                    }

                    Box {
                        ColumnLayout {
                            Layout.fillWidth: true; Layout.margins: 20; spacing: 8
                            Text { text: "Nu se încarcă deloc? Resetează SMC-ul"; color: root.ink; font.pixelSize: 16; font.weight: Font.DemiBold }
                            Lbl {
                                Layout.fillWidth: true; color: root.ink2
                                text: "1. Oprește laptopul și conectează încărcătorul MagSafe.\n"
                                    + "2. Ține apăsate împreună Shift + Control + Option din stânga și butonul de pornire, 2 secunde.\n"
                                    + "3. Dă drumul tuturor tastelor deodată (lumina de pe încărcător poate clipi).\n"
                                    + "4. Pornește laptopul și rulează din nou doctorul."
                            }
                        }
                    }
                }

                // ===== Actualizări =====
                ColumnLayout {
                    visible: root.page === "actualizari"; Layout.fillWidth: true; spacing: 18
                    Title { text: "Actualizări" }
                    Box {
                        Setting { label: "Versiunea instalată"; Lbl { text: "ACM OS " + (root.upd.version || "") } }
                        Setting {
                            label: root.upd.text || "Verific pe GitHub…"; last: true
                            hint: "Actualizarea face întâi un punct de restaurare; o poți anula oricând."
                            Btn {
                                text: root.updBusy ? "Se instalează…" : "Actualizează acum"; primary: true; opacity: root.updBusy ? 0.5 : 1
                                onClicked: root.updRun("apply")
                            }
                        }
                    }
                    // progresul, fără terminal
                    Box {
                        visible: root.updBusy || root.updLine !== ""
                        ColumnLayout {
                            Layout.fillWidth: true; Layout.margins: 20; spacing: 6
                            Text { text: root.updBusy ? "Instalez… nu închide laptopul" : "Gata"; color: root.accent; font.pixelSize: 15; font.weight: Font.DemiBold }
                            Lbl { Layout.fillWidth: true; text: root.updLine; color: root.ink2; font.pixelSize: 13 }
                        }
                    }
                    Box {
                        Setting { label: "Verifică din nou"; Btn { text: "Verifică"; onClicked: { root.upd = { version: root.upd.version }; root.loadUpd() } } }
                        Setting { label: "Revino la versiunea de dinainte"; last: true
                            Btn { text: "Anulează ultima actualizare"; onClicked: root.updRun("rollback") } }
                    }
                }

                // ===== Despre =====
                ColumnLayout {
                    visible: root.page === "despre"; Layout.fillWidth: true; spacing: 18
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter; spacing: 6; Layout.topMargin: 10
                        Image { Layout.alignment: Qt.AlignHCenter; source: "file:///usr/share/pixmaps/acm-os.png"; sourceSize.width: 120; sourceSize.height: 120 }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "ACM OS " + (root.about.version || ""); color: root.ink; font.pixelSize: 26; font.weight: Font.DemiBold }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "FLAWLESS EXECUTION"; color: "#BD9A6A"; font.pixelSize: 12; font.letterSpacing: 4 }
                    }
                    Box {
                        Setting { label: "Calculator"; Lbl { text: root.about.model || "—" } }
                        Setting { label: "Procesor"; Lbl { text: root.about.cpu || "—" } }
                        Setting { label: "Memorie"; Lbl { text: root.about.ram || "—" } }
                        Setting { label: "Disc"; Lbl { text: root.about.disk || "—" } }
                        Setting { label: "Nucleu Linux"; Lbl { text: root.about.kernel || "—" } }
                        Setting { label: "Pornire"; Lbl { text: root.about.boot || "—"; Layout.maximumWidth: 360 } }
                        Setting { label: "Cel mai lent la pornire"; last: true; Lbl { text: root.about.slow || "—"; Layout.maximumWidth: 360 } }
                    }
                }
            }
        }
    }
}
