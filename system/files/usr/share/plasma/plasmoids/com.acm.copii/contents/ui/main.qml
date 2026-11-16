// Ecranul modului copii: salut mare și butoane uriașe, colorate, fără meniuri și fără text mult.
// Ieșirea cere parola unui părinte (acm-kids-off prin pkexec).
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    property date now: new Date()
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = new Date() }

    readonly property string chrome: "google-chrome --no-first-run --no-default-browser-check --app="
    readonly property var tiles: [
        { name: "Desenăm", icon: "tuxpaint", color: "#f28b54", cmd: "tuxpaint" },
        { name: "Învățăm jucându-ne", icon: "gcompris-qt", color: "#5aa9e6", cmd: "gcompris-qt" },
        { name: "Desene animate", icon: "youtube", fallback: "video-television", color: "#e5484d", cmd: chrome + "https://www.youtubekids.com" },
        { name: "Cântece", icon: "audio-headphones", color: "#9b6ad6", cmd: chrome + "https://www.youtubekids.com/search?q=cantece%20pentru%20copii" },
        { name: "Cartoful", icon: "ktuberling", color: "#6fb35f", cmd: "ktuberling" }
    ]

    P5Support.DataSource { id: sh; engine: "executable"; connectedSources: []; onNewData: (s) => disconnectSource(s) }
    function run(cmd) { sh.connectSource("setsid -f " + cmd + " >/dev/null 2>&1") }

    fullRepresentation: Item {
        Layout.preferredWidth: 1100; Layout.preferredHeight: 700

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 36

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: 4
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: { var h = root.now.getHours(); return h < 11 ? "Bună dimineața! 🌞" : h < 18 ? "Bună! Ce facem azi? 🎈" : "Bună seara! 🌙" }
                    color: Kirigami.Theme.textColor; font.pixelSize: 44; font.weight: Font.Bold
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Apasă pe un buton mare"
                    color: Kirigami.Theme.disabledTextColor; font.pixelSize: 20
                }
            }

            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: 3; rowSpacing: 26; columnSpacing: 26
                Repeater {
                    model: root.tiles
                    delegate: Rectangle {
                        id: tile
                        required property var modelData
                        implicitWidth: 230; implicitHeight: 190; radius: 36
                        color: modelData.color
                        scale: ma.pressed ? 0.94 : (ma.containsMouse ? 1.04 : 1)
                        Behavior on scale { NumberAnimation { duration: 120 } }
                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 12
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 96; implicitHeight: 96; radius: 48; color: Qt.rgba(1, 1, 1, 0.92)
                                Kirigami.Icon {
                                    anchors.centerIn: parent; width: 68; height: 68
                                    source: tile.modelData.icon
                                    fallback: tile.modelData.fallback || "applications-games"
                                }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: tile.modelData.name; color: "white"; font.pixelSize: 22; font.weight: Font.Bold
                            }
                        }
                        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.run(tile.modelData.cmd) }
                    }
                }
            }
        }

        // ieșirea, discretă, pentru părinți
        MouseArea {
            anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 16
            width: exitRow.implicitWidth + 24; height: 40
            cursorShape: Qt.PointingHandCursor; hoverEnabled: true
            onClicked: sh.connectSource("pkexec /opt/acm-os/system/bin/acm-kids-off && busctl --user call org.kde.Shutdown /Shutdown org.kde.Shutdown logout")
            Rectangle { anchors.fill: parent; radius: 12; color: Qt.rgba(0, 0, 0, parent.containsMouse ? 0.12 : 0.06) }
            RowLayout {
                id: exitRow; anchors.centerIn: parent; spacing: 8
                Kirigami.Icon { implicitWidth: 18; implicitHeight: 18; source: "system-lock-screen" }
                Text { text: "Părinte: ieșire"; color: Kirigami.Theme.textColor; font.pixelSize: 14 }
            }
        }
    }
}
