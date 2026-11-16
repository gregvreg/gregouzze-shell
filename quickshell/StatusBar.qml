// ==============================================================================
// StatusBar.qml — Floating top status bar for gregouzze-shell
// Workspaces · Active Window · System Stats · Clock · Quick Actions
// ==============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar

    // ── Public interface ─────────────────────────────────────────────────────
    property int activeWorkspace: 1
    property string cpuUsage: "0"
    property string ramUsage: "0G"

    signal launcherClicked()
    signal wallpaperClicked()
    signal powerClicked()

    // ── Geometry ─────────────────────────────────────────────────────────────
    anchors { top: true; left: true; right: true }
    height: 48
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 48

    // ── Clock tick ───────────────────────────────────────────────────────────
    property string clockText: Qt.formatDateTime(new Date(), "HH:mm")
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: bar.clockText = Qt.formatDateTime(new Date(), "HH:mm")
    }

    // ── Bar container ────────────────────────────────────────────────────────
    Rectangle {
        id: container
        anchors {
            fill: parent; margins: 4
            leftMargin: 14; rightMargin: 14
        }
        radius: 14
        color: Colors.withAlpha(Colors.surfaceContainer, 0.88)
        border.color: Colors.withAlpha(Colors.outlineVariant, 0.30)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10; anchors.rightMargin: 10
            spacing: 8

            // ── LEFT: Brand pill + Workspaces ────────────────────────────────
            Rectangle {
                Layout.preferredHeight: 28
                Layout.preferredWidth: brandRow.implicitWidth + 18
                radius: 10
                color: brandHover.hovered ? Colors.primary : Colors.primaryContainer
                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                    id: brandRow
                    anchors.centerIn: parent; spacing: 5
                    Text { text: "󰣇"; font.pixelSize: 14; color: brandHover.hovered ? Colors.contentPrimary : Colors.contentPrimaryContainer }
                    Text { text: "G"; font.pixelSize: 12; font.bold: true; color: brandHover.hovered ? Colors.contentPrimary : Colors.contentPrimaryContainer }
                }
                HoverHandler { id: brandHover }
                TapHandler { onTapped: bar.launcherClicked() }
            }

            // Workspace indicators
            Row {
                spacing: 4
                Repeater {
                    model: 10
                    Rectangle {
                        required property int index
                        width: (index + 1) === bar.activeWorkspace ? 22 : 8
                        height: 8; radius: 4
                        color: (index + 1) === bar.activeWorkspace
                               ? Colors.primary
                               : Colors.withAlpha(Colors.contentSurfaceVariant, 0.35)
                        Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                        Behavior on color  { ColorAnimation  { duration: 200 } }
                    }
                }
            }

            // ── CENTER: Active window title ──────────────────────────────────
            Item { Layout.fillWidth: true }
            Text {
                text: "Desktop"
                font.pixelSize: 12; font.weight: Font.Medium
                color: Colors.contentSurfaceVariant
                elide: Text.ElideRight
                Layout.maximumWidth: 300
            }
            Item { Layout.fillWidth: true }

            // ── RIGHT: System pills + clock + actions ────────────────────────
            // CPU
            Row {
                spacing: 4
                Text { text: "󰻠"; font.pixelSize: 14; color: Colors.secondary; anchors.verticalCenter: parent.verticalCenter }
                Text { text: bar.cpuUsage; font.pixelSize: 11; color: Colors.contentSurface; anchors.verticalCenter: parent.verticalCenter }
            }

            Rectangle { width: 1; height: 16; color: Colors.withAlpha(Colors.outline, 0.3); Layout.alignment: Qt.AlignVCenter }

            // RAM
            Row {
                spacing: 4
                Text { text: "󰍛"; font.pixelSize: 14; color: Colors.tertiary; anchors.verticalCenter: parent.verticalCenter }
                Text { text: bar.ramUsage; font.pixelSize: 11; color: Colors.contentSurface; anchors.verticalCenter: parent.verticalCenter }
            }

            Rectangle { width: 1; height: 16; color: Colors.withAlpha(Colors.outline, 0.3); Layout.alignment: Qt.AlignVCenter }

            // Clock
            Text {
                text: bar.clockText
                font.pixelSize: 13; font.bold: true
                color: Colors.primary
            }

            Rectangle { width: 1; height: 16; color: Colors.withAlpha(Colors.outline, 0.3); Layout.alignment: Qt.AlignVCenter }

            // Wallpaper action
            Rectangle {
                width: 28; height: 28; radius: 8
                color: wallHover.hovered ? Colors.secondaryContainer : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { text: "󰸉"; font.pixelSize: 15; anchors.centerIn: parent; color: Colors.contentSurface }
                HoverHandler { id: wallHover }
                TapHandler { onTapped: bar.wallpaperClicked() }
            }

            // Power action
            Rectangle {
                width: 28; height: 28; radius: 8
                color: powerHover.hovered ? Colors.errorContainer : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { text: "⏻"; font.pixelSize: 14; anchors.centerIn: parent; color: powerHover.hovered ? Colors.error : Colors.contentSurface }
                HoverHandler { id: powerHover }
                TapHandler { onTapped: bar.powerClicked() }
            }
        }
    }
}
