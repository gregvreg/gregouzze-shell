// ==============================================================================
// Launcher.qml — Application launcher overlay for gregouzze-shell
// Search-driven grid with fuzzy filtering and keyboard navigation
// ==============================================================================

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: launcher

    required property var screen
    property bool active: false
    signal dismissed()

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: active

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0

    // ── App catalogue ────────────────────────────────────────────────────────
    ListModel {
        id: appModel
        ListElement { name: "Kitty";           icon: "󰄛"; cmd: "kitty" }
        ListElement { name: "Firefox";         icon: "󰈹"; cmd: "firefox" }
        ListElement { name: "Files";           icon: "󰉋"; cmd: "thunar" }
        ListElement { name: "Code";            icon: "󰨞"; cmd: "code" }
        ListElement { name: "Discord";         icon: "󰙯"; cmd: "discord" }
        ListElement { name: "Spotify";         icon: "󰓇"; cmd: "spotify-launcher" }
        ListElement { name: "System Monitor";  icon: "󱕍"; cmd: "gnome-system-monitor" }
        ListElement { name: "Settings";        icon: "󰒓"; cmd: "gnome-control-center" }
        ListElement { name: "Chromium";        icon: "󰊯"; cmd: "chromium" }
        ListElement { name: "OBS Studio";      icon: "󰑋"; cmd: "obs" }
        ListElement { name: "GIMP";            icon: "󰃣"; cmd: "gimp" }
        ListElement { name: "Steam";           icon: "󰓓"; cmd: "steam" }
        ListElement { name: "Telegram";        icon: "󰔁"; cmd: "telegram-desktop" }
        ListElement { name: "VLC";             icon: "󰕼"; cmd: "vlc" }
        ListElement { name: "Calculator";      icon: "󰃬"; cmd: "gnome-calculator" }
        ListElement { name: "Screenshot";      icon: "󰹑"; cmd: "grimblast" }
    }

    // Filtered proxy model
    ListModel { id: filteredModel }

    function updateFilter() {
        filteredModel.clear();
        var query = searchField.text.toLowerCase();
        for (var i = 0; i < appModel.count; i++) {
            var item = appModel.get(i);
            if (query === "" || item.name.toLowerCase().indexOf(query) !== -1) {
                filteredModel.append(item);
            }
        }
    }

    // Reset search on open
    onActiveChanged: {
        if (active) {
            searchField.text = "";
            updateFilter();
            searchField.forceActiveFocus();
        }
    }

    // ── Scrim ────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Colors.withAlpha(Colors.scrim, 0.45)
        TapHandler { onTapped: launcher.dismissed() }

        // ── Card ─────────────────────────────────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            width: 560; height: 480; radius: 20
            color: Colors.withAlpha(Colors.surfaceContainer, 0.95)
            border.color: Colors.withAlpha(Colors.outlineVariant, 0.25)
            border.width: 1

            // Prevent scrim click-through
            TapHandler { }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 20
                spacing: 14

                // ── Search bar ───────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true; height: 44; radius: 12
                    color: Colors.surfaceContainerHigh

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: "󰍉"; font.pixelSize: 18
                            color: Colors.contentSurfaceVariant
                            Layout.alignment: Qt.AlignVCenter
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            font.pixelSize: 14
                            color: Colors.contentSurface
                            clip: true
                            selectByMouse: true

                            Text {
                                anchors.fill: parent
                                text: "Search applications…"
                                font.pixelSize: 14
                                color: Colors.withAlpha(Colors.contentSurfaceVariant, 0.5)
                                visible: !searchField.text && !searchField.activeFocus
                                verticalAlignment: Text.AlignVCenter
                            }

                            onTextChanged: launcher.updateFilter()

                            Keys.onEscapePressed: launcher.dismissed()
                            Keys.onReturnPressed: {
                                if (filteredModel.count > 0) {
                                    Quickshell.execDetached([filteredModel.get(0).cmd]);
                                    launcher.dismissed();
                                }
                            }
                        }
                    }
                }

                // ── Grid ─────────────────────────────────────────────────────
                GridView {
                    id: appGrid
                    Layout.fillWidth: true; Layout.fillHeight: true
                    model: filteredModel
                    cellWidth: 125; cellHeight: 100
                    clip: true

                    delegate: Item {
                        width: appGrid.cellWidth; height: appGrid.cellHeight
                        required property int index
                        required property string name
                        required property string icon
                        required property string cmd

                        Rectangle {
                            anchors.fill: parent; anchors.margins: 4; radius: 14
                            color: cellHover.hovered ? Colors.primaryContainer : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Column {
                                anchors.centerIn: parent; spacing: 6

                                Text {
                                    text: icon; font.pixelSize: 28
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: cellHover.hovered ? Colors.contentPrimaryContainer : Colors.contentSurface
                                }
                                Text {
                                    text: name; font.pixelSize: 11; font.weight: Font.Medium
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: cellHover.hovered ? Colors.contentPrimaryContainer : Colors.contentSurfaceVariant
                                    elide: Text.ElideRight
                                    width: appGrid.cellWidth - 16
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            HoverHandler { id: cellHover }
                            TapHandler {
                                onTapped: {
                                    Quickshell.execDetached([cmd]);
                                    launcher.dismissed();
                                }
                            }
                        }
                    }

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        text: "No matching applications"
                        font.pixelSize: 13; color: Colors.contentSurfaceVariant
                        visible: filteredModel.count === 0
                    }
                }
            }
        }
    }
}
