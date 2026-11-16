// Lansatorul ACM OS: grilă cu toate aplicațiile (cele folosite des primele), căutare, oprire, modul copii.
// Stă în bara de sus (sigiliul ACM) și primul în dock (iconița de grilă).
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    readonly property string bin: "/opt/acm-os/system/bin/"
    readonly property color ink: Kirigami.Theme.textColor
    readonly property color ink2: Kirigami.Theme.disabledTextColor
    readonly property color accent: Kirigami.Theme.highlightColor
    property var apps: []
    property string query: ""
    property var callbacks: ({})

    switchWidth: 0; switchHeight: 0
    toolTipMainText: "Aplicații"
    toolTipSubText: "Toate aplicațiile ACM OS"

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
    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }

    function load() {
        run(bin + "acm-apps", function (out) {
            var list = [];
            out.split("\n").forEach(function (l) {
                if (l.indexOf("app=") !== 0) return;
                var p = l.slice(4).split("|");
                list.push({ id: p[0], name: p[1], icon: p[2], file: p[3], uses: parseInt(p[4]) || 0 });
            });
            list.sort(function (a, b) { return a.name.localeCompare(b.name, "ro") });
            root.apps = list;
        })
    }
    function norm(s) {
        s = String(s).toLowerCase();
        try { return s.normalize("NFD").replace(/[̀-ͯ]/g, "") } catch (e) { return s }
    }
    readonly property var frequent: apps.filter(function (a) { return a.uses > 0 })
                                        .sort(function (a, b) { return b.uses - a.uses }).slice(0, 6)
    readonly property var shown: query === "" ? apps
        : apps.filter(function (a) { return norm(a.name).indexOf(norm(query)) >= 0 || norm(a.id).indexOf(norm(query)) >= 0 })
    function open(a) { root.expanded = false; run(bin + "acm-apps open " + q(a.file), load) }

    onExpandedChanged: if (expanded) { query = ""; load() }
    Component.onCompleted: load()

    compactRepresentation: MouseArea {
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.preferredWidth: height
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        Kirigami.Icon {
            anchors.fill: parent
            anchors.margins: Plasmoid.formFactor === PlasmaCore.Types.Horizontal && parent.height < 48 ? 1 : 4
            source: Plasmoid.configuration.icon
            active: parent.containsMouse
        }
    }

    component Tile: Item {
        id: tile
        property var app
        width: 112; height: 104
        Rectangle {
            anchors.fill: parent; anchors.margins: 3; radius: 14
            color: tma.containsMouse ? Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.08) : "transparent"
        }
        ColumnLayout {
            anchors.centerIn: parent; spacing: 6; width: parent.width - 12
            Kirigami.Icon { Layout.alignment: Qt.AlignHCenter; implicitWidth: 52; implicitHeight: 52; source: tile.app ? tile.app.icon : "" }
            Text {
                Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                text: tile.app ? tile.app.name : ""; color: root.ink; font.pixelSize: 12
                elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap
            }
        }
        MouseArea { id: tma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.open(tile.app) }
    }
    component Power: MouseArea {
        property string label
        property string icon
        property string cmd
        implicitWidth: prow.implicitWidth + 24; implicitHeight: 34
        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onClicked: { root.expanded = false; root.run(cmd) }
        Rectangle { anchors.fill: parent; radius: 9; color: parent.containsMouse ? Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.08) : "transparent" }
        RowLayout {
            id: prow; anchors.centerIn: parent; spacing: 6
            Kirigami.Icon { implicitWidth: 16; implicitHeight: 16; source: icon }
            Text { text: label; color: root.ink; font.pixelSize: 13 }
        }
    }

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: 800; Layout.preferredHeight: 560
        Layout.minimumWidth: 600; Layout.minimumHeight: 420
        spacing: 12

        PlasmaComponents3.TextField {
            id: search
            Layout.fillWidth: true; Layout.margins: 6
            placeholderText: "Caută o aplicație…"
            font.pixelSize: 16
            text: root.query
            onTextChanged: root.query = text
            focus: true
            Keys.onReturnPressed: if (root.shown.length) root.open(root.shown[0])
            Connections { target: root; function onExpandedChanged() { if (root.expanded) search.forceActiveFocus() } }
        }

        Flickable {
            Layout.fillWidth: true; Layout.fillHeight: true
            contentHeight: body.implicitHeight; clip: true
            ColumnLayout {
                id: body; width: parent.width; spacing: 6
                Text {
                    visible: root.query === "" && root.frequent.length > 0
                    text: "FOLOSITE DES"; color: root.ink2; font.pixelSize: 11; font.letterSpacing: 2; Layout.leftMargin: 10
                }
                Flow {
                    visible: root.query === "" && root.frequent.length > 0
                    Layout.fillWidth: true
                    Repeater { model: root.frequent; delegate: Tile { required property var modelData; app: modelData } }
                }
                Text {
                    text: root.query === "" ? "TOATE APLICAȚIILE" : (root.shown.length ? "REZULTATE" : "Nicio aplicație găsită")
                    color: root.ink2; font.pixelSize: 11; font.letterSpacing: 2; Layout.leftMargin: 10; Layout.topMargin: 6
                }
                Flow {
                    Layout.fillWidth: true
                    Repeater { model: root.shown; delegate: Tile { required property var modelData; app: modelData } }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.1) }
        RowLayout {
            Layout.fillWidth: true; spacing: 4
            Power { label: "Mod copii"; icon: "face-smile"; cmd: "pkexec " + root.bin + "acm-kids-on && busctl --user call org.kde.Shutdown /Shutdown org.kde.Shutdown logout" }
            Item { Layout.fillWidth: true }
            Power { label: "Somn"; icon: "system-suspend"; cmd: "systemctl suspend" }
            Power { label: "Repornește"; icon: "system-reboot"; cmd: "systemctl reboot" }
            Power { label: "Oprește"; icon: "system-shutdown"; cmd: "systemctl poweroff" }
        }
    }
}
