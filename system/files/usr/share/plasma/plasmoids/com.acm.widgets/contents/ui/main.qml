// Widget-ul ACM de pe desktop: coloana de carduri din machete (ceas, baterie, proiecte, sistem).
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    readonly property color gold: "#BD9A6A"
    readonly property color ink: Kirigami.Theme.textColor
    readonly property color ink2: Kirigami.Theme.disabledTextColor
    property var info: ({})
    property date now: new Date()

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    P5Support.DataSource {
        id: shell
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            if (source.indexOf("acm-widget-info") >= 0) root.info = root.parse(data["stdout"])
            else refresh.restart()
            disconnectSource(source)
        }
    }
    Timer { id: refresh; interval: 1500; onTriggered: shell.connectSource("/opt/acm-os/system/bin/acm-widget-info") }
    Timer {
        interval: 20000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: shell.connectSource("/opt/acm-os/system/bin/acm-widget-info")
    }
    function parse(out) {
        var o = {};
        (out || "").split("\n").forEach(function (l) { var i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1); });
        return o;
    }
    function cap(s) { return s.length ? s.charAt(0).toUpperCase() + s.slice(1) : s }
    function batteryText() {
        if (!info.bat) return "Nu e detectată";
        var min = parseInt(info.batmin);
        var eta = min > 0 && min < 1000 ? " · " + (min >= 60 ? Math.floor(min / 60) + " h " + (min % 60) + " min" : min + " min") : "";
        if (info.batstate === "Charging") return "Se încarcă" + eta;
        if (info.batstate === "Full") return "Încărcată";
        if (info.batstate === "Not charging") return "Nu se încarcă";
        return "Pe baterie" + eta;
    }

    component Card: Rectangle {
        default property alias content: inner.data
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + 28
        radius: 16
        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.82)
        border.color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.08)
        ColumnLayout { id: inner; anchors.fill: parent; anchors.margins: 14; spacing: 4 }
    }
    component Line: RowLayout {
        property string label
        property string value
        property color valueColor: root.ink
        Layout.fillWidth: true
        Text { text: label; color: root.ink2; font.pixelSize: 13; Layout.fillWidth: true }
        Text { text: value; color: valueColor; font.pixelSize: 13 }
    }

    fullRepresentation: ColumnLayout {
        spacing: 12
        Layout.preferredWidth: 250

        Card {
            Text { text: root.cap(root.now.toLocaleDateString(Qt.locale("ro_RO"), "dddd, d MMMM")); color: root.ink2; font.pixelSize: 13 }
            Text { text: Qt.formatTime(root.now, "HH:mm"); color: root.ink; font.pixelSize: 40; font.weight: Font.Light }
            Text { text: "Oradea" + (root.info.weather ? " · " + root.info.weather : ""); color: root.ink2; font.pixelSize: 13 }
        }

        Card {
            RowLayout {
                spacing: 14
                Item {
                    implicitWidth: 52; implicitHeight: 52
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.12); strokeWidth: 6; fillColor: "transparent"
                            PathAngleArc { centerX: 26; centerY: 26; radiusX: 21; radiusY: 21; startAngle: 0; sweepAngle: 360 }
                        }
                        ShapePath {
                            strokeColor: root.gold; strokeWidth: 6; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                            PathAngleArc {
                                centerX: 26; centerY: 26; radiusX: 21; radiusY: 21; startAngle: -90
                                sweepAngle: 3.6 * (parseInt(root.info.bat) || 0)
                            }
                        }
                    }
                }
                ColumnLayout {
                    spacing: 2
                    Text { text: root.info.bat ? "Baterie " + root.info.bat + "%" : "Baterie"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Text { text: root.batteryText(); color: root.ink2; font.pixelSize: 13 }
                    Text {
                        visible: root.info.doctor === "running"
                        text: "Doctor baterie activ · OPREȘTE"
                        color: "#e0675a"; font.pixelSize: 12; font.weight: Font.DemiBold
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shell.connectSource("/opt/acm-os/system/bin/acm-battery stop") }
                    }
                }
            }
        }

        Card {
            RowLayout {
                Layout.fillWidth: true; Layout.bottomMargin: 4
                Text { text: "Proiecte"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true }
                Text { text: root.info.projcount || ""; visible: (root.info.projcount || "0") !== "0"; color: root.ink2; font.pixelSize: 13 }
            }
            Repeater {
                model: [root.info.proj0, root.info.proj1, root.info.proj2].filter(function (p) { return !!p })
                delegate: RowLayout {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Rectangle { implicitWidth: 8; implicitHeight: 8; radius: 4; color: [root.gold, "#6f8f6a", "#6b7fa8"][index % 3] }
                    Text { text: modelData.split("|")[0]; color: root.ink; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                    Text { text: modelData.split("|")[1]; color: root.ink2; font.pixelSize: 11 }
                }
            }
            Text { visible: !root.info.proj0; text: "Pune proiectele în ~/Proiecte"; color: root.ink2; font.pixelSize: 13 }
        }

        Card {
            Text { text: "Sistem"; color: root.ink; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.bottomMargin: 4 }
            Line { label: "Pornire"; value: root.info.boot ? root.info.boot + " s" : "—" }
            Line { label: "Memorie"; value: (root.info.memused || "—") + " / " + (root.info.memtotal || "—") + " GB" }
            Line {
                label: "ACM OS"
                value: root.info.available ? "actualizare " + root.info.available : (root.info.version || "") + " · la zi"
                valueColor: root.info.available ? root.gold : "#4caf6a"
            }
        }
        // cardurile stau strânse sus, ca în machete
        Item { Layout.fillHeight: true }
    }
}
