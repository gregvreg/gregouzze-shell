// ==============================================================================
// WallpaperSelector.qml — Interactive wallpaper grid for gregouzze-shell
// Scans ~/Pictures/Wallpapers, shows thumbnails, calls wall-switch.sh on click
// ==============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: wallSel

    required property var screen
    property bool active: false
    property string wallpaperDir: (Quickshell.env("HOME") || "/tmp") + "/Pictures/Wallpapers"
    signal dismissed()

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: active

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0

    // ── Wallpaper list model ─────────────────────────────────────────────────
    ListModel { id: wallModel }
    property bool scanning: false

    // Scan the wallpaper directory using a shell command
    function scanWallpapers() {
        wallModel.clear();
        wallSel.scanning = true;
        scanProcess.command = ["bash", "-c", "find \"$1\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) 2>/dev/null | sort", "_", wallSel.wallpaperDir];
        scanProcess.running = true;
    }

    Process {
        id: scanProcess
        stdout: StdioCollector {
            onStreamFinished: {
                wallSel.scanning = false;
                wallModel.clear();
                var files = text.trim() ? text.trim().split("\n") : [];
                for (var i = 0; i < files.length; i++) {
                    var path = files[i].trim();
                    if (!path) continue;
                    var parts = path.split("/");
                    wallModel.append({"filePath": path, "fileName": parts[parts.length - 1]});
                }
            }
        }
    }

    onActiveChanged: {
        if (active) scanWallpapers();
    }

    // ── Current wallpaper tracking ───────────────────────────────────────────
    property string currentWall: ""
    Component.onCompleted: {
        currentWallProcess.running = true;
    }

    Process {
        id: currentWallProcess
        command: ["bash", "-c", "cat \"$1\" 2>/dev/null || true", "_", (Quickshell.env("XDG_CONFIG_HOME") || ((Quickshell.env("HOME") || "/tmp") + "/.config")) + "/gregouzze-shell/.wallpaper_path"]
        stdout: StdioCollector { onStreamFinished: wallSel.currentWall = text.trim() }
    }

    // ── Scrim ────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Colors.withAlpha(Colors.scrim, 0.50)
        TapHandler { onTapped: wallSel.dismissed() }
        Keys.onEscapePressed: wallSel.dismissed()

        // ── Card ─────────────────────────────────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            width: 780; height: 520; radius: 22
            color: Colors.withAlpha(Colors.surfaceContainer, 0.95)
            border.color: Colors.withAlpha(Colors.outlineVariant, 0.20)
            border.width: 1

            // Block click-through
            TapHandler { }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 22
                spacing: 14

                // ── Header ───────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "󰸉"; font.pixelSize: 22; color: Colors.primary
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: "Wallpaper Selector"
                        font.pixelSize: 17; font.bold: true
                        color: Colors.contentSurface
                        Layout.fillWidth: true
                    }

                    // Refresh button
                    Rectangle {
                        width: 32; height: 32; radius: 8
                        color: refreshH.hovered ? Colors.secondaryContainer : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { text: "󰑐"; font.pixelSize: 16; anchors.centerIn: parent; color: Colors.contentSurface }
                        HoverHandler { id: refreshH }
                        TapHandler { onTapped: wallSel.scanWallpapers() }
                    }

                    // Open folder button
                    Rectangle {
                        width: 32; height: 32; radius: 8
                        color: folderH.hovered ? Colors.secondaryContainer : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { text: "󰉋"; font.pixelSize: 16; anchors.centerIn: parent; color: Colors.contentSurface }
                        HoverHandler { id: folderH }
                        TapHandler {
                            onTapped: Quickshell.execDetached(["xdg-open", wallSel.wallpaperDir])
                        }
                    }

                    // Dismiss
                    Rectangle {
                        width: 32; height: 32; radius: 8
                        color: closeH.hovered ? Colors.surfaceContainerHighest : "transparent"
                        Text { text: "✕"; font.pixelSize: 14; anchors.centerIn: parent; color: Colors.contentSurfaceVariant }
                        HoverHandler { id: closeH }
                        TapHandler { onTapped: wallSel.dismissed() }
                    }
                }

                // ── Grid ─────────────────────────────────────────────────────
                GridView {
                    id: wallGrid
                    Layout.fillWidth: true; Layout.fillHeight: true
                    model: wallModel
                    cellWidth: 185; cellHeight: 125
                    clip: true

                    delegate: Item {
                        width: wallGrid.cellWidth; height: wallGrid.cellHeight
                        required property int index
                        required property string filePath
                        required property string fileName

                        Rectangle {
                            anchors.fill: parent; anchors.margins: 5
                            radius: 12; clip: true
                            color: Colors.surfaceContainerHigh

                            // Active wallpaper indicator
                            border.color: filePath === wallSel.currentWall ? Colors.primary : (imgHover.hovered ? Colors.withAlpha(Colors.primary, 0.6) : "transparent")
                            border.width: filePath === wallSel.currentWall ? 3 : (imgHover.hovered ? 2 : 0)
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Image {
                                anchors.fill: parent; anchors.margins: 1
                                source: "file://" + filePath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 360
                                sourceSize.height: 200

                                // Loading placeholder
                                Rectangle {
                                    anchors.fill: parent; visible: parent.status !== Image.Ready
                                    color: Colors.surfaceContainerHighest
                                    Text { text: "⏳"; font.pixelSize: 20; anchors.centerIn: parent; color: Colors.contentSurfaceVariant }
                                }
                            }

                            // Filename overlay
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: 24; radius: 0
                                color: Colors.withAlpha(Colors.scrim, 0.55)

                                // Bottom radius hack
                                Rectangle {
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                    height: 12; radius: 12; color: parent.color
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: fileName
                                    font.pixelSize: 9; color: "#ffffff"
                                    elide: Text.ElideMiddle
                                    width: parent.width - 12
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            // Current wallpaper badge
                            Rectangle {
                                visible: filePath === wallSel.currentWall
                                anchors { top: parent.top; right: parent.right; margins: 6 }
                                width: 20; height: 20; radius: 10
                                color: Colors.primary
                                Text { text: "✓"; font.pixelSize: 11; font.bold: true; anchors.centerIn: parent; color: Colors.contentPrimary }
                            }

                            HoverHandler { id: imgHover }
                            TapHandler {
                                onTapped: {
                                    wallSel.currentWall = filePath;
                                    Quickshell.execDetached([
                                        "bash",
                                        (Quickshell.env("XDG_CONFIG_HOME") || ((Quickshell.env("HOME") || "/tmp") + "/.config")) + "/gregouzze-shell/scripts/wall-switch.sh",
                                        filePath
                                    ]);
                                    wallSel.dismissed();
                                }
                            }
                        }
                    }

                    // Empty state
                    Column {
                        anchors.centerIn: parent; spacing: 10
                        visible: wallModel.count === 0 && !wallSel.scanning

                        Text { text: "󰉋"; font.pixelSize: 48; color: Colors.contentSurfaceVariant; anchors.horizontalCenter: parent.horizontalCenter }
                        Text {
                            text: "No wallpapers found"
                            font.pixelSize: 14; color: Colors.contentSurfaceVariant
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "Place images in ~/Pictures/Wallpapers"
                            font.pixelSize: 11; color: Colors.outline
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    // Loading indicator
                    Text {
                        anchors.centerIn: parent
                        text: "Scanning…"
                        font.pixelSize: 13; color: Colors.contentSurfaceVariant
                        visible: wallSel.scanning
                    }
                }
            }
        }
    }
}
