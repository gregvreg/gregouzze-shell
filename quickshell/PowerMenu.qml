// ==============================================================================
// PowerMenu.qml — Fullscreen power overlay modal for gregouzze-shell
// Lock · Logout · Reboot · Shutdown
// ==============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: powerMenu

    property bool active: false
    signal dismissed()

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: active

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0

    // ── Scrim ────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Colors.withAlpha(Colors.scrim, 0.55)

        TapHandler { onTapped: powerMenu.dismissed() }
        Keys.onEscapePressed: powerMenu.dismissed()

        // ── Card ─────────────────────────────────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            width: 480; height: 280; radius: 24
            color: Colors.surfaceContainer

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 24
                spacing: 16

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "⏻  Power Menu"
                        font.pixelSize: 18; font.bold: true
                        color: Colors.contentSurface
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        width: 30; height: 30; radius: 8
                        color: dismissHover.hovered ? Colors.surfaceContainerHighest : "transparent"
                        Text { text: "✕"; font.pixelSize: 14; anchors.centerIn: parent; color: Colors.contentSurfaceVariant }
                        HoverHandler { id: dismissHover }
                        TapHandler { onTapped: powerMenu.dismissed() }
                    }
                }

                // Action buttons
                RowLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    spacing: 12

                    // Lock
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                        color: lockH.hovered ? Colors.primaryContainer : Colors.surfaceContainerHigh
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Column {
                            anchors.centerIn: parent; spacing: 6
                            Text { text: "󰌾"; font.pixelSize: 26; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.primary }
                            Text { text: "Lock"; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.contentSurface }
                        }
                        HoverHandler { id: lockH }
                        TapHandler { onTapped: { powerMenu.dismissed(); Quickshell.execDetached(["hyprlock"]); } }
                    }

                    // Logout
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                        color: logoutH.hovered ? Colors.secondaryContainer : Colors.surfaceContainerHigh
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Column {
                            anchors.centerIn: parent; spacing: 6
                            Text { text: "󰍃"; font.pixelSize: 26; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.secondary }
                            Text { text: "Logout"; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.contentSurface }
                        }
                        HoverHandler { id: logoutH }
                        TapHandler { onTapped: { powerMenu.dismissed(); Quickshell.execDetached(["hyprctl", "dispatch", "exit"]); } }
                    }

                    // Reboot
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                        color: rebootH.hovered ? Colors.tertiaryContainer : Colors.surfaceContainerHigh
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Column {
                            anchors.centerIn: parent; spacing: 6
                            Text { text: "󰑓"; font.pixelSize: 26; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.tertiary }
                            Text { text: "Reboot"; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.contentSurface }
                        }
                        HoverHandler { id: rebootH }
                        TapHandler { onTapped: { powerMenu.dismissed(); Quickshell.execDetached(["systemctl", "reboot"]); } }
                    }

                    // Shutdown
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                        color: shutH.hovered ? Colors.errorContainer : Colors.surfaceContainerHigh
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Column {
                            anchors.centerIn: parent; spacing: 6
                            Text { text: "⏻"; font.pixelSize: 26; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.error }
                            Text { text: "Power Off"; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.contentSurface }
                        }
                        HoverHandler { id: shutH }
                        TapHandler { onTapped: { powerMenu.dismissed(); Quickshell.execDetached(["systemctl", "poweroff"]); } }
                    }
                }

                // Hint
                Text {
                    text: "Press ESC or click outside to dismiss"
                    font.pixelSize: 10; color: Colors.outline
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
