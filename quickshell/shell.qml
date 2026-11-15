// ==============================================================================
// gregouzze-shell - Modern Wayland Shell & Widgets (shell.qml)
// Inspired by Caelestia Shell • Dynamic Material You Dark Theme
// ==============================================================================

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    // Global session state for interactive modals
    property bool powerMenuOpen: false
    property int activeWorkspace: 1
    property string cpuUsage: "8%"
    property string ramUsage: "3.2G"
    property string volumeLevel: "75%"
    property bool isMuted: false

    // Periodic System Monitor (Pure QML /proc reader - zero lag & no dependencies)
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // Update RAM Usage
            var xhrMem = new XMLHttpRequest();
            xhrMem.open("GET", "file:///proc/meminfo", true);
            xhrMem.onreadystatechange = function() {
                if (xhrMem.readyState === XMLHttpRequest.DONE && xhrMem.status === 200) {
                    var text = xhrMem.responseText;
                    var totalMatch = text.match(/MemTotal:\s+(\d+)\s+kB/);
                    var availMatch = text.match(/MemAvailable:\s+(\d+)\s+kB/);
                    if (totalMatch && availMatch) {
                        var total = parseInt(totalMatch[1]);
                        var avail = parseInt(availMatch[1]);
                        var used = total - avail;
                        root.ramUsage = (used / 1024 / 1024).toFixed(1) + "G";
                    }
                }
            };
            xhrMem.send();

            // Update CPU Load
            var xhrCpu = new XMLHttpRequest();
            xhrCpu.open("GET", "file:///proc/loadavg", true);
            xhrCpu.onreadystatechange = function() {
                if (xhrCpu.readyState === XMLHttpRequest.DONE && xhrCpu.status === 200) {
                    var parts = xhrCpu.responseText.trim().split(" ");
                    if (parts.length > 0) {
                        root.cpuUsage = parts[0];
                    }
                }
            };
            xhrCpu.send();
        }
    }

    // --------------------------------------------------------------------------
    // 1. TOP STATUS BAR (Instantiated on each connected monitor)
    // --------------------------------------------------------------------------
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                id: barWindow
                required property var modelData
                screen: modelData

                anchors {
                    top: true
                    left: true
                    right: true
                }
                height: 52
                color: "transparent"

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                exclusiveZone: 52

                // Floating Glass Container
                Rectangle {
                    id: barContainer
                    anchors {
                        fill: parent
                        margins: 6
                        leftMargin: 16
                        rightMargin: 16
                    }
                    radius: 14
                    color: Colors.withAlpha(Colors.surfaceContainer, 0.88)
                    border.color: Colors.withAlpha(Colors.outlineVariant, 0.35)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        // ------------------------------------------------------
                        // LEFT: Launcher Pill & Workspaces
                        // ------------------------------------------------------
                        // Brand Launcher Pill
                        Rectangle {
                            Layout.preferredHeight: 30
                            Layout.preferredWidth: brandRow.implicitWidth + 20
                            radius: 10
                            color: brandHover.hovered ? Colors.primary : Colors.primaryContainer
                            Behavior on color { ColorAnimation { duration: 180 } }

                            Row {
                                id: brandRow
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: "󰣇"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: brandHover.hovered ? Colors.onPrimary : Colors.onPrimaryContainer
                                }
                                Text {
                                    text: "gregouzze"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: brandHover.hovered ? Colors.onPrimary : Colors.onPrimaryContainer
                                }
                            }

                            HoverHandler { id: brandHover }
                            TapHandler {
                                onTapped: {
                                    Quickshell.execDetached(["kitty"]);
                                }
                            }
                        }

                        // Workspaces Pill Bar
                        Rectangle {
                            Layout.preferredHeight: 30
                            Layout.preferredWidth: wsRow.implicitWidth + 14
                            radius: 10
                            color: Colors.withAlpha(Colors.surfaceContainerHigh, 0.6)
                            border.color: Colors.withAlpha(Colors.outlineVariant, 0.2)
                            border.width: 1

                            Row {
                                id: wsRow
                                anchors.centerIn: parent
                                spacing: 4

                                Repeater {
                                    model: [1, 2, 3, 4, 5]
                                    delegate: Rectangle {
                                        id: wsButton
                                        required property int modelData
                                        width: 24
                                        height: 22
                                        radius: 6
                                        color: (root.activeWorkspace === modelData) ? Colors.primary : 
                                               (wsHover.hovered ? Colors.withAlpha(Colors.surfaceContainerHighest, 0.8) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: 11
                                            font.bold: (root.activeWorkspace === modelData)
                                            color: (root.activeWorkspace === modelData) ? Colors.onPrimary : Colors.onSurfaceVariant
                                        }

                                        HoverHandler { id: wsHover }
                                        TapHandler {
                                            onTapped: {
                                                root.activeWorkspace = modelData;
                                                Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(modelData)]);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Quick Kitty Terminal Icon Button
                        Rectangle {
                            Layout.preferredHeight: 30
                            Layout.preferredWidth: 32
                            radius: 8
                            color: termHover.hovered ? Colors.secondaryContainer : Colors.withAlpha(Colors.surfaceContainerHigh, 0.5)

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.pixelSize: 13
                                color: termHover.hovered ? Colors.onSecondaryContainer : Colors.onSurface
                            }

                            HoverHandler { id: termHover }
                            TapHandler {
                                onTapped: Quickshell.execDetached(["kitty"])
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // ------------------------------------------------------
                        // CENTER: Dynamic Island Capsule (Clock & Date)
                        // ------------------------------------------------------
                        Rectangle {
                            Layout.preferredHeight: 32
                            Layout.preferredWidth: clockRow.implicitWidth + 28
                            radius: 16
                            color: Colors.withAlpha(Colors.surfaceContainerHighest, 0.75)
                            border.color: clockHover.hovered ? Colors.primary : Colors.withAlpha(Colors.primary, 0.25)
                            border.width: 1
                            Behavior on border.color { ColorAnimation { duration: 200 } }

                            Row {
                                id: clockRow
                                anchors.centerIn: parent
                                spacing: 10

                                Text {
                                    id: dateLabel
                                    text: "󰸗 " + Qt.formatDateTime(new Date(), "ddd dd MMM")
                                    font.pixelSize: 11
                                    font.bold: false
                                    color: Colors.onSurfaceVariant
                                }

                                Rectangle {
                                    width: 1
                                    height: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Colors.withAlpha(Colors.outline, 0.4)
                                }

                                Text {
                                    id: timeLabel
                                    text: "󰥔 " + Qt.formatDateTime(new Date(), "hh:mm:ss")
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Colors.onSurface
                                }
                            }

                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                onTriggered: {
                                    dateLabel.text = "󰸗 " + Qt.formatDateTime(new Date(), "ddd dd MMM");
                                    timeLabel.text = "󰥔 " + Qt.formatDateTime(new Date(), "hh:mm:ss");
                                }
                            }

                            HoverHandler { id: clockHover }
                        }

                        Item { Layout.fillWidth: true }

                        // ------------------------------------------------------
                        // RIGHT: System Monitor, Tools & Session Control
                        // ------------------------------------------------------
                        // RAM Usage Pill
                        Rectangle {
                            Layout.preferredHeight: 28
                            Layout.preferredWidth: ramText.implicitWidth + 16
                            radius: 8
                            color: Colors.withAlpha(Colors.surfaceContainerHigh, 0.6)

                            Text {
                                id: ramText
                                anchors.centerIn: parent
                                text: "󰘚 " + root.ramUsage
                                font.pixelSize: 11
                                font.bold: true
                                color: Colors.secondary
                            }
                        }

                        // CPU Load Pill
                        Rectangle {
                            Layout.preferredHeight: 28
                            Layout.preferredWidth: cpuText.implicitWidth + 16
                            radius: 8
                            color: Colors.withAlpha(Colors.surfaceContainerHigh, 0.6)

                            Text {
                                id: cpuText
                                anchors.centerIn: parent
                                text: " " + root.cpuUsage
                                font.pixelSize: 11
                                font.bold: true
                                color: Colors.tertiary
                            }
                        }

                        // Volume / Audio Pill
                        Rectangle {
                            Layout.preferredHeight: 28
                            Layout.preferredWidth: volText.implicitWidth + 16
                            radius: 8
                            color: volHover.hovered ? Colors.secondaryContainer : Colors.withAlpha(Colors.surfaceContainerHigh, 0.6)

                            Text {
                                id: volText
                                anchors.centerIn: parent
                                text: (root.isMuted ? "󰝟 Muted" : "󰕾 " + root.volumeLevel)
                                font.pixelSize: 11
                                font.bold: true
                                color: volHover.hovered ? Colors.onSecondaryContainer : Colors.onSurface
                            }

                            HoverHandler { id: volHover }
                            TapHandler {
                                onTapped: {
                                    root.isMuted = !root.isMuted;
                                    Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
                                }
                            }
                        }

                        // Wallpaper Switcher Button (One-click theme refresh)
                        Rectangle {
                            Layout.preferredHeight: 28
                            Layout.preferredWidth: 32
                            radius: 8
                            color: wallHover.hovered ? Colors.primary : Colors.withAlpha(Colors.surfaceContainerHigh, 0.6)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰸉"
                                font.pixelSize: 13
                                color: wallHover.hovered ? Colors.onPrimary : Colors.primary
                            }

                            HoverHandler { id: wallHover }
                            TapHandler {
                                onTapped: {
                                    Quickshell.execDetached(["bash", "-c", "~/.config/gregouzze-shell/scripts/wall-switch.sh"]);
                                }
                            }
                        }

                        // Power / Session Menu Trigger Button
                        Rectangle {
                            Layout.preferredHeight: 28
                            Layout.preferredWidth: 32
                            radius: 8
                            color: powerHover.hovered ? Colors.error : Colors.withAlpha(Colors.errorContainer, 0.45)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "⏻"
                                font.pixelSize: 12
                                font.bold: true
                                color: powerHover.hovered ? Colors.onError : Colors.error
                            }

                            HoverHandler { id: powerHover }
                            TapHandler {
                                onTapped: {
                                    root.powerMenuOpen = !root.powerMenuOpen;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // --------------------------------------------------------------------------
    // 2. DESKTOP CORNER CLOCK & STATUS WIDGET (Sits nicely above wallpaper)
    // --------------------------------------------------------------------------
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData

                anchors {
                    top: true
                    left: true
                }
                margins {
                    top: 70
                    left: 28
                }
                width: 260
                height: 120
                color: "transparent"

                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                exclusiveZone: 0 // Do not push tiled windows

                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: Colors.withAlpha(Colors.surfaceContainerLowest, 0.55)
                    border.color: Colors.withAlpha(Colors.outlineVariant, 0.25)
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 2

                        Text {
                            id: bigClock
                            text: Qt.formatDateTime(new Date(), "hh:mm")
                            font.pixelSize: 34
                            font.bold: true
                            color: Colors.primary
                        }

                        Text {
                            id: fullDate
                            text: Qt.formatDateTime(new Date(), "dddd, dd MMMM yyyy")
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Colors.onSurface
                        }

                        Text {
                            text: "Arch Linux • Hyprland Rice"
                            font.pixelSize: 10
                            color: Colors.onSurfaceVariant
                        }
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: {
                            bigClock.text = Qt.formatDateTime(new Date(), "hh:mm");
                            fullDate.text = Qt.formatDateTime(new Date(), "dddd, dd MMMM yyyy");
                        }
                    }
                }
            }
        }
    }

    // --------------------------------------------------------------------------
    // 3. FLOATING POWER OVERLAY MODAL (Toggleable from the Top Bar)
    // --------------------------------------------------------------------------
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                color: "transparent"
                visible: root.powerMenuOpen

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                exclusiveZone: 0

                // Scrim backdrop
                Rectangle {
                    anchors.fill: parent
                    color: Colors.withAlpha(Colors.scrim, 0.55)

                    TapHandler {
                        onTapped: root.powerMenuOpen = false
                    }
                }

                // Centered Power Card
                Rectangle {
                    anchors.centerIn: parent
                    width: 360
                    height: 220
                    radius: 20
                    color: Colors.surfaceContainer
                    border.color: Colors.withAlpha(Colors.outlineVariant, 0.4)
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16

                        // Modal Header
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Session Control"
                                font.pixelSize: 16
                                font.bold: true
                                color: Colors.onSurface
                                Layout.fillWidth: true
                            }
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: closeHover.hovered ? Colors.surfaceContainerHighest : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.pixelSize: 12
                                    color: Colors.onSurfaceVariant
                                }
                                HoverHandler { id: closeHover }
                                TapHandler { onTapped: root.powerMenuOpen = false }
                            }
                        }

                        // Action Buttons Grid
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            // Lock Button
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 70
                                radius: 12
                                color: lockH.hovered ? Colors.secondaryContainer : Colors.surfaceContainerHigh
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text { text: "󰌾"; font.pixelSize: 20; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.secondary }
                                    Text { text: "Lock"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.onSurface }
                                }
                                HoverHandler { id: lockH }
                                TapHandler {
                                    onTapped: {
                                        root.powerMenuOpen = false;
                                        Quickshell.execDetached(["hyprlock"]);
                                    }
                                }
                            }

                            // Logout Button
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 70
                                radius: 12
                                color: exitH.hovered ? Colors.primaryContainer : Colors.surfaceContainerHigh
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text { text: "󰍃"; font.pixelSize: 20; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.primary }
                                    Text { text: "Logout"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.onSurface }
                                }
                                HoverHandler { id: exitH }
                                TapHandler {
                                    onTapped: {
                                        root.powerMenuOpen = false;
                                        Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
                                    }
                                }
                            }

                            // Reboot Button
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 70
                                radius: 12
                                color: rebootH.hovered ? Colors.tertiaryContainer : Colors.surfaceContainerHigh
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text { text: "󰑓"; font.pixelSize: 20; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.tertiary }
                                    Text { text: "Reboot"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.onSurface }
                                }
                                HoverHandler { id: rebootH }
                                TapHandler {
                                    onTapped: {
                                        root.powerMenuOpen = false;
                                        Quickshell.execDetached(["systemctl", "reboot"]);
                                    }
                                }
                            }

                            // Shutdown Button
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 70
                                radius: 12
                                color: shutH.hovered ? Colors.errorContainer : Colors.surfaceContainerHigh
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text { text: "⏻"; font.pixelSize: 20; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.error }
                                    Text { text: "Power Off"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.onSurface }
                                }
                                HoverHandler { id: shutH }
                                TapHandler {
                                    onTapped: {
                                        root.powerMenuOpen = false;
                                        Quickshell.execDetached(["systemctl", "poweroff"]);
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Press ESC or click outside to dismiss"
                            font.pixelSize: 10
                            color: Colors.outline
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
