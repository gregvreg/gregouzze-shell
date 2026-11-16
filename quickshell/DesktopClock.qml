// ==============================================================================
// DesktopClock.qml — Desktop overlay clock widget for gregouzze-shell
// Sits on the desktop behind windows, shows time + date + branding
// ==============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: clockWidget

    anchors { top: true; left: true }
    margins { top: 70; left: 28 }
    width: 260; height: 120
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 0

    // ── State ────────────────────────────────────────────────────────────────
    property string timeStr: Qt.formatDateTime(new Date(), "HH:mm")
    property string dateStr: Qt.formatDateTime(new Date(), "dddd, dd MMMM yyyy")

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            clockWidget.timeStr = Qt.formatDateTime(new Date(), "HH:mm")
            clockWidget.dateStr = Qt.formatDateTime(new Date(), "dddd, dd MMMM yyyy")
        }
    }

    // ── Visual ───────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 18
        color: Colors.withAlpha(Colors.surfaceContainerLowest, 0.55)
        border.color: Colors.withAlpha(Colors.outlineVariant, 0.25)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 14
            spacing: 2

            Text {
                text: clockWidget.timeStr
                font.pixelSize: 34; font.bold: true
                color: Colors.primary
            }
            Text {
                text: clockWidget.dateStr
                font.pixelSize: 12; font.weight: Font.Medium
                color: Colors.contentSurface
            }
            Text {
                text: "Arch Linux • gregouzze-shell"
                font.pixelSize: 10
                color: Colors.contentSurfaceVariant
            }
        }
    }
}
