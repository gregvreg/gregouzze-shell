// ==============================================================================
// gregouzze-shell - Quickshell Entrypoint (shell.qml)
// Inspired by Caelestia Shell - Modern, lightweight Wayland Qt6 bar
// ==============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: root

    // Panel Window targeting all connected Wayland monitors
    PanelWindow {
        id: panel
        anchors {
            top: true
            left: true
            right: true
        }
        height: 44
        color: "transparent"

        // Wayland LayerShell configuration
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.exclusiveZone: 44

        // Main Bar Container with Material You dynamic glassmorphism
        Rectangle {
            id: barBackground
            anchors {
                fill: parent
                margins: 4
                leftMargin: 12
                rightMargin: 12
            }
            radius: 12
            color: Colors.withAlpha(Colors.surfaceContainer, 0.85)
            border.color: Colors.withAlpha(Colors.outlineVariant, 0.4)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                // Left: Host & Shell Brand Pill
                Rectangle {
                    Layout.preferredHeight: 26
                    Layout.preferredWidth: brandText.implicitWidth + 20
                    radius: 8
                    color: Colors.primaryContainer

                    Text {
                        id: brandText
                        anchors.centerIn: parent
                        text: "󰣇 gregouzze"
                        font.pixelSize: 12
                        font.bold: true
                        color: Colors.onPrimaryContainer
                    }
                }

                // Middle: Workspace / Status indicator placeholder
                Item {
                    Layout.fillWidth: true
                }

                // Center Clock / Date Widget
                Rectangle {
                    Layout.preferredHeight: 26
                    Layout.preferredWidth: clockText.implicitWidth + 24
                    radius: 8
                    color: Colors.withAlpha(Colors.surfaceContainerHighest, 0.6)

                    Text {
                        id: clockText
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(new Date(), "ddd dd MMM  •  hh:mm")
                        font.pixelSize: 12
                        font.bold: true
                        color: Colors.onSurface
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: {
                            clockText.text = Qt.formatDateTime(new Date(), "ddd dd MMM  •  hh:mm");
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                // Right: Dynamic Theme indicator pill
                Rectangle {
                    Layout.preferredHeight: 26
                    Layout.preferredWidth: themeText.implicitWidth + 20
                    radius: 8
                    color: Colors.secondaryContainer

                    Text {
                        id: themeText
                        anchors.centerIn: parent
                        text: "󰔎 " + Colors.mode
                        font.pixelSize: 12
                        font.bold: true
                        color: Colors.onSecondaryContainer
                    }
                }
            }
        }
    }
}
